atuin_ai_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified
UPSTREAM_COMMIT=${4:-}

./build_debian.sh "$1" "$2" "$ARCH" "$UPSTREAM_COMMIT"
./build_src.sh "$1" "$2" "$UPSTREAM_COMMIT"
