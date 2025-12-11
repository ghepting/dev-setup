install_homebrew() {
  if ! command -v brew &> /dev/null
  then
    echo -e "${WHITE}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    RESTART_REQUIRED=true
    if command -v brew &> /dev/null;
    then
      export PATH="$(brew --prefix)/bin:$PATH"
    fi
  else
    echo -e "${WHITE}Updating Homebrew...${NC}"
    brew update &> /dev/null
  fi
  echo -e "${BLUE}Using Homebrew $(brew --version)${NC}"
}

install_homebrew_path() {
  # ensure ~/.zshrc exists for initial setup
  touch "$ZSHRC_FILE"

  # ensure brew bins are added to $PATH
  BREW_PREFIX_CMD='export PATH="$(brew --prefix)/bin:$PATH"'
  if ! grep -qF "$BREW_PREFIX_CMD" "$ZSHRC_FILE"
  then
    echo '' >> "$ZSHRC_FILE"
    echo '# homebrew' >> "$ZSHRC_FILE"
    echo "$BREW_PREFIX_CMD" >> "$ZSHRC_FILE"
    echo -e "${GREEN}Homebrew PATH line added to $ZSHRC_FILE.${NC}"
    RESTART_REQUIRED=true
  fi
}

install_homebrew_formulae() {
  # install homebrew packages
  echo -e "${WHITE}Installing Homebrew formulae...${NC}"
  brew bundle --upgrade -q
}
