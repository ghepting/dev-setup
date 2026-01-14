#!/usr/bin/env zsh

install_pyenv_and_python() {
  if ! command -v pyenv &> /dev/null; then
    if is_macos; then
      brew bundle --file=lib/packages/python/Brewfile -q
    else
      # Install dependencies first (Fedora/Debian/Arch)
      if is_debian; then
        install_packages_from_file "lib/packages/python/debian.list"
      elif is_fedora; then
        install_packages_from_file "lib/packages/python/fedora.list"
      elif is_arch; then
         # arch.list handles most, but ensuring base-devel is key
         install_pkg "base-devel"
      fi

      # Install pyenv via git if not present
      if [ ! -d "$HOME/.pyenv" ]; then
        echo -e "${WHITE}Cloning pyenv to ~/.pyenv...${NC}"
        git clone https://github.com/pyenv/pyenv.git ~/.pyenv
      fi
    fi
    RESTART_REQUIRED=true
  else
    echo -e "${BLUE}Using $(pyenv --version)${NC}"
  fi

  # Ensure environment is set up for the current script session
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

  if command -v pyenv &> /dev/null; then
    eval "$(pyenv init -)"
  fi

  # add pyenv init to zsh config
  local pyenv_config='# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"'

  if add_to_zsh_config "$pyenv_config" "pyenv"; then
    echo -e "${GREEN}Added pyenv init to config${NC}"
    RESTART_REQUIRED=true
  fi

  # look for a .python-version file, otherwise default to a stable 3.x version
  PYTHON_VERSION=$(cat .python-version 2> /dev/null || echo "3.14.2")

  # check if the desired version is already installed by pyenv
  if pyenv versions --bare | grep -q "^$PYTHON_VERSION$"; then
    echo -e "${BLUE}Using python $PYTHON_VERSION${NC}"
  else
    echo -e "${WHITE}Installing python $PYTHON_VERSION...${NC}"
    if pyenv install $PYTHON_VERSION &> /dev/null; then
      echo -e "${GREEN}Successfully installed python $PYTHON_VERSION${NC}"
      RESTART_REQUIRED=true
      # set global default and report
      pyenv global "$PYTHON_VERSION" &> /dev/null

      PYTHON_EXECUTABLE=$(pyenv which python)
      PYTHON_VERSION=$($PYTHON_EXECUTABLE --version 2> /dev/null | awk '{print $2}')
      PIP_VERSION=$($PYTHON_EXECUTABLE -m pip --version 2> /dev/null | awk '{print $2}')

      echo -e "${BLUE}Default python set to $PYTHON_VERSION / pip $PIP_VERSION${NC}"
    else
      echo -e "${RED}Failed to install python $PYTHON_VERSION${NC}"
      exit 1
    fi
  fi
}
