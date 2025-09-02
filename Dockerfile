# === Stage 1: Build fusermount3-proxy ===
FROM golang:1.20.7 AS fusermount3-proxy-builder

# === ARG ===
ARG HTTP_PROXY

# === PROXY ===
# Queste variabili sono necessarie per il Go toolchain
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTP_PROXY}
ENV GOPROXY=https://proxy.golang.org,direct

WORKDIR /meta-fuse-csi-plugin
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN make fusermount3-proxy BINDIR=/bin

# === Stage 2: Runtime image ===
FROM ubuntu:22.04
ARG TARGETARCH

# === ARG ===
ARG HTTP_PROXY=""
ARG NO_PROXY=""

# === PROXY ===
# Imposta le variabili d'ambiente per il runtime in modo consistente
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTP_PROXY}
ENV NO_PROXY=${NO_PROXY}

# Configura il proxy per apt
RUN echo "Acquire::http::Proxy \"$HTTP_PROXY\";" > /etc/apt/apt.conf.d/99proxy && \
    echo "Acquire::https::Proxy \"$HTTP_PROXY\";" >> /etc/apt/apt.conf.d/99proxy

# Install dependencies
RUN apt update && apt install -y \
    ca-certificates \
    fuse3 \
    sshfs \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Copy fusermount3 proxy
COPY --from=fusermount3-proxy-builder /bin/fusermount3-proxy /bin/fusermount3
# Usa il flag -f per forzare la sovrascrittura del link esistente
RUN ln -sf /bin/fusermount3 /bin/fusermount

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
