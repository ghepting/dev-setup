#!/usr/bin/env zsh

app_store_ids=(
  "413857545" # Divvy
  "937984704" # Amphetamine
  "603637384" # Name Mangler 3
  "1295203466" # Windows App (remote desktop)
)

install_mas_apps() {
    # check if mas is installed
    if ! command -v mas &> /dev/null
    then
        echo -e "${YELLOW}Installing mas...${NC}"
        brew install mas
    fi

    # install apps
    for app_store_id in "${app_store_ids[@]}"
    do
        mas install "$app_store_id"
    done

    echo -e "${GREEN}Installed apps from App Store${NC}"
}