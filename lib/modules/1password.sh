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
  elif is_fedora; then
    if ! rpm -q "1password" &> /dev/null; then
      log_info "Installing 1Password GUI for Fedora..."
      # Import the 1Password key
      sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc

      # Add the 1Password repo (DNF uses yum.repos.d)
      sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'

      # Install
      sudo dnf install -y 1password
    else
       log_status "1Password GUI is already installed."
    fi
  elif is_arch; then
    if ! pacman -Qi 1password &> /dev/null; then
      log_info "Installing 1Password GUI for Arch (via AUR)..."

      # Import key
      curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import

      # Install from AUR
      local tmp_dir
      tmp_dir=$(mktemp -d)
      pushd "$tmp_dir" > /dev/null || return 1

      if git clone https://aur.archlinux.org/1password.git .; then
        makepkg -si --noconfirm
      else
        log_error "Failed to clone 1password AUR repo"
      fi

      popd > /dev/null || return 1
      rm -rf "$tmp_dir"
    else
      log_status "1Password GUI is already installed."
    fi
  else
    log_warn "1Password GUI installation not yet supported on this Linux distribution."
  fi
}
