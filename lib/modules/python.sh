#!/usr/bin/env zsh

install_pyenv_and_python() {
  if ! command -v pyenv &> /dev/null; then
    if is_debian; then
      # Build dependencies for pyenv
      local deps=("build-essential" "libssl-dev" "zlib1g-dev" "libbz2-dev" "libreadline-dev" "libsqlite3-dev" "curl" "git" "libncursesw5-dev" "xz-utils" "tk-dev" "libxml2-dev" "libxmlsec1-dev" "libffi-dev" "liblzma-dev" "pyenv")
      for dep in "${deps[@]}"; do
        install_pkg "$dep"
      done
    else
      install_pkg "pyenv"
    fi
    RESTART_REQUIRED=true
  else
    log_status "Using $(pyenv --version)"
  fi

  # run 'eval "$(pyenv init -)"' to use pyenv commands in the current script session
  if command -v pyenv &> /dev/null; then
    eval "$(pyenv init -)"
  fi

  # add pyenv init to .zshrc
  if ! grep -q "pyenv init" "$ZSHRC_FILE"; then
    echo '' >> "$ZSHRC_FILE"
    echo '# pyenv' >> "$ZSHRC_FILE"
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$ZSHRC_FILE"
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> "$ZSHRC_FILE"
    echo 'eval "$(pyenv init - zsh)"' >> "$ZSHRC_FILE"
    log_success "Added pyenv init to .zshrc"
    RESTART_REQUIRED=true
  fi

  # look for a .python-version file, otherwise default to a stable 3.x version
  PYTHON_VERSION=$(cat .python-version 2> /dev/null || echo "3.14.2")

  # check if the desired version is already installed by pyenv
  if pyenv versions --bare | grep -q "^$PYTHON_VERSION$"; then
    log_status "Using python $PYTHON_VERSION"
  else
    log_info "Installing python $PYTHON_VERSION..."
    if pyenv install $PYTHON_VERSION &> /dev/null; then
      log_success "Successfully installed python $PYTHON_VERSION"
      RESTART_REQUIRED=true
      # set global default and report
      pyenv global "$PYTHON_VERSION" &> /dev/null

      PYTHON_EXECUTABLE=$(pyenv which python)
      PYTHON_VERSION=$($PYTHON_EXECUTABLE --version 2> /dev/null | awk '{print $2}')
      PIP_VERSION=$($PYTHON_EXECUTABLE -m pip --version 2> /dev/null | awk '{print $2}')

      log_status "Default python set to $PYTHON_VERSION / pip $PIP_VERSION"
    else
      log_error "Failed to install python $PYTHON_VERSION"
      exit 1
    fi
  fi
}
