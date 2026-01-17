#!/usr/bin/env bats

load "test_helper.sh"

setup() {
  export MOCK_OS="macOS"
  # Mock id returns 501 by default
  id() {
    if [[ "$1" == "-u" ]]; then
      echo "501"
    else
      command id "$@"
    fi
  }
  export -f id

  # Mock logs to avoid dependency on utils during tests
  log_info() { echo "[INFO] $1"; }
  log_note() { echo "[NOTE] $1"; }
  log_status() { echo "[STATUS] $1"; }
  log_success() { echo "[SUCCESS] $1"; }
  log_warn() { echo "[WARN] $1"; }
  log_error() { echo "[ERROR] $1"; }
  export -f log_info log_note log_status log_success log_warn log_error

  export MOCK_PKG_INSTALLED="pam-u2f"
  export MOCK_PAM_U2F_PATH="/opt/homebrew/Cellar/pam-u2f/1.0.0/lib/pam_u2f.so"
  export HOSTNAME="test-mac"

  # Temporary directories for mocks
  export MOCK_CONFIG_DIR="$BATS_TEST_TMPDIR/.config"
  export MOCK_PAM_DIR="$BATS_TEST_TMPDIR/pam.d"
  mkdir -p "$MOCK_CONFIG_DIR"
  mkdir -p "$MOCK_PAM_DIR"

  # Create dummy sudo PAM file
  echo "#%PAM-1.0" > "$MOCK_PAM_DIR/sudo"
  echo "auth       required       pam_opendirectory.so" >> "$MOCK_PAM_DIR/sudo"
  echo "account    required       pam_permit.so" >> "$MOCK_PAM_DIR/sudo"

  # Mock commands

  # Mock uname (already in helper, but ensure it's set)
  uname() { echo "Darwin"; }
  export -f uname

  # Mock hostname
  hostname() { echo "$HOSTNAME"; }
  export -f hostname

  # Mock find to locate pam module
  find() {
    if [[ "$*" == *"pam_u2f.so"* ]]; then
      echo "$MOCK_PAM_U2F_PATH"
    fi
  }
  export -f find

  # Mock mkdir - just pass through, but handle specific mocked paths if needed
  mkdir() {
    command mkdir "$@"
  }
  export -f mkdir

  # Mock pamu2fcfg
  pamu2fcfg() {
    echo "test_key_credential"
    return 0
  }
  export -f pamu2fcfg

  # Mock sudo to intercept file operations
  sudo() {
    local cmd="$1"
    shift
    echo "DEBUG: sudo called with cmd='$cmd' args='$*'" >&2
    if [[ "$cmd" == "cp" || "$cmd" == "grep" ]]; then
       local args=()
       for arg in "$@"; do
         if [[ "$arg" == "/etc/pam.d/"* ]]; then
           local remapped="$MOCK_PAM_DIR/$(basename "$arg")"
           echo "DEBUG: Remapping $arg to $remapped" >&2
           args+=("$remapped")
         else
           args+=("$arg")
         fi
       done
       echo "DEBUG: Executing command $cmd with args: ${args[*]}" >&2
       command "$cmd" "${args[@]}"
       local ret=$?
       echo "DEBUG: Command returned $ret" >&2
       return $ret
    elif [[ "$cmd" == "true" ]]; then
        if [[ "${MOCK_SUDO_FAIL:-}" == "true" ]]; then
           return 1
        fi
        return 0
    elif [[ "$cmd" == "-n" ]]; then
        # sudo -n true check
        if [[ "$1" == "true" ]]; then
           if [[ "${MOCK_SUDO_FAIL:-}" == "true" ]]; then
             return 1
           fi
           return 0
        fi
        return 0
    fi
    echo "MOCKED: sudo $cmd $*" >&2
  }
  export -f sudo

  # Mock mktemp
  mktemp() {
    command mktemp "$BATS_TEST_TMPDIR/tmp.XXXXXX"
  }
  export -f mktemp

  # Mock diff so it doesn't output to stdout/stderr in a confusing way
  diff() {
    return 0
  }
  export -f diff

  # Mock awk to remap paths
  awk() {
    local args=()
    for arg in "$@"; do
       if [[ "$arg" == "/etc/pam.d/"* ]]; then
          args+=("$MOCK_PAM_DIR/$(basename "$arg")")
       else
          args+=("$arg")
       fi
    done
    command awk "${args[@]}"
  }
  export -f awk

  # Mock HOME to redirect ~/.config checks
  export HOME="$BATS_TEST_TMPDIR"

  # Mock confirm_action
  confirm_action() {
    echo "confirm_action: $1" >&2
    local prompt="$1"
    local default="${2:-}"
    read -r REPLY
    echo "DEBUG: confirm_action read '$REPLY'" >&2
    [[ "$REPLY" =~ ^[Yy] ]]
  }
  export -f confirm_action
}

