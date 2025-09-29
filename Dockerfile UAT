# syntax=docker/dockerfile:1.7

# Stage 1: Download dependencies
FROM ghcr.io/fintronners/base-go:latest AS deps
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Stage 2: Build binary
FROM ghcr.io/fintronners/base-go:latest AS builder
WORKDIR /src

# Copy dependencies from previous stage
COPY --from=deps /go/pkg/mod /go/pkg/mod

# Copy source code
COPY . .

# Build with cache mounts (removed conservative flags for speed)
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build --tags=UAT -trimpath -ldflags="-s -w" \
    -o /out/ftron cmd/ftron/main.go

# Stage 3: Final minimal image
FROM alpine:3.20
WORKDIR /app

# Install only necessary packages (no cleanup needed with --no-cache)
RUN apk add --no-cache tzdata ca-certificates

# Copy binary from builder
COPY --from=builder /out/ftron /app/ftron

# Run as non-root user
USER 65532:65532

ENTRYPOINT ["/app/ftron"]
