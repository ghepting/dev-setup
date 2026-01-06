#!/usr/bin/env bats

load "test_helper.bash"

# We'll use one file for all core logic tests to ensure a clean state
setup() {
  export TEST_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$TEST_HOME"

  # Only load utils by default
  load_lib "lib/utils.sh"

  # Set up mocks AFTER loading libs to ensure they take precedence
  setup_mocks
}

@test "Utilities: is_macos and is_debian work" {
  export PLATFORM="macOS"
  run is_macos
  [ "$status" -eq 0 ]
  run is_debian
  [ "$status" -eq 1 ]

  export PLATFORM="Debian"
  run is_macos
  [ "$status" -eq 1 ]
  run is_debian
  [ "$status" -eq 0 ]
}

@test "Utilities: is_enabled logic with platform-aware defaults" {
  export CONFIG_FILE="/tmp/dev-setup-test.conf"
  rm -f "$CONFIG_FILE"

  # macOS Defaults (Should be true)
  export PLATFORM="macOS"
  run is_enabled "docker"
  [ "$status" -eq 0 ]
  run is_enabled "ruby"
  [ "$status" -eq 0 ]
  run is_enabled "dotfiles"
  [ "$status" -eq 0 ]

  # Debian Defaults (Should be false for non-core)
  export PLATFORM="Debian"
  run is_enabled "docker"
  [ "$status" -eq 1 ]
  run is_enabled "ruby"
  [ "$status" -eq 1 ]
  run is_enabled "op"
  [ "$status" -eq 1 ]
  # Debian core tools (Should stay true)
  run is_enabled "dotfiles"
  [ "$status" -eq 0 ]
  run is_enabled "vim_tmux"
  [ "$status" -eq 0 ]

  # Explicit overrides
  echo "docker=true" > "$CONFIG_FILE"
  run is_enabled "docker"
  [ "$status" -eq 0 ]
  
  echo "dotfiles=false" >> "$CONFIG_FILE"
  run is_enabled "dotfiles"
  [ "$status" -eq 1 ]
  
  rm -f "$CONFIG_FILE"
}

@test "Editor: favors vim on Debian or SSH" {
  load_lib "lib/editor.sh"
  export ZSHRC_FILE="/tmp/zshrc_test"
  echo "" > "$ZSHRC_FILE"

  # Debian -> vim
  export PLATFORM="Debian"
  export SSH_CONNECTION=""
  run configure_editor
  echo "$output" | grep -q "Configured vim as EDITOR"

  # macOS & NO SSH -> agy
  export PLATFORM="macOS"
  export SSH_CONNECTION=""
  echo "" > "$ZSHRC_FILE" # reset
  run configure_editor
  echo "$output" | grep -q "Configured agy --wait as EDITOR"

  # macOS & SSH -> vim
  export PLATFORM="macOS"
  export SSH_CONNECTION="1.2.3.4 5678 127.0.0.1 22"
  echo "" > "$ZSHRC_FILE" # reset
  run configure_editor
  echo "$output" | grep -q "Configured vim as EDITOR"

  rm -f "$ZSHRC_FILE"
}

@test "Dotfiles: correctly chooses paths" {
  load_lib "lib/dotfiles.sh"
  export PLATFORM="macOS"
  # Mock the Google Drive source
  mkdir -p "$TEST_HOME/Google Drive/My Drive/dotfiles/antigravity"
  touch "$TEST_HOME/Google Drive/My Drive/dotfiles/antigravity/settings.json"

  run symlink_antigravity_config
  [ -L "$TEST_HOME/Library/Application Support/Antigravity/User/settings.json" ]

  export PLATFORM="Debian"
  run symlink_antigravity_config
  [ -L "$TEST_HOME/.config/Antigravity/User/settings.json" ]
}

@test "Docker: installs correctly when enabled" {
  load_lib "lib/docker.sh"
  echo "docker=true" > "$CONFIG_FILE"
  export MOCKED_NOT_FOUND="docker"

  export PLATFORM="macOS"
  run setup_docker
  echo "$output" | grep -q "Installing Docker"

  export PLATFORM="Debian"
  export MOCKED_NOT_FOUND="docker"
  # Mock whoami for usermod
  whoami() { echo "tester"; }
  export -f whoami
  run setup_docker
  echo "$output" | grep -q "Installing docker.io via apt"
}

@test "1Password: handles platform specific paths and opt-in" {
  load_lib "lib/1password.sh"
  export PLATFORM="macOS"
  # Mock op whoami to skip interactive part
  op() { if [[ "$1" == "whoami" ]]; then return 0; fi; }
  export -f op
  run setup_1password
  [ "$status" -eq 0 ]

  export PLATFORM="Debian"
  # Should skip by default
  run setup_1password
  echo "$output" | grep -q "skipped on Debian"

  # Should run with explicit opt-in
  echo "op=true" > "$CONFIG_FILE"
  export MOCKED_NOT_FOUND="op"
  run setup_1password
  echo "$output" | grep -q "Installing 1Password CLI"
}

@test "Languages: installs correctly when enabled" {
  export PLATFORM="macOS"
  export MOCKED_NOT_FOUND="rbenv pyenv nvm"
  # Sourcing explicitly to ensure fresh state for functions
  load_lib "lib/ruby.sh"
  load_lib "lib/python.sh"
  load_lib "lib/node.sh"

  run install_rbenv_and_ruby
  echo "$output" | grep -q "Installing rbenv"

  run install_pyenv_and_python
  echo "$output" | grep -q "Installing pyenv"

  run install_nvm_and_node
  echo "$output" | grep -q "Installing nvm"
}

@test "Google Drive: configures rclone on Debian" {
  echo "google_drive=true" > "$CONFIG_FILE"

  export PLATFORM="Debian"
  export MOCKED_NOT_FOUND="rclone"
  run setup_google_drive
  echo "$output" | grep -q "Installing rclone"
}

@test "Google Drive: installs app on macOS" {
  echo "google_drive=true" > "$CONFIG_FILE"

  export PLATFORM="macOS"
  export MOCKED_APP_INSTALLED="" # Not installed
  export MOCKED_NOT_FOUND="google-drive" # Not in PATH
  run setup_google_drive
  echo "$output" | grep -q "Google Drive for macOS"
}

@test "CLI Tools: Gemini, Claude, and Postman installation" {
  load_lib "lib/gemini.sh"
  load_lib "lib/claude.sh"
  load_lib "lib/postman.sh"

  echo "gemini_cli=true" > "$CONFIG_FILE"
  echo "claude_code_cli=true" >> "$CONFIG_FILE"
  echo "postman_cli=true" >> "$CONFIG_FILE"

  # Initial state: none found
  export MOCKED_NOT_FOUND="gemini claude postman"

  run install_gemini_cli
  echo "$output" | grep -q "Installing Gemini CLI"

  # For Claude, we need to mock it being found AFTER the install curl call
  # But our command mock is static. Let's just verify the curl call happened.
  run install_claude_code_cli
  echo "$output" | grep -q "Successfully installed" || echo "$output" | grep -q "MOCKED: curl"

  run install_postman_cli
  echo "$output" | grep -q "Installing Postman CLI"
}

@test "Vim/Tmux: installs vim-nox and alternatives on Debian" {
  export PLATFORM="Debian"
  export MOCKED_NOT_FOUND="vim"

  load_lib "lib/vim_tmux.sh"
  run setup_vim_tmux_config
  echo "$output" | grep -q "Installing vim-nox"
  echo "$output" | grep -q "MOCKED: sudo update-alternatives --set vi /usr/bin/vim.nox"
}
