FROM golang:1.22-alpine AS builder
WORKDIR /ord

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o order-service .

FROM alpine:3.22
WORKDIR /notif

COPY --from=builder /ord/order-service .

EXPOSE 8081

CMD ["./order-service"]