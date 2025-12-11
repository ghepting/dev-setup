SSH_CONFIG_BLOCK=$(cat <<EOF
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
)
SSH_CONFIG_FILE="$HOME/.ssh/config"

setup_1password() {
  echo -e "${BLUE}Using 1Password $(defaults read /Applications/1Password.app/Contents/Info CFBundleShortVersionString)${NC}"

  # ensure 1Password CLI is installed
  if ! command -v op &> /dev/null
  then
    echo -e "${WHITE}Installing 1Password CLI...${NC}"
    brew install --cask 1password-cli
  fi

  # ensure user is logged in
  if ! op whoami &> /dev/null
  then
    open /Applications/1Password.app
    echo -e "${WHITE}Please log in to 1Password and enable the 1Password CLI integration in the Developer settings...${NC}"
    read "?Press [Enter] after logging in to 1Password and enabling the 1Password CLI integration..."
    op signin
  fi

  # Verify login was successful
  if ! op whoami &> /dev/null
  then
    echo -e "${RED}Failed to sign in to 1Password CLI.${NC}"
    exit 1
  fi

  # configure SSH Config (Idempotent)
  # create ssh config file if it doesn't already exist
  if [ ! -f "$SSH_CONFIG_FILE" ]
  then
    mkdir -p "$(dirname "$SSH_CONFIG_FILE")"
    touch "$SSH_CONFIG_FILE"
  fi

  # add 1password ssh agent to ssh config if not already present
  if ! grep -q "IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"" "$SSH_CONFIG_FILE"
  then
    echo "$SSH_CONFIG_BLOCK" >> "$SSH_CONFIG_FILE"
    echo -e "${GREEN}Added 1Password SSH agent to $SSH_CONFIG_FILE${NC}"
  else
    echo -e "${BLUE}Using 1Password SSH agent${NC}"
  fi

  # configure environment variable (Idempotent)
  # ensure SSH_AUTH_SOCK is exported in .zshrc
  SOCK_PATH="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  EXPORT_CMD="export SSH_AUTH_SOCK=\"$SOCK_PATH\""

  if ! grep -qF "$EXPORT_CMD" "$ZSHRC_FILE"
  then
    echo '' >> "$ZSHRC_FILE"
    echo '# 1password' >> "$ZSHRC_FILE"
    echo "$EXPORT_CMD" >> "$ZSHRC_FILE"
    echo -e "${GREEN}Added SSH_AUTH_SOCK export to $ZSHRC_FILE${NC}"
    RESTART_REQUIRED=true
  fi

  # verify that $HOME/.config/1Password/ssh/agent.toml exists and is configured with correct "Development" vault
  if [ ! -f "$HOME/.config/1Password/ssh/agent.toml" ]
  then
    mkdir -p "$HOME/.config/1Password/ssh"
    touch "$HOME/.config/1Password/ssh/agent.toml"
    echo "[[ssh-keys]]" >> "$HOME/.config/1Password/ssh/agent.toml"
    echo "vault = \"Development\"" >> "$HOME/.config/1Password/ssh/agent.toml"
    echo -e "${GREEN}Created $HOME/.config/1Password/ssh/agent.toml${NC}"
  elif ! grep -q "vault = \"Development\"" "$HOME/.config/1Password/ssh/agent.toml"
  then
    # replace default "Private" vault value with "Development"
    sed -i '' 's/vault = "Private"/vault = "Development"/' "$HOME/.config/1Password/ssh/agent.toml"
    echo -e "${GREEN}Configured $HOME/.config/1Password/ssh/agent.toml${NC}"
  else
    echo -e "${BLUE}Using 1Password \"Development\" vault${NC}"
  fi
}
