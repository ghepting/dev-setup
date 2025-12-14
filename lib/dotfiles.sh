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
            echo -e "${BLUE}Using Google Drive dotfile ~/${dotfile}${NC}"
            continue
        fi

        if [ -f "$HOME/${dotfile}" ]; then
            echo -n "File ~/${dotfile} already exists. Replace it? (y/n) "
            read -k 1 REPLY
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${GRAY}Skipping ~/${dotfile}${NC}"
                continue
            fi
        fi

        ln -sf "$HOME/Google Drive/My Drive/dotfiles/${file}" "$HOME/${dotfile}"
        echo -e "${GREEN}~/${dotfile} symlinked to Google Drive file ${file}${NC}"
    done
}
