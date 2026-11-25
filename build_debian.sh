#!/bin/bash
# Builds the atuin-ai .deb for one architecture from an upstream commit.
#
# Upstream (atuinsh/atuin-ai) publishes no releases and no binaries, so the
# client is compiled here, natively: amd64 on an amd64 host, arm64 on an arm64
# host (GitHub's ubuntu-24.04-arm runner). The packages are weekly snapshots
# of upstream's main branch, versioned <cargo version>.<YYYYMMDD>.

atuin_ai_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}
UPSTREAM_COMMIT=${4:-}

UPSTREAM_REPO="atuinsh/atuin-ai"

if [ -z "$atuin_ai_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <atuin_ai_version> <build_version> [architecture] [upstream_commit]"
    echo "Example: $0 0.1.0.20261127 1 amd64 c1514876b950a915656592d7fe555f994db1b7e4"
    echo "Supported architectures: amd64, arm64 (the host's own: the build is native)"
    echo "Without a commit, upstream's current main is built."
    exit 1
fi

if ! [[ "$atuin_ai_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]{8}$ ]]; then
    echo "❌ Version must be <cargo version>.<YYYYMMDD>, e.g. 0.1.0.20261127"
    exit 1
fi

# Runtime dependencies, measured on the built binary (readelf -d and
# --dyn-syms): glibc 2.34, libgcc_s, OpenSSL 3.0; SQLite is linked in. Built on
# Ubuntu 22.04, so the floor stays at or below jammy's 2.35 and it runs on
# every suite. libssl3t64 is the t64 rename (noble, trixie and later).
# atuin: the bash and zsh hooks build on Atuin's own widget, and the client
# reads Atuin's history database.
ATUIN_AI_DEPENDS="libc6 (>= 2.34), libgcc-s1, libssl3t64 | libssl3 (>= 3.0.0), atuin"

case "$ARCH" in
    amd64|arm64) ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        echo "Supported architectures: amd64, arm64"
        exit 1
        ;;
esac

HOST_ARCH=$(dpkg --print-architecture 2>/dev/null || true)
if [ -z "$HOST_ARCH" ]; then
    case "$(uname -m)" in
        x86_64) HOST_ARCH=amd64 ;;
        aarch64) HOST_ARCH=arm64 ;;
        *) HOST_ARCH=$(uname -m) ;;
    esac
fi
if [ "$ARCH" != "$HOST_ARCH" ]; then
    echo "❌ $ARCH is compiled natively and this host is $HOST_ARCH"
    exit 1
fi

if [ -z "$UPSTREAM_COMMIT" ]; then
    UPSTREAM_COMMIT=$(git ls-remote "https://github.com/${UPSTREAM_REPO}.git" refs/heads/main | cut -f1)
fi
if ! [[ "$UPSTREAM_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
    echo "❌ Upstream commit must be a full 40-character sha, got '${UPSTREAM_COMMIT}'"
    exit 1
fi

SRC_DIR="atuin-ai-src"
rm -rf "$SRC_DIR"
mkdir -p "$SRC_DIR"
if ! wget -q "https://github.com/${UPSTREAM_REPO}/archive/${UPSTREAM_COMMIT}.tar.gz" -O "$SRC_DIR.tar.gz"; then
    echo "❌ Failed to download upstream source at ${UPSTREAM_COMMIT}"
    exit 1
fi
tar -xzf "$SRC_DIR.tar.gz" -C "$SRC_DIR" --strip-components=1
rm -f "$SRC_DIR.tar.gz"
for f in client/Cargo.toml client/Cargo.lock client/LICENSE client/ai.example.toml; do
    if [ ! -f "$SRC_DIR/$f" ]; then
        echo "❌ Unexpected source layout: $SRC_DIR/$f not found"
        exit 1
    fi
done

# The snapshot version starts with the client's own version at that commit,
# so atuin-ai --version and the package agree.
CARGO_VERSION=$(sed -n 's/^version = "\(.*\)"$/\1/p' "$SRC_DIR/client/Cargo.toml" | head -1)
if [ "${atuin_ai_VERSION%.*}" != "$CARGO_VERSION" ]; then
    echo "❌ Version $atuin_ai_VERSION does not start with the client's version $CARGO_VERSION at ${UPSTREAM_COMMIT}"
    exit 1
fi

# One package for every suite, versioned <ver>-<build>~griffo: the ~ keeps it
# below a distro's own build of the same version.
FULL_VERSION="$atuin_ai_VERSION-${BUILD_VERSION}~griffo_${ARCH}"
echo "🚀 Building atuin-ai $FULL_VERSION from ${UPSTREAM_REPO}@${UPSTREAM_COMMIT}"

if ! docker build . -t "atuin-ai-$ARCH" \
    --build-arg atuin_ai_VERSION="$atuin_ai_VERSION" \
    --build-arg BUILD_VERSION="$BUILD_VERSION" \
    --build-arg FULL_VERSION="$FULL_VERSION" \
    --build-arg ARCH="$ARCH" \
    --build-arg UPSTREAM_COMMIT="$UPSTREAM_COMMIT" \
    --build-arg ATUIN_AI_SRC="$SRC_DIR" \
    --build-arg ATUIN_AI_DEPENDS="$ATUIN_AI_DEPENDS"; then
    echo "❌ Failed to build Docker image for $ARCH"
    exit 1
fi

id="$(docker create "atuin-ai-$ARCH")"
if ! docker cp "$id:/atuin-ai_$FULL_VERSION.deb" - > "./atuin-ai_$FULL_VERSION.deb"; then
    echo "❌ Failed to extract .deb package for $ARCH"
    exit 1
fi
docker rm "$id" >/dev/null || true

if ! tar -xf "./atuin-ai_$FULL_VERSION.deb"; then
    echo "❌ Failed to extract .deb contents for $ARCH"
    exit 1
fi

rm -rf "$SRC_DIR"
echo "✅ Successfully built atuin-ai_$FULL_VERSION.deb"
