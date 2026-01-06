#!/usr/bin/env zsh

install_gemini_cli() {
  # install gemini CLI
  NPM_GEMINI_PACKAGE="@google/gemini-cli"
  NPM_LIST_ARGS=(list -g --parseable ${NPM_GEMINI_PACKAGE})
  NPM_OUTDATED_ARGS=(outdated)
  NPM_INSTALL_ARGS=(install -g --no-audit --no-fund --loglevel silent)
  NPM_UPDATE_ARGS=(update -g --no-audit --no-fund --loglevel silent)

  if command -v gemini &> /dev/null
  then
    OUTDATED_OUTPUT=$(npm $NPM_OUTDATED_ARGS $NPM_GEMINI_PACKAGE --json 2> /dev/null)
    if [[ "$OUTDATED_OUTPUT" == *"$NPM_GEMINI_PACKAGE"* ]]
    then
      # prompt to update
      read -p "Update $NPM_GEMINI_PACKAGE? [y/N] " -n 1 -r
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo -e "${YELLOW}$NPM_GEMINI_PACKAGE is outdated${NC}"
        echo -e "${WHITE}Updating Gemini CLI...${NC}"
        if npm $NPM_UPDATE_ARGS $NPM_GEMINI_PACKAGE
        then
          echo -e "${GREEN}Successfully updated $NPM_GEMINI_PACKAGE${NC}"
        else
          echo -e "${MAGENTA}Failed to npm update $NPM_GEMINI_PACKAGE. Manually removing current package directories to do clean install...${NC}"
          # update failed due to permissions, remove gemini to install fresh
          rm -rf $(which gemini)
          rm -rf $(npm $NPM_LIST_ARGS)
          if npm $NPM_INSTALL_ARGS $NPM_GEMINI_PACKAGE
          then
            echo -e "${GREEN}Successfully re-installed $NPM_GEMINI_PACKAGE${NC}"
          else
            echo -e "${RED}Failed to re-install $NPM_GEMINI_PACKAGE${NC}"
            exit 1
          fi
        fi
      fi
    fi

    echo -e "${BLUE}Using gemini $(gemini --version)${NC}"
  else
    # check if gemini is enabled in config file
    if is_enabled "gemini_cli"
    then
      echo -e "${WHITE}Installing Gemini CLI...${NC}"
      if npm $NPM_INSTALL_ARGS $NPM_GEMINI_PACKAGE
      then
        echo -e "${GREEN}Successfully installed $NPM_GEMINI_PACKAGE${NC}"
        RESTART_REQUIRED=true
      else
        echo -e "${RED}Failed to install $NPM_GEMINI_PACKAGE${NC}"
        exit 1
      fi
    fi
  fi
}
