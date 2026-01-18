#!/usr/bin/env bats

setup() {
  # Skip integration tests unless running in CI
  # These tests run the actual setup script and modify the system
  if [[ -z "${CI:-}" ]]; then
    skip "Integration tests only run in CI. Use: bats test/test_{detection,utils,vars}.bats for local testing"
  fi

  export TEST_DIR="$BATS_TEST_TMPDIR"
  export HOME="$TEST_DIR/home"
  export CONFIG_DIR="$HOME/.config"
  export CONFIG_FILE="$CONFIG_DIR/dev-setup.conf"
  export ZSHRC_FILE="$HOME/.zshrc"

  # Create directory structure
  mkdir -p "$CONFIG_DIR"
  mkdir -p "$HOME/lib"
  touch "$ZSHRC_FILE"

  # Copy PROJECT to temp dir for isolation
  export PROJECT_DIR="$TEST_DIR/project"
  mkdir -p "$PROJECT_DIR"
  cp -r "$BATS_TEST_DIRNAME/../bin" "$PROJECT_DIR/"
  cp -r "$BATS_TEST_DIRNAME/../lib" "$PROJECT_DIR/"
  cp "$BATS_TEST_DIRNAME/../dev-setup.conf" "$PROJECT_DIR/"
  chmod +x "$PROJECT_DIR/bin/setup"
  find "$PROJECT_DIR/lib" -name "*.sh" -exec chmod +x {} +
  touch "$PROJECT_DIR/.ruby-version"

  # Prepend mocks to PATH
  export MOCKS_DIR="$BATS_TEST_DIRNAME/mocks"
  export PATH="$MOCKS_DIR:$PATH"

  # Set default editor mock
  export EDITOR="true"

  # Also remove prompt text to keep output clean but this is optional
  sed -i.bak '/echo -n "Press \[Enter\]/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/echo -n "Update.*\[y\/N\]/d' "$PROJECT_DIR/lib/modules/gemini.sh"

  # Helper for smoke tests to skip interactive config
  patch_smoke_tests() {
    # For smoke tests, we want confirm_action to always return true (or false based on need) automatically
    # and prompt_input to return default.
    # Since we can't easily patch functions dynamically in the sourced file without complexity,
    # let's modify utils.sh directly in the project dir to non-interactive versions.

    cat <<EOF >> "$PROJECT_DIR/lib/core/utils.sh"
confirm_action() {
  local prompt="\$1"
  local default="\${2:-n}"
  # For smoke tests, always return true if default is y
  [[ "\$default" == "y" ]]
}

prompt_input() {
  local prompt="\$1"
  local default="\$2"
  echo "\$default"
}

wait_for_enter() {
  return 0
}
EOF
  }

  patch_interactive_only() {
    # Remove reads from bin/setup outside of prompt_config if any remain (none should with new refactor)
    # But now configuration happens via prompt_input/confirm_action in utils.sh.
    # We WANT utils.sh to retain its read logic so we can pipe input to it.

    # However, patch_interactive_only isn't really needed if we trust utils.sh reads.
    # The original logic removed "pause" type reads.
    # Let's just ensure we DON'T patch utils.sh.

    # We might still want to patch other modules if they have stray reads (though we refactored them).
    # Let's exclude utils.sh from the find command.
    find "$PROJECT_DIR/lib" -name "*.sh" ! -name "utils.sh" -exec sed -i.bak -e '/^[[:space:]]*read /d' -e '/^[[:space:]]*read$/d' -e '/^[[:space:]]*read?/d' {} +

    # Inject line-based confirm_action for test stability
    cat <<EOF >> "$PROJECT_DIR/lib/core/utils.sh"
confirm_action() {
  local prompt="\$1"
  local default="\${2:-n}"
  # Read line from stdin for deterministic testing
  local reply
  if ! read -r reply; then
     # End of input
     return 1
  fi

  if [[ "\$default" == "y" ]]; then
     [[ "\$reply" =~ ^[Yy]$ || -z "\$reply" ]]
  else
     [[ "\$reply" =~ ^[Yy]$ ]]
  fi
}

wait_for_enter() {
  return 0
}
EOF
  }

  # PATCH: Remove host-specific Homebrew path evals
  sed -i.bak '/shellenv/d' "$PROJECT_DIR/lib/modules/brew.sh"
  sed -i.bak '/iterm/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/homebrew/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/\${EDITOR:-vim}/d' "$PROJECT_DIR/bin/setup"

  # PATCH: Force dependencies not found to test installation logic
  sed -i.bak 's/command -v docker/false/' "$PROJECT_DIR/lib/modules/docker.sh"
  sed -i.bak 's/command -v rbenv/false/' "$PROJECT_DIR/lib/modules/ruby.sh"
  sed -i.bak 's/command -v pyenv/false/' "$PROJECT_DIR/lib/modules/python.sh"
}

