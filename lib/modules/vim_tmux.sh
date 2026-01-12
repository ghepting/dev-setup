#!/usr/bin/env zsh

setup_vim_tmux_config() {
  # List of files to symlink
  # Format: "Source in repo:Destination in home"
  local files=(
    "tmux.conf:$HOME/.tmux.conf"
    "tmux.conf.local:$HOME/.tmux.conf.local"
    "vimrc:$HOME/.vimrc"
    "vimrc.bundles:$HOME/.vimrc.bundles"
    "vimrc.local:$HOME/.vimrc.local"
    "vimrc.bundles.local:$HOME/.vimrc.bundles.local"
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

  # Install dependencies
  if is_linux; then
    # Default to debian/ubuntu package names
    local vim_pkg="vim-nox"
    local ctags_pkg="universal-ctags"
    local ag_pkg="silversearcher-ag"

    if is_arch; then
      vim_pkg="vim"
      ctags_pkg="ctags"
      ag_pkg="the_silver_searcher"
    elif is_fedora; then
      vim_pkg="vim-enhanced"
      ctags_pkg="ctags"
      ag_pkg="the_silver_searcher"
    fi

    DEPS=("$vim_pkg" "tmux" "git" "curl" "direnv" "$ag_pkg" "$ctags_pkg")
    for pkg in "${DEPS[@]}"; do
      install_pkg "$pkg"
    done

    # Ensure vi and vim point to a full vim on Debian/Fedora
    if is_debian || is_fedora; then
      if ! vim --version | grep -q "+syntax"; then
        local vim_target="/usr/bin/vim.nox"
        is_fedora && vim_target="/usr/bin/vim"

        echo -e "${WHITE}Configuring vim as default editor...${NC}"
        if command -v update-alternatives &>/dev/null; then
          sudo update-alternatives --set vi "$vim_target"
          sudo update-alternatives --set vim "$vim_target"
        fi
      fi
    fi
  fi

  for entry in "${files[@]}"; do
    local SOURCE_FILE_BASE="${entry%%:*}"
    local DEST_FILE="${entry#*:}"
    local SOURCE_FILE="$REPO_ROOT/$SOURCE_FILE_BASE"

    # Skip if source doesn't exist (e.g. optional .local files)
    if [[ ! -f "$SOURCE_FILE" ]]
    then
      continue
    fi

    # For .local files, do not overwrite if they already exist as real files
    if [[ "$SOURCE_FILE_BASE" == *.local && -f "$DEST_FILE" && ! -L "$DEST_FILE" ]]
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
          # Check if it's pointing to our dotfiles repository
          if [[ -n "$DOTFILES_DIR" && "$CURRENT_TARGET" == "$DOTFILES_DIR"* ]]; then
            echo -e "${BLUE}Skipping $SOURCE_FILE_BASE as it is already symlinked to dotfiles repo${NC}"
            NEEDS_LINK=false
          else
            NEEDS_LINK=true
          fi
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
      echo -e "${GREEN}Linked $SOURCE_FILE_BASE${NC}"
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
