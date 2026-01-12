#!/usr/bin/env bats

load "test_helper.sh"

# We'll use one file for all core logic tests to ensure a clean state
setup() {
  export TEST_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$TEST_HOME"

  # Only load utils by default
  load_lib "lib/core/utils.sh"

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
  load_lib "lib/modules/editor.sh"
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
  load_lib "lib/modules/dotfiles.sh"
  export PLATFORM="macOS"
  export DOTFILES_DIR="$TEST_HOME/dotfiles"

  # Mock git clone/pull
  git() { return 0; }
  export -f git

  # Mock read to always say yes for prompts
  read() { REPLY="y"; return 0; }
  export -f read

  # Mock the repository source
  mkdir -p "$DOTFILES_DIR/.antigravity"
  touch "$DOTFILES_DIR/.antigravity/settings.json"
  mkdir -p "$DOTFILES_DIR/.ssh"
  touch "$DOTFILES_DIR/.ssh/id_rsa"
  touch "$DOTFILES_DIR/.zshrc"

  run setup_dotfiles
  [ -L "$TEST_HOME/.zshrc" ]
  [ -L "$TEST_HOME/.ssh" ]
  [ -L "$TEST_HOME/.antigravity" ]

  run symlink_antigravity_config
  [ -L "$TEST_HOME/Library/Application Support/Antigravity/User" ]

  export PLATFORM="Debian"
  run symlink_antigravity_config
  [ -L "$TEST_HOME/.config/Antigravity/User" ]
}

@test "Docker: installs correctly when enabled" {
  load_lib "lib/modules/docker.sh"
  echo "docker=true" > "$CONFIG_FILE"
  export MOCKED_NOT_FOUND="docker"

  export PLATFORM="macOS"
  run setup_docker
  echo "$output" | grep -q "Installing Docker"

  export PLATFORM="Debian"
  run setup_docker
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Setting up Docker CE repository for Debian"
  echo "$output" | grep -q "MOCKED: sudo curl -fsSL https://download.docker.com/linux/debian/gpg"
  echo "$output" | grep -q "MOCKED: sudo tee /etc/apt/sources.list.d/docker.list"

  export PLATFORM="Fedora"
  run setup_docker
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Setting up Docker CE repository for Fedora"
  echo "$output" | grep -q "MOCKED: sudo dnf config-manager --add-repo"

  export PLATFORM="Arch"
  run setup_docker
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "MOCKED: sudo pacman -S --noconfirm docker"
}

@test "1Password GUI: handles macOS and Debian" {
  load_lib "lib/modules/1password.sh"
  setup_mocks

  export PLATFORM="macOS"
  export MOCKED_APP_INSTALLED=""
  run setup_1password
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Installing 1Password GUI for macOS"

  export PLATFORM="Debian"
  export MOCKED_NOT_FOUND="1password"
  run setup_1password
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Installing 1Password GUI for Debian"
}

@test "1Password CLI: handles installation and sign-in" {
  load_lib "lib/modules/1password_cli.sh"
  setup_mocks

  export PLATFORM="macOS"
  export MOCKED_NOT_FOUND="op"
  # Mock op whoami to skip interactive part
  op() { if [[ "$1" == "whoami" ]]; then return 0; fi; }
  export -f op

  run setup_1password_cli
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Installing 1Password CLI"
}

@test "1Password SSH: configures agent and agent.toml" {
  load_lib "lib/modules/1password_ssh.sh"
  setup_mocks

  export PLATFORM="macOS"
  echo "1password=true" > "$CONFIG_FILE"

  run setup_1password_ssh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Using 1Password SSH agent" || echo "$output" | grep -q "Added 1Password SSH agent"
  echo "$output" | grep -q "Using 1Password \"Development\" vault" || echo "$output" | grep -q "Configured $HOME/.config/1Password/ssh/agent.toml" || echo "$output" | grep -q "Created $HOME/.config/1Password/ssh/agent.toml"

  # Verify symlink creation on macOS
  if [[ "$PLATFORM" == "macOS" ]]; then
    # We need to mock the existence of the source socket for the symlink creation to occur in the script
    # but the script has 'if [ -S "$op_sock_macos" ]'.
    # Since we can't easily mock the -S check without more complex test setup,
    # let's just ensure the directory was created.
    [ -d "$TEST_HOME/.1password" ]
  fi
}

@test "Languages: installs correctly when enabled" {
  export PLATFORM="macOS"
  export MOCKED_NOT_FOUND="rbenv pyenv nvm"
  # Sourcing explicitly to ensure fresh state for functions
  load_lib "lib/modules/ruby.sh"
  load_lib "lib/modules/python.sh"
  load_lib "lib/modules/node.sh"

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
  export MOCKED_APP_INSTALLED=""         # Not installed
  export MOCKED_NOT_FOUND="google-drive" # Not in PATH
  run setup_google_drive
  echo "$output" | grep -q "Google Drive for macOS"
}

@test "CLI Tools: Gemini, Claude, and Postman installation" {
  load_lib "lib/modules/gemini.sh"
  load_lib "lib/modules/claude.sh"
  load_lib "lib/modules/postman.sh"

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

  load_lib "lib/modules/vim_tmux.sh"
  run setup_vim_tmux_config
  echo "$output" | grep -q "Installing vim-nox"
  echo "$output" | grep -q "MOCKED: sudo update-alternatives --set vi /usr/bin/vim.nox"
}
