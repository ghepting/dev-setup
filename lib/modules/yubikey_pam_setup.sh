#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This script is for macOS only"
    exit 1
fi

# Check if running with sudo (we need it for PAM edits)
if [[ $EUID -eq 0 ]]; then
    log_error "Don't run this script with sudo. It will prompt when needed."
    exit 1
fi

log_info "Starting YubiKey PAM setup for macOS..."

# Install pam-u2f if not already installed
if ! brew list pam-u2f &>/dev/null; then
    log_info "Installing pam-u2f via Homebrew..."
    brew install pam-u2f
else
    log_info "pam-u2f already installed"
fi

# Find the pam_u2f.so module path
PAM_U2F_PATH=$(find /opt/homebrew/Cellar/pam-u2f -name "pam_u2f.so" 2>/dev/null | head -n1)

if [[ -z "$PAM_U2F_PATH" ]]; then
    log_error "Could not find pam_u2f.so module. Is pam-u2f installed correctly?"
    exit 1
fi

log_info "Found pam_u2f module at: $PAM_U2F_PATH"

# Create YubiKey config directory
mkdir -p ~/.config/Yubico

# Check if YubiKey credentials already exist
if [[ -f ~/.config/Yubico/u2f_keys ]]; then
    log_warn "YubiKey credentials already exist at ~/.config/Yubico/u2f_keys"
    read -p "Do you want to overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping YubiKey credential generation"
    else
        log_info "Generating YubiKey credentials..."
        log_info "Please enter your YubiKey PIN and touch it when it blinks"
        pamu2fcfg -o "pam://$(hostname)" -i "pam://$(hostname)" > ~/.config/Yubico/u2f_keys
        log_info "YubiKey credentials generated successfully"
    fi
else
    log_info "Generating YubiKey credentials..."
    log_info "Please enter your YubiKey PIN and touch it when it blinks"
    if pamu2fcfg -o "pam://$(hostname)" -i "pam://$(hostname)" > ~/.config/Yubico/u2f_keys; then
        log_info "YubiKey credentials generated successfully"
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

# Function to safely update PAM config
update_pam_config() {
    local pam_file=$1
    local pam_line="auth       sufficient     $PAM_U2F_PATH cue"

    log_info "Updating $pam_file..."

    # Check if file exists
    if [[ ! -f "$pam_file" ]]; then
        log_warn "$pam_file does not exist, skipping"
        return 0
    fi

    # Check if already configured
    if sudo grep -q "pam_u2f.so" "$pam_file"; then
        log_warn "$pam_file already contains pam_u2f configuration, skipping"
        return 0
    fi

    # Create backup
    local backup_file="${pam_file}.backup-$(date +%Y%m%d-%H%M%S)"
    log_info "Creating backup: $backup_file"
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
    read -p "Apply these changes to $pam_file? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping $pam_file"
        rm -f "$temp_file"
        return 0
    fi

    # Apply changes
    sudo cp "$temp_file" "$pam_file"
    rm -f "$temp_file"

    # Verify sudo still works (critical check)
    if [[ "$pam_file" == "/etc/pam.d/sudo" ]]; then
        log_info "Testing sudo with new configuration..."
        if sudo -n true 2>/dev/null || sudo true; then
            log_info "✓ sudo test successful"
        else
            log_error "✗ sudo test failed! Restoring backup..."
            sudo cp "$backup_file" "$pam_file"
            log_error "Backup restored. Please investigate the issue."
            return 1
        fi
    fi

    log_info "✓ Successfully updated $pam_file"
}

# Update sudo PAM config
log_info "Configuring PAM for sudo..."
update_pam_config "/etc/pam.d/sudo"

# Ask if user wants to configure screensaver
# Note: this actually doesn't really work on macOS with the modern touch id, but it's worth having for fallback/older devices
read -p "Do you want to enable YubiKey for screen unlock? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    update_pam_config "/etc/pam.d/screensaver"
fi

log_info ""
log_info "========================================="
log_info "YubiKey PAM setup complete!"
log_info "========================================="
log_info ""
log_info "To test, run: sudo echo 'testing'"
log_info "You should be prompted for your YubiKey PIN and touch."
log_info ""
log_info "Backups are stored with timestamp suffixes in /etc/pam.d/"
log_info "To restore: sudo cp /etc/pam.d/sudo.backup-YYYYMMDD-HHMMSS /etc/pam.d/sudo"
log_info ""
