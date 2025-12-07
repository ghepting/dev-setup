#!/usr/bin/env zsh

# --- Function to log messages ---
log() {
  echo -e "\n\033[1;34m>>> $1\033[0m" # Blue color
}

# --- Configuration ---
PACKAGE_FILE="package.json"

# --- Check for file existence ---
if [ ! -f "$PACKAGE_FILE" ]; then
  echo -e "\033[1;31mError: $PACKAGE_FILE not found.\033[0m" # Red color
  exit 1
fi

log "Starting global npm package installation from $PACKAGE_FILE..."

# Ensure Homebrew is available (common prerequisite on macOS/zsh)
if ! command -v brew &> /dev/null; then
    echo -e "\033[1;31mError: Homebrew is not installed. Please install Homebrew to proceed.\033[0m"
    exit 1
fi

# Install/update npm and jq via Homebrew
if ! brew install npm jq; then
    echo -e "\033[1;31mError: Failed to install or update npm and jq via Homebrew. Exiting.\033[0m"
    exit 1
fi

NPM_EXECUTABLE="`brew --prefix`/bin/npm"
NPM_GLOBAL_ARGS=(install -g --no-audit --no-fund --loglevel=error)
JQ_EXECUTABLE="`brew --prefix`/bin/jq"

# 1. Use 'jq' to extract the keys (package names) from the 'dependencies' object.
#    .dependencies: targets the object
#    | keys_as_strings: extracts the keys (package names) as an array of strings
#    | .[]: expands the array into separate lines/items
#
#    Note: 'jq' is the preferred tool for JSON processing in bash.
#
DEPENDENCIES=$($JQ_EXECUTABLE -r '.dependencies | keys | .[]' "$PACKAGE_FILE")

# Check if any dependencies were found
if [ -z "$DEPENDENCIES" ]; then
  log "No dependencies found in the 'dependencies' section. Exiting."
  exit 0
fi

# 2. Loop through each dependency name
for PACKAGE_NAME in $DEPENDENCIES; do
  log "Processing package: $PACKAGE_NAME"

  # 3. Get the specific version string for the current package
  #    .dependencies[<PACKAGE_NAME>]: safely retrieves the version string
  #    | @json: ensures the output is properly escaped JSON (removing quotes)
  #
  #    The version output includes the quotes, e.g., "0.19.4"
  #    We remove the surrounding quotes using 'sed'
  VERSION_STRING=$($JQ_EXECUTABLE -r ".dependencies[\"$PACKAGE_NAME\"] | @json" "$PACKAGE_FILE" | sed 's/^"//;s/"$//')

  if [ -z "$VERSION_STRING" ]; then
    echo -e "\033[0;33mWarning: Could not find version for $PACKAGE_NAME. Skipping.\033[0m" # Yellow color
    continue
  fi

  # 4. Construct the package@version string
  INSTALL_TARGET="${PACKAGE_NAME}@${VERSION_STRING}"
  
  log "Installing $INSTALL_TARGET..."

  # 5. Execute the installation command
  if $NPM_EXECUTABLE $NPM_GLOBAL_ARGS "$INSTALL_TARGET"; then
    echo -e "\033[0;32mSuccessfully installed $INSTALL_TARGET\033[0m" # Green color
  else
    echo -e "\033[1;31mFailed to install $INSTALL_TARGET. Check the error above.\033[0m" # Red color
  fi

done

log "Global npm installation complete."
