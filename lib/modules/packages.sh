#!/usr/bin/env zsh

install_common_packages() {
  echo -e "${WHITE}Installing common packages...${NC}"

  # Install common packages (skip on macOS as Brewfile handles them)
  if ! is_macos; then
    install_packages_from_file "./lib/packages/common.list"
  fi

  # Install platform specific packages
  if is_fedora; then
    install_packages_from_file "./lib/packages/fedora.list"
  elif is_debian; then
    install_packages_from_file "./lib/packages/debian.list"
  elif is_arch; then
    install_packages_from_file "./lib/packages/arch.list"
  elif is_macos; then
    # On macOS, we currently rely on Homebrew & Brewfile
    # But we could also have a macos.list if we wanted discrete control
    echo -e "${WHITE}Running Homebrew bundle...${NC}"
    brew bundle --no-lock
  fi
}
