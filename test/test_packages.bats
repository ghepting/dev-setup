#!/usr/bin/env bats

load "test_helper.sh"

setup() {
  export TEST_DIR="$BATS_TEST_TMPDIR"
  # Source needed libraries
  source "lib/core/vars.sh"
  source "lib/core/utils.sh"
  source "lib/modules/packages.sh"

  # Setup system mocks
  setup_mocks
}

@test "Packages: list files exist and are not empty" {
  local package_dir="lib/packages"

  [ -f "$package_dir/common.list" ]
  [ -s "$package_dir/common.list" ]

  [ -f "$package_dir/fedora.list" ]
  [ -s "$package_dir/fedora.list" ]

  [ -f "$package_dir/debian.list" ]
  [ -s "$package_dir/debian.list" ]

  [ -f "$package_dir/arch.list" ]
  [ -s "$package_dir/arch.list" ]
}

@test "Packages: install_common_packages loads common list" {
  export PLATFORM="macOS" # Defaults to just common + brew bundle

  # Mock install_packages_from_file to verify it's called
  install_packages_from_file() {
    echo "CALLED: install_packages_from_file $*"
  }
  export -f install_packages_from_file

  run install_common_packages

  [[ "$output" != *"CALLED: install_packages_from_file ./lib/packages/common.list"* ]]
}

@test "Packages: install_common_packages loads fedora list on Fedora" {
  export PLATFORM="Fedora"

  install_packages_from_file() {
    echo "CALLED: install_packages_from_file $*"
  }
  export -f install_packages_from_file

  run install_common_packages

  [[ "$output" == *"CALLED: install_packages_from_file ./lib/packages/common.list"* ]]
  [[ "$output" == *"CALLED: install_packages_from_file ./lib/packages/fedora.list"* ]]
}

@test "Packages: install_common_packages loads debian list on Debian" {
  export PLATFORM="Debian"

  install_packages_from_file() {
    echo "CALLED: install_packages_from_file $*"
  }
  export -f install_packages_from_file

  run install_common_packages

  [[ "$output" == *"CALLED: install_packages_from_file ./lib/packages/common.list"* ]]
  [[ "$output" == *"CALLED: install_packages_from_file ./lib/packages/debian.list"* ]]
}

@test "Packages: ctags is split correctly" {
  # Fedora should have ctags, not universal-ctags
  run grep "ctags" lib/packages/fedora.list
  [ "$status" -eq 0 ]
  run grep "universal-ctags" lib/packages/fedora.list
  [ "$status" -eq 1 ]

  # Debian should have universal-ctags
  run grep "universal-ctags" lib/packages/debian.list
  [ "$status" -eq 0 ]

  # Arch should have universal-ctags
  run grep "universal-ctags" lib/packages/arch.list
  [ "$status" -eq 0 ]

  # Common should NOT have universal-ctags anymore
  run grep "universal-ctags" lib/packages/common.list
  [ "$status" -eq 1 ]
}
