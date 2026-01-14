#!/usr/bin/env zsh

install_rbenv_and_ruby() {
  # install rbenv
  # install rbenv
  if ! command -v rbenv &> /dev/null; then
    if is_macos; then
       brew bundle --file=lib/packages/ruby/Brewfile -q
    elif is_linux; then
      # Install platform-specific build dependencies
      if is_debian; then
        install_packages_from_file "lib/packages/ruby/debian.list"
      elif is_fedora; then
        install_packages_from_file "lib/packages/ruby/fedora.list"
      elif is_arch; then
        install_packages_from_file "lib/packages/ruby/arch.list"
      fi

      # Install rbenv
      install_pkg "rbenv"
      RESTART_REQUIRED=true
    else
       install_pkg "rbenv" # Fallback for other non-macOS/non-Linux systems
       RESTART_REQUIRED=true
    fi
  else
    echo -e "${BLUE}Using $(rbenv --version)${NC}"
  fi

  # add rbenv init to zsh config
  if add_to_zsh_config 'eval "$(rbenv init -)"' "rbenv"; then
    echo -e "${GREEN}Added rbenv init to config${NC}"
  fi

  # install ruby
  RUBY_VERSION=$(cat .ruby-version)
  if [[ "$(rbenv version-name)" == "$RUBY_VERSION" ]] &> /dev/null; then
    echo -e "${BLUE}Using ruby $(rbenv version-name)${NC}"

  else
    echo -e "${WHITE}Installing ruby $RUBY_VERSION...${NC}"
    if rbenv install $RUBY_VERSION -s && rbenv global $RUBY_VERSION &> /dev/null; then
      echo -e "${GREEN}Successfully installed ruby $RUBY_VERSION via rbenv${NC}"
      RESTART_REQUIRED=true
    else
      echo -e "${RED}Failed to install ruby $RUBY_VERSION via rbenv${NC}"
      exit 1
    fi
  fi
}
