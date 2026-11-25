#!/bin/bash
set -euo pipefail

atuin_ai_VERSION=${1:-}
BUILD_VERSION=${2:-}
UPSTREAM_COMMIT=${3:-}

UPSTREAM_REPO="atuinsh/atuin-ai"

if [ -z "$atuin_ai_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <atuin_ai_version> <build_version> [upstream_commit]"
    echo "Example: $0 0.1.0.20261127 1 c1514876b950a915656592d7fe555f994db1b7e4"
    exit 1
fi

PACKAGE_NAME="atuin-ai"
ORIG_TARBALL="${PACKAGE_NAME}_${atuin_ai_VERSION}.orig.tar.gz"
BUILD_DIR="${PACKAGE_NAME}-${atuin_ai_VERSION}"

echo "Creating the source package for atuin-ai ${atuin_ai_VERSION}-${BUILD_VERSION}..."

# A rebuild of a snapshot already released here (a +N build bump) must ship
# the very same orig tarball: the pool holds one per upstream version and
# reprepro refuses a different one, and nothing guarantees the archive
# download is byte-identical next time. Reuse the earlier release's copy.
if [ ! -f "$ORIG_TARBALL" ]; then
    for ((b = BUILD_VERSION - 1; b >= 1; b--)); do
        if wget -q "https://github.com/dariogriffo/atuin-ai-debian/releases/download/${atuin_ai_VERSION}%2B${b}/${ORIG_TARBALL}" -O "$ORIG_TARBALL"; then
            echo "  Reusing $ORIG_TARBALL from release ${atuin_ai_VERSION}+${b}"
            break
        fi
        rm -f "$ORIG_TARBALL"
    done
fi

# Otherwise the orig tarball is upstream's source at the snapshot's commit
if [ ! -f "$ORIG_TARBALL" ]; then
    if [ -z "$UPSTREAM_COMMIT" ]; then
        UPSTREAM_COMMIT=$(git ls-remote "https://github.com/${UPSTREAM_REPO}.git" refs/heads/main | cut -f1)
    fi
    if ! [[ "$UPSTREAM_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
        echo "❌ Upstream commit must be a full 40-character sha, got '${UPSTREAM_COMMIT}'"
        exit 1
    fi
    echo "Downloading upstream source at ${UPSTREAM_COMMIT}..."
    wget -q "https://github.com/${UPSTREAM_REPO}/archive/${UPSTREAM_COMMIT}.tar.gz" -O "$ORIG_TARBALL"
    echo "  Downloaded $ORIG_TARBALL"
else
    echo "  Using existing $ORIG_TARBALL"
fi

build_source_package() {
    local FULL_VERSION="${atuin_ai_VERSION}-${BUILD_VERSION}~griffo"
    local top

    echo "  Building source package ${FULL_VERSION}..."

    # GitHub archives extract as atuin-ai-<sha>/; rename to BUILD_DIR
    # (the whole listing, not head -1: an early exit is SIGPIPE under pipefail)
    top=$(tar -tzf "$ORIG_TARBALL" | cut -d/ -f1 | sort -u)
    if [ -z "$top" ] || [ "$(printf '%s\n' "$top" | wc -l)" -ne 1 ]; then
        echo "❌ Unexpected orig tarball layout: top-level entries '${top}'"
        exit 1
    fi
    if [ -z "$UPSTREAM_COMMIT" ]; then
        UPSTREAM_COMMIT="${top#atuin-ai-}"
    fi
    rm -rf "$BUILD_DIR" "$top"
    tar -xf "$ORIG_TARBALL"
    mv "$top" "$BUILD_DIR"

    # Copy Debian packaging directory
    cp -r debian "$BUILD_DIR/"

    # Generate the changelog (overwrites placeholder)
    cat > "$BUILD_DIR/debian/changelog" << EOF2
atuin-ai (${FULL_VERSION}) stable; urgency=medium

  * Snapshot of ${UPSTREAM_REPO} at ${UPSTREAM_COMMIT}.

 -- Dario Griffo <dariogriffo@gmail.com>  $(date -R)
EOF2

    # Build source package (.dsc + .debian.tar.xz); reuses existing .orig.tar.gz
    dpkg-source -b "$BUILD_DIR"

    rm -rf "$BUILD_DIR"
    echo "    ${FULL_VERSION}"
}

echo ""
# One source package for every suite, as with the binaries (see build_debian.sh).
build_source_package

echo ""
echo "Source packages created successfully!"
echo ""
echo "Generated files:"
ls -la "${PACKAGE_NAME}_"*.dsc "${PACKAGE_NAME}_"*.orig.tar.gz "${PACKAGE_NAME}_"*.debian.tar.xz 2>/dev/null || true