@test "Integration: MacOS Smoke Test" {
  export PLATFORM="macOS"
  export MOCK_UNAME="Darwin"

  # Explicitly disable all to avoid missing mocks
  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"
  echo "op_cli=false" >> "$CONFIG_FILE"
  echo "1password=false" >> "$CONFIG_FILE"
  echo "1password_ssh=false" >> "$CONFIG_FILE"
  echo "app_store=false" >> "$CONFIG_FILE"
  echo "docker=false" >> "$CONFIG_FILE"
  echo "ruby=false" >> "$CONFIG_FILE"
  echo "python=false" >> "$CONFIG_FILE"
  echo "node=false" >> "$CONFIG_FILE"
  echo "vim_tmux=false" >> "$CONFIG_FILE"
  echo "yubikey=false" >> "$CONFIG_FILE"
  echo "gemini_cli=false" >> "$CONFIG_FILE"
  echo "claude_code_cli=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  patch_smoke_tests
  run ./bin/setup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: macOS"* ]]
}

@test "Integration: Debian Smoke Test" {
  export PLATFORM="Debian"
  export MOCK_UNAME="Linux"

  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"
  echo "op=false" >> "$CONFIG_FILE"
  echo "docker=false" >> "$CONFIG_FILE"

  # Mock apt-get

  cd "$PROJECT_DIR"
  patch_smoke_tests
  run ./bin/setup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: Debian"* ]] || [[ "$output" == *"Detected platform: Linux"* ]]
}

@test "Integration: Arch Smoke Test" {
  export PLATFORM="Arch"
  export MOCK_UNAME="Linux"

  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  patch_smoke_tests
  run ./bin/setup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: Arch"* ]] || [[ "$output" == *"Detected platform: Linux"* ]]
}

@test "Integration: Fedora Smoke Test" {
  export PLATFORM="Fedora"
  export MOCK_UNAME="Linux"

  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  patch_smoke_tests
  run ./bin/setup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: Fedora"* ]] || [[ "$output" == *"Detected platform: Linux"* ]]
}

