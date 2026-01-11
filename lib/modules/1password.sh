#!/usr/bin/env zsh

SSH_CONFIG_BLOCK=$(cat <<EOF
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
)
SSH_CONFIG_FILE="$HOME/.ssh/config"

setup_1password() {
  if is_debian; then
    # Strict opt-in for Debian servers
    if ! grep -q "^op=true$" "$CONFIG_FILE" 2>/dev/null; then
       echo -e "${GRAY}1Password setup skipped on Debian (explicit opt-in required)${NC}"
       return
    fi
  fi

  if is_macos; then
    echo -e "${BLUE}Using 1Password $(defaults read /Applications/1Password.app/Contents/Info CFBundleShortVersionString)${NC}"
  fi

  # ensure 1Password CLI is installed
  if ! command -v op &> /dev/null
  then
    echo -e "${WHITE}Installing 1Password CLI...${NC}"
    if is_macos; then
      brew install --cask 1password-cli
    elif is_debian; then
      # Install dependencies for 1Password CLI
      install_pkg "gnupg"
      install_pkg "ca-certificates"

      # Install 1Password CLI on Debian
      curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

      sudo tee /etc/apt/sources.list.d/1password.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main
EOF
      sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
      curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
      sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22/
      curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
      sudo apt-get update && sudo apt-get install -y 1password-cli
    fi
  fi

  # ensure user is logged in
  if ! op whoami &> /dev/null
  then
    if is_macos; then
      open /Applications/1Password.app
    fi
    echo -e "${WHITE}Please log in to 1Password and enable the 1Password CLI integration in the Developer settings...${NC}"
    echo -n "Press [Enter] after logging in to 1Password and enabling the 1Password CLI integration..."
    read
    op signin
  fi

  # Verify login was successful
  if ! op whoami &> /dev/null
  then
    echo -e "${RED}Failed to sign in to 1Password CLI.${NC}"
    exit 1
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
  if [ ! -f "$SSH_CONFIG_FILE" ]
  then
    mkdir -p "$(dirname "$SSH_CONFIG_FILE")"
    touch "$SSH_CONFIG_FILE"
  fi

  # add 1password ssh agent to ssh config if not already present
  if ! grep -q "IdentityAgent \"$sock_path\"" "$SSH_CONFIG_FILE"
  then
    echo "Host *" >> "$SSH_CONFIG_FILE"
    echo "  IdentityAgent \"$sock_path\"" >> "$SSH_CONFIG_FILE"
    echo -e "${GREEN}Added 1Password SSH agent to $SSH_CONFIG_FILE${NC}"
  else
    echo -e "${BLUE}Using 1Password SSH agent${NC}"
  fi

  # configure environment variable (Idempotent)
  # ensure SSH_AUTH_SOCK is exported in .zshrc
  local export_cmd="export SSH_AUTH_SOCK=\"$sock_path\""

  if ! grep -qF "export SSH_AUTH_SOCK" "$ZSHRC_FILE"
  then
    echo '' >> "$ZSHRC_FILE"
    echo '# 1password' >> "$ZSHRC_FILE"
    echo "$export_cmd" >> "$ZSHRC_FILE"
    echo -e "${GREEN}Added SSH_AUTH_SOCK export to $ZSHRC_FILE${NC}"
    RESTART_REQUIRED=true
  fi

  # verify that agent.toml exists and is configured with correct "Development" vault
  local agent_config
  if is_macos; then
    agent_config="$HOME/.config/1Password/ssh/agent.toml"
  else
    agent_config="$HOME/.config/1Password/ssh/agent.toml" # Same on Linux
  fi

  if [ ! -f "$agent_config" ]
  then
    mkdir -p "$(dirname "$agent_config")"
    touch "$agent_config"
    echo "[[ssh-keys]]" >> "$agent_config"
    echo "vault = \"Development\"" >> "$agent_config"
    echo -e "${GREEN}Created $agent_config${NC}"
  elif ! grep -q "vault = \"Development\"" "$agent_config"
  then
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
