#!/usr/bin/env bats

load integration_helper.bash

setup() {
  setup_integration "macOS"
}

@test "Integration: MacOS Smoke Test" {
  export PLATFORM="macOS"

  # Enable only a subset for smoke test to keep it relatively fast but real
  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"
  echo "op_cli=false" >> "$CONFIG_FILE"
  echo "1password=false" >> "$CONFIG_FILE"
  echo "1password_ssh=false" >> "$CONFIG_FILE"
  echo "app_store=false" >> "$CONFIG_FILE"
  echo "docker=false" >> "$CONFIG_FILE"
  echo "ruby=true" >> "$CONFIG_FILE"   # Test real ruby installation if possible
  echo "python=false" >> "$CONFIG_FILE"
  echo "node=false" >> "$CONFIG_FILE"
  echo "vim_tmux=false" >> "$CONFIG_FILE"
  echo "yubikey=false" >> "$CONFIG_FILE"
  echo "gemini_cli=false" >> "$CONFIG_FILE"
  echo "claude_code_cli=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  # Provide 'y' for the "Proceed with current configuration?" prompt
  run zsh -c "printf 'y\n' | ./bin/setup"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: macOS"* ]]
}

@test "Integration: Prompt Defaults (macOS)" {
  export PLATFORM="macOS"

  # Ensure config exists
  echo "python=false" > "$CONFIG_FILE"
  echo "dotfiles=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"

  # Provide empty input (just Enter) for the "Proceed with current configuration?" prompt
  run zsh -c "printf '\n' | ./bin/setup"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Using current configuration."* ]]
}
