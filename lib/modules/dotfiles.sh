#!/usr/bin/env zsh

setup_dotfiles() {
  log_info "Setting up dotfiles from ${DOTFILES_REPO}..."

  if [ ! -d "$DOTFILES_DIR" ]; then
    log_status "Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  else
    log_status "Updating dotfiles repository..."
    git -C "$DOTFILES_DIR" pull
  fi

  # targets to symlink to $HOME
  local targets=(
    ".zshrc"
    ".aliases"
    ".gitconfig"
    ".tmux.conf"
    ".tmux.conf.local"
    ".vimrc.local"
    ".vimrc.bundles.local"
    ".ssh"
    ".antigravity"
  )

  for target in "${targets[@]}"; do
    local source_path="${DOTFILES_DIR}/${target}"
    local dest_path="$HOME/${target}"

    if [ ! -e "$source_path" ]; then
      log_info "Target ${target} not found in repository, skipping."
      continue
    fi

    # check if target is already symlinked correctly
    if [ -L "$dest_path" ]; then
      if [[ "$(readlink "$dest_path")" == "$source_path" ]]; then
        log_status "Using repository target ${target}"
        continue
      fi
    fi

    if [ -e "$dest_path" ]; then
      if ! confirm_action "Target ${dest_path} already exists. Replace it?" "n"; then
        log_info "Skipping ${dest_path}"
        continue
      fi

      if [ -d "$dest_path" ] && [ ! -L "$dest_path" ]; then
        local backup="$dest_path.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$dest_path" "$backup"
        log_info "Backed up existing directory to $(basename "$backup")"
      else
        rm -rf "$dest_path"
      fi
    fi

    ln -sf "$source_path" "$dest_path"
    log_success "${dest_path} symlinked to repository ${target}"
  done

  # Special handling for git signing wrapper
  local wrapper_source="${DOTFILES_DIR}/.git-ssh-sign-wrapper"
  local wrapper_dest="$HOME/.local/bin/git-ssh-sign-wrapper"

  mkdir -p "$HOME/.local/bin"
  ln -sf "$wrapper_source" "$wrapper_dest"
  log_success "${wrapper_dest} symlinked to repository .git-ssh-sign-wrapper"
}

symlink_antigravity_config() {
  local config_dest_base
  if is_macos; then
    config_dest_base="$HOME/Library/Application Support/Antigravity/User"
  elif is_debian; then
    config_dest_base="$HOME/.config/Antigravity/User"
  else
    log_error "Unsupported OS for Antigravity config symlink."
    return
  fi

  local config_source="${DOTFILES_DIR}/.antigravity"

  if [ ! -d "$config_source" ]; then
    log_info "Antigravity directory not found in dotfiles repository, skipping symlink."
    return
  fi

  # ensure the destination parent directory exists
  mkdir -p "$(dirname "$config_dest_base")"

  if [ -L "$config_dest_base" ]; then
    if [[ "$(readlink "$config_dest_base")" == "$config_source" ]]; then
      log_status "Using repository for Antigravity config directory"
      return
    fi
  fi

  if [ -e "$config_dest_base" ]; then
    if ! confirm_action "Antigravity config directory already exists at $config_dest_base. Replace with repository version?" "n"; then
      log_info "Skipping Antigravity config directory symlink"
      return
    fi

    local backup="$config_dest_base.backup.$(date +%Y%m%d_%H%M%S)"
    mv "$config_dest_base" "$backup"
    log_info "Backed up existing config directory to $(basename "$backup")"
  fi

  ln -sf "$config_source" "$config_dest_base"
  log_success "Antigravity config directory symlinked to repository version"
}
