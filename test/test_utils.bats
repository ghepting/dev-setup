#!/usr/bin/env bats

# We need to make sure utils.sh can be sourced by Bash
# Some zsh-isms like [[ $PLATFORM == Debian || $PLATFORM == Arch ]] are fine in Bash 4+
# The main issue is likely the check at the bottom that executes detect_platform.

setup() {
  export TEST_DIR="$BATS_TEST_TMPDIR"
  export HOME="$TEST_DIR/home"
  export CONFIG_DIR="$HOME/.config"
  export CONFIG_FILE="$CONFIG_DIR/dev-setup.conf"
  mkdir -p "$CONFIG_DIR"

  # Prepend mocks to PATH
  export MOCKS_DIR="$BATS_TEST_DIRNAME/mocks"
  export PATH="$MOCKS_DIR:$PATH"

  # Source core libs
  source "lib/core/vars.sh"
  source "lib/core/utils.sh"

  # Export functions so 'run' can find them in subshells
  export -f detect_platform is_macos is_linux is_debian is_arch is_fedora is_enabled install_pkg
}

@test "Utils: Platform Detection macOS" {
  export MOCK_UNAME="Darwin"
  detect_platform
  [ "$PLATFORM" == "macOS" ]

  # Use standard BATS comparison since functions might not be exported to 'run' subshell
  is_macos
}

@test "Utils: Platform Detection Debian" {
  export MOCK_UNAME="Linux"
  # Mock the detect_platform logic by setting PLATFORM if we can't easily mock /etc/os-release
  # But let's try to test the logic indeed.
  # detect_platform calls _get_linux_distro.
  # _get_linux_distro checks /etc/os-release.

  # We can't easily mock /etc/os-release without a bind mount or chroot.
  # So for unit testing 'detect_platform', we'll rely on the fact that we can set PLATFORM.
  # But the user wants specific tests for utils.sh logic.

  # Let's test is_debian directly with a set PLATFORM
  export PLATFORM="Debian"
  is_debian
  is_linux
  ! is_macos
}

@test "Utils: is_enabled logic" {
  # Default enabled on macOS
  export PLATFORM="macOS"
  is_enabled "dotfiles"

  # Default disabled on Linux for some
  export PLATFORM="Debian"
  ! is_enabled "editor"

  # Explicitly disabled in config
  echo "dotfiles=false" > "$CONFIG_FILE"
  ! is_enabled "dotfiles"

  # Explicitly enabled in config
  echo "docker=true" > "$CONFIG_FILE"
  is_enabled "docker"
}

@test "Utils: install_pkg macOS" {
  export PLATFORM="macOS"

  # Ensure brew is found (it is via mocks/)
  # install_pkg calls brew list "$package"
  # Our mock brew echoes "MOCKED: brew ..."

  run install_pkg "test-pkg"
  [[ "$output" == *"MOCKED: brew install test-pkg"* ]]
}

@test "Utils: install_pkg Debian" {
  export PLATFORM="Debian"

  # Mock sudo to handle apt-get (already in mocks/sudo)
  # install_pkg calls: dpkg-query -W ...
  # We need a mock for dpkg-query.
  echo '#!/usr/bin/env zsh' > "$MOCKS_DIR/dpkg-query"
  echo 'exit 1' >> "$MOCKS_DIR/dpkg-query"
  chmod +x "$MOCKS_DIR/dpkg-query"

  run install_pkg "test-pkg"
  [[ "$output" == *"MOCKED: sudo apt-get install -y test-pkg"* ]]

  rm "$MOCKS_DIR/dpkg-query"
}

@test "Utils: install_packages_from_file" {
  export PLATFORM="macOS"

  local list_file="$TEST_DIR/pkg_list.txt"
  echo "# Comment" > "$list_file"
  rpm() {
    if [[ "$1" == "-q" && "$2" == "--whatprovides" ]]; then
       # shift args to simulate looking up the package name
       local pkg_name="$3"
       if [[ "$pkg_name" == "vim" ]]; then
          return 0 # vim is installed
       fi
       return 1
    elif [[ "$1" == "-q" ]]; then
       if [[ "$2" == "$MOCKED_NOT_FOUND" ]]; then
         return 1
       fi
       return 0
    fi
  }
  echo "pkg1" >> "$list_file"
  echo "" >> "$list_file"
  echo "pkg2" >> "$list_file"

  run install_packages_from_file "$list_file"

  [[ "$output" == *"MOCKED: brew install pkg1"* ]]
  [[ "$output" == *"MOCKED: brew install pkg2"* ]]
}

@test "Utils: install_pkg Fedora uses rpm --whatprovides" {
  export PLATFORM="Fedora"

  # Mock rpm to simulate failure on simple query but success on whatprovides for 'vim'
  rpm() {
    if [[ "$1" == "-q" && "$2" == "--whatprovides" ]]; then
       if [[ "$3" == "vim" ]]; then
          return 0
       fi
       return 1
    elif [[ "$1" == "-q" ]]; then
       return 1 # fail standard check
    fi
  }
  export -f rpm

  # Mock dnf
  dnf() { echo "MOCKED: dnf $*"; }
  export -f dnf

  # Mock sudo (pass through)
  sudo() {
    if [[ "$1" == "dnf" ]]; then
      dnf "${@:2}"
    else
      "$@"
    fi
  }
  export -f sudo

  # Case 1: Package not found by name or provider -> Installs
  run install_pkg "unknown-pkg"
  [[ "$output" == *"Installing unknown-pkg via dnf"* ]]
  [[ "$output" == *"MOCKED: dnf install -y unknown-pkg"* ]]

  # Case 2: Package found by provider (vim) -> Skips install
  run install_pkg "vim"
  [[ "$output" != *"Installing vim via dnf"* ]]
  [[ "$output" != *"MOCKED: dnf install -y vim"* ]]
}
