#!/usr/bin/env zsh

setup_dotfiles() {
  echo -e "${WHITE}Setting up dotfiles from ${DOTFILES_REPO}...${NC}"

  if [ ! -d "$DOTFILES_DIR" ]; then
    echo -e "${CYAN}Cloning dotfiles repository...${NC}"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  else
    echo -e "${CYAN}Updating dotfiles repository...${NC}"
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
      echo -e "${GRAY}Target ${target} not found in repository, skipping.${NC}"
      continue
    fi

    # check if target is already symlinked correctly
    if [ -L "$dest_path" ]; then
      if [[ "$(readlink "$dest_path")" == "$source_path" ]]; then
        echo -e "${BLUE}Using repository target ${target}${NC}"
        continue
      fi
    fi

    if [ -e "$dest_path" ]; then
      echo -n "Target ${dest_path} already exists. Replace it? (y/n) "
      read -k 1 REPLY
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GRAY}Skipping ${dest_path}${NC}"
        continue
      fi

      if [ -d "$dest_path" ] && [ ! -L "$dest_path" ]; then
        local backup="$dest_path.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$dest_path" "$backup"
        echo -e "${GRAY}Backed up existing directory to $(basename "$backup")${NC}"
      else
        rm -rf "$dest_path"
      fi
    fi

    ln -sf "$source_path" "$dest_path"
    echo -e "${GREEN}${dest_path} symlinked to repository ${target}${NC}"
  done
}

symlink_antigravity_config() {
  local config_dest_base
  if is_macos; then
    config_dest_base="$HOME/Library/Application Support/Antigravity/User"
  elif is_debian; then
    config_dest_base="$HOME/.config/Antigravity/User"
  else
    echo -e "${RED}Unsupported OS for Antigravity config symlink.${NC}"
    return
  fi

  local config_source="${DOTFILES_DIR}/.antigravity"

  if [ ! -d "$config_source" ]; then
    echo -e "${GRAY}Antigravity directory not found in dotfiles repository, skipping symlink.${NC}"
    return
  fi

  # ensure the destination parent directory exists
  mkdir -p "$(dirname "$config_dest_base")"

  if [ -L "$config_dest_base" ]; then
    if [[ "$(readlink "$config_dest_base")" == "$config_source" ]]; then
      echo -e "${BLUE}Using repository for Antigravity config directory${NC}"
      return
    fi
  fi

  if [ -e "$config_dest_base" ]; then
    echo -n "Antigravity config directory already exists at $config_dest_base. Replace with repository version? (y/n) "
    read -k 1 REPLY
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${GRAY}Skipping Antigravity config directory symlink${NC}"
      return
    fi

    local backup="$config_dest_base.backup.$(date +%Y%m%d_%H%M%S)"
    mv "$config_dest_base" "$backup"
    echo -e "${GRAY}Backed up existing config directory to $(basename "$backup")${NC}"
  fi

  ln -sf "$config_source" "$config_dest_base"
  echo -e "${GREEN}Antigravity config directory symlinked to repository version${NC}"
}
