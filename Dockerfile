# Compiled on Ubuntu 22.04, the oldest suite served (glibc 2.35, OpenSSL 3.0),
# so the one binary runs on every Debian and Ubuntu suite.
FROM ubuntu:22.04 AS build

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential pkg-config libssl-dev curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# The client needs Rust 1.95 or newer, which no suite's rustc provides
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable
ENV PATH=/root/.cargo/bin:$PATH

ARG ATUIN_AI_SRC
COPY ${ATUIN_AI_SRC} /src
WORKDIR /src/client
RUN cargo build --release --locked \
    && strip target/release/atuin-ai \
    && ./target/release/atuin-ai --version

FROM ubuntu:22.04

ARG atuin_ai_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG UPSTREAM_COMMIT
ARG ATUIN_AI_SRC
ARG ATUIN_AI_DEPENDS

RUN mkdir -p /output/DEBIAN /output/usr/bin /output/usr/share/doc/atuin-ai/examples

COPY --from=build /src/client/target/release/atuin-ai /output/usr/bin/atuin-ai
COPY ${ATUIN_AI_SRC}/client/ai.example.toml /output/usr/share/doc/atuin-ai/examples/ai.example.toml

COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
COPY output/copyright /output/usr/share/doc/atuin-ai/
COPY output/changelog.Debian /output/usr/share/doc/atuin-ai/
COPY output/README.md /output/usr/share/doc/atuin-ai/

RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/atuin-ai/changelog.Debian
RUN sed -i "s/UPSTREAM_COMMIT/$UPSTREAM_COMMIT/" /output/usr/share/doc/atuin-ai/changelog.Debian
RUN sed -i "s/atuin_ai_VERSION/$atuin_ai_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control
RUN sed -i "s/ATUIN_AI_DEPENDS/$ATUIN_AI_DEPENDS/" /output/DEBIAN/control

# Normalise modes: COPY keeps the build host's (a 002 umask makes files group-writable)
RUN chmod -R u=rwX,go=rX /output && chmod 755 /output/usr/bin/atuin-ai /output/DEBIAN/postinst

RUN dpkg-deb -Zxz --build /output /atuin-ai_${FULL_VERSION}.deb
