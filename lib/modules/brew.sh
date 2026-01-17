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
  # ensure ~/.zshrc exists for initial setup
  touch "$ZSHRC_FILE"

  # ensure brew bins are added to $PATH
  BREW_PREFIX_CMD='PATH="$(brew --prefix)/bin:$PATH" && export PATH'
  if ! grep -qF "$BREW_PREFIX_CMD" "$ZSHRC_FILE"; then
    echo '' >>"$ZSHRC_FILE"
    echo '# homebrew' >>"$ZSHRC_FILE"
    echo "$BREW_PREFIX_CMD" >>"$ZSHRC_FILE"
    log_success "Homebrew PATH line added to $ZSHRC_FILE."
    RESTART_REQUIRED=true
  fi
}

install_homebrew_formulae() {
  # install homebrew packages
  log_info "Installing Homebrew formulae..."
  brew bundle --upgrade -q

  log_status "Using iterm2 $(defaults read /Applications/iTerm.app/Contents/Info.plist CFBundleShortVersionString)"
  log_status "Using $(tmux -V)"
  log_status "Using vim $(vim --version | head -n 1 | sed -E 's/.*([0-9]+\.[0-9]+).*/\1/')"
  log_status "Using direnv $(direnv --version)"
  log_status "Using Antigravity $(agy -v 2>/dev/null | grep -E --color=no '^[0-9]+\.[0-9]+\.[0-9]+$')"
  log_status "Using Postman $(defaults read /Applications/Postman.app/Contents/Info.plist CFBundleShortVersionString)"
  log_status "Using $(ngrok --version)"
  log_status "Using Google Chrome $(defaults read /Applications/Google\ Chrome.app/Contents/Info.plist CFBundleShortVersionString)"
  log_status "Using Linear $(defaults read /Applications/Linear.app/Contents/Info.plist CFBundleShortVersionString)"
}
