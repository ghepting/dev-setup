#!/usr/bin/env bash

# Minimal test helper for smoke tests
# Only mocks essential platform detection for cross-platform testing

# Helper to source the library under test
load_lib() {
  local lib_file="$1"
  local repo_root
  repo_root="$(pwd)"

  export BATS_TEST_TMPDIR
  export HOME="$BATS_TEST_TMPDIR/home"
  export TEST_HOME="$HOME"
  export CONFIG_FILE="$HOME/.config/dev-setup.conf"
  export ZSHRC_FILE="$HOME/.zshrc"
  mkdir -p "$(dirname "$CONFIG_FILE")"
  touch "$ZSHRC_FILE"

  # Source core utilities
  # shellcheck source=lib/core/utils.sh
  source "$repo_root/lib/core/utils.sh"

  # Source core variables
  # shellcheck source=lib/core/vars.sh
  source "$repo_root/lib/core/vars.sh"

  # Source the target library
  if [[ "$lib_file" != "lib/core/vars.sh" && "$lib_file" != "lib/core/utils.sh" ]]; then
    # shellcheck disable=SC1090
    source "$repo_root/$lib_file"
  fi

  # Mock uname for platform detection tests
  if [[ -n "${MOCK_OS:-}" ]]; then
    uname() {
      if [[ "${MOCK_OS}" == "macOS" ]]; then
        echo "Darwin"
      else
        echo "Linux"
      fi
    }
    export -f uname
  fi
}
