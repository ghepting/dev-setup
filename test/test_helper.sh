#!/usr/bin/env zsh

# Mock functions to isolate tests from the host system

setup_mocks() {
  # Mock uname
  uname() {
    if [ "$MOCK_OS" == "macOS" ]; then
      echo "Darwin"
    else
      echo "Linux"
    fi
  }
  export -f uname

  # Mock brew
  brew() {
    if [[ "$1" == "list" ]]; then
      if [[ "$MOCK_PKG_INSTALLED" == *"$2"* ]]; then
        return 0
      else
        return 1
      fi
    fi
    echo "MOCKED: brew $*" >&2
  }
  export -f brew

  # Mock sudo
  sudo() {
    local cmd=$1
    shift
    echo "MOCKED: sudo $cmd $*" >&2
    case "$cmd" in
    apt-get | pacman | dnf | update-alternatives | install | curl | chmod | tee)
      # For these commands, we just echo that they were mocked
      # Some might need actual execution or further mocking if output is required
      ;;
    *)
      # Already echoed above
      ;;
    esac
  }
  export -f sudo

  apt-get() {
    echo "MOCKED: apt-get $*" >&2
  }
  export -f apt-get

  dpkg() {
    if [[ "$*" == *"--print-architecture"* ]]; then
      echo "amd64"
      return 0
    fi
    echo "MOCKED: dpkg $*" >&2
  }
  export -f dpkg

  dpkg-query() {
    if [[ "$*" == *"-W"* ]]; then
      local pkg="${@: -1}" # get last arg
      if [[ "$MOCK_PKG_INSTALLED" == *"$pkg"* ]]; then
        echo "hi ok installed"
        return 0
      else
        echo "not installed"
        return 1
      fi
    fi
    echo "MOCKED: dpkg-query $*" >&2
  }
  export -f dpkg-query

  # Mock defaults
  defaults() {
    echo "MOCKED: defaults $*" >&2
  }
  export -f defaults

  # Mock rclone
  rclone() {
    echo "MOCKED: rclone $*" >&2
  }
  export -f rclone

  # Mock Arch/Fedora pkg managers
  pacman() {
    if [[ "$*" == *"-Qs"* ]]; then
      local pkg="${@: -1}"
      # Remove regex anchors if present for simple mock matching
      local clean_pkg="${pkg#^}"
      clean_pkg="${clean_pkg%$}"
      if [[ "$MOCK_PKG_INSTALLED" == *"$clean_pkg"* ]]; then
        return 0
      fi
      return 1
    fi
    echo "MOCKED: pacman $*" >&2
  }
  export -f pacman

  dnf() {
    echo "MOCKED: dnf $*" >&2
  }
  export -f dnf

  rpm() {
    if [[ "$1" == "-q" ]]; then
      if [[ "$MOCK_PKG_INSTALLED" == *"$2"* ]]; then
        return 0
      fi
      return 1
    fi
    echo "MOCKED: rpm $*" >&2
  }
  export -f rpm

  # Mock op (1Password CLI)
  op() {
    echo "MOCKED: op $*" >&2
    if [[ "$1" == "whoami" ]]; then
      # Simulate logged in by default in tests
      return 0
    fi
  }
  export -f op

  # Mock gpg
  gpg() {
    echo "MOCKED: gpg $*" >&2
  }
  export -f gpg

  # Mock tee
  tee() {
    echo "MOCKED: tee $*" >&2
  }
  export -f tee

  # Better Mock read: don't break loops
  read() {
    # If we appear to be reading from a file (usually -r and a variable)
    if [[ "$*" == *"-r"* ]]; then
      builtin read "$@"
      return $?
    fi
    # If it's an interactive prompt mock
    return 0
  }
  export -f read

  # Mock command -v to allow simulating missing binaries
  command() {
    if [[ "$1" == "-v" ]]; then
      # Exact word matching for MOCKED_NOT_FOUND
      for pkg in $MOCKED_NOT_FOUND; do
        if [[ "$pkg" == "$2" ]]; then
          return 1
        fi
      done
    fi
    builtin command "$@"
  }
  export -f command

  # Mock npm
  npm() {
    echo "MOCKED: npm $*" >&2
    if [[ "$*" == *"list"* ]] && [[ "$MOCK_PKG_INSTALLED" == *"$2"* ]]; then
      return 0
    elif [[ "$*" == *"outdated"* ]]; then
      return 1 # Not outdated by default in tests
    fi
  }
  export -f npm

  # Mock update-alternatives
  update-alternatives() {
    echo "MOCKED: update-alternatives $*" >&2
  }
  export -f update-alternatives

  # Better Mock curl
  curl() {
    echo "MOCKED: curl $*" >&2
    if [[ "$*" == *"claude.ai/install.sh"* ]]; then
      # Simulate the installer script
      echo "echo 'Successfully installed claude'"
      return 0
    fi
  }
  export -f curl

  # Mock vim
  vim() {
    if [[ "$*" == "--version" ]]; then
      echo "VIM - Vi IMproved 9.1 (MOCKED)"
      # Return 1 to simulate missing syntax on Debian for tests
      return 1
    fi
    echo "MOCKED: vim $*" >&2
  }
  export -f vim

  # Mock check_app
  check_app() {
    if [[ "$MOCKED_APP_INSTALLED" == *"$1"* ]]; then
      return 0
    else
      return 1
    fi
  }
  export -f check_app

  # Mock open
  open() {
    echo "MOCKED: open $*" >&2
  }
  export -f open
}

# Common colors for scripts
export NC='\033[0m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export WHITE='\033[1;37m'
export GRAY='\033[0;90m'
export CYAN='\033[0;36m'

# Helper to source the library under test
load_lib() {
  local lib_file="$1"
  export HOME="$BATS_TEST_TMPDIR/home"
  export TEST_HOME="$HOME"
  export CONFIG_FILE="$HOME/.config/dev-setup.conf"
  export ZSHRC_FILE="$HOME/.zshrc"
  mkdir -p "$HOME/.config"
  touch "$ZSHRC_FILE"

  # Always source vars and utils first, but only if not already loaded
  # to avoid overwriting mocks
  local repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

  if [[ -z "$PLATFORM" ]]; then
    source "$repo_root/lib/core/vars.sh"
  fi

  if ! typeset -f is_macos > /dev/null; then
    source "$repo_root/lib/core/utils.sh"
  fi

  if [[ "$lib_file" != "lib/core/vars.sh" && "$lib_file" != "lib/core/utils.sh" ]]; then
    source "$repo_root/$lib_file"
  fi

  # AUTO-EXPORT FUNCTIONS so 'run' can see them
  # This finds all function definitions in the just-sourced file
  local funcs
  # Only try to extract functions from the specific file we loaded if it's not core
  if [[ -f "$repo_root/$lib_file" ]]; then
    funcs=$(grep -E '^[a-z0-9_]+[[:space:]]*\(\)' "$repo_root/$lib_file" | cut -d'(' -f1 | xargs)
    for f in $funcs; do
      export -f "$f"
    done
  fi
  # Also always export core functions and ensure mocks take precedence
  setup_mocks
  export -f detect_platform is_macos is_linux is_debian is_arch is_fedora is_enabled install_pkg is_ssh check_app
}
