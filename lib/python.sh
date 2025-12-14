#!/usr/bin/env zsh

install_pyenv_and_python() {
  if ! command -v pyenv &> /dev/null
  then
    echo -e "${WHITE}Installing pyenv...${NC}"
    if brew install pyenv -q &> /dev/null
    then
      echo -e "${GREEN}Successfully installed pyenv${NC}"
      RESTART_REQUIRED=true
    else
      echo -e "${RED}Failed to install pyenv${NC}"
      exit 1
    fi
  else
    echo -e "${BLUE}Using $(pyenv --version)${NC}"
  fi

  # run 'eval "$(pyenv init -)"' to use pyenv commands in the current script session
  if command -v pyenv &> /dev/null
  then
    eval "$(pyenv init -)"
  fi

  # add pyenv init to .zshrc
  if ! grep -q "pyenv init" "$ZSHRC_FILE"
  then
    echo '' >> "$ZSHRC_FILE"
    echo '# pyenv' >> "$ZSHRC_FILE"
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$ZSHRC_FILE"
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> "$ZSHRC_FILE"
    echo 'eval "$(pyenv init - zsh)"' >> "$ZSHRC_FILE"
    echo -e "${GREEN}Added pyenv init to .zshrc${NC}"
    RESTART_REQUIRED=true
  fi

  # look for a .python-version file, otherwise default to a stable 3.x version
  PYTHON_VERSION=$(cat .python-version 2> /dev/null || echo "3.14.2")

  # check if the desired version is already installed by pyenv
  if pyenv versions --bare | grep -q "^$PYTHON_VERSION$"
  then
    echo -e "${BLUE}Using python $PYTHON_VERSION${NC}"
  else
    echo -e "${WHITE}Installing python $PYTHON_VERSION...${NC}"
    if pyenv install $PYTHON_VERSION &> /dev/null
    then
      echo -e "${GREEN}Successfully installed python $PYTHON_VERSION${NC}"
      RESTART_REQUIRED=true
      # set global default and report
      pyenv global "$PYTHON_VERSION" &> /dev/null

      PYTHON_EXECUTABLE=$(pyenv which python)
      PYTHON_VERSION=$($PYTHON_EXECUTABLE --version 2>/dev/null | awk '{print $2}')
      PIP_VERSION=$($PYTHON_EXECUTABLE -m pip --version 2>/dev/null | awk '{print $2}')

      echo -e "${BLUE}Default python set to $PYTHON_VERSION / pip $PIP_VERSION${NC}"
    else
      echo -e "${RED}Failed to install python $PYTHON_VERSION${NC}"
      exit 1
    fi
  fi
}
