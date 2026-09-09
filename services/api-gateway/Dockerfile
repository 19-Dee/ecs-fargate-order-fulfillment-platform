FROM golang:1.22-alpine AS builder
WORKDIR /api

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o api-gateway .

FROM alpine:3.22
WORKDIR /api

COPY --from=builder /api/api-gateway .

EXPOSE 8080

CMD ["./api-gateway"]