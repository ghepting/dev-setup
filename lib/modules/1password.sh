#!/usr/bin/env zsh

setup_1password() {
  if is_macos; then
    if ! check_app "1Password"; then
      echo -e "${WHITE}Installing 1Password GUI for macOS...${NC}"
      brew bundle --file=lib/packages/1password/Brewfile -q
    else
      echo -e "${BLUE}1Password GUI already installed${NC}"
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
  elif is_fedora; then
    if ! command -v 1password &> /dev/null; then
      echo -e "${WHITE}Installing 1Password GUI for Fedora...${NC}"
      # Add the 1Password Yum repository
      sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
      sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'

      install_pkg "1password"
    else
      echo -e "${BLUE}1Password GUI already installed${NC}"
    fi
  else
    echo -e "${YELLOW}1Password GUI installation not yet supported on this Linux distribution.${NC}"
  fi
}
