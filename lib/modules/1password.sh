#!/usr/bin/env zsh

setup_1password() {
  if is_macos; then
    if ! check_app "1Password"; then
      echo -e "${WHITE}Installing 1Password GUI for macOS...${NC}"
      brew install --cask 1password
    else
      echo -e "${BLUE}Using 1Password $(defaults read /Applications/1Password.app/Contents/Info CFBundleShortVersionString)${NC}"
    fi
  elif is_debian; then
    if ! command -v 1password &> /dev/null; then
      echo -e "${WHITE}Installing 1Password GUI for Debian...${NC}"
      # Add 1Password GPG key and repo if not present
      if [ ! -f /usr/share/keyrings/1password-archive-keyring.gpg ]; then
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
      fi
      if [ ! -f /etc/apt/sources.list.d/1password.list ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | sudo tee /etc/apt/sources.list.d/1password.list
      fi
      sudo apt-get update && sudo apt-get install -y 1password
    else
      echo -e "${BLUE}1Password GUI is already installed.${NC}"
    fi
  else
    echo -e "${YELLOW}1Password GUI installation not yet supported on this Linux distribution.${NC}"
  fi
}
