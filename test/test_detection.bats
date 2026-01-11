#!/usr/bin/env bats

load "test_helper.sh"

setup() {
  export TEST_HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$TEST_HOME"

  # Reset PLATFORM to ensure detection runs
  unset PLATFORM
}

@test "Helpers: is_macos, is_linux, is_debian, is_arch, is_fedora work" {
  load_lib "lib/utils.sh"

  export PLATFORM="macOS"
  is_macos
  is_linux && return 1 || true
  is_debian && return 1 || true

  export PLATFORM="Debian"
  is_macos && return 1 || true
  is_linux
  is_debian
  is_arch && return 1 || true

  export PLATFORM="Arch"
  is_linux
  is_arch
  is_debian && return 1 || true

  export PLATFORM="Fedora"
  is_linux
  is_fedora
  is_debian && return 1 || true

  export PLATFORM="Linux"
  is_linux
  is_debian && return 1 || true
  is_arch && return 1 || true
}

@test "Detection: identifies macOS via uname" {
  load_lib "lib/utils.sh"
  uname() { echo "Darwin"; }
  export -f uname
  detect_platform
  [ "$PLATFORM" = "macOS" ]
}

@test "Detection: identifies Debian via _get_linux_distro" {
  load_lib "lib/utils.sh"
  uname() { echo "Linux"; }
  export -f uname
  _get_linux_distro() { echo "debian"; }

  detect_platform
  [ "$PLATFORM" = "Debian" ]
}

@test "Detection: identifies Ubuntu as Debian via _get_linux_distro" {
  load_lib "lib/utils.sh"
  uname() { echo "Linux"; }
  export -f uname
  _get_linux_distro() { echo "ubuntu"; }

  detect_platform
  [ "$PLATFORM" = "Debian" ]
}

@test "Detection: identifies Arch via _get_linux_distro" {
  load_lib "lib/utils.sh"
  uname() { echo "Linux"; }
  export -f uname
  _get_linux_distro() { echo "arch"; }

  detect_platform
  [ "$PLATFORM" = "Arch" ]
}

@test "Detection: identifies Fedora via _get_linux_distro" {
  load_lib "lib/utils.sh"
  uname() { echo "Linux"; }
  export -f uname
  _get_linux_distro() { echo "fedora"; }

  detect_platform
  [ "$PLATFORM" = "Fedora" ]
}

@test "Detection: identifies generic Linux when _get_linux_distro returns unknown" {
  load_lib "lib/utils.sh"
  uname() { echo "Linux"; }
  export -f uname
  _get_linux_distro() { echo "unknown_distro"; }

  detect_platform
  [ "$PLATFORM" = "Linux" ]
}

@test "Detection: identifies generic Linux via uname if _get_linux_distro returns empty" {
  load_lib "lib/utils.sh"
  uname() { echo "Linux"; }
  export -f uname
  _get_linux_distro() { echo ""; }

  detect_platform
  [ "$PLATFORM" = "Linux" ]
}

@test "Detection: returns Unknown for other systems" {
  load_lib "lib/utils.sh"
  uname() { echo "FreeBSD"; }
  export -f uname

  detect_platform
  [ "$PLATFORM" = "Unknown" ]
}

@test "install_pkg: uses brew on macOS" {
  load_lib "lib/utils.sh"
  setup_mocks
  export PLATFORM="macOS"
  export MOCK_PKG_INSTALLED=""

  run install_pkg "test-pkg"
  echo "$output" | grep -q "Installing test-pkg via Homebrew"
}

@test "install_pkg: uses apt on Debian" {
  load_lib "lib/utils.sh"
  setup_mocks
  export PLATFORM="Debian"
  export MOCK_PKG_INSTALLED=""

  run install_pkg "test-pkg"
  echo "$output" | grep -q "Installing test-pkg via apt"
}

@test "install_pkg: uses pacman on Arch" {
  load_lib "lib/utils.sh"
  setup_mocks
  export PLATFORM="Arch"
  export MOCK_PKG_INSTALLED=""

  run install_pkg "test-pkg"
  echo "$output" | grep -q "Installing test-pkg via pacman"
}

@test "install_pkg: uses dnf on Fedora" {
  load_lib "lib/utils.sh"
  setup_mocks
  export PLATFORM="Fedora"
  export MOCK_PKG_INSTALLED=""

  run install_pkg "test-pkg"
  echo "$output" | grep -q "Installing test-pkg via dnf"
}

@test "install_pkg: skips if already installed (apt)" {
  load_lib "lib/utils.sh"
  setup_mocks
  export PLATFORM="Debian"
  export MOCK_PKG_INSTALLED="test-pkg"

  run install_pkg "test-pkg"
  [ -z "$output" ]
}

@test "install_pkg: skips if already installed (pacman)" {
  load_lib "lib/utils.sh"
  setup_mocks
  export PLATFORM="Arch"
  export MOCK_PKG_INSTALLED="test-pkg"

  run install_pkg "test-pkg"
  [ -z "$output" ]
}

@test "install_pkg: skips if already installed (dnf/rpm)" {
  load_lib "lib/utils.sh"
  setup_mocks
  export PLATFORM="Fedora"
  export MOCK_PKG_INSTALLED="test-pkg"

  run install_pkg "test-pkg"
  [ -z "$output" ]
}
