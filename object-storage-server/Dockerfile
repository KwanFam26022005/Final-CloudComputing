# Build source MinIO chinh thuc tren local cho bai lab.
# Source goc: https://github.com/minio/minio/tree/RELEASE.2025-10-15T17-29-55Z
# Digest image nen da doi chieu voi manifest nhieu kien truc tren registry.
FROM --platform=$BUILDPLATFORM golang:1.24.8-alpine@sha256:3d78beb141d98f42337f1252ecf2a5f20374109929a4c3f6817f9e4179cc0ae5 AS build

RUN apk add --no-cache ca-certificates git
RUN git clone --depth 1 --branch RELEASE.2025-10-15T17-29-55Z \
    https://github.com/minio/minio.git /src/minio
WORKDIR /src/minio

# Gioi han tai nguyen bien dich theo Docker VM local.
ENV CGO_ENABLED=0 GOMAXPROCS=2 GOTOOLCHAIN=local
RUN go mod download
ARG TARGETOS
ARG TARGETARCH
RUN mkdir -p /out \
    && MINIO_RELEASE=RELEASE go run buildscripts/gen-ldflags.go \
        2025-10-15T17:29:55Z > /tmp/minio-ldflags \
    && GOOS="$TARGETOS" GOARCH="$TARGETARCH" go build -mod=readonly -p 1 -tags kqueue -trimpath \
        -ldflags "$(cat /tmp/minio-ldflags)" -o /out/minio .

FROM alpine:3.22@sha256:2e0b81d60597f449baa56dc25d355367869d2dca4cd57e866f1e2b52af3eb55f

LABEL org.opencontainers.image.title="N07_CLoud MinIO lab source build" \
      org.opencontainers.image.source="https://github.com/minio/minio" \
      org.opencontainers.image.version="RELEASE.2025-10-15T17-29-55Z" \
      org.opencontainers.image.licenses="AGPL-3.0-only"

COPY --from=build /out/minio /usr/local/bin/minio
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /src/minio/LICENSE /src/minio/CREDITS /usr/share/licenses/minio/

# Kiem tra binary tren kien truc dich sau giai doan bien dich.
RUN /usr/local/bin/minio --version

EXPOSE 9000 9001
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=6 \
    CMD wget -q -O /dev/null http://127.0.0.1:9000/minio/health/live || exit 1

ENTRYPOINT ["/usr/local/bin/minio"]
CMD ["server", "/data", "--console-address", ":9001"]
