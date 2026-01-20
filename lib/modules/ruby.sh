#!/usr/bin/env zsh

install_rbenv_and_ruby() {
  # install rbenv
  if ! command -v rbenv &> /dev/null; then
    if is_debian; then
      # Build dependencies for ruby-build
      local deps=("autoconf" "bison" "build-essential" "libssl-dev" "libyaml-dev" "libreadline6-dev" "zlib1g-dev" "libncurses5-dev" "libffi-dev" "libgdbm6" "libgdbm-dev" "libdb-dev" "rbenv")
      for dep in "${deps[@]}"; do
        install_pkg "$dep"
      done
    else
      install_pkg "rbenv"
    fi
    RESTART_REQUIRED=true
  else
    log_status "Using $(rbenv --version)"
  fi

  # add rbenv init to .zshrc.dev
  install_zsh_config "rbenv"
  ensure_zshrc_dev_sourced

  # install ruby
  RUBY_VERSION=$(cat .ruby-version)

  # Check for latest stable version
  log_info "Checking for latest stable Ruby version..."
  local latest_ruby
  latest_ruby=$(rbenv install --list | grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+$" | tr -d ' ' | sort -V | tail -1)

  if [[ -n "$latest_ruby" && "$latest_ruby" != "$RUBY_VERSION" ]]; then
    if confirm_action "Latest stable Ruby is $latest_ruby (current: $RUBY_VERSION). Update .ruby-version?" "n"; then
      echo "$latest_ruby" > .ruby-version
      RUBY_VERSION="$latest_ruby"
      log_success "Updated .ruby-version to $latest_ruby"
    fi
  fi

  if [[ "$(rbenv version-name)" == "$RUBY_VERSION" ]] &> /dev/null; then
    log_status "Using ruby $(rbenv version-name)"
  else
    log_info "Installing ruby $RUBY_VERSION..."
    if rbenv install $RUBY_VERSION -s && rbenv global $RUBY_VERSION &> /dev/null; then
      log_success "Successfully installed ruby $RUBY_VERSION via rbenv"
      RESTART_REQUIRED=true
    else
      log_error "Failed to install ruby $RUBY_VERSION via rbenv"
      exit 1
    fi
  fi
}
