#!/usr/bin/env zsh

# Utility functions that depend on PLATFORM being set in lib/core/vars.sh

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
      log_info "Installing $package via Homebrew..."
      brew install "$package"
    fi
  elif is_debian; then
    if ! dpkg-query -W -f='${Status}' "$package" 2> /dev/null | grep -q "ok installed"; then
      log_info "Installing $package via apt..."
      sudo apt-get update
      sudo apt-get install -y "$package"
    fi
  elif is_arch; then
    if ! pacman -Qs "^$package$" &> /dev/null; then
      log_info "Installing $package via pacman..."
      sudo pacman -S --noconfirm "$package"
    fi
  elif is_fedora; then
    if ! rpm -q "$package" &> /dev/null; then
      log_info "Installing $package via dnf..."
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
    # For everything else (docker, languages, op_cli, 1password_ssh, etc.)
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
  [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" ]]
}

check_app() {
  local app_name=$1
  [ -d "/Applications/${app_name}.app" ]
}

# Logging Utilities
log_note() { echo -e "${GRAY}$1${NC}" >&2; }
log_info() { echo -e "${WHITE}$1${NC}" >&2; }
log_status() { echo -e "${BLUE}$1${NC}" >&2; }
log_success() { echo -e "${GREEN}$1${NC}" >&2; }
log_warn() { echo -e "${YELLOW}$1${NC}" >&2; }
log_error() { echo -e "${RED}$1${NC}" >&2; }

# User Interaction
confirm_action() {
  local prompt="$1"
  local default="${2:-n}"
  local prompt_suffix

  if [[ "$default" == "y" ]]; then
    prompt_suffix="[Y/n]"
  else
    prompt_suffix="[y/N]"
  fi

  # Print prompt to stderr to handle capture cases (e.g. $(prompt_input ...))
  echo -n -e "${prompt} ${prompt_suffix} " >&2

  local reply
  if [[ -n "$ZSH_VERSION" ]]; then
    read -k 1 -r reply
  else
    read -n 1 -r reply
  fi
  echo >&2

  if [[ "$default" == "y" ]]; then
     [[ "$reply" =~ ^[Yy]$ || -z "$reply" || "$reply" == $'\n' || "$reply" == $'\r' ]]
  else
     [[ "$reply" =~ ^[Yy]$ ]]
  fi
}

prompt_input() {
  local prompt="$1"
  local default="$2"
  local reply

  # Print prompt to stderr
  if [[ -n "$default" ]]; then
    echo -n -e "${prompt} (default: $default): " >&2
  else
    echo -n -e "${prompt}: " >&2
  fi

  if [[ -n "$ZSH_VERSION" ]]; then
    read -r reply
  else
    read -r reply
  fi

  echo "${reply:-$default}"
}

wait_for_enter() {
  local prompt="$1"
  echo -n -e "${prompt}" >&2
  if [[ -n "$ZSH_VERSION" ]]; then
    read -r
  else
    read -r
  fi
}
