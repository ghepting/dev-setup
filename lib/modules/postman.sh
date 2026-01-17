#!/usr/bin/env zsh

install_postman_cli() {
  # install postman CLI
  NPM_PACKAGE="postman-cli"
  NPM_INSTALL_ARGS=(install -g --no-audit --no-fund --loglevel silent)

  if command -v postman &> /dev/null; then
    log_status "Using postman $(postman --version)"
  else
    # check if postman is enabled in config file
    if is_enabled "postman_cli"; then
      log_info "Installing Postman CLI..."
      if npm $NPM_INSTALL_ARGS $NPM_PACKAGE; then
        log_success "Successfully installed $NPM_PACKAGE"
        RESTART_REQUIRED=true
      else
        log_error "Failed to install $NPM_PACKAGE"
        exit 1
      fi
    fi
  fi
}