@test "Fail if not macOS" {
  uname() { echo "Linux"; }
  export -f uname

  sed -e 's/\$EUID/$(id -u)/g' lib/modules/yubikey_pam_setup.sh > "$BATS_TEST_TMPDIR/script_under_test.sh"

  run bash -c "source '$BATS_TEST_TMPDIR/script_under_test.sh'; setup_yubikey_pam"

  [ "$status" -eq 1 ]
  [[ "$output" == *"This script is for macOS only"* ]]
}

@test "Fail if running as root" {
  id() { echo "0"; }
  export -f id



  sed -e 's/\$EUID/$(id -u)/g' lib/modules/yubikey_pam_setup.sh > "$BATS_TEST_TMPDIR/script_under_test.sh"

  run bash -c "source '$BATS_TEST_TMPDIR/script_under_test.sh'; setup_yubikey_pam"

  echo "OUTPUT: $output" >&2
  [ "$status" -eq 1 ]
  [[ "$output" == *"Don't run this script with sudo"* ]]
}

@test "Install pam-u2f if missing" {
  export MOCK_PKG_INSTALLED=""

  # Mock brew to track calls
  brew() {
    echo "MOCKED: brew $*"
    if [[ "$1" == "list" ]]; then return 1; fi
    if [[ "$1" == "install" && "$2" == "pam-u2f" ]]; then return 0; fi
  }
  export -f brew

  sed -e 's/\$EUID/$(id -u)/g' lib/modules/yubikey_pam_setup.sh > "$BATS_TEST_TMPDIR/script_under_test.sh"

  # Inputs: y (apply sudo), n (screensaver) - Pamu2fcfg handles missing file without prompt
  run bash -c "source '$BATS_TEST_TMPDIR/script_under_test.sh'; echo -e 'y\nn' | setup_yubikey_pam"

  [[ "$output" == *"[INFO] Installing pam-u2f via Homebrew"* ]]
}

@test "Generate YubiKey credentials if missing" {
  # Mock inputs: y (apply sudo), n (screensaver)
  # Pre-condition: no u2f_keys file
  [ ! -f "$MOCK_CONFIG_DIR/Yubico/u2f_keys" ]

  # Create a testable copy of the script that replaces EUID check
  sed -e 's/\$EUID/$(id -u)/g' lib/modules/yubikey_pam_setup.sh > "$BATS_TEST_TMPDIR/script_under_test.sh"

  run bash -c "source '$BATS_TEST_TMPDIR/script_under_test.sh'; echo -e 'y\nn' | setup_yubikey_pam"

  echo "GEN_KEY_OUTPUT: $output" >&2
  [ "$status" -eq 0 ]
  [[ "$output" == *"[STATUS] Generating YubiKey credentials"* ]]
  [[ "$output" == *"[SUCCESS] YubiKey credentials generated successfully"* ]]

  [ -f "$BATS_TEST_TMPDIR/.config/Yubico/u2f_keys" ]
}

@test "Skip generation if credentials exist and user says no" {
  mkdir -p "$BATS_TEST_TMPDIR/.config/Yubico"
  touch "$BATS_TEST_TMPDIR/.config/Yubico/u2f_keys"
  echo "existing_key" > "$BATS_TEST_TMPDIR/.config/Yubico/u2f_keys"

  sed -e 's/\$EUID/$(id -u)/g' lib/modules/yubikey_pam_setup.sh > "$BATS_TEST_TMPDIR/script_under_test.sh"

  # Inputs: n (overwrite), y (apply sudo), n (screensaver)
  run bash -c "source '$BATS_TEST_TMPDIR/script_under_test.sh'; echo -e 'n\ny\nn' | setup_yubikey_pam"

  [[ "$output" == *"[WARN] YubiKey credentials already exist"* ]]
  [[ "$output" == *"[STATUS] Using YubiKey credentials from"* ]]
  # File should remain unchanged
  run cat "$BATS_TEST_TMPDIR/.config/Yubico/u2f_keys"
  [[ "$output" == "existing_key" ]]
}

