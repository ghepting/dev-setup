#!/usr/bin/env zsh

install_gemini_cli() {
  # install gemini CLI
  NPM_GEMINI_PACKAGE="@google/gemini-cli"
  NPM_LIST_ARGS=(list -g --parseable ${NPM_GEMINI_PACKAGE})
  NPM_OUTDATED_ARGS=(outdated)
  NPM_INSTALL_ARGS=(install -g --no-audit --no-fund --loglevel silent)
  NPM_UPDATE_ARGS=(update -g --no-audit --no-fund --loglevel silent)

  if command -v gemini &> /dev/null; then
    OUTDATED_OUTPUT=$(npm $NPM_OUTDATED_ARGS $NPM_GEMINI_PACKAGE --json 2> /dev/null)
    if [[ "$OUTDATED_OUTPUT" == *"$NPM_GEMINI_PACKAGE"* ]]; then
      # prompt to update
      if confirm_action "Update $NPM_GEMINI_PACKAGE?" "n"; then
        log_warn "$NPM_GEMINI_PACKAGE is outdated"
        log_info "Updating Gemini CLI..."
        if npm $NPM_UPDATE_ARGS $NPM_GEMINI_PACKAGE; then
          log_success "Successfully updated $NPM_GEMINI_PACKAGE"
        else
          log_error "Failed to npm update $NPM_GEMINI_PACKAGE. Manually removing current package directories to do clean install..."
          # update failed due to permissions, remove gemini to install fresh
          rm -rf $(which gemini)
          rm -rf $(npm $NPM_LIST_ARGS)
          if npm $NPM_INSTALL_ARGS $NPM_GEMINI_PACKAGE; then
            log_success "Successfully re-installed $NPM_GEMINI_PACKAGE"
          else
            log_error "Failed to re-install $NPM_GEMINI_PACKAGE"
            exit 1
          fi
        fi
      fi
    fi

    log_status "Using gemini $(gemini --version)"
  else
    # check if gemini is enabled in config file
    if is_enabled "gemini_cli"; then
      log_info "Installing Gemini CLI..."
      if npm $NPM_INSTALL_ARGS $NPM_GEMINI_PACKAGE; then
        log_success "Successfully installed $NPM_GEMINI_PACKAGE"
        RESTART_REQUIRED=true
      else
        log_error "Failed to install $NPM_GEMINI_PACKAGE"
        exit 1
      fi
    fi
  fi
}
