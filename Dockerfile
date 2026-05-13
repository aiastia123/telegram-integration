# Build stage - 使用多阶段构建支持多架构
FROM --platform=$BUILDPLATFORM cgr.dev/chainguard/go:latest AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o memogram ./bin/memogram
RUN chmod +x memogram
RUN adduser -D -u 1000 memogram
RUN mkdir -p /app/data && chown memogram:memogram /app/data && chmod 700 /app/data

# Run stage
FROM cgr.dev/chainguard/static:latest
WORKDIR /app
ENV SERVER_ADDR=dns:localhost:5230
ENV BOT_TOKEN=your_telegram_bot_token
ENV DATA=/app/data/data.txt
COPY .env.example .env
COPY --from=builder /app/memogram .
# 从 builder 复制数据目录（chainguard/static 没有 shell，无法用 RUN）
COPY --from=builder /app/data /app/data
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
USER memogram
CMD ["./memogram"]
