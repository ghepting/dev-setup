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

Integration tests are designed for CI containers only. They actually run `bin/setup` which installs packages and modifies the system.

## Test Suite Overview

### Unit Tests (39 tests) - Safe to Run Locally ✓

**`test_detection.bats`** (9 tests)

- Platform detection logic
- Helper functions (`is_macos`, `is_linux`, etc.)

**`test_utils.bats`** (20 tests)

- Config file management (`set_config_value`)
- SSH detection (`is_ssh`)
- Module enable/disable logic (`is_enabled`)

**`test_vars.bats`** (10 tests)

- Config loading and variable expansion
- Sanitization of corrupted values
- Fallback to defaults

### Integration Tests (7 tests) - CI Only ⚠️

**`test_integration.bats`** (7 tests)

- Smoke tests for each platform (macOS, Debian, Arch, Fedora)
- **These run the actual setup script and modify the system**
- Only meant for CI containers, not local development

## Running Full Integration Tests in Docker

To test the complete setup in a clean container (like CI does):

### Debian/Ubuntu

```bash
# Build the test image
docker build -t dev-setup-debian -f test/Dockerfile.debian .

# Run the full setup in a container
docker run --rm -it dev-setup-debian

# Or run interactively to debug
docker run --rm -it dev-setup-debian /bin/bash
# Then inside: cd /workspace && ./bin/setup
```

### Custom Test Scenarios

```bash
# Mount your local code for live testing
docker run --rm -it -v $(pwd):/workspace dev-setup-debian

# Run with specific environment variables
docker run --rm -it -e DEV_SETUP_REAL_SYSTEM=true dev-setup-debian
```

## Test Philosophy

- **Unit tests**: Cover pure logic functions without complex mocking - **safe to run locally**
- **Integration tests**: Run actual setup script - **only for CI containers**
- **CI tests**: Full end-to-end setup on real systems (Ubuntu, Debian containers)

We intentionally avoid:

- Complex mocking of system commands
- Testing interactive prompts (tested manually)
- Testing package installation in unit tests (tested in CI)

## Writing Tests

Tests use [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

### Example Unit Test

```bash
@test "function_name: does something" {
  load_lib "lib/core/utils.sh"

  # Setup
  export SOME_VAR="value"

  # Execute
  run some_function "arg"

  # Assert
  [ "$status" -eq 0 ]
  [[ "$output" == *"expected"* ]]
}
```

### Test Helper

Use `load_lib` to source modules with proper environment setup:

```bash
load_lib "lib/core/utils.sh"
load_lib "lib/modules/dotfiles.sh"
```

## CI Integration

GitHub Actions runs:

- **Unit tests** on the runner
- **Integration tests** in Ubuntu/Debian containers

See `.github/workflows/ci.yml` for details.
