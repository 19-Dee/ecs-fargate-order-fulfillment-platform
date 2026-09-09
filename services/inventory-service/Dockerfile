FROM golang:1.22-alpine AS builder
WORKDIR /inv

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o inventory-service .

FROM alpine:3.22
WORKDIR /inv

COPY --from=builder /inv/inventory-service .

EXPOSE 8082

CMD ["./inventory-service"]