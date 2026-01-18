#!/usr/bin/env bats

load integration_helper.bash

setup() {
  setup_integration "Debian"
}

@test "Integration: Debian Smoke Test" {
  export PLATFORM="Debian"

  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"
  echo "ruby=false" >> "$CONFIG_FILE"
  echo "python=false" >> "$CONFIG_FILE"
  echo "docker=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  run zsh -c "printf 'y\n' | ./bin/setup"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: Debian"* ]] || [[ "$output" == *"Detected platform: Linux"* ]]
}

@test "Integration: Config Toggles (Linux)" {
  # Test a simple toggle that doesn't take forever
  echo "dotfiles=false" > "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"
  echo "ruby=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  run zsh -c "printf 'y\n' | ./bin/setup"
  [ "$status" -eq 0 ]
}
