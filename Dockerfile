#
# Builder
#

FROM golang:alpine as builder

# use version (for example "v0.3.3") or "main"
ARG WATCHTOWER_VERSION=main

RUN apk add --no-cache \
    alpine-sdk \
    ca-certificates \
    git \
    tzdata \
    curl

RUN git clone --branch "${WATCHTOWER_VERSION}" https://github.com/containrrr/watchtower.git

RUN \
  cd watchtower && \
  \
  GO111MODULE=on CGO_ENABLED=0 GOOS=linux go build -a -ldflags "-extldflags '-static' -X github.com/containrrr/watchtower/internal/meta.Version=$(git describe --tags)" . && \
  GO111MODULE=on go test ./... -v


#
# watchtower
#

FROM scratch

LABEL "com.centurylinklabs.watchtower"="true"

# copy files from other container, including curl
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /usr/bin/curl /usr/bin/curl
COPY --from=builder /bin/sh /bin/sh
COPY --from=builder /go/watchtower/watchtower /watchtower

ENTRYPOINT ["/watchtower"]
