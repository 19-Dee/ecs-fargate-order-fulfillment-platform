FROM golang:1.22-alpine AS builder
WORKDIR /dash

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o dashboard-api .

FROM alpine:3.22
WORKDIR /dash

COPY --from=builder /dash/dashboard-api .

EXPOSE 8086

CMD ["./dashboard-api"]