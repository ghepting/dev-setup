#!/usr/bin/env zsh

install_postman_cli() {
  # install postman CLI
  NPM_PACKAGE="postman-cli"
  NPM_INSTALL_ARGS=(install -g --no-audit --no-fund --loglevel silent)

  if command -v postman &> /dev/null
  then
    echo -e "${BLUE}Using postman $(postman --version)${NC}"
  else
    # check if postman is enabled in config file
    if [ -f "$CONFIG_FILE" ] && grep -q "^postman_cli=true$" "$CONFIG_FILE"
    then
      echo -e "${WHITE}Installing Postman CLI...${NC}"
      if npm $NPM_INSTALL_ARGS $NPM_PACKAGE
      then
        echo -e "${GREEN}Successfully installed $NPM_PACKAGE${NC}"
        RESTART_REQUIRED=true
      else
        echo -e "${RED}Failed to install $NPM_PACKAGE${NC}"
        exit 1
      fi
    fi
  fi
}