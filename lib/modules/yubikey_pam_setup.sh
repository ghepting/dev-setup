#!/usr/bin/env zsh

setup_yubikey_pam() {
  local yubikey_credentials_generated=false
  local pam_conf_updated=false

  # Check if running on macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This script is for macOS only"
    return 1
  fi

  # Check if running with sudo (we need it for PAM edits)
  if [[ $EUID -eq 0 ]]; then
    log_error "Don't run this script with sudo. It will prompt when needed."
    return 1
  fi

  log_info "Configuring YubiKey PAM for macOS..."

  # Install pam-u2f if not already installed
  if ! brew list pam-u2f &>/dev/null; then
    log_info "Installing pam-u2f via Homebrew..."
    brew install pam-u2f
  else
    log_note "Verified pam-u2f Homebrew package is installed"
  fi

  # Find the pam_u2f.so module path
  PAM_U2F_PATH=$(find /opt/homebrew/Cellar/pam-u2f -name "pam_u2f.so" 2>/dev/null | head -n1)

  if [[ -z "$PAM_U2F_PATH" ]]; then
    log_error "Could not find pam_u2f.so module. Is pam-u2f installed correctly?"
    exit 1
  fi

  log_note "Found pam_u2f module at: $PAM_U2F_PATH"

  # Create YubiKey config directory
  mkdir -p ~/.config/Yubico

  # Check if YubiKey credentials already exist
  if [[ -f ~/.config/Yubico/u2f_keys ]]; then
    log_warn "YubiKey credentials already exist at ~/.config/Yubico/u2f_keys"
    if ! confirm_action "Do you want to overwrite?"; then
      log_status "Using YubiKey credentials from ~/.config/Yubico/u2f_keys"
    else
      log_status "Generating YubiKey credentials..."
      log_status "Please enter your YubiKey PIN and touch it when it blinks"
      pamu2fcfg -o "pam://$(hostname)" -i "pam://$(hostname)" > ~/.config/Yubico/u2f_keys
      log_success "YubiKey credentials generated successfully"
      yubikey_credentials_generated=true
    fi
  else
    log_status "Generating YubiKey credentials..."
    log_status "Please enter your YubiKey PIN and touch it when it blinks"
    if pamu2fcfg -o "pam://$(hostname)" -i "pam://$(hostname)" > ~/.config/Yubico/u2f_keys; then
      log_success "YubiKey credentials generated successfully"
      yubikey_credentials_generated=true
    else
      log_error "Failed to generate YubiKey credentials"
      exit 1
    fi
  fi

  # Verify credentials were created
  if [[ ! -s ~/.config/Yubico/u2f_keys ]]; then
    log_error "YubiKey credentials file is empty or missing"
    exit 1
  fi

  # Helper to check if already configured
  is_pam_configured() {
    local pam_file=$1
    grep -q "pam_u2f.so" "$pam_file" 2>/dev/null
  }

  # Function to safely update PAM config
  update_pam_config() {
    local pam_file=$1
    local pam_line="auth       sufficient     $PAM_U2F_PATH cue"

    # Check if file exists
    if [[ ! -f "$pam_file" ]]; then
      log_warn "$pam_file does not exist, skipping"
      return 0
    fi

    # Create backup
    local backup_file="${pam_file}.backup-$(date +%Y%m%d-%H%M%S)"
    log_note "Creating backup: $backup_file"
    sudo cp "$pam_file" "$backup_file"

    # Create temp file with new content
    local temp_file=$(mktemp)

    # Add pam_u2f line after the first comment line
    awk -v line="$pam_line" '
      !inserted && /^#/ {print; print line; inserted=1; next}
      {print}
    ' "$pam_file" > "$temp_file"

    # Verify the temp file is valid (has content)
    if [[ ! -s "$temp_file" ]]; then
      log_error "Generated temp file is empty, aborting"
      rm -f "$temp_file"
      return 1
    fi

    # Show diff for review
    log_info "Changes to be made:"
    diff "$pam_file" "$temp_file" || true

    # Prompt for confirmation
    if ! confirm_action "Apply these changes to $pam_file?"; then
      log_note "Skipping $pam_file"
      rm -f "$temp_file"
      return 0
    fi

    # Apply changes
    log_status "Updating $pam_file..."
    sudo cp "$temp_file" "$pam_file"
    pam_conf_updated=true
    rm -f "$temp_file"

    # Verify sudo still works (critical check)
    if [[ "$pam_file" == "/etc/pam.d/sudo" ]]; then
      log_status "Testing sudo with new configuration..."
      if sudo -n true 2>/dev/null || sudo true; then
        log_success "✓ sudo test successful"
      else
        log_error "✗ sudo test failed! Restoring backup..."
        sudo cp "$backup_file" "$pam_file"
        if sudo true 2>/dev/null; then
          log_success "Backup restored successfully."
        else
          log_error "CRITICAL: Backup restoration may have failed, or sudo is still broken."
          log_error "------------------------------------------------------------"
          log_error "!!! SUDO LOCKOUT DETECTED !!!"
          log_error "------------------------------------------------------------"
          log_error "If you cannot use sudo, you must fix it via Recovery Mode:"
          log_info "  1. Restart your Mac:"
          log_info "     - Intel: Hold Cmd+R during startup"
          log_info "     - Apple Silicon: Hold Power button during startup, then select Options"
          log_info "  2. Open Terminal from the Utilities menu"
          log_info "  3. Mount your disk (if it's not already mounted):"
          log_info "     diskutil mount 'Macintosh HD'"
          log_info "  4. Navigate to the config:"
          log_info "     cd /Volumes/Macintosh\ HD/etc/pam.d"
          log_info "  5. Restore the backup or manually remove the line:\n"
          log_info "     cp sudo.backup-* sudo"
          log_info "  6. Restart normally"
          log_error "------------------------------------------------------------"
        fi
        return 1
      fi
    fi

    log_success "✓ Successfully updated $pam_file"
  }

  # Update sudo PAM config
  local sudo_pam="/etc/pam.d/sudo"
  if is_pam_configured "$sudo_pam"; then
    log_status "Using YubiKey PAM configuration in $sudo_pam"
  elif confirm_action "Do you want to enable YubiKey for sudo?" "n"; then
    update_pam_config "$sudo_pam" || exit 1
  fi

  # Ask if user wants to configure screensaver
  local screensaver_pam="/etc/pam.d/screensaver"
  if is_pam_configured "$screensaver_pam"; then
    log_status "Using YubiKey PAM configuration in $screensaver_pam"
  elif confirm_action "Do you want to enable YubiKey for screen unlock?" "n"; then
    update_pam_config "$screensaver_pam" || exit 1
  fi

  if [[ "$pam_conf_updated" == "true" ]]; then
    log_warn "To test, run 'sudo echo \"testing\"' in a *new* shell."
    log_info "You should be prompted for your YubiKey PIN and touch."
    log_info "Backups are stored with timestamp suffixes in /etc/pam.d/"
    log_info "To restore: sudo cp /etc/pam.d/sudo.backup-YYYYMMDD-HHMMSS /etc/pam.d/sudo"
  fi

  if [[ "$yubikey_credentials_generated" == "true" || "$pam_conf_updated" == "true" ]]; then
    log_success "YubiKey setup complete"
  fi
}
