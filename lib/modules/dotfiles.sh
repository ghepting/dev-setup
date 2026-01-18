#!/usr/bin/env zsh

setup_dotfiles() {
  log_note "Setting up dotfiles..."

  # Prompt for repository URL
  local repo_reply
  repo_reply=$(prompt_input "Dotfiles repository URL" "$DOTFILES_REPO")
  if [[ "$repo_reply" != "$DOTFILES_REPO" ]]; then
    DOTFILES_REPO="$repo_reply"
    set_config_value "dotfiles_repo" "$DOTFILES_REPO"
    log_success "Saved custom repository URL to config"
  fi

  # Prompt for directory path
  local dir_reply
  dir_reply=$(prompt_input "Dotfiles directory path" "$DOTFILES_DIR")
  # Expand ~ if present
  dir_reply="${dir_reply/#\~/$HOME}"
  if [[ "$dir_reply" != "$DOTFILES_DIR" ]]; then
    DOTFILES_DIR="$dir_reply"
    set_config_value "dotfiles_dir" "$DOTFILES_DIR"
    log_success "Saved custom directory path to config"
  fi

  if [ -d "$DOTFILES_DIR/.git" ]; then
    log_status "Updating dotfiles repository..."
    git -C "$DOTFILES_DIR" pull
  else
    if [ -d "$DOTFILES_DIR" ]; then
      log_warn "Directory $DOTFILES_DIR exists but is not a git repository"
      if confirm_action "Remove and re-clone?" "y"; then
        rm -rf "$DOTFILES_DIR"
        log_status "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
      else
        log_error "Cannot proceed without a valid dotfiles repository"
        return 1
      fi
    else
      log_status "Cloning dotfiles repository..."
      git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
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
  )

  log_info "Configuring symlinks for dotfiles..."

  for target in "${targets[@]}"; do
    local source_path="${DOTFILES_DIR}/${target}"
    local dest_path="$HOME/${target}"

    if [ ! -e "$source_path" ]; then
      log_note "Target ${target} not found in repository, skipping."
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
        log_note "Skipped ${dest_path}"
        continue
      fi

      if [ -d "$dest_path" ] && [ ! -L "$dest_path" ]; then
        local backup="$dest_path.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$dest_path" "$backup"
        log_note "Backed up existing directory to $(basename "$backup")"
      else
        rm -rf "$dest_path"
      fi
    fi

    ln -sf "$source_path" "$dest_path"
    log_success "${dest_path} symlinked to ${source_path}"
  done

  # Special handling for git signing wrapper
  local wrapper_source="${DOTFILES_DIR}/.git-ssh-sign-wrapper"
  local wrapper_dest="$HOME/.local/bin/git-ssh-sign-wrapper"

  if [ -f "$wrapper_source" ]; then
    mkdir -p "$HOME/.local/bin"
    if [ -L "$wrapper_dest" ] && [[ "$(readlink "$wrapper_dest")" == "$wrapper_source" ]]; then
      log_status "Using repository target .git-ssh-sign-wrapper"
    else
      ln -sf "$wrapper_source" "$wrapper_dest"
      log_success "${wrapper_dest} symlinked to ${wrapper_source}"
    fi
  fi
}
