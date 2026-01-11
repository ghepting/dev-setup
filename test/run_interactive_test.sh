#!/usr/bin/env zsh

# This script builds and runs the Debian test container interactively.
# It mounts the current directory as a volume so you can run scripts and see changes.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_NAME="dev-setup-debian-interactive"

echo "Building Debian test environment..."
docker build -t "$IMAGE_NAME" -f "$REPO_ROOT/test/Dockerfile.debian" "$REPO_ROOT"

echo "--------------------------------------------------------"
echo "Starting interactive Debian session as user 'tester'."
echo "Your repository is mounted at ~/dev-setup"
echo ""
echo "Try running:"
echo "  ./bin/setup         # Runs the full setup"
echo "  source lib/utils.sh # Test individual functions"
echo "--------------------------------------------------------"

docker run --rm -it \
  -v "$REPO_ROOT:/home/tester/dev-setup" \
  --name "dev-setup-test" \
  "$IMAGE_NAME" \
  /usr/bin/zsh
