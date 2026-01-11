#!/usr/bin/env zsh

setup_1password_cli() {
  # ensure 1Password CLI is installed
  if ! command -v op &> /dev/null; then
    echo -e "${WHITE}Installing 1Password CLI...${NC}"
    if is_macos; then
      brew install --cask 1password-cli
    elif is_debian; then
      # Install dependencies for 1Password CLI
      install_pkg "gnupg"
      install_pkg "ca-certificates"

      # Add 1Password GPG key and repo if not present (shared with GUI but here for completeness)
      if [ ! -f /usr/share/keyrings/1password-archive-keyring.gpg ]; then
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
      fi
      if [ ! -f /etc/apt/sources.list.d/1password.list ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | sudo tee /etc/apt/sources.list.d/1password.list
      fi

      sudo apt-get update && sudo apt-get install -y 1password-cli
    fi
  fi

  # ensure user is logged in
  if ! op whoami &> /dev/null; then
    if is_macos && [ -d "/Applications/1Password.app" ]; then
      open /Applications/1Password.app
    fi
    echo -e "${WHITE}Please log in to 1Password and enable the 1Password CLI integration in the Developer settings...${NC}"
    echo -n "Press [Enter] after logging in to 1Password and enabling the 1Password CLI integration..."
    read
    op signin
  fi

  # Verify login was successful
  if ! op whoami &> /dev/null; then
    echo -e "${RED}Failed to sign in to 1Password CLI.${NC}"
    exit 1
  fi
}
