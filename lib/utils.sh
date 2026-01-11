#!/usr/bin/env zsh

# Utility functions that depend on PLATFORM being set in lib/vars.sh

is_macos() {
  [[ "$PLATFORM" == "macOS" ]]
}

is_linux() {
  [[ "$PLATFORM" == "Debian" || "$PLATFORM" == "Arch" || "$PLATFORM" == "Fedora" || "$PLATFORM" == "Linux" ]]
}

is_debian() {
  [[ "$PLATFORM" == "Debian" ]]
}

is_arch() {
  [[ "$PLATFORM" == "Arch" ]]
}

is_fedora() {
  [[ "$PLATFORM" == "Fedora" ]]
}

install_pkg() {
  local package=$1
  if is_macos; then
    if ! brew list "$package" &> /dev/null; then
      echo -e "${WHITE}Installing $package via Homebrew...${NC}"
      brew install "$package"
    fi
  elif is_debian; then
    if ! dpkg-query -W -f='${Status}' "$package" 2> /dev/null | grep -q "ok installed"; then
      echo -e "${WHITE}Installing $package via apt...${NC}"
      sudo apt-get update
      sudo apt-get install -y "$package"
    fi
  elif is_arch; then
    if ! pacman -Qs "^$package$" &> /dev/null; then
      echo -e "${WHITE}Installing $package via pacman...${NC}"
      sudo pacman -S --noconfirm "$package"
    fi
  elif is_fedora; then
    if ! rpm -q "$package" &> /dev/null; then
      echo -e "${WHITE}Installing $package via dnf...${NC}"
      sudo dnf install -y "$package"
    fi
  fi
}

is_enabled() {
  local module=$1

  # Check if explicitly set in config
  if [ -f "$CONFIG_FILE" ]; then
    if grep -q "^${module}=false$" "$CONFIG_FILE"; then
      return 1
    elif grep -q "^${module}=true$" "$CONFIG_FILE"; then
      return 0
    fi
  fi

  # Default values if not explicitly set
  case "$module" in
  dotfiles | vim_tmux)
    return 0 # Always enabled by default
    ;;
  editor)
    is_macos && return 0
    return 1 # GUI IDE setup disabled by default on Linux
    ;;
  *)
    # For everything else (docker, languages, op_cli, 1password_ssh, google_drive, etc.)
    is_macos && return 0 # Enable on Mac
    return 1             # Disable on Linux
    ;;
  esac
}

# Set config value in ~/.config/dev-setup.conf
set_config_value() {
  local key=$1
  local value=$2

  if grep -q "^${key}=" "$CONFIG_FILE" 2> /dev/null; then
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
    rm -f "${CONFIG_FILE}.bak"
  else
    echo "${key}=${value}" >> "$CONFIG_FILE"
  fi
}

is_ssh() {
  [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]
}

check_app() {
  local app_name=$1
  [ -d "/Applications/${app_name}.app" ]
}

setup_google_drive() {
  if ! is_enabled "google_drive"; then
    return
  fi

  local gdrive_type="app"
  is_linux && gdrive_type="rclone"

  if grep -q "^google_drive_type=rclone$" "$CONFIG_FILE" 2> /dev/null; then
    gdrive_type="rclone"
  elif grep -q "^google_drive_type=app$" "$CONFIG_FILE" 2> /dev/null; then
    gdrive_type="app"
  fi

  if is_macos && [[ "$gdrive_type" == "app" ]]; then
    if ! check_app "Google Drive"; then
      echo -e "${YELLOW}Installing Google Drive for macOS...${NC}"
      brew install --cask google-drive
      open /Applications/Google\ Drive.app
      echo -n "Press [Enter] after logging in to Google Drive..."
      read
    fi
  elif is_linux || [[ "$gdrive_type" == "rclone" ]]; then
    if ! command -v rclone &> /dev/null; then
      echo -e "${YELLOW}Installing rclone for Google Drive support...${NC}"
      install_pkg "rclone"
    fi

    # Check if a mount directory exists
    local gdrive_mount="$HOME/Google Drive"
    if [ ! -d "$gdrive_mount" ]; then
      mkdir -p "$gdrive_mount"
    fi

    # Check if it's already mounted (simple check for files)
    if [ -z "$(ls -A "$gdrive_mount" 2> /dev/null)" ]; then
      echo -e "${YELLOW}Google Drive is not mounted at $gdrive_mount${NC}"
      echo -e "${WHITE}Please ensure rclone is configured with a 'gdrive' remote.${NC}"
      if ! rclone listremotes | grep -q "gdrive:"; then
        echo -e "${MAGENTA}No 'gdrive' remote found in rclone configuration.${NC}"
        echo -e "${WHITE}Running 'rclone config' - please create a new remote named 'gdrive' of type google drive.${NC}"
        rclone config
      fi

      echo -e "${YELLOW}Attempting to mount Google Drive via rclone...${NC}"
      # We use --daemon to run it in the background
      # On macOS, mounting might require macfuse, but let's try the basic mount first
      if rclone mount gdrive: "$gdrive_mount" --vfs-cache-mode full --daemon; then
        echo -e "${GREEN}Google Drive mounted successfully at $gdrive_mount${NC}"
      else
        echo -e "${RED}Failed to mount Google Drive. Please check rclone configuration.${NC}"
        if is_macos; then
          echo -e "${YELLOW}Note: rclone mount on macOS may require macfuse (brew install --cask macfuse).${NC}"
        fi
      fi
    fi
  fi
}
