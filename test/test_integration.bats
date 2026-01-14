#!/usr/bin/env bats

# Do NOT load test_helper.sh to avoid MOCKS.
# We want real execution.

# Helper to source the library under test without mocks
load_lib_real() {
  local lib_file="$1"
  # We assume setup() has already set TEST_HOME/HOME properly
  local repo_root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

  if [[ -z "$PLATFORM" ]]; then
    source "$repo_root/lib/core/vars.sh"
  fi

  if ! typeset -f is_macos > /dev/null; then
    source "$repo_root/lib/core/utils.sh"
  fi
  source "$repo_root/lib/core/zsh.sh"

  if [[ "$lib_file" != "lib/core/vars.sh" && "$lib_file" != "lib/core/utils.sh" ]]; then
    source "$repo_root/$lib_file"
  fi

  # Auto-export functions so 'run' subshells can see them
  if [[ -f "$repo_root/$lib_file" ]]; then
     local funcs=$(grep -E '^[a-z0-9_]+[[:space:]]*\(\)' "$repo_root/$lib_file" | cut -d'(' -f1 | xargs)
     for f in $funcs; do
       export -f "$f"
     done
  fi

  # Ensure core util functions are explicitly exported if they are defined
  if typeset -f install_pkg > /dev/null; then
     export -f install_pkg install_packages_from_file is_macos is_linux is_debian is_arch is_fedora is_enabled is_ssh check_app
  fi
}

setup() {
  # Unset potential functions to ensure clean slate
  unset -f nvm 2>/dev/null || true
  unset -f rbenv 2>/dev/null || true
  unset -f pyenv 2>/dev/null || true
  unset -f install_pkg 2>/dev/null || true

  export TEST_HOME="$BATS_TEST_TMPDIR/home"
  export CONFIG_DIR="$TEST_HOME/.config"
  export CONFIG_FILE="$CONFIG_DIR/dev-setup.conf"
  export ZSHRC_FILE="$TEST_HOME/.zshrc"

  mkdir -p "$TEST_HOME" "$CONFIG_DIR"
  touch "$ZSHRC_FILE"
  touch "$TEST_HOME/.zshrc.dev"

  # Override HOME for the tests
  export HOME="$TEST_HOME"

  # Ensure we are treated as Linux by vars.sh (unless on Mac)
  if [ "$(uname)" == "Darwin" ]; then
      export PLATFORM="macOS"
  else
      # Let vars.sh detect, but we can force it if we want specific distro logic coverage
      unset PLATFORM
  fi

  # Load libs using specific non-mocking loader
  load_lib_real "lib/core/vars.sh"
  # Force non-interactive for any prompts
  export DEBIAN_FRONTEND=noninteractive

  # Load language modules
  load_lib_real "lib/modules/ruby.sh"
  load_lib_real "lib/modules/python.sh"
  load_lib_real "lib/modules/node.sh"

  # Sanitize PATH to ensure we don't pick up system-installed managers
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
}

@test "Integration: Install rbenv and Ruby dependencies" {
  # This test runs REAL commands.
  # If local, it might fail usage of sudo unless user has passwordless sudo.
  # In CI, it will work.
  # We skip if sudo is required but not available?
  # Actually, we can just run it. If it fails, we see.

  if [ "$(uname)" == "Linux" ] && [ "$(id -u)" -ne 0 ]; then
     # Check if we have passwordless sudo?
     if ! sudo -n true 2>/dev/null; then
        skip "Skipping integration test: Passwordless sudo required for package installation"
     fi
  fi

  # If we are effectively root or have sudo, proceed.

  export PLATFORM="${PLATFORM:-Linux}"

  run install_rbenv_and_ruby

  if [ ! -d "$TEST_HOME/.rbenv" ]; then
    echo "DEBUG: install_rbenv_and_ruby output:"
    echo "$output"
  fi

  # Check rbenv is available (either via PATH or ~/.rbenv)
  if command -v rbenv >/dev/null; then
     true # Installed in path
  elif [ -d "$TEST_HOME/.rbenv" ]; then
     [ -x "$TEST_HOME/.rbenv/bin/rbenv" ]
  else
     echo "rbenv not found in PATH or $TEST_HOME/.rbenv"
     false
  fi
}

@test "Integration: Install pyenv and Python dependencies" {
  if [ "$(uname)" == "Linux" ] && [ "$(id -u)" -ne 0 ]; then
     if ! sudo -n true 2>/dev/null; then
        skip "Skipping integration test: Passwordless sudo required"
     fi
  fi

  export PLATFORM="${PLATFORM:-Linux}"

  run install_pyenv_and_python

  if [ ! -d "$TEST_HOME/.pyenv" ]; then
    echo "DEBUG: install_pyenv_and_python output:"
    echo "$output"
  fi

  if command -v pyenv >/dev/null; then
     true
  elif [ -d "$TEST_HOME/.pyenv" ]; then
     [ -x "$TEST_HOME/.pyenv/bin/pyenv" ]
  else
     echo "pyenv not found"
     false
  fi
}

@test "Integration: Install nvm and Node dependencies" {
  if [ "$(uname)" == "Linux" ] && [ "$(id -u)" -ne 0 ]; then
     if ! sudo -n true 2>/dev/null; then
        skip "Skipping integration test: Passwordless sudo required"
     fi
  fi

  export PLATFORM="${PLATFORM:-Linux}"

  run install_nvm_and_node

  if [ ! -d "$TEST_HOME/.nvm" ]; then
    echo "DEBUG: install_nvm_and_node output:"
    echo "$output"
  fi

  [ -d "$TEST_HOME/.nvm" ]
  [ -s "$TEST_HOME/.nvm/nvm.sh" ]

  # Source nvm and check version
  export NVM_DIR="$TEST_HOME/.nvm"
  . "$NVM_DIR/nvm.sh"

  run nvm --version
  [ "$status" -eq 0 ]

  # Attempt install
  run nvm install --lts
  [ "$status" -eq 0 ]
}
