FROM golang:1.22-alpine AS builder
WORKDIR /ship

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o shipping-service .

FROM alpine:3.22
WORKDIR /sched

COPY --from=builder /ship/shipping-service .

EXPOSE 8085

CMD ["./shipping-service"]