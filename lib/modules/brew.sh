#!/usr/bin/env zsh

install_homebrew() {
  if ! command -v brew &>/dev/null; then
    echo -e "${WHITE}Installing Homebrew...${NC}"
    /usr/bin/env zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    RESTART_REQUIRED=true

    # Configure shell environment for the current session
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    echo -e "${WHITE}Updating Homebrew...${NC}"
    brew update &>/dev/null
  fi
  echo -e "${BLUE}Using Homebrew $(brew --version)${NC}"
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
    echo -e "${GREEN}Homebrew PATH line added to $ZSHRC_FILE.${NC}"
    RESTART_REQUIRED=true
  fi
}

install_ghostty_path() {
  # add ghostty path to ~/.zshrc
  GHOSTTY_PATH_CMD='export PATH=$PATH:/Applications/Ghostty.app/Contents/MacOS'
  if ! grep -qF "$GHOSTTY_PATH_CMD" "$ZSHRC_FILE"; then
    echo '' >>"$ZSHRC_FILE"
    echo '# ghostty' >>"$ZSHRC_FILE"
    echo "$GHOSTTY_PATH_CMD" >>"$ZSHRC_FILE"
    echo -e "${GREEN}Ghostty PATH line added to $ZSHRC_FILE.${NC}"
    RESTART_REQUIRED=true
  fi
}

install_homebrew_formulae() {
  # install homebrew packages
  echo -e "${WHITE}Installing Homebrew formulae...${NC}"
  brew bundle --upgrade -q

  echo -e "${BLUE}Using iterm2 $(defaults read /Applications/iTerm.app/Contents/Info.plist CFBundleShortVersionString)${NC}"
  echo -e "${BLUE}Using ghostty $(defaults read /Applications/Ghostty.app/Contents/Info.plist CFBundleShortVersionString)${NC}"
  echo -e "${BLUE}Using $(tmux -V)${NC}"
  echo -e "${BLUE}Using vim $(vim --version | head -n 1 | sed -E 's/.*([0-9]+\.[0-9]+).*/\1/')${NC}"
  echo -e "${BLUE}Using direnv $(direnv --version)${NC}"
  echo -e "${BLUE}Using Antigravity $(agy -v 2>/dev/null | grep -E --color=no '^[0-9]+\.[0-9]+\.[0-9]+$')${NC}"
  echo -e "${BLUE}Using Postman $(defaults read /Applications/Postman.app/Contents/Info.plist CFBundleShortVersionString)${NC}"
  echo -e "${BLUE}Using $(ngrok --version)${NC}"
  echo -e "${BLUE}Using Google Drive $(defaults read /Applications/Google\ Drive.app/Contents/Info.plist CFBundleShortVersionString)${NC}"
  echo -e "${BLUE}Using Google Chrome $(defaults read /Applications/Google\ Chrome.app/Contents/Info.plist CFBundleShortVersionString)${NC}"
  echo -e "${BLUE}Using Linear $(defaults read /Applications/Linear.app/Contents/Info.plist CFBundleShortVersionString)${NC}"
}
