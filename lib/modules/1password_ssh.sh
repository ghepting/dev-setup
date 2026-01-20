#!/usr/bin/env zsh

setup_1password_ssh() {
  local SSH_CONFIG_FILE="$HOME/.ssh/config"

  # Determine if we should proceed (must have GUI or CLI enabled)
  if ! is_enabled "1password_gui" && ! is_enabled "1password_cli"; then
    log_info "1Password SSH configuration skipped (requires 1Password GUI or CLI)"
    return
  fi

  # configure SSH Config (Idempotent)
  # Use the system-agnostic socket path
  local sock_path="~/.1password/agent.sock"
  local expanded_sock_path="${sock_path/#\~/$HOME}"
  local op_sock_macos="$HOME/Library/Group Containers/2BU8B4S4C3.com.1password/t/agent.sock"

  # Ensure the directory for the symlink exists
  mkdir -p "$HOME/.1password"

  # Create symlink if it doesn't exist (specifically for macOS)
  if is_macos && [ ! -e "$expanded_sock_path" ]; then
    if [ -S "$op_sock_macos" ]; then
      ln -s "$op_sock_macos" "$expanded_sock_path"
      log_success "Created symlink $expanded_sock_path -> $op_sock_macos"
    else
      log_warn "Warning: 1Password SSH agent socket not found at $op_sock_macos"
      log_info "Symlink $expanded_sock_path not created."
    fi
  fi

  # create ssh config file if it doesn't already exist
  if [ ! -f "$SSH_CONFIG_FILE" ]; then
    mkdir -p "$(dirname "$SSH_CONFIG_FILE")"
    touch "$SSH_CONFIG_FILE"
  fi

  # add 1password ssh agent to ssh config if not already present
  # we check for the path both with and without quotes, and handles ~ or full path
  local sock_regex="IdentityAgent[[:space:]]+\"?($sock_path|${sock_path/#\~/$HOME})\"?"
  if ! grep -qE "$sock_regex" "$SSH_CONFIG_FILE"; then
    # Only add Host * if it's not already at the end of the file or if the file is empty
    if [ ! -s "$SSH_CONFIG_FILE" ] || ! tail -n 1 "$SSH_CONFIG_FILE" | grep -q "Host \*"; then
      echo "" >>"$SSH_CONFIG_FILE"
      echo "Host *" >>"$SSH_CONFIG_FILE"
    fi
    echo "  IdentityAgent \"$sock_path\"" >>"$SSH_CONFIG_FILE"
    log_success "Added 1Password SSH agent to $SSH_CONFIG_FILE"
  else
    log_status "Using 1Password SSH agent"
  fi

  # ensure SSH_AUTH_SOCK is exported in .zshrc.dev
  install_zsh_config "1password_ssh"
  ensure_zshrc_dev_sourced

  # verify that agent.toml exists and is configured with correct "Development" vault
  local agent_config="$HOME/.config/1Password/ssh/agent.toml"

  if [ ! -f "$agent_config" ]; then
    mkdir -p "$(dirname "$agent_config")"
    touch "$agent_config"
    echo "[[ssh-keys]]" >>"$agent_config"
    echo "vault = \"Development\"" >>"$agent_config"
    log_success "Created $agent_config"
  elif ! grep -q "vault = \"Development\"" "$agent_config"; then
    # Resolve symlink to edit the actual file if necessary
    local target_file="$agent_config"
    if [[ -L "$agent_config" ]]; then
      target_file=$(readlink "$agent_config")
      [[ "$target_file" != /* ]] && target_file="$(dirname "$agent_config")/$target_file"
    fi

    # replace default vault value with "Development"
    if is_macos; then
      sed -i '' 's/vault = "[^"]*"/vault = "Development"/' "$target_file"
    else
      sed -i 's/vault = "[^"]*"/vault = "Development"/' "$target_file"
    fi
    log_success "Configured $agent_config"
  else
    log_status "Using 1Password \"Development\" vault"
  fi
}
