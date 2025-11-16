# ========================================
# Stage 1: Build LibreSpot
# ========================================
FROM alpine:3.19 AS build-librespot

# Install tools required to build Rust projects
RUN apk add --no-cache \
    git \
    curl \
    build-base \
    pkgconfig \
    openssl-dev \
    alsa-lib-dev \
    alsa-lib-dev \
    pulseaudio-dev

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
FROM alpine:3.19 AS build-snapcast

RUN apk add --no-cache \
    git \
    build-base \
    cmake \
    boost-dev \
    alsa-lib-dev \
    soxr-dev \
    avahi-dev \
    flac-dev \
    libogg-dev \
    libvorbis-dev \
    opus-dev \
    expat-dev \
    openssl-dev

RUN git clone --depth=1 https://github.com/badaix/snapcast.git /src/snapcast

WORKDIR /src/snapcast
RUN mkdir build && cd build && cmake .. && make -j$(nproc)

# ========================================
# Stage 3: Final minimal runtime image
# ========================================
FROM alpine:3.19

RUN apk add --no-cache \
    openssl \
    alsa-lib \
    soxr \
    boost1.82-system \
    boost1.82-thread \
    libpulse \
    avahi-libs \
    flac-libs \
    libogg \
    libvorbis \
    opus \
    expat

# Copy built binaries
COPY --from=build-librespot /src/librespot/target/release/librespot /usr/local/bin/librespot
COPY --from=build-snapcast /src/snapcast/bin/snapserver /usr/local/bin/snapserver

CMD ["/bin/sh"]