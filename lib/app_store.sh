#!/usr/bin/env zsh

install_mas_apps() {
  local -A apps
  apps=(
    413857545 "Divvy"
    937984704 "Amphetamine"
    603637384 "Name Mangler 3"
    1295203466 "Windows App"
  )

  # ensure mas is installed
  if [[ ! $(command -v mas) ]]
  then
    echo -e "${WHITE}Installing mas (Mac App Store CLI)...${NC}"
    brew install mas
  fi

  # get installed apps
  local -A installed_apps
  local -a installed_ids
  installed_ids=( $(mas list | awk '{print $1}') )
  for id in "${installed_ids[@]}"
  do
    installed_apps[$id]=1
  done

  # identify missing apps using zsh-native expansion
  local -a missing_apps
  missing_apps=()
  for app_id in "${(@k)apps}"
  do
    if [[ -z "${installed_apps[$app_id]}" ]]
    then
      missing_apps+=("$app_id")
    fi
  done

  # show header if something needs to be installed
  if (( ${#missing_apps} > 0 ))
  then
    echo -e "${WHITE}Installing apps from App Store...${NC}"
  fi

  # report status and install if missing
  for app_id in "${(@k)apps}"
  do
    local app_name="${apps[$app_id]}"
    if [[ -n "${installed_apps[$app_id]}" ]]
    then
      local version=$(defaults read "/Applications/${app_name}.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "unknown")
      echo -e "${BLUE}Using ${app_name} ${version}${NC}"
    else
      mas install "$app_id"
      local version=$(defaults read "/Applications/${app_name}.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "unknown")
      echo -e "${GREEN}Installed ${app_name} ${version}${NC}"
    fi
  done

  # show footer if something was installed
  if (( ${#missing_apps} > 0 ))
  then
    echo -e "${GREEN}Installed apps from App Store${NC}"
  fi
}