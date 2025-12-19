#!/usr/bin/env zsh

setup_iterm_colors() {
  local presets_dir="iterm2-colors-solarized"
  local dark_preset="Solarized Dark"
  local light_preset="Solarized Light"
  
  if [ ! -d "$presets_dir" ]
  then
    echo -e "${RED}Error: $presets_dir directory not found.${NC}"
    return 1
  fi

  # Check if Solarized presets are already installed in iTerm2
  # We use plurals to get the list of names
  local installed_presets
  installed_presets=$(defaults read com.googlecode.iterm2 'Custom Color Presets' 2>/dev/null)

  local need_dark=true
  local need_light=true

  if [[ $installed_presets == *"$dark_preset"* ]]
  then
    need_dark=false
  fi

  if [[ $installed_presets == *"$light_preset"* ]]
  then
    need_light=false
  fi

  if [ "$need_dark" = true ] || [ "$need_light" = true ]
  then
    echo -e "${WHITE}Configuring iTerm2 solorized themes...${NC}"

    if [ "$need_dark" = true ]
    then
      echo -e "${BLUE}Importing $dark_preset...${NC}"
      open -a "/Applications/iTerm.app" "$presets_dir/$dark_preset.itermcolors"
    else
      echo -e "${GRAY}$dark_preset already installed.${NC}"
    fi

    if [ "$need_light" = true ]
    then
      echo -e "${BLUE}Importing $light_preset...${NC}"
      open -a "/Applications/iTerm.app" "$presets_dir/$light_preset.itermcolors"
    else
      echo -e "${GRAY}$light_preset already installed.${NC}"
    fi

    echo -e "${GREEN}Iterm themes configured.${NC}"
    echo -e "${GRAY}Please confirm the import in iTerm2 if prompted.${NC}"
    echo -e "${GRAY}You can then set these in iTerm2 Preferences -> Profiles -> Colors -> Color Presets.${NC}"
  else
    echo -e "${BLUE}Using iTerm2 solorized themes.${NC}"
  fi
}
