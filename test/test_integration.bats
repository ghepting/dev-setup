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
  sed -i.bak '/echo -n "Update.*\[y\/N\]/d' "$PROJECT_DIR/lib/gemini.sh"

  # Helper for smoke tests to skip interactive config
  patch_smoke_tests() {
    sed -i.bak '/read -r REPLY/d' "$PROJECT_DIR/bin/setup"
    sed -i.bak '/read -r REPLY/d' "$PROJECT_DIR/lib/gemini.sh" # if any left
    # Target the specific prompt in prompt_config
    sed -i.bak 's/read -r REPLY/REPLY="n"/' "$PROJECT_DIR/bin/setup"
  }

  # PATCH: Remove host-specific Homebrew/Ghostty path evals
  sed -i.bak '/shellenv/d' "$PROJECT_DIR/lib/brew.sh"
  sed -i.bak '/ghostty/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/iterm/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/homebrew/d' "$PROJECT_DIR/bin/setup"
  sed -i.bak '/\${EDITOR:-vim}/d' "$PROJECT_DIR/bin/setup"

  # PATCH: Remove all remaining interactive components globally
  find "$PROJECT_DIR" -name "*.sh" -exec sed -i.bak '/read -p/d' {} +
  find "$PROJECT_DIR" -name "*.sh" -exec sed -i.bak '/read -k/d' {} +
  sed -i.bak 's/read -n 1/read -r/' "$PROJECT_DIR/lib/gemini.sh" 2>/dev/null || true

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
  patch_smoke_tests
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
  patch_smoke_tests
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
  patch_smoke_tests
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

    # Test TRUE
    echo "google_drive=false" > "$CONFIG_FILE"
    echo "editor=false" >> "$CONFIG_FILE"
    echo "op=false" >> "$CONFIG_FILE"
    echo "app_store=false" >> "$CONFIG_FILE"
    echo "${module}=true" >> "$CONFIG_FILE"

    cd "$PROJECT_DIR"
    patch_smoke_tests
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

@test "Integration: Interactive Config Update" {
  export PLATFORM="macOS"
  export MOCK_UNAME="Darwin"

  # Initial config: python=false
  echo "python=false" > "$CONFIG_FILE"
  echo "dotfiles=true" >> "$CONFIG_FILE"

  cd "$PROJECT_DIR"

  # Simulate interaction:
  # 1. Modify configuration? [y/N]: y
  # 2. Enable google_drive? ... (default: n): [Enter]
  # 3. Enable dotfiles? ... (default: y): n
  # 4. Enable vim_tmux? ... (default: n): [Enter]
  # 5. Enable editor? ... (default: n): [Enter]
  # 6. Enable op? ... (default: n): [Enter]
  # 7. Enable ruby? ... (default: n): [Enter]
  # 8. Enable python? ... (default: n): y
  # 9. Enable node? ... (default: n): [Enter]
  # 10-13. (defaults): [Enter]x4

  # We need to provide exactly enough inputs for the 13 modules + the initial "y"
  # Let's ensure the PLATFORM is available to bin/setup as an env var
  export PLATFORM="macOS"

  # Run with zsh explicitly to ensure prompt-reading behavior matches reality
  run zsh -c "printf 'y\n\nn\n\n\n\n\ny\n\n\n\n\n\n' | ./bin/setup"
  if [ "$status" -ne 0 ]; then
    echo "Interactive setup failed with output:"
    echo "$output"
    return 1
  fi

  # Verify persistence
  grep "^python=true" "$CONFIG_FILE"
  grep "^dotfiles=false" "$CONFIG_FILE"
}
