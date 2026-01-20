#!/usr/bin/env zsh

install_claude_code_cli() {
  if command -v claude &> /dev/null; then
    log_status "Using claude $(claude --version)"
  else
    # check if claude is enabled in config file
    if is_enabled "claude_code_cli"; then
      # Add ~/.local/bin to PATH for the installer check and subsequent verification
      export PATH="$HOME/.local/bin:$PATH"

      curl -fsSL https://claude.ai/install.sh | zsh

      install_zsh_config "local_bin"
      ensure_zshrc_dev_sourced

      if command -v claude &> /dev/null; then
        log_success "Successfully installed claude $(claude --version)"
        RESTART_REQUIRED=true
      else
        log_error "Failed to install claude"
        exit 1
      fi
    fi
  fi
}
