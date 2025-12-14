#!/usr/bin/env zsh

install_mas_apps() {
  typeset -A apps
  apps=(
    [413857545]="Divvy"
    [937984704]="Amphetamine"
    [603637384]="Name Mangler 3"
    [1295203466]="Windows App"
  )

  # check if mas is installed
  if [[ ! $(command -v mas) ]]; then
    echo -e "${WHITE}Installing mas (Mac App Store CLI)...${NC}"
    brew install mas
  fi

  echo -e "${WHITE}Installing apps from App Store...${NC}"
  # install apps
  for app_id in "${(@k)apps}"
  do
    if mas list | grep -q "${apps[$app_id]}"
    then
      echo -e "${BLUE}Using ${apps[$app_id]} $(defaults read /Applications/${apps[$app_id]}.app/Contents/Info CFBundleShortVersionString)${NC}"
    else
      mas install "$app_id"
    fi
  done

  echo -e "${GREEN}Installed apps from App Store${NC}"
}