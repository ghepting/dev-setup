#!/usr/bin/env bash
# Helper script to test dev-setup in Docker containers

set -e

PLATFORMS=("debian" "arch" "fedora")

usage() {
    echo "Usage: $0 [platform]"
    echo ""
    echo "Platforms:"
    echo "  debian  - Test on Debian stable"
    echo "  arch    - Test on Arch Linux"
    echo "  fedora  - Test on Fedora latest"
    echo "  all     - Test on all platforms"
    echo ""
    echo "Examples:"
    echo "  $0 debian          # Build and run on Debian"
    echo "  $0 all             # Test all platforms"
    echo "  $0 debian shell    # Start interactive shell"
}

build_and_run() {
    local platform=$1
    local mode=${2:-run}

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Building dev-setup-${platform}..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    docker build -t "dev-setup-${platform}" -f "test/Dockerfile.${platform}" .

    if [[ "$mode" == "shell" ]]; then
        echo ""
        echo "Starting interactive shell in ${platform} container..."
        docker run --rm -it "dev-setup-${platform}" /bin/bash
    else
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Running setup on ${platform}..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        docker run --rm -it "dev-setup-${platform}"
    fi
}

# Main
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

PLATFORM=$1
MODE=${2:-run}

case "$PLATFORM" in
    debian|arch|fedora)
        build_and_run "$PLATFORM" "$MODE"
        ;;
    all)
        for platform in "${PLATFORMS[@]}"; do
            build_and_run "$platform" "$MODE"
            echo ""
        done
        ;;
    *)
        echo "Error: Unknown platform '$PLATFORM'"
        echo ""
        usage
        exit 1
        ;;
esac
