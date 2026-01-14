#!/usr/bin/env bats

load "test_helper.sh"

setup() {
  export TEST_DIR="$BATS_TEST_TMPDIR"
  export HOME="$TEST_DIR/home"
  export CONFIG_DIR="$HOME/.config"
  export CONFIG_FILE="$CONFIG_DIR/dev-setup.conf"

  mkdir -p "$CONFIG_DIR"
  touch "$CONFIG_FILE"

  # Copy bin/setup for modification
  cp "bin/setup" "$TEST_DIR/setup_script"
  chmod +x "$TEST_DIR/setup_script"

  export PROJECT_DIR="$BATS_TEST_DIRNAME/.."
}

# Helper to run prompt_config and capture output
run_config() {
  # We need to source the script but prompt_config is internal.
  # Or we can just run the script but we need to bypass the actual setup steps.
  # bin/setup runs prompt_config then proceeds.
  # We can patch it to exit after prompt_config.
  sed -i.bak '/# initial setup/i exit 0' "$TEST_DIR/setup_script"

  # We also need to supply "n" to "Proceed with current configuration?" if we want to see the interactive list.
  # But "Current Toggles" is shown BEFORE the prompt.
  export PLATFORM=$1

  # Use MOCKED_UNAME to override detection inside script?
  # The script does ` [ -z "$PLATFORM" ] && detect_platform ` inside sourced vars.
  # We can pre-set PLATFORM env var.

  # We need to supply input to the read command to avoid hang
  printf "y\n" | "$TEST_DIR/setup_script"
}

@test "Config: Filters app_store on Linux" {
  export PLATFORM="Debian"
  run run_config "Debian"

  [[ "$output" != *"app_store"* ]]
}

@test "Config: Shows app_store on macOS" {
  export PLATFORM="macOS"
  run run_config "macOS"

  [[ "$output" == *"app_store"* ]]
}

@test "Config: Filters editor on Linux" {
  export PLATFORM="Fedora"
  run run_config "Fedora"

  [[ "$output" == *"editor"* ]]
}

@test "Config: Shows editor on macOS" {
  export PLATFORM="macOS"
  run run_config "macOS"

  [[ "$output" == *"editor"* ]]
}
