#!/usr/bin/env bats

setup() {
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

  # Prepend mocks to PATH
  export MOCKS_DIR="$BATS_TEST_DIRNAME/mocks"
  export PATH="$MOCKS_DIR:$PATH"

  # Set default editor mock
  export EDITOR="true"

  # PATCH: Remove all interactive components
  # Target specific interactive prompts to avoid breaking while loops
  sed -i.bak '/read -r/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/read -k/d' "$PROJECT_DIR/lib/gemini.sh"
  sed -i.bak '/read -p/d' "$PROJECT_DIR/lib/utils.sh"
  sed -i.bak '/read -k/d' "$PROJECT_DIR/lib/dotfiles.sh"

  # Also remove prompt text to keep output clean but this is optional
  sed -i.bak '/echo -n "Press \[Enter\]/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/echo -n "Update.*\[y\/N\]/d' "$PROJECT_DIR/lib/gemini.sh"

  # PATCH: Remove host-specific Homebrew/Ghostty path evals
  sed -i.bak '/shellenv/d' "$PROJECT_DIR/lib/brew.sh"
  sed -i.bak '/ghostty/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/iterm/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/homebrew/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/\${EDITOR:-vim}/d' "$PROJECT_DIR/bin/setup"

  # PATCH: Force dependencies not found to test installation logic
  sed -i.bak 's/command -v docker/false/' "$PROJECT_DIR/lib/docker.sh"
  sed -i.bak 's/command -v rbenv/false/' "$PROJECT_DIR/lib/ruby.sh"
  sed -i.bak 's/command -v pyenv/false/' "$PROJECT_DIR/lib/python.sh"
}

@test "Integration: MacOS Smoke Test" {
  export PLATFORM="macOS"
  export MOCK_UNAME="Darwin"

  # Explicitly disable all to avoid missing mocks
  echo "google_drive=false" > "$CONFIG_FILE"
  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"
  echo "op=false" >> "$CONFIG_FILE"
  echo "app_store=false" >> "$CONFIG_FILE"
  echo "docker=false" >> "$CONFIG_FILE"
  echo "ruby=false" >> "$CONFIG_FILE"
  echo "python=false" >> "$CONFIG_FILE"
  echo "node=false" >> "$CONFIG_FILE"
  echo "vim_tmux=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  run ./bin/setup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: macOS"* ]]
}

@test "Integration: Debian Smoke Test" {
  export PLATFORM="Debian"
  export MOCK_UNAME="Linux"

  echo "google_drive=false" > "$CONFIG_FILE"
  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"
  echo "op=false" >> "$CONFIG_FILE"
  echo "docker=false" >> "$CONFIG_FILE"

  # Mock apt-get
  ln -sf "$MOCKS_DIR/sudo" "$MOCKS_DIR/apt-get"

  cd "$PROJECT_DIR"
  run ./bin/setup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: Debian"* ]] || [[ "$output" == *"Detected platform: Linux"* ]]
}

@test "Integration: Arch Smoke Test" {
  export PLATFORM="Arch"
  export MOCK_UNAME="Linux"

  echo "google_drive=false" > "$CONFIG_FILE"
  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
  run ./bin/setup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Detected platform: Arch"* ]] || [[ "$output" == *"Detected platform: Linux"* ]]
}

@test "Integration: Fedora Smoke Test" {
  export PLATFORM="Fedora"
  export MOCK_UNAME="Linux"

  echo "google_drive=false" > "$CONFIG_FILE"
  echo "dotfiles=false" >> "$CONFIG_FILE"
  echo "editor=false" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"
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

    # Test TRUE
    echo "google_drive=false" > "$CONFIG_FILE"
    echo "editor=false" >> "$CONFIG_FILE"
    echo "op=false" >> "$CONFIG_FILE"
    echo "app_store=false" >> "$CONFIG_FILE"
    echo "${module}=true" >> "$CONFIG_FILE"

    cd "$PROJECT_DIR"
    run ./bin/setup
    [[ "$output" == *"$expected_text"* ]]

    # Test FALSE
    echo "google_drive=false" > "$CONFIG_FILE"
    echo "editor=false" >> "$CONFIG_FILE"
    echo "op=false" >> "$CONFIG_FILE"
    echo "app_store=false" >> "$CONFIG_FILE"
    echo "${module}=false" >> "$CONFIG_FILE"

    run ./bin/setup
    [[ "$output" != *"$expected_text"* ]]
  }

  check_toggle "docker" "MOCKED: brew install --cask docker"
  check_toggle "ruby" "MOCKED: brew install rbenv"
}
