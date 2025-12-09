SSH_CONFIG_BLOCK=$(cat <<EOF
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
)
SSH_CONFIG_FILE="$HOME/.ssh/config"

setup_1password() {
  echo -e "${BLUE}Using 1Password $(defaults read /Applications/1Password.app/Contents/Info CFBundleShortVersionString)${NC}"
  echo -e "${BLUE}Using op $(op --version) ${GRAY}(1Password CLI)${NC}"

  echo -e "${WHITE}Configuring 1Password...${NC}"

  # sign into 1password via CLI
  op signin

  if [[ "$SSH_AUTH_SOCK" =~ "1password" ]]
  then
    echo -e "${BLUE}Using 1Password ssh agent${NC}"
  else
    echo -e "${WHITE}Configuring 1Password ssh agent...${NC}"
    # create ssh config file if it doesn't already exist
    if [ -f "$SSH_CONFIG_FILE" ]
    then
      # backup existing ssh config if it contains any other content
      TIMESTAMP=$(date +%Y%m%d_%H%M%S)
      cp "$SSH_CONFIG_FILE" "$SSH_CONFIG_FILE.backup.$TIMESTAMP"
      echo -e "${GRAY}Backed up existing $SSH_CONFIG_FILE to $SSH_CONFIG_FILE.backup.$TIMESTAMP${NC}"
    else
      mkdir -p "$(dirname "$SSH_CONFIG_FILE")"
      touch "$SSH_CONFIG_FILE"
    fi

    # add 1password ssh agent to ssh config
    echo "$SSH_CONFIG_BLOCK" >> "$SSH_CONFIG_FILE"
    echo -e "${GREEN}Added 1Password ssh agent configuration to $SSH_CONFIG_FILE${NC}"

    # restart ssh agent if it's not already running
    if [ -z "$SSH_AUTH_SOCK" ]
    then
      echo -e "${YELLOW}SSH_AUTH_SOCK is not set. Please restart your terminal to activate 1Password ssh agent.${NC}"
      RESTART_REQUIRED=true
    fi
  fi
}
