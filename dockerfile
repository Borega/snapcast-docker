ARG ALPINE_VERSION=3.19

# ========================================
# Stage 1: Build LibreSpot
# ========================================
FROM alpine:${ALPINE_VERSION} AS build-librespot
RUN apk add --no-cache \
  git curl build-base pkgconfig \
  openssl-dev alsa-lib-dev pulseaudio-dev

# Install rustup and latest stable Rust (edition 2024 support)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --profile minimal && \
    echo 'source $HOME/.cargo/env' >> /etc/profile

ENV PATH="/root/.cargo/bin:${PATH}"

# Clone latest librespot
RUN git clone --depth=1 https://github.com/librespot-org/librespot.git /src/librespot

# Build librespot with dynamic linking
WORKDIR /src/librespot
ENV RUSTFLAGS="-C target-feature=-crt-static"
RUN cargo build --release

# ========================================
# Stage 2: Build Snapcast
# ========================================
FROM alpine:${ALPINE_VERSION} AS build-snapcast
RUN apk add --no-cache \
  git build-base cmake boost-dev alsa-lib-dev soxr-dev \
  avahi-dev flac-dev libogg-dev libvorbis-dev opus-dev expat-dev openssl-dev

RUN git clone --depth=1 https://github.com/badaix/snapcast.git /src/snapcast

WORKDIR /src/snapcast
RUN mkdir build && cd build && cmake .. && make -j$(nproc)

# ========================================
# Stage 3: Final minimal runtime image
# ========================================
FROM alpine:${ALPINE_VERSION}
RUN apk add --no-cache \
  openssl alsa-lib soxr boost-libs libpulse avahi dbus \
  flac-libs libogg libvorbis opus expat

# Copy built binaries
COPY --from=build-librespot /src/librespot/target/release/librespot /usr/local/bin/librespot
COPY --from=build-snapcast /src/snapcast/bin/snapserver /usr/local/bin/snapserver

# Create entrypoint script
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'mkdir -p /var/run/dbus' >> /entrypoint.sh && \
    echo 'dbus-daemon --system' >> /entrypoint.sh && \
    echo 'avahi-daemon --daemonize' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '# Start librespot if enabled' >> /entrypoint.sh && \
    echo 'if [ "$START_LIBRESPOT" = "true" ]; then' >> /entrypoint.sh && \
    echo '  rm -f /tmp/snapfifo' >> /entrypoint.sh && \
    echo '  mkfifo /tmp/snapfifo' >> /entrypoint.sh && \
    echo '  /usr/local/bin/librespot --name "${LIBRESPOT_NAME:-Snapcast}" --backend pipe --device /tmp/snapfifo --bitrate ${LIBRESPOT_BITRATE:-320} --initial-volume 100 &' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo 'exec "$@"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/sh"]