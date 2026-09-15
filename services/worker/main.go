package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
)

// Event represents a message from SQS
type Event struct {
	Type      string                 `json:"type"`
	Payload   map[string]interface{} `json:"payload"`
	Timestamp string                 `json:"timestamp"`
}

func main() {
	sqsQueue := os.Getenv("SQS_QUEUE_URL")
	if sqsQueue == "" {
		log.Fatal("SQS_QUEUE_URL is required")
	}
	awsConfig, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Fatalf("failed to load AWS configuration: %v", err)
	}

	sqsClient := sqs.NewFromConfig(awsConfig)

	// Internal service URLs for event-driven calls
	services := map[string]string{
		"inventory":    getEnv("INVENTORY_SERVICE_URL", "http://inventory-service:8082"),
		"payment":      getEnv("PAYMENT_SERVICE_URL", "http://payment-service:8083"),
		"notification": getEnv("NOTIFICATION_SERVICE_URL", "http://notification-service:8084"),
		"shipping":     getEnv("SHIPPING_SERVICE_URL", "http://shipping-service:8085"),
		"order":        getEnv("ORDER_SERVICE_URL", "http://order-service:8081"),
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Health check endpoint
	go func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/livez", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(http.StatusOK) })
		mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]string{"status": "ok", "service": "worker"})
		})
		port := getEnv("HEALTH_PORT", "8090")
		log.Printf("Worker health check on :%s", port)
		http.ListenAndServe(":"+port, mux)
	}()

	// Graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigChan
		log.Println("Shutting down worker...")
		cancel()
	}()

	log.Println("Worker started, polling SQS for events...")
	pollAndProcess(ctx, sqsClient, sqsQueue, services)
}

func pollAndProcess(ctx context.Context, sqsClient *sqs.Client, queueURL string, services map[string]string) {
	client := &http.Client{Timeout: 10 * time.Second}

	for {
		select {
		case <-ctx.Done():
			log.Println("Worker stopped")
			return
		default:
			messages, err := receiveSQSMessages(ctx, sqsClient, queueURL)
			if err != nil {
				if ctx.Err() != nil {
					continue
				}
				log.Printf("Failed to receive messages from SQS: %v", err)
				time.Sleep(5 * time.Second)
				continue
			}

			for _, message := range messages {
				if message.Body == nil {
					log.Println("Received SQS message with no body; leaving it for retry")
					continue
				}

				var event Event
				if err := json.Unmarshal([]byte(*message.Body), &event); err != nil {
					log.Printf("Failed to parse event: %v", err)
					continue
				}

				log.Printf("Processing event: %s", event.Type)

				if err := handleEvent(client, services, event); err != nil {
					log.Printf("Failed to handle event %s: %v", event.Type, err)
					// In production: don't delete from SQS, let it retry or go to DLQ
					continue
				}

				log.Printf("Successfully processed: %s", event.Type)
				if message.ReceiptHandle == nil {
					log.Println("Processed SQS message has no receipt handle; cannot delete it")
					continue
				}

				if err := deleteSQSMessage(ctx, sqsClient, queueURL, *message.ReceiptHandle); err != nil {
					log.Printf("Failed to delete processed event %s from SQS: %v", event.Type, err)
					continue
				}

				log.Printf("Deleted processed event from SQS: %s", event.Type)
			}

			if len(messages) == 0 {
				time.Sleep(5 * time.Second)
			}
		}
	}
}

