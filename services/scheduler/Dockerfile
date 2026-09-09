FROM golang:1.22-alpine AS builder
WORKDIR /sched

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o scheduler .

FROM alpine:3.22
WORKDIR /sched

COPY --from=builder /sched/scheduler .

EXPOSE 8091

CMD ["./scheduler"]