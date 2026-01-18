#!/usr/bin/env bats

load "test_helper.sh"

setup() {
  export TEST_HOME="$BATS_TEST_TMPDIR/home"
  export CONFIG_DIR="$TEST_HOME/.config"
  export CONFIG_FILE="$CONFIG_DIR/dev-setup.conf"
  mkdir -p "$CONFIG_DIR"
}

# ============================================================================
# set_config_value tests
# ============================================================================

@test "set_config_value: creates new key-value pair" {
  load_lib "lib/core/utils.sh"

  set_config_value "test_key" "test_value"

  [ -f "$CONFIG_FILE" ]
  grep -q "^test_key=test_value$" "$CONFIG_FILE"
}

@test "set_config_value: updates existing key" {
  load_lib "lib/core/utils.sh"

  echo "test_key=old_value" > "$CONFIG_FILE"
  set_config_value "test_key" "new_value"

  grep -q "^test_key=new_value$" "$CONFIG_FILE"
  ! grep -q "old_value" "$CONFIG_FILE"
}

@test "set_config_value: handles values with spaces" {
  load_lib "lib/core/utils.sh"

  set_config_value "test_key" "value with spaces"

  grep -q "^test_key=value with spaces$" "$CONFIG_FILE"
}

@test "set_config_value: handles paths with slashes" {
  load_lib "lib/core/utils.sh"

  set_config_value "dotfiles_dir" "/home/user/dotfiles"

  grep -q "^dotfiles_dir=/home/user/dotfiles$" "$CONFIG_FILE"
}

@test "set_config_value: handles special characters" {
  load_lib "lib/core/utils.sh"

  set_config_value "test_key" "value@with#special\$chars"

  grep -q "^test_key=value@with#special\\\$chars$" "$CONFIG_FILE"
}

@test "set_config_value: preserves other keys when updating" {
  load_lib "lib/core/utils.sh"

  echo "key1=value1" > "$CONFIG_FILE"
  echo "key2=value2" >> "$CONFIG_FILE"
  set_config_value "key1" "new_value"

  grep -q "^key1=new_value$" "$CONFIG_FILE"
  grep -q "^key2=value2$" "$CONFIG_FILE"
}

# ============================================================================
# is_ssh tests
# ============================================================================

@test "is_ssh: returns true when SSH_CONNECTION is set" {
  load_lib "lib/core/utils.sh"

  export SSH_CONNECTION="192.168.1.1 12345 192.168.1.2 22"
  is_ssh
}

@test "is_ssh: returns true when SSH_CLIENT is set" {
  load_lib "lib/core/utils.sh"

  export SSH_CLIENT="192.168.1.1 12345 22"
  is_ssh
}

@test "is_ssh: returns true when SSH_TTY is set" {
  load_lib "lib/core/utils.sh"

  export SSH_TTY="/dev/pts/0"
  is_ssh
}

@test "is_ssh: returns false when no SSH variables are set" {
  load_lib "lib/core/utils.sh"

  unset SSH_CONNECTION
  unset SSH_CLIENT
  unset SSH_TTY

  run is_ssh
  [ "$status" -eq 1 ]
}

# ============================================================================
# is_enabled tests
# ============================================================================

@test "is_enabled: dotfiles is always enabled" {
  load_lib "lib/core/utils.sh"

  export PLATFORM="macOS"
  is_enabled "dotfiles"

  export PLATFORM="Debian"
  is_enabled "dotfiles"
}

@test "is_enabled: vim_tmux is always enabled" {
  load_lib "lib/core/utils.sh"

  export PLATFORM="macOS"
  is_enabled "vim_tmux"

  export PLATFORM="Linux"
  is_enabled "vim_tmux"
}

@test "is_enabled: editor is enabled on macOS by default" {
  load_lib "lib/core/utils.sh"

  export PLATFORM="macOS"
  is_enabled "editor"
}

@test "is_enabled: editor is disabled on Linux by default" {
  load_lib "lib/core/utils.sh"

  export PLATFORM="Debian"
  run is_enabled "editor"
  [ "$status" -eq 1 ]
}

@test "is_enabled: other modules enabled on macOS by default" {
  load_lib "lib/core/utils.sh"

  export PLATFORM="macOS"
  is_enabled "docker"
  is_enabled "languages"
  is_enabled "1password_cli"
}

@test "is_enabled: other modules disabled on Linux by default" {
  load_lib "lib/core/utils.sh"

  export PLATFORM="Debian"

  run is_enabled "docker"
  [ "$status" -eq 1 ]

  run is_enabled "languages"
  [ "$status" -eq 1 ]
}

@test "is_enabled: respects explicit module=true in config" {
  load_lib "lib/core/utils.sh"

  export PLATFORM="Debian"
  echo "docker=true" > "$CONFIG_FILE"

  is_enabled "docker"
}

@test "is_enabled: respects explicit module=false in config" {
  load_lib "lib/core/utils.sh"

  export PLATFORM="macOS"
  echo "dotfiles=false" > "$CONFIG_FILE"

  run is_enabled "dotfiles"
  [ "$status" -eq 1 ]
}

@test "is_enabled: config overrides default behavior" {
  load_lib "lib/core/utils.sh"

  export PLATFORM="macOS"
  echo "editor=false" > "$CONFIG_FILE"

  run is_enabled "editor"
  [ "$status" -eq 1 ]
}

@test "is_enabled: handles missing config file gracefully" {
  load_lib "lib/core/utils.sh"

  rm -f "$CONFIG_FILE"
  export PLATFORM="macOS"

  is_enabled "dotfiles"
  is_enabled "docker"
}
