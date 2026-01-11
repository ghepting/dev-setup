#!/usr/bin/env zsh

setup_1password_ssh() {
  local SSH_CONFIG_FILE="$HOME/.ssh/config"

  # Determine if we should proceed (must have GUI or CLI enabled)
  if ! is_enabled "1password" && ! is_enabled "op_cli"; then
    echo -e "${GRAY}1Password SSH configuration skipped (requires 1Password GUI or CLI)${NC}"
    return
  fi

  # configure SSH Config (Idempotent)
  # Set socket path based on OS
  local sock_path
  if is_macos; then
    sock_path="~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  else
    sock_path="~/.1password/agent.sock"
  fi

  # create ssh config file if it doesn't already exist
  if [ ! -f "$SSH_CONFIG_FILE" ]; then
    mkdir -p "$(dirname "$SSH_CONFIG_FILE")"
    touch "$SSH_CONFIG_FILE"
  fi

  # add 1password ssh agent to ssh config if not already present
  if ! grep -q "IdentityAgent \"$sock_path\"" "$SSH_CONFIG_FILE"; then
    echo "Host *" >> "$SSH_CONFIG_FILE"
    echo "  IdentityAgent \"$sock_path\"" >> "$SSH_CONFIG_FILE"
    echo -e "${GREEN}Added 1Password SSH agent to $SSH_CONFIG_FILE${NC}"
  else
    echo -e "${BLUE}Using 1Password SSH agent${NC}"
  fi

  # configure environment variable (Idempotent)
  # ensure SSH_AUTH_SOCK is exported in .zshrc
  local export_cmd="export SSH_AUTH_SOCK=\"$sock_path\""

  if ! grep -qF "export SSH_AUTH_SOCK" "$ZSHRC_FILE"; then
    echo '' >> "$ZSHRC_FILE"
    echo '# 1password' >> "$ZSHRC_FILE"
    echo "$export_cmd" >> "$ZSHRC_FILE"
    echo -e "${GREEN}Added SSH_AUTH_SOCK export to $ZSHRC_FILE${NC}"
    RESTART_REQUIRED=true
  fi

  # verify that agent.toml exists and is configured with correct "Development" vault
  local agent_config="$HOME/.config/1Password/ssh/agent.toml"

  if [ ! -f "$agent_config" ]; then
    mkdir -p "$(dirname "$agent_config")"
    touch "$agent_config"
    echo "[[ssh-keys]]" >> "$agent_config"
    echo "vault = \"Development\"" >> "$agent_config"
    echo -e "${GREEN}Created $agent_config${NC}"
  elif ! grep -q "vault = \"Development\"" "$agent_config"; then
    # replace default vault value with "Development"
    if is_macos; then
      sed -i '' 's/vault = "[^"]*"/vault = "Development"/' "$agent_config"
    else
      sed -i 's/vault = "[^"]*"/vault = "Development"/' "$agent_config"
    fi
    echo -e "${GREEN}Configured $agent_config${NC}"
  else
    echo -e "${BLUE}Using 1Password \"Development\" vault${NC}"
  fi
}
