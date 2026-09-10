resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/ecs/api-gateway"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "order_service" {
  name              = "/ecs/order-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "inventory_service" {
  name              = "/ecs/inventory-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "payment_service" {
  name              = "/ecs/payment-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "notification_service" {
  name              = "/ecs/notification-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "shipping_service" {
  name              = "/ecs/shipping-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "dashboard_api" {
  name              = "/ecs/dashboard-api"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/worker"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "scheduler" {
  name              = "/ecs/scheduler"
  retention_in_days = 7
}
