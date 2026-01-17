#!/usr/bin/env zsh

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"
GRAY="\e[90m"
NC="\e[0m" # No Color (Reset)

# Global Variables
ZSHRC_FILE="$HOME/.zshrc"
RESTART_REQUIRED=false
CONFIG_DIR="${HOME}/.config"
CONFIG_FILE="${CONFIG_DIR}/dev-setup.conf"

# Load dotfiles config from file if it exists
if [ -f "$CONFIG_FILE" ]; then
  # We grep instead of sourcing to avoid executing arbitrary code
  # but this means we must manually expand variables like $HOME
  cfg_dir=$(grep "^dotfiles_dir=" "$CONFIG_FILE" | cut -d= -f2 | tr -d '"')
  cfg_repo=$(grep "^dotfiles_repo=" "$CONFIG_FILE" | cut -d= -f2 | tr -d '"')

  # Sanitize: if the value contains prompt text, it's corrupted from a previous buggy run
  [[ "$cfg_dir" == *"Directory path"* ]] && cfg_dir=""
  [[ "$cfg_repo" == *"Repository URL"* ]] && cfg_repo=""

  if [ -n "$cfg_dir" ]; then
    DOTFILES_DIR="${cfg_dir//\$\{HOME\}/$HOME}"
    DOTFILES_DIR="${DOTFILES_DIR//\$HOME/$HOME}"
    DOTFILES_DIR="${DOTFILES_DIR/#\~/$HOME}"
  fi

  if [ -n "$cfg_repo" ]; then
    DOTFILES_REPO="${cfg_repo//\$\{HOME\}/$HOME}"
    DOTFILES_REPO="${DOTFILES_REPO//\$HOME/$HOME}"
    DOTFILES_REPO="${DOTFILES_REPO/#\~/$HOME}"
  fi
fi

# Fallback to defaults and export
export DOTFILES_DIR=${DOTFILES_DIR:-"${HOME}/dotfiles"}
export DOTFILES_REPO=${DOTFILES_REPO:-"git@github.com:ghepting/dotfiles.git"}

# Platform Detection
_get_linux_distro() {
  if [[ -f /etc/os-release ]]; then
    grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"'
  elif [[ -f /etc/debian_version ]]; then
    echo "debian"
  fi
}

detect_platform() {
  if [[ "$(uname)" == "Darwin" ]]; then
    export PLATFORM="macOS"
  elif [[ "$(uname)" == "Linux" ]]; then
    local distro
    distro=$(_get_linux_distro)
    case "$distro" in
    debian | ubuntu | pop | kali)
      export PLATFORM="Debian"
      ;;
    arch | manjaro)
      export PLATFORM="Arch"
      ;;
    fedora | centos | rhel)
      export PLATFORM="Fedora"
      ;;
    *)
      export PLATFORM="Linux"
      ;;
    esac
  else
    export PLATFORM="Unknown"
  fi
}

# Detect platform if not already set
if [[ -z "$PLATFORM" ]]; then
  detect_platform
fi
