#!/usr/bin/env zsh

install_homebrew() {
  if ! command -v brew &>/dev/null; then
    log_info "Installing Homebrew..."
    /usr/bin/env zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    RESTART_REQUIRED=true

    # Configure shell environment for the current session
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    log_info "Updating Homebrew..."
    brew update &>/dev/null
  fi
  log_status "Using Homebrew $(brew --version)"
}

install_homebrew_path() {
  # ensure brew config is in .zshrc.dev
  install_zsh_config "brew"
  ensure_zshrc_dev_sourced
}

install_homebrew_formulae() {
  # install homebrew packages
  log_info "Installing Homebrew formulae..."
  brew bundle --upgrade -q

  # Log installed package versions
  log_info "Verifying installed versions..."

  # Get all installed formulae and casks with versions in one go
  local installed_list
  installed_list=$(brew list --versions && brew list --cask --versions)

  # Function to log version from brew list output
  log_brew_version() {
    local name=$1
    local type=$2 # "formula" or "cask"
    local version

    version=$(echo "$installed_list" | grep -i "^${name} " | head -n 1 | awk '{print $2}')
    if [[ -n "$version" ]]; then
      log_status "Using ${name} ${version} (${type})"
    fi
  }

  # Log versions for formulae and casks defined in Brewfile
  log_brew_version "rbenv" "formula"
  log_brew_version "ruby-build" "formula"
  log_brew_version "pyenv" "formula"
  log_brew_version "iterm2" "cask"
  log_brew_version "tmux" "formula"
  log_brew_version "direnv" "formula"
  log_brew_version "vim" "formula"
  log_brew_version "the_silver_searcher" "formula"
  log_brew_version "universal-ctags" "formula"
  log_brew_version "gh" "formula"
  log_brew_version "docker-desktop" "cask"
  log_brew_version "antigravity" "cask"
  log_brew_version "postman" "cask"
  log_brew_version "ngrok" "cask"
  log_brew_version "linear-linear" "cask"
  log_brew_version "1password" "cask"
  log_brew_version "google-chrome" "cask"
  log_brew_version "mas" "formula"
  log_brew_version "duti" "formula"
  log_brew_version "google-drive" "cask"
  log_brew_version "slack" "cask"
  log_brew_version "ykman" "formula"
  log_brew_version "pam-u2f" "formula"
}