@test "Integration: Config Toggles" {
  export PLATFORM="macOS"
  export MOCK_UNAME="Darwin"

  check_toggle() {
    local module=$1
    local expected_text=$2

    echo "editor=false" > "$CONFIG_FILE"
    echo "op_cli=false" >> "$CONFIG_FILE"
    echo "1password=false" >> "$CONFIG_FILE"
    echo "1password_ssh=false" >> "$CONFIG_FILE"
    echo "app_store=false" >> "$CONFIG_FILE"
    echo "yubikey=false" >> "$CONFIG_FILE"
    echo "gemini_cli=false" >> "$CONFIG_FILE"
    echo "claude_code_cli=false" >> "$CONFIG_FILE"
    echo "${module}=true" >> "$CONFIG_FILE"

    cd "$PROJECT_DIR"
    patch_smoke_tests
    run ./bin/setup
    if [[ "$output" != *"$expected_text"* ]]; then
      echo "Failed to find '$expected_text' in output:"
      echo "$output"
      return 1
    fi

    # Test FALSE
    echo "editor=false" > "$CONFIG_FILE"
    echo "op_cli=false" >> "$CONFIG_FILE"
    echo "1password=false" >> "$CONFIG_FILE"
    echo "1password_ssh=false" >> "$CONFIG_FILE"
    echo "app_store=false" >> "$CONFIG_FILE"
    echo "yubikey=false" >> "$CONFIG_FILE"
    echo "gemini_cli=false" >> "$CONFIG_FILE"
    echo "claude_code_cli=false" >> "$CONFIG_FILE"
    echo "${module}=false" >> "$CONFIG_FILE"

    run ./bin/setup
    [[ "$output" != *"$expected_text"* ]]
  }

  check_toggle "docker" "MOCKED: brew install --cask docker"
  check_toggle "ruby" "MOCKED: brew install rbenv"
}

@test "Integration: Interactive Config Update" {
  export PLATFORM="macOS"
  export MOCK_UNAME="Darwin"

  # Initial config: python=false
  echo "python=false" > "$CONFIG_FILE"
  echo "dotfiles=true" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"

  # Simulate interaction:
  # 1. Proceed with current configuration? [Y/n]: n
  # 2. Enable dotfiles? ... (default: y): n
  # 3. Enable vim_tmux? ... (default: n): [Enter]
  # 4. Enable editor? ... (default: n): [Enter]
  # 5. Enable op? ... (default: n): [Enter]
  # 6. Enable ruby? ... (default: n): [Enter]
  # 7. Enable python? ... (default: n): y
  # 8. Enable node? ... (default: n): [Enter]
  # 9-12. (defaults): [Enter]x4

  # We need to provide exactly enough inputs for the 13 modules + the initial "y"
  # Let's ensure the PLATFORM is available to bin/setup as an env var
  patch_interactive_only

  # Run with zsh explicitly to ensure prompt-reading behavior matches reality
  export MOCK_UNAME="Darwin"
  export PLATFORM="macOS"
  run zsh -c "export PATH=\"$PATH\"; export MOCK_UNAME=\"$MOCK_UNAME\"; export PLATFORM=\"$PLATFORM\"; printf 'n\nn\n\n\n\n\n\n\ny\n\n\n\n\n\n\n' | ./bin/setup"
  if [ "$status" -ne 0 ]; then
    echo "Interactive setup failed with output:"
    echo "$output"
    return 1
  fi

  # Verify persistence
  grep "^python=true" "$CONFIG_FILE"
  grep "^dotfiles=false" "$CONFIG_FILE"
}
@test "Integration: Prompt Defaults" {
  export PLATFORM="macOS"
  export MOCK_UNAME="Darwin"

  # Ensure config exists
  echo "python=false" > "$CONFIG_FILE"
  echo "docker=false" >> "$CONFIG_FILE"
  echo "yubikey=false" >> "$CONFIG_FILE"
  echo "app_store=false" >> "$CONFIG_FILE"
  echo "1password=false" >> "$CONFIG_FILE"
  echo "op_cli=false" >> "$CONFIG_FILE"
  echo "1password_ssh=false" >> "$CONFIG_FILE"
  echo "gemini_cli=false" >> "$CONFIG_FILE"
  echo "claude_code_cli=false" >> "$CONFIG_FILE"
  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "vim_tmux=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"
  echo "ruby=false" >> "$CONFIG_FILE"
  echo "node=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  patch_smoke_tests

  # Provide empty input (just Enter) for the "Proceed with current configuration?" prompt
  run zsh -c "export PATH=\"$PATH\"; export MOCK_UNAME=\"$MOCK_UNAME\"; export PLATFORM=\"$PLATFORM\"; printf '\n' | ./bin/setup"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Using current configuration."* ]]
}
