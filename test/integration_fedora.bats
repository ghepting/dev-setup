#!/usr/bin/env bats

load integration_helper.bash

setup() {
  setup_integration "Fedora"
}

@test "Integration: Fedora Smoke Test" {
  export PLATFORM="Fedora"

  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  run zsh -c "printf 'y\n' | ./bin/setup"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: Fedora"* ]] || [[ "$output" == *"Detected platform: Linux"* ]]
}