func handleEvent(client *http.Client, services map[string]string, event Event) error {
	switch event.Type {
	case "order.created":
		orderID, err := payloadInt(event.Payload, "order_id")
		if err != nil {
			return err
		}
		order, err := getOrder(client, services["order"], orderID)
		if err != nil {
			return err
		}
		if payloadString(order, "status") != "pending" {
			log.Printf("  -> Order %d already progressed to %s; skipping duplicate order.created", orderID, payloadString(order, "status"))
			return nil
		}
		items, ok := event.Payload["items"]
		if !ok {
			return fmt.Errorf("order.created missing items")
		}
		log.Printf("  -> Reserving inventory for order %d", orderID)
		if _, _, err := requestJSON(client, http.MethodPost, services["inventory"]+"/reserve", map[string]interface{}{
			"order_id": orderID,
			"items":    items,
		}); err != nil {
			return fmt.Errorf("reserve inventory: %w", err)
		}

		log.Printf("  -> Charging payment for order %d", orderID)
		status, _, err := requestJSON(client, http.MethodPost, services["payment"]+"/charge", map[string]interface{}{
			"order_id":    orderID,
			"customer_id": payloadString(event.Payload, "customer_id"),
			"amount":      payloadFloat(event.Payload, "total"),
			"currency":    payloadString(event.Payload, "currency"),
			"method":      "demo",
		})
		if err != nil && status != http.StatusPaymentRequired {
			return fmt.Errorf("charge payment: %w", err)
		}
		// Both completed and failed charges publish their own event. A 402 is a
		// handled business outcome, not an infrastructure failure.
		return nil

	case "order.status_changed":
		newStatus, _ := event.Payload["new_status"].(string)
		orderID, err := payloadInt(event.Payload, "order_id")
		if err != nil {
			return err
		}

		switch newStatus {
		case "processing":
			order, err := getOrder(client, services["order"], orderID)
			if err != nil {
				return err
			}
			log.Printf("  -> Creating shipment for order %d", orderID)
			_, _, err = requestJSON(client, http.MethodPost, services["shipping"]+"/shipments", map[string]interface{}{
				"order_id":       orderID,
				"recipient_name": payloadString(order, "customer_id"),
				"address_line1":  "Demo fulfilment address",
				"city":           "London",
				"country":        "GB",
				"weight_kg":      1,
			})
			return err

		case "cancelled":
			order, err := getOrder(client, services["order"], orderID)
			if err != nil {
				return err
			}
			log.Printf("  -> Releasing inventory for cancelled order %d", orderID)
			if _, _, err := requestJSON(client, http.MethodPost, services["inventory"]+"/release", map[string]interface{}{"order_id": orderID}); err != nil {
				return err
			}
			log.Printf("  -> Refunding completed payment for cancelled order %d when present", orderID)
			if _, _, err := requestJSON(client, http.MethodPost, services["payment"]+"/refund", map[string]interface{}{
				"order_id": orderID,
				"reason":   "order cancelled",
			}); err != nil {
				return err
			}
			return sendNotification(client, services["notification"], order, "payment_failed", orderID, map[string]interface{}{})
		}

	case "payment.completed":
		orderID, err := payloadInt(event.Payload, "order_id")
		if err != nil {
			return err
		}
		log.Printf("  -> Payment successful, confirming order %d", orderID)
		if err := ensureOrderStatus(client, services["order"], orderID, "confirmed"); err != nil {
			return err
		}
		order, err := getOrder(client, services["order"], orderID)
		if err != nil {
			return err
		}
		if err := sendNotification(client, services["notification"], order, "order_confirmed", orderID, map[string]interface{}{
			"Total":    order["total"],
			"Currency": order["currency"],
		}); err != nil {
			return err
		}
		return ensureOrderStatus(client, services["order"], orderID, "processing")

	case "payment.failed":
		orderID, err := payloadInt(event.Payload, "order_id")
		if err != nil {
			return err
		}
		log.Printf("  -> Payment failed, cancelling order %d", orderID)
		// The resulting order.status_changed event owns release/refund/notification.
		return ensureOrderStatus(client, services["order"], orderID, "cancelled")

	case "shipment.created":
		orderID, err := payloadInt(event.Payload, "order_id")
		if err != nil {
			return err
		}
		tracking := payloadString(event.Payload, "tracking_number")
		log.Printf("  -> Shipment created, marking order %d shipped", orderID)
		if err := ensureOrderStatus(client, services["order"], orderID, "shipped"); err != nil {
			return err
		}
		order, err := getOrder(client, services["order"], orderID)
		if err != nil {
			return err
		}
		if err := sendNotification(client, services["notification"], order, "order_shipped", orderID, map[string]interface{}{"TrackingNumber": tracking}); err != nil {
			return err
		}
		if getEnv("AUTO_DELIVER", "true") == "true" {
			log.Printf("  -> Completing demo carrier delivery for order %d", orderID)
			_, _, err = requestJSON(client, http.MethodPost, services["shipping"]+"/webhook", map[string]interface{}{
				"tracking_number": tracking,
				"status":          "delivered",
				"location":        "London",
				"description":     "Delivered by demo carrier",
			})
			return err
		}

	case "shipment.delivered":
		orderID, err := payloadInt(event.Payload, "order_id")
		if err != nil {
			return err
		}
		log.Printf("  -> Shipment delivered, completing order %d", orderID)
		if err := ensureOrderStatus(client, services["order"], orderID, "delivered"); err != nil {
			return err
		}
		order, err := getOrder(client, services["order"], orderID)
		if err != nil {
			return err
		}
		return sendNotification(client, services["notification"], order, "order_delivered", orderID, map[string]interface{}{})

	default:
		log.Printf("  -> Unknown event type: %s (skipping)", event.Type)
	}
	return nil
}

