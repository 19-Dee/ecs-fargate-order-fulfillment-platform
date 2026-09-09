FROM golang:1.22-alpine AS builder
WORKDIR /notif

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o notification-service .

FROM alpine:3.22
WORKDIR /notif

COPY --from=builder /notif/notification-service .

EXPOSE 8084

CMD ["./notification-service"]
