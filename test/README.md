# Testing Guide

This directory contains the test suite for the dev-setup automation scripts.

## Quick Start - Local Testing

**Run unit tests locally (safe, no system changes):**

```bash
# All unit tests (recommended)
bats test/test_detection.bats test/test_utils.bats test/test_vars.bats

# Or individually
bats test/test_detection.bats  # Platform detection
bats test/test_utils.bats      # Core utilities
bats test/test_vars.bats       # Config loading
```

**⚠️ Do NOT run integration tests locally:**

```bash
# This will try to modify your system!
bats test/test_integration.bats  # ❌ Don't run this locally
```

## Test Suite Overview

### Unit Tests (39 tests) - Safe to Run Locally ✓

- **`test_detection.bats`** (9 tests) - Platform detection
- **`test_utils.bats`** (20 tests) - Core utilities
- **`test_vars.bats`** (10 tests) - Config loading

### Integration Tests (7 tests) - CI/Docker Only ⚠️

- **`test_integration.bats`** (7 tests) - Full setup smoke tests
- These run `bin/setup` and modify the system
- Auto-skip when run locally (not in CI)

## Docker Testing (Recommended for Integration Tests)

### Quick Start

Use the helper script to test on any platform:

```bash
# Test on Debian
./test/docker-test.sh debian

# Test on Arch Linux
./test/docker-test.sh arch

# Test on Fedora
./test/docker-test.sh fedora

# Test on all platforms
./test/docker-test.sh all

# Start interactive shell for debugging
./test/docker-test.sh debian shell
```

### Manual Docker Commands

If you prefer to run Docker commands directly:

```bash
# Debian
docker build -t dev-setup-debian -f test/Dockerfile.debian .
docker run --rm -it dev-setup-debian

# Arch Linux
docker build -t dev-setup-arch -f test/Dockerfile.arch .
docker run --rm -it dev-setup-arch

# Fedora
docker build -t dev-setup-fedora -f test/Dockerfile.fedora .
docker run --rm -it dev-setup-fedora
```

### Interactive Debugging

```bash
# Start a shell in the container
docker run --rm -it dev-setup-debian /bin/bash

# Then manually run setup
cd /workspace
./bin/setup
```

### Live Code Testing

Mount your local code for testing without rebuilding:

```bash
docker run --rm -it -v $(pwd):/workspace dev-setup-debian
```

## How It Works

**Developers can run integration tests locally using Docker:**

1. **Build** - Creates a clean container with the platform's base image
2. **Copy** - Copies your code into `/workspace` in the container
3. **Run** - Executes `./bin/setup` as a non-root user
4. **Isolated** - No changes to your host machine
5. **Disposable** - Container is deleted after run (`--rm` flag)

This gives you the same confidence as CI without affecting your system!

## Test Philosophy

- **Unit tests**: Pure logic, no mocking - safe locally
- **Integration tests**: Full setup - Docker/CI only
- **Docker tests**: Real systems, isolated containers

## Writing Tests

Tests use [BATS](https://github.com/bats-core/bats-core).

### Example

```bash
@test "function_name: does something" {
  load_lib "lib/core/utils.sh"

  export SOME_VAR="value"
  run some_function "arg"

  [ "$status" -eq 0 ]
  [[ "$output" == *"expected"* ]]
}
```

## CI Integration

GitHub Actions runs:

- Unit tests on the runner
- Integration tests in Docker containers

See `.github/workflows/ci.yml`.
