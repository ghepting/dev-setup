#!/usr/bin/env bats

load "test_helper.sh"

setup() {
  export TEST_DIR="$BATS_TEST_TMPDIR"
  export HOME="$TEST_DIR/home"
  export CONFIG_DIR="$HOME/.config"
  export DEV_ZSH_CONFIG="$HOME/.zshrc.dev"
  export ZSHRC_FILE="$HOME/.zshrc"

  mkdir -p "$CONFIG_DIR"
  touch "$ZSHRC_FILE"

  # Source ZSH lib
  source "lib/core/vars.sh"
  source "lib/core/utils.sh"
  source "lib/core/zsh.sh"

  # Setup environment logic
  if [ "$(type -t setup_mocks)" == "function" ]; then
    setup_mocks
  fi
}

@test "ZSH: ensure_zsh_include creates dev config and adds source line" {
  rm -f "$DEV_ZSH_CONFIG"

  ensure_zsh_include

  [ -f "$DEV_ZSH_CONFIG" ]
  run grep "source \"$DEV_ZSH_CONFIG\"" "$ZSHRC_FILE"
  [ "$status" -eq 0 ]
}

@test "ZSH: ensure_zsh_include is idempotent" {
  ensure_zsh_include
  ensure_zsh_include

  # COUNT occurrences
  run grep -c "source \"$DEV_ZSH_CONFIG\"" "$ZSHRC_FILE"
  [ "$output" -eq 1 ]
}

@test "ZSH: add_to_zsh_config appends content" {
  ensure_zsh_include

  add_to_zsh_config "export TEST_VAR=1" "test var"

  run grep "export TEST_VAR=1" "$DEV_ZSH_CONFIG"
  [ "$status" -eq 0 ]

  run grep "# test var" "$DEV_ZSH_CONFIG"
  [ "$status" -eq 0 ]
}

@test "ZSH: add_to_zsh_config is idempotent" {
  ensure_zsh_include
  add_to_zsh_config "export TEST_VAR=1"

  run add_to_zsh_config "export TEST_VAR=1"
  [ "$status" -eq 1 ]

  run grep -c "export TEST_VAR=1" "$DEV_ZSH_CONFIG"
  [ "$output" -eq 1 ]
}

@test "ZSH: add_to_zsh_config is idempotent with marker" {
  ensure_zsh_include
  local multiline="Line 1
Line 2"

  add_to_zsh_config "$multiline" "TEST_MARKER"
  run grep "Line 1" "$DEV_ZSH_CONFIG"

  run add_to_zsh_config "Line 1
Line 2 CHANGED" "TEST_MARKER"
  [ "$status" -eq 1 ]

  # Should match content based on marker presence, not content difference
  run grep -c "# TEST_MARKER" "$DEV_ZSH_CONFIG"
  [ "$output" -eq 1 ]
}