@test "Overwrite credentials if valid exist and user says yes" {
  mkdir -p "$BATS_TEST_TMPDIR/.config/Yubico"
  echo "old_key" > "$BATS_TEST_TMPDIR/.config/Yubico/u2f_keys"

  sed -e 's/\$EUID/$(id -u)/g' lib/modules/yubikey_pam_setup.sh > "$BATS_TEST_TMPDIR/script_under_test.sh"

  run bash -c "source '$BATS_TEST_TMPDIR/script_under_test.sh'; echo -e 'y\nn' | setup_yubikey_pam"

  [[ "$output" == *"Generating YubiKey credentials..."* ]]

  # The script uses > redirection, so it writes to the actual path in $HOME
  run cat "$BATS_TEST_TMPDIR/.config/Yubico/u2f_keys"
  [[ "$output" != "old_key" ]]
}

@test "Update sudo PAM config successfully" {
  sed -e 's/\$EUID/$(id -u)/g' lib/modules/yubikey_pam_setup.sh > "$BATS_TEST_TMPDIR/script_under_test.sh"

  # Inputs: y (enable sudo), y (apply changes), n (screensaver)
  run bash -c "source '$BATS_TEST_TMPDIR/script_under_test.sh'; echo -e 'y\ny\nn' | setup_yubikey_pam"

  [ "$status" -eq 0 ]
  [[ "$output" == *"[STATUS] Updating /etc/pam.d/sudo"* ]]
  [[ "$output" == *"[SUCCESS] ✓ Successfully updated /etc/pam.d/sudo"* ]]

  # Verify modifying the mocked file
  run cat "$MOCK_PAM_DIR/sudo"
  [[ "$output" == *"auth       sufficient     $MOCK_PAM_U2F_PATH cue"* ]]
}

@test "Skip PAM update if user says no" {
  sed -e 's/\$EUID/$(id -u)/g' lib/modules/yubikey_pam_setup.sh > "$BATS_TEST_TMPDIR/script_under_test.sh"

  # Inputs: y (enable sudo), n (don't apply changes), n (screensaver)
  run bash -c "source '$BATS_TEST_TMPDIR/script_under_test.sh'; echo -e 'y\nn\nn' | setup_yubikey_pam"

    [[ "$output" == *"[NOTE] Skipping /etc/pam.d/sudo"* ]]

    # Verify NOT modifying the mocked file
    run cat "$MOCK_PAM_DIR/sudo"
    [[ "$output" != *"auth       sufficient     $MOCK_PAM_U2F_PATH cue"* ]]
}

@test "Verify sudo access failure (rollback)" {
    export MOCK_SUDO_FAIL="true"

    sed -e 's/\$EUID/$(id -u)/g' -e '/source.*lib\/core/d' -e 's/if \[\[ -n "\$ZSH_VERSION" \]\]; then/setup_yubikey_pam "$@"; exit $?; if false; then/' lib/modules/yubikey_pam_setup.sh > "$BATS_TEST_TMPDIR/script_under_test.sh"
    chmod +x "$BATS_TEST_TMPDIR/script_under_test.sh"

    # Inputs: y (enable sudo), y (apply changes), n (screensaver)
    run bash -c "source '$BATS_TEST_TMPDIR/script_under_test.sh'; echo -e 'y\ny\nn' | setup_yubikey_pam"

    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR] ✗ sudo test failed! Restoring backup..."* ]]
    [[ "$output" == *"SUDO LOCKOUT DETECTED"* ]]
    [[ "$output" == *"Intel: Hold Cmd+R during startup"* ]]
    [[ "$output" == *"Apple Silicon: Hold Power button during startup"* ]]

    # Verify backup restored (file should not have u2f line)
    run cat "$MOCK_PAM_DIR/sudo"
    [[ "$output" != *"auth       sufficient     $MOCK_PAM_U2F_PATH cue"* ]]
}

@test "Fail regarding pam module missing" {
    find() { echo ""; }
    export -f find

    sed -e 's/\$EUID/$(id -u)/g' lib/modules/yubikey_pam_setup.sh > "$BATS_TEST_TMPDIR/script_under_test.sh"

    run bash -c "source '$BATS_TEST_TMPDIR/script_under_test.sh'; echo -e 'y\ny\nn' | setup_yubikey_pam"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Could not find pam_u2f.so module"* ]]
}
