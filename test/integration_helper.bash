#!/usr/bin/env bash

setup_integration() {
  local platform_name=$1

  # Skip integration tests unless running in a Docker container or CI
  local is_container=false
  [[ -f /.dockerenv ]] && is_container=true

  if [[ -z "${CI:-}" && "$is_container" == "false" ]]; then
    skip "Integration tests only run in CI or Docker containers."
  fi

  export TEST_DIR="$BATS_TEST_TMPDIR"
  export HOME="$TEST_DIR/home"
  export CONFIG_DIR="$HOME/.config"
  export CONFIG_FILE="$CONFIG_DIR/dev-setup.conf"
  export ZSHRC_FILE="$HOME/.zshrc"

  mkdir -p "$CONFIG_DIR"
  mkdir -p "$HOME/lib"
  touch "$ZSHRC_FILE"

  # PROJECT_DIR is the mounted workspace for Linux containers
  if [[ "$platform_name" == "macOS" ]]; then
     export PROJECT_DIR="$TEST_DIR/project"
     setup_macos_project
  else
     if [[ -d "/workspace" ]]; then
       export PROJECT_DIR="/workspace"
     elif [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
       export PROJECT_DIR="$GITHUB_WORKSPACE"
     else
       export PROJECT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
     fi
  fi

  export EDITOR="vim"
}

setup_macos_project() {
  mkdir -p "$PROJECT_DIR"
  cp -r "$BATS_TEST_DIRNAME/../bin" "$PROJECT_DIR/"
  cp -r "$BATS_TEST_DIRNAME/../lib" "$PROJECT_DIR/"
  cp "$BATS_TEST_DIRNAME/../dev-setup.conf" "$PROJECT_DIR/"
  chmod +x "$PROJECT_DIR/bin/setup"
  find "$PROJECT_DIR/lib" -name "*.sh" -exec chmod +x {} +
  touch "$PROJECT_DIR/.ruby-version"
}
