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
    echo "  $0 debian test     # Run bats tests inside container"
}

build_and_run() {
    local platform=$1
    local mode=${2:-run}
    local container_name="dev-setup-${platform}"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Building ${container_name}..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    docker build -t "${container_name}" -f "test/Dockerfile.${platform}" .

    # Create a volume for persistent home directory if it doesn't exist
    local volume_name="${container_name}-home"
    docker volume create "${volume_name}" >/dev/null

    # Pre-populate .zshrc in the volume to prevent zsh-newuser-install prompt
    # running a momentary container to touch the file in the shared volume
    docker run --rm -v "${volume_name}:/home/tester" "${container_name}" touch /home/tester/.zshrc

    local common_args=(
        --rm
        -it
        -v "$(pwd):/workspace"
        -v "${volume_name}:/home/tester"
        "${container_name}"
    )

    if [[ "$mode" == "shell" ]]; then
        echo ""
        echo "Starting interactive shell in ${platform} container..."
        docker run "${common_args[@]}" /bin/zsh
    elif [[ "$mode" == "test" ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Running Bats tests on ${platform}..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        # Run specific platform test file
        docker run -e CI=true "${common_args[@]}" bats "test/integration_${platform}.bats"
    elif [[ "$mode" == "debug" ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Debugging setup on ${platform}..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Pre-configure to match the failing test case
        # We need to run this in a separate container first to modify the persistent volume
        docker run --rm -v "${volume_name}:/home/tester" "${container_name}" \
            /bin/zsh -c "mkdir -p ~/.config && \
                         cat > ~/.config/dev-setup.conf <<EOF
dotfiles=false
editor=false
ruby=false
python=false
docker=false
EOF"

        # Run setup exactly as the test does
        docker run -e CI=true "${common_args[@]}" /bin/zsh -c "printf 'y\n' | ./bin/setup"
    else
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Running setup on ${platform}..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        docker run "${common_args[@]}"
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
