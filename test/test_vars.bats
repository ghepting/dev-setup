#!/usr/bin/env bats

load "test_helper.sh"

setup() {
  export TEST_HOME="$BATS_TEST_TMPDIR/home"
  export CONFIG_DIR="$TEST_HOME/.config"
  export CONFIG_FILE="$CONFIG_DIR/dev-setup.conf"
  mkdir -p "$CONFIG_DIR"

  # Set HOME for variable expansion tests
  export HOME="$TEST_HOME"
}

# ============================================================================
# Config loading and variable expansion tests
# ============================================================================

@test "vars: expands \${HOME} in dotfiles_dir" {
  echo 'dotfiles_dir="${HOME}/my-dotfiles"' > "$CONFIG_FILE"

  # Source vars.sh to trigger config loading
  source "$(pwd)/lib/core/vars.sh"

  [ "$DOTFILES_DIR" = "$TEST_HOME/my-dotfiles" ]
}

@test "vars: expands \$HOME in dotfiles_dir" {
  echo 'dotfiles_dir="$HOME/my-dotfiles"' > "$CONFIG_FILE"

  source "$(pwd)/lib/core/vars.sh"

  [ "$DOTFILES_DIR" = "$TEST_HOME/my-dotfiles" ]
}

@test "vars: expands ~ in dotfiles_dir" {
  echo 'dotfiles_dir="~/my-dotfiles"' > "$CONFIG_FILE"

  source "$(pwd)/lib/core/vars.sh"

  [ "$DOTFILES_DIR" = "$TEST_HOME/my-dotfiles" ]
}

@test "vars: expands \${HOME} in dotfiles_repo" {
  echo 'dotfiles_repo="${HOME}/repos/dotfiles.git"' > "$CONFIG_FILE"

  source "$(pwd)/lib/core/vars.sh"

  [ "$DOTFILES_REPO" = "$TEST_HOME/repos/dotfiles.git" ]
}

@test "vars: sanitizes corrupted dotfiles_dir containing prompt text" {
  echo 'dotfiles_dir="Directory path for your dotfiles"' > "$CONFIG_FILE"

  source "$(pwd)/lib/core/vars.sh"

  # Should fall back to default (uses real HOME, not TEST_HOME)
  [[ "$DOTFILES_DIR" == */dotfiles ]]
}

@test "vars: sanitizes corrupted dotfiles_repo containing prompt text" {
  echo 'dotfiles_repo="Repository URL for your dotfiles"' > "$CONFIG_FILE"

  source "$(pwd)/lib/core/vars.sh"

  # Should fall back to default
  [ "$DOTFILES_REPO" = "git@github.com:ghepting/dotfiles.git" ]
}

@test "vars: falls back to defaults when config file missing" {
  rm -f "$CONFIG_FILE"

  source "$(pwd)/lib/core/vars.sh"

  [[ "$DOTFILES_DIR" == */dotfiles ]]
  [ "$DOTFILES_REPO" = "git@github.com:ghepting/dotfiles.git" ]
}

@test "vars: falls back to defaults when keys not in config" {
  echo 'some_other_key=value' > "$CONFIG_FILE"

  source "$(pwd)/lib/core/vars.sh"

  [[ "$DOTFILES_DIR" == */dotfiles ]]
  [ "$DOTFILES_REPO" = "git@github.com:ghepting/dotfiles.git" ]
}

@test "vars: preserves literal paths without expansion" {
  echo 'dotfiles_dir="/opt/dotfiles"' > "$CONFIG_FILE"

  source "$(pwd)/lib/core/vars.sh"

  [ "$DOTFILES_DIR" = "/opt/dotfiles" ]
}

@test "vars: handles both dotfiles_dir and dotfiles_repo in same config" {
  cat > "$CONFIG_FILE" <<EOF
dotfiles_dir="~/custom-dotfiles"
dotfiles_repo="git@github.com:user/custom-repo.git"
EOF

  source "$(pwd)/lib/core/vars.sh"

  [ "$DOTFILES_DIR" = "$TEST_HOME/custom-dotfiles" ]
  [ "$DOTFILES_REPO" = "git@github.com:user/custom-repo.git" ]
}
