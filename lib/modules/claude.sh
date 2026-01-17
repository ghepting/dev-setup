#!/usr/bin/env zsh

install_claude_code_cli() {
  if command -v claude &> /dev/null; then
    log_status "Using claude $(claude --version)"
  else
    # check if claude is enabled in config file
    if is_enabled "claude_code_cli"; then
      curl -fsSL https://claude.ai/install.sh | zsh
      # ensure claude is in PATH
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc

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