func requestJSON(client *http.Client, method, url string, payload interface{}) (int, map[string]interface{}, error) {
	var body io.Reader
	if payload != nil {
		data, err := json.Marshal(payload)
		if err != nil {
			return 0, nil, err
		}
		body = bytes.NewReader(data)
	}
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return 0, nil, err
	}
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := client.Do(req)
	if err != nil {
		return 0, nil, err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return resp.StatusCode, nil, err
	}
	result := map[string]interface{}{}
	if len(data) > 0 {
		_ = json.Unmarshal(data, &result)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return resp.StatusCode, result, fmt.Errorf("%s %s returned %d: %s", method, url, resp.StatusCode, string(data))
	}
	return resp.StatusCode, result, nil
}

func getOrder(client *http.Client, orderService string, orderID int) (map[string]interface{}, error) {
	_, order, err := requestJSON(client, http.MethodGet, fmt.Sprintf("%s/%d", orderService, orderID), nil)
	if err != nil {
		return nil, fmt.Errorf("get order %d: %w", orderID, err)
	}
	return order, nil
}

func ensureOrderStatus(client *http.Client, orderService string, orderID int, target string) error {
	order, err := getOrder(client, orderService, orderID)
	if err != nil {
		return err
	}
	current := payloadString(order, "status")
	if statusAtOrBeyond(current, target) && current != target {
		return nil
	}
	_, _, err = requestJSON(client, http.MethodPut, orderService+"/status", map[string]interface{}{
		"order_id":   orderID,
		"new_status": target,
	})
	return err
}

func statusAtOrBeyond(current, target string) bool {
	if current == "cancelled" {
		return target == "cancelled"
	}
	rank := map[string]int{"pending": 0, "confirmed": 1, "processing": 2, "shipped": 3, "delivered": 4}
	currentRank, currentOK := rank[current]
	targetRank, targetOK := rank[target]
	return currentOK && targetOK && currentRank >= targetRank
}

func sendNotification(client *http.Client, notificationService string, order map[string]interface{}, template string, orderID int, extra map[string]interface{}) error {
	data := map[string]interface{}{
		"OrderID":      orderID,
		"CustomerName": payloadString(order, "customer_id"),
	}
	for key, value := range extra {
		data[key] = value
	}
	_, _, err := requestJSON(client, http.MethodPost, notificationService+"/send", map[string]interface{}{
		"recipient":       payloadString(order, "customer_id"),
		"channel":         "email",
		"template":        template,
		"idempotency_key": fmt.Sprintf("order:%d:%s", orderID, template),
		"data":            data,
	})
	return err
}

func payloadInt(payload map[string]interface{}, key string) (int, error) {
	value, ok := payload[key]
	if !ok {
		return 0, fmt.Errorf("missing %s", key)
	}
	switch n := value.(type) {
	case float64:
		return int(n), nil
	case int:
		return n, nil
	default:
		return 0, fmt.Errorf("invalid %s", key)
	}
}

func payloadFloat(payload map[string]interface{}, key string) float64 {
	switch n := payload[key].(type) {
	case float64:
		return n
	case int:
		return float64(n)
	default:
		return 0
	}
}

func payloadString(payload map[string]interface{}, key string) string {
	value, _ := payload[key].(string)
	return value
}

func receiveSQSMessages(ctx context.Context, sqsClient *sqs.Client, queueURL string) ([]types.Message, error) {
	output, err := sqsClient.ReceiveMessage(ctx, &sqs.ReceiveMessageInput{
		QueueUrl:            &queueURL,
		WaitTimeSeconds:     20,
		MaxNumberOfMessages: 10,
	})
	if err != nil {
		return nil, err
	}

	return output.Messages, nil
}

func deleteSQSMessage(ctx context.Context, sqsClient *sqs.Client, queueURL, receiptHandle string) error {
	_, err := sqsClient.DeleteMessage(ctx, &sqs.DeleteMessageInput{
		QueueUrl:      &queueURL,
		ReceiptHandle: &receiptHandle,
	})
	return err
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
