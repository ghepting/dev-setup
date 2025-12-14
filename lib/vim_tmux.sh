#!/usr/bin/env zsh

setup_vim_tmux_config() {
  # List of files to symlink
  # Source in repo -> Destination in home
  typeset -A FILES
  FILES=(
    ["tmux.conf"]="$HOME/.tmux.conf"
    ["tmux.conf.local"]="$HOME/.tmux.conf.local"
    ["vimrc"]="$HOME/.vimrc"
    ["vimrc.bundles"]="$HOME/.vimrc.bundles"
    ["vimrc.local"]="$HOME/.vimrc.local"
    ["vimrc.bundles.local"]="$HOME/.vimrc.bundles.local"
  )

  # Get the absolute path of the repo root (assuming this script is in lib/)
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")/.." && pwd)"

  HEADER_PRINTED=false
  print_header() {
    if [ "$HEADER_PRINTED" = false ]; then
      echo -e "${WHITE}Configuring Vim and Tmux...${NC}"
      HEADER_PRINTED=true
    fi
  }

  for file in "${(@k)FILES}"; do
    SOURCE_FILE="$REPO_ROOT/$file"
    DEST_FILE="${FILES[$file]}"

    # Skip if source doesn't exist (e.g. optional .local files)
    if [[ ! -f "$SOURCE_FILE" ]]
    then
      continue
    fi

    # For .local files, do not overwrite if they already exist
    if [[ "$file" == *.local && -f "$DEST_FILE" ]]
    then
      continue
    fi

    # Check if we need to do anything (backup or link)
    NEEDS_LINK=false
    if [[ ! -L "$DEST_FILE" ]]; then
       NEEDS_LINK=true
    else
       # It is a link, but is it pointing to the right place?
       CURRENT_TARGET=$(readlink "$DEST_FILE")
       if [[ "$CURRENT_TARGET" != "$SOURCE_FILE" ]]; then
          NEEDS_LINK=true
       fi
    fi

    if [ "$NEEDS_LINK" = true ]; then
      print_header

      # Backup existing file if it's a real file (not a symlink to our source)
      if [[ -f "$DEST_FILE" && ! -L "$DEST_FILE" ]]
      then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mv "$DEST_FILE" "$DEST_FILE.backup.$TIMESTAMP"
        echo -e "${GRAY}Backed up existing $DEST_FILE to $DEST_FILE.backup.$TIMESTAMP${NC}"
      fi

      # Create/Update symlink
      ln -sf "$SOURCE_FILE" "$DEST_FILE"
      RESTART_REQUIRED=true
      echo -e "${GREEN}Linked $file${NC}"
    fi
  done

  # Setup Vundle
  VUNDLE_DIR="$HOME/.vim/bundle/Vundle.vim"
  if [[ ! -d "$VUNDLE_DIR" ]]
  then
    print_header
    echo -e "${WHITE}Installing Vundle...${NC}"
    git clone https://github.com/VundleVim/Vundle.vim.git "$VUNDLE_DIR"
    RESTART_REQUIRED=true
  fi

  # Install/Update Vim Plugins if Vundle is present
  if [[ -d "$VUNDLE_DIR" ]]
  then
    vim +PluginInstall +qall > /dev/null 2>&1 &
  fi
}
