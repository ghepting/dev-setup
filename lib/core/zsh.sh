#!/usr/bin/env zsh

ensure_zsh_include() {
  # Ensure the dev config file exists
  if [ ! -f "$DEV_ZSH_CONFIG" ]; then
    touch "$DEV_ZSH_CONFIG"
    echo -e "${GREEN}Created ${DEV_ZSH_CONFIG}${NC}"
  fi

  # Ensure ~/.zshrc sources our dev config
  local source_line="source \"$DEV_ZSH_CONFIG\""
  if ! grep -qF "$source_line" "$ZSHRC_FILE"; then
    echo '' >> "$ZSHRC_FILE"
    echo "# dev-setup configuration" >> "$ZSHRC_FILE"
    echo "$source_line" >> "$ZSHRC_FILE"
    echo -e "${GREEN}Added source line to ${ZSHRC_FILE}${NC}"
    RESTART_REQUIRED=true
  fi
}

add_to_zsh_config() {
  local content="$1"
  local comment="$2"

  # Check if content is already in the file
  if ! grep -qF "$content" "$DEV_ZSH_CONFIG"; then
    echo '' >> "$DEV_ZSH_CONFIG"
    if [ -n "$comment" ]; then
      echo "# $comment" >> "$DEV_ZSH_CONFIG"
    fi
    echo "$content" >> "$DEV_ZSH_CONFIG"
    RESTART_REQUIRED=true
    return 0
  fi
  return 1
}
