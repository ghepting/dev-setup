#!/usr/bin/env zsh

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"
NC="\e[0m" # No Color (Reset)

# Global Variables
ZSHRC_FILE="$HOME/.zshrc"
RESTART_REQUIRED=false
CONFIG_DIR="${HOME}/.config"
CONFIG_FILE="${CONFIG_DIR}/dev-setup.conf"

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
      debian|ubuntu|pop|kali)
        export PLATFORM="Debian"
        ;;
      arch|manjaro)
        export PLATFORM="Arch"
        ;;
      fedora|centos|rhel)
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
