#!/usr/bin/env bats

load integration_helper.bash

setup() {
  setup_integration "Arch"
}

@test "Integration: Arch Smoke Test" {
  export PLATFORM="Arch"

  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  run zsh -c "printf 'y\n' | ./bin/setup"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: Arch"* ]] || [[ "$output" == *"Detected platform: Linux"* ]]
}
