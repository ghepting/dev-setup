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
    # For everything else (docker, languages, 1password_cli, 1password_ssh, etc.)
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
    # Resolve symlink to edit the actual file if necessary
    local target_file="$CONFIG_FILE"
    if [[ -L "$CONFIG_FILE" ]]; then
      target_file=$(readlink "$CONFIG_FILE")
      [[ "$target_file" != /* ]] && target_file="$(dirname "$CONFIG_FILE")/$target_file"
    fi

    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$target_file"
    rm -f "${target_file}.bak"
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
    if [[ -t 0 ]]; then
      # Interactive: read single key
      read -k 1 -r reply
      # Only print newline if the reply wasn't already a newline
      if [[ "$reply" != $'\n' && "$reply" != $'\r' ]]; then
        echo >&2
      fi
    else
      # Non-interactive (pipe): read line
      read -r reply
    fi
  else
    read -n 1 -r reply
    if [[ "$reply" != $'\n' && "$reply" != $'\r' ]]; then
      echo >&2
    fi
  fi

  if [[ "$default" == "y" ]]; then
     [[ "$reply" =~ ^[Yy]$ || -z "$reply" || "$reply" == $'\n' || "$reply" == $'\r' ]]
  else
     [[ "$reply" =~ ^[Yy]$ ]]
  fi
}

prompt_input() {
  local prompt="$1"
  local default="$2"
  local reply=""

  # Use vared for tab completion in zsh
  if [[ -n "$ZSH_VERSION" ]]; then
    # Build the prompt string with default shown
    local prompt_str
    if [[ -n "$default" ]]; then
      prompt_str="${prompt} (default: ${default}): "
    else
      prompt_str="${prompt}: "
    fi
    # vared provides tab completion and line editing
    # Don't pre-fill reply - let user type or press Enter for default
    vared -p "$prompt_str" reply
  else
    # Fallback for non-zsh shells
    if [[ -n "$default" ]]; then
      echo -n -e "${prompt} (default: $default): " >&2
    else
      echo -n -e "${prompt}: " >&2
    fi
    read -e -r reply </dev/tty
  fi

  # Return the value to stdout (for capture)
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

# ZSH Configuration Management

ensure_zshrc_dev_sourced() {
  # Ensure .zshrc sources .zshrc.dev
  # Check for common variations:
  # source "$HOME/.zshrc.dev"
  # source ~/.zshrc.dev
  # source /full/path/.zshrc.dev

  if ! grep -q -E "source .*\.zshrc\.dev" "$ZSHRC_FILE"; then
    echo '' >>"$ZSHRC_FILE"
    echo "source \"\$HOME/.zshrc.dev\"" >>"$ZSHRC_FILE"
    log_success "Added source of .zshrc.dev to .zshrc"
    RESTART_REQUIRED=true
  fi
}

ensure_zshrc_header() {
  local header_line="# This file is managed by dev-setup. Do not edit manually."

  if [ ! -f "$ZSHRC_DEV_FILE" ]; then
    touch "$ZSHRC_DEV_FILE"
  fi

  # Read first line
  local first_line
  first_line=$(head -n 1 "$ZSHRC_DEV_FILE")

  if [[ "$first_line" != "$header_line" ]]; then
    # Prepend header
    local temp_file="${ZSHRC_DEV_FILE}.tmp"
    echo "$header_line" > "$temp_file"
    echo "# Any changes made here may be overwritten." >> "$temp_file"
    echo "" >> "$temp_file"
    cat "$ZSHRC_DEV_FILE" >> "$temp_file"
    mv "$temp_file" "$ZSHRC_DEV_FILE"
  fi
}

install_zsh_config() {
  local config_name="$1"
  local template_file="$ZSHRC_TEMPLATES_DIR/$config_name"

  if [ ! -f "$template_file" ]; then
    log_error "Template $template_file not found."
    return 1
  fi

  # Ensure .zshrc.dev exists and has header
  ensure_zshrc_header

  # Read template content
  local content
  content=$(<"$template_file")

  # Extract markers
  local start_marker
  start_marker=$(head -n 1 "$template_file")
  local end_marker
  end_marker=$(tail -n 1 "$template_file")

  # Validate markers
  if [[ "$start_marker" != \#* || "$end_marker" != \#* ]]; then
    log_warn "Template $config_name does not have valid start/end markers. Appending without replacement logic."
    if [ -s "$ZSHRC_DEV_FILE" ]; then echo "" >> "$ZSHRC_DEV_FILE"; fi
    cat "$template_file" >> "$ZSHRC_DEV_FILE"
    return 0
  fi

  # Check if block exists
  if grep -qF "$start_marker" "$ZSHRC_DEV_FILE"; then
    # Block exists, replace it
    local temp_file="${ZSHRC_DEV_FILE}.tmp"

    # Identify positions
    local start_line
    start_line=$(grep -nF "$start_marker" "$ZSHRC_DEV_FILE" | head -n 1 | cut -d: -f1)

    # We construct the new file
    # 1. Content before the block
    if [[ "$start_line" -gt 1 ]]; then
      sed -n "1,$((start_line - 1))p" "$ZSHRC_DEV_FILE" > "$temp_file"
      # FORCE BLANK LINE SEPARATION
      if [ -s "$temp_file" ] && [ "$(tail -n 1 "$temp_file" | wc -l)" -gt 0 ]; then
          # Check if lines are not blank? Or just ensure blank.
          # Easier: if the last line isn't blank, append newline.
          # tail -n 1 returns the last line.
          # [[ -n "$(tail -n 1 file)" ]] checks if not empty string.
          if [[ -n "$(tail -n 1 "$temp_file")" ]]; then
              echo "" >> "$temp_file"
          fi
      fi
    else
      : > "$temp_file"
    fi

    # 2. The new content
    cat "$template_file" >> "$temp_file"

    # 3. Content after the block
    # Find end marker that appears after start_line
    local end_line
    end_line=$(awk -v start="$start_line" -v marker="$end_marker" 'NR > start && $0 == marker {print NR; exit}' "$ZSHRC_DEV_FILE")

    if [[ -n "$end_line" ]]; then
       # Append everything after end_line
       # Check if there are lines after
       local total_lines
       total_lines=$(wc -l < "$ZSHRC_DEV_FILE")
       if [[ "$total_lines" -gt "$end_line" ]]; then
         sed -n "$((end_line + 1)),\$p" "$ZSHRC_DEV_FILE" >> "$temp_file"
       fi
    else
       # If no end marker found, we can't safely preserve what follows (or maybe it was truncated).
       # For safety, let's just warn and append rest? Or assume previous block went to end.
       log_warn "Could not find closing marker for $config_name. Replacing up to end of file."
    fi

    mv "$temp_file" "$ZSHRC_DEV_FILE"
    log_status "Updated $config_name config in .zshrc.dev"
    RESTART_REQUIRED=true

  else
    # Block does not exist, append it
    # Avoid adding leading newline if file is empty
    if [ -s "$ZSHRC_DEV_FILE" ]; then
       # Check if the last character is a newline.
       # And ensure we have a blank line separator.

       # If last line is empty, we already have separation?
       # Let's ensure we add a newline if the file doesn't end with TWO newlines?
       # Simplest: Just append a newline, then content.
       # If the user wants a visible gap (empty line), we need \n\n if the file currently ends in text.

       # Check current tail
       if [ "$(tail -c 1 "$ZSHRC_DEV_FILE" | wc -l)" -eq 0 ]; then
          echo "" >> "$ZSHRC_DEV_FILE"
       fi
       echo "" >> "$ZSHRC_DEV_FILE"
    fi

    cat "$template_file" >> "$ZSHRC_DEV_FILE"
    log_success "Added $config_name config to .zshrc.dev"
    RESTART_REQUIRED=true
  fi
}
