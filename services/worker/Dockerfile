FROM golang:1.22-alpine AS builder
WORKDIR /work

COPY go.mod ./
RUN go mod download

COPY . .
RUN go build -o worker .

FROM alpine:3.22
WORKDIR /work

COPY --from=builder /work/worker .

EXPOSE 8090

CMD ["./worker"]