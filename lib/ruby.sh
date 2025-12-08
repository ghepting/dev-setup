install_rbenv_and_ruby() {
  # install rbenv
  if ! command -v rbenv &> /dev/null
  then
    echo -e "${WHITE}Installing rbenv...${NC}"
    if brew install rbenv -q &> /dev/null
    then
      echo -e "${GREEN}Successfully installed rbenv${NC}"
      RESTART_REQUIRED=true
    else
      echo -e "${RED}Failed to install rbenv${NC}"
      exit 1
    fi
  else
    echo -e "${BLUE}Using $(rbenv --version)${NC}"
  fi

  RUBY_VERSION=$(cat .ruby-version)

  # install ruby
  if rbenv version-name = "$RUBY_VERSION" &> /dev/null
  then
    echo -e "${BLUE}Using ruby $(rbenv version-name)${NC}"
  else
    echo -e "${WHITE}Installing ruby $RUBY_VERSION...${NC}"
    if rbenv install $RUBY_VERSION -s && rbenv global $RUBY_VERSION &> /dev/null
    then
      echo -e "${GREEN}Successfully installed ruby $RUBY_VERSION via rbenv${NC}"
      RESTART_REQUIRED=true
    else
      echo -e "${RED}Failed to install ruby $RUBY_VERSION via rbenv${NC}"
      exit 1
    fi
  fi
}
