#!/usr/bin/env zsh

install_claude_code_cli() {
  if command -v claude &> /dev/null
  then
    echo -e "${BLUE}Using claude $(claude --version)${NC}"
  else
    # check if claude is enabled in config file
    if is_enabled "claude_code_cli"
    then
      curl -fsSL https://claude.ai/install.sh | bash
      # ensure claude is in PATH
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc

      if command -v claude &> /dev/null
      then
        echo -e "${GREEN}Successfully installed claude $(claude --version)${NC}"
        RESTART_REQUIRED=true
      else
        echo -e "${RED}Failed to install claude${NC}"
        exit 1
      fi
    fi
  fi
}
