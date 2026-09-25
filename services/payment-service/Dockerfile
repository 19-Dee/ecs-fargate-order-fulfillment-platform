FROM golang:1.26-alpine AS builder
WORKDIR /pay

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o payment-service .

FROM alpine:3.22
WORKDIR /pay

COPY --from=builder /pay/payment-service .

EXPOSE 8083

CMD ["./payment-service"]