#!/usr/bin/env zsh

setup_1password() {
  if is_macos; then
    if ! check_app "1Password"; then
      log_info "Installing 1Password GUI for macOS..."
      brew install --cask 1password
    else
      log_status "Using 1Password $(defaults read /Applications/1Password.app/Contents/Info CFBundleShortVersionString)"
    fi
  elif is_debian; then
    if ! command -v 1password &> /dev/null; then
      log_info "Installing 1Password GUI for Debian..."
      # Add 1Password GPG key and repo if not present
      if [ ! -f /usr/share/keyrings/1password-archive-keyring.gpg ]; then
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
      fi
      if [ ! -f /etc/apt/sources.list.d/1password.list ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | sudo tee /etc/apt/sources.list.d/1password.list
      fi
      sudo apt-get update && sudo apt-get install -y 1password
    else
      log_status "1Password GUI is already installed."
    fi
  else
    log_warn "1Password GUI installation not yet supported on this Linux distribution."
  fi
}
