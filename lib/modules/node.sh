#!/usr/bin/env zsh

install_nvm_and_node() {
  # install nvm
  export NVM_DIR="$HOME/.nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"

    echo -e "${BLUE}Using nvm $(nvm --version)${NC}"
  else
    echo -e "${WHITE}Installing nvm...${NC}"

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | zsh

    # source nvm
    if [ -s "$NVM_DIR/nvm.sh" ]; then
      . "$NVM_DIR/nvm.sh"
      echo -e "${GREEN}Successfully installed nvm $(nvm --version)${NC}"
      RESTART_REQUIRED=true
    else
      echo -e "${RED}Failed to install nvm${NC}"
      exit 1
    fi
  fi

  # add nvm to ~/.zshrc
  if ! grep -q "NVM_DIR" "$ZSHRC_FILE"; then
    echo '' >> "$ZSHRC_FILE"
    echo '# nvm' >> "$ZSHRC_FILE"
    echo 'export NVM_DIR="$HOME/.nvm"' >> "$ZSHRC_FILE"
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$ZSHRC_FILE"
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$ZSHRC_FILE"
    echo -e "${GREEN}Successfully added nvm to path${NC}"
    RESTART_REQUIRED=true
  fi

  # install node & npm
  NODE_VERSION=$(cat .nvmrc 2> /dev/null || echo "lts/*")
  if [[ "$(node -v)" != "$NODE_VERSION" ]]; then
    echo -e "${WHITE}Installing node $NODE_VERSION via nvm...${NC}"
    if nvm install "$NODE_VERSION" -s; then
      nvm alias default "$NODE_VERSION"
      echo -e "${GREEN}Successfully installed node $NODE_VERSION${NC}"
      RESTART_REQUIRED=true
    else
      echo -e "${RED}Failed to install node $NODE_VERSION via nvm${NC}"
      exit 1
    fi
  else
    echo -e "${BLUE}Using node $(node -v)${NC}"
  fi
}
