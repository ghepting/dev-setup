#!/usr/bin/env zsh

install_nvm_and_node() {
  # install nvm
  export NVM_DIR="$HOME/.nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"

    log_status "Using nvm $(nvm --version)"
  else
    log_info "Installing nvm..."

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # source nvm
    if [ -s "$NVM_DIR/nvm.sh" ]; then
      . "$NVM_DIR/nvm.sh"
      log_success "Successfully installed nvm $(nvm --version)"
      RESTART_REQUIRED=true
    else
      log_error "Failed to install nvm"
      exit 1
    fi
  fi

  # add nvm to ~/.zshrc.dev
  install_zsh_config "nvm"
  ensure_zshrc_dev_sourced

  # install node & npm
  NODE_VERSION=$(cat .nvmrc 2> /dev/null || echo "lts/*")
  if [[ "$(node -v)" != "$NODE_VERSION" ]]; then
    log_info "Installing node $NODE_VERSION via nvm..."
    if nvm install "$NODE_VERSION" -s; then
      nvm alias default "$NODE_VERSION"
      log_success "Successfully installed node $NODE_VERSION"
      RESTART_REQUIRED=true
    else
      log_error "Failed to install node $NODE_VERSION via nvm"
      exit 1
    fi
  else
    log_status "Using node $(node -v)"
  fi
}
