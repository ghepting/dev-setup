#!/usr/bin/env zsh

setup_iterm_colors() {
  local presets_dir="iterm2-colors-solarized"
  local dark_preset="Solarized Dark"
  local light_preset="Solarized Light"

  if [ ! -d "$presets_dir" ]; then
    log_error "$presets_dir directory not found."
    return 1
  fi

  # Check if Solarized presets are already installed in iTerm2
  # We use plurals to get the list of names
  local installed_presets
  installed_presets=$(defaults read com.googlecode.iterm2 'Custom Color Presets' 2> /dev/null)

  local need_dark=true
  local need_light=true

  if [[ $installed_presets == *"$dark_preset"* ]]; then
    need_dark=false
  fi

  if [[ $installed_presets == *"$light_preset"* ]]; then
    need_light=false
  fi

  if [ "$need_dark" = true ] || [ "$need_light" = true ]; then
    log_info "Configuring iTerm2 solorized themes..."

    if [ "$need_dark" = true ]; then
      log_status "Importing $dark_preset..."
      open -a "/Applications/iTerm.app" "$presets_dir/$dark_preset.itermcolors"
    else
      log_info "$dark_preset already installed."
    fi

    if [ "$need_light" = true ]; then
      log_status "Importing $light_preset..."
      open -a "/Applications/iTerm.app" "$presets_dir/$light_preset.itermcolors"
    else
      log_info "$light_preset already installed."
    fi

    log_success "Iterm themes configured."
    log_info "Please confirm the import in iTerm2 if prompted."
    log_info "You can then set these in iTerm2 Preferences -> Profiles -> Colors -> Color Presets."
  else
    log_status "Using iTerm2 solorized themes."
  fi
}
