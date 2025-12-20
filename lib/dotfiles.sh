#!/usr/bin/env zsh

symlink_google_drive_dotfiles() {
    # for each of the following files, create a symlink to the Google Drive version
    # if the file already exists, prompt the user to replace it
    # google drive files are in ~/Google Drive/My Drive/dotfiles
    # google drive files start with _ and local files start with .

    local files=(
        "_zshrc"
        "_aliases"
        "_gitconfig"
        "_tmux.conf.local"
        "_vimrc.local"
        "_vimrc.bundles.local"
    )

    for file in "${files[@]}"; do
        dotfile="${file/_/.}"

        # check if file is already symlinked to Google Drive dotfile, otherwise prompt to replace
        if [ -L "$HOME/${dotfile}" ]; then
            if [[ "$(readlink "$HOME/${dotfile}")" == "$HOME/Google Drive/My Drive/dotfiles/${file}" ]]; then
                echo -e "${BLUE}Using Google Drive dotfile $HOME/Google Drive/My Drive/dotfiles/${file}${NC}"
                continue
            fi
        fi

        if [ -f "$HOME/${dotfile}" ]; then
            echo -n "File ${HOME}/${dotfile} already exists. Replace it? (y/n) "
            read -k 1 REPLY
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${GRAY}Skipping ${HOME}/${dotfile}${NC}"
                continue
            fi
        fi

        ln -sf "$HOME/Google Drive/My Drive/dotfiles/${file}" "$HOME/${dotfile}"
        echo -e "${GREEN}${HOME}/${dotfile} symlinked to Google Drive file ${file}${NC}"
    done
}

symlink_antigravity_config() {
  local files=(
    "settings.json"
    "mcp.json"
  )

  for file in "${files[@]}"; do
    local config_source="$HOME/Google Drive/My Drive/dotfiles/antigravity/${file}"
    local config_dest="$HOME/Library/Application Support/Antigravity/User/${file}"

    if [ ! -f "$config_source" ]; then
      echo -e "${GRAY}Antigravity ${file} not found in Google Drive, skipping symlink.${NC}"
      continue
    fi

    # ensure the destination directory exists
    mkdir -p "$(dirname "$config_dest")"

    if [ -L "$config_dest" ]; then
      if [[ "$(readlink "$config_dest")" == "$config_source" ]]; then
        echo -e "${BLUE}Using Google Drive dotfile $config_source${NC}"
        continue
      fi
    fi

    if [ -e "$config_dest" ]; then
      echo -n "Antigravity ${file} already exists at $config_dest. Replace with Google Drive version? (y/n) "
      read -k 1 REPLY
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GRAY}Skipping Antigravity ${file} symlink${NC}"
        continue
      fi

      local backup="$config_dest.backup.$(date +%Y%m%d_%H%M%S)"
      mv "$config_dest" "$backup"
      echo -e "${GRAY}Backed up existing ${file} to $(basename "$backup")${NC}"
    fi

    ln -sf "$config_source" "$config_dest"
    echo -e "${GREEN}Antigravity ${file} symlinked to Google Drive${NC}"
  done
}
