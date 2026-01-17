configure_editor() {
  local preferred_editor="agy --wait"

  if is_debian || is_ssh; then
    preferred_editor="vim"
  fi

  # configure default EDITOR in ~/.zshrc
  if ! grep -q "export EDITOR" "$ZSHRC_FILE"; then
    echo "export EDITOR=\"$preferred_editor\"" >>"$ZSHRC_FILE"
    log_success "Configured $preferred_editor as EDITOR in $ZSHRC_FILE"
  fi

  # macOS-specific file associations
  if is_macos; then
    if ! check_app "Antigravity"; then
      log_info "Antigravity not found, skipping file associations"
      return
    fi

    # verify duti is installed
    ANTIGRAVITY_BUNDLE_ID=$(mdls -name kMDItemCFBundleIdentifier -r /Applications/Antigravity.app 2>/dev/null || echo "com.google.Antigravity")

    if ! command -v duti &>/dev/null; then
      brew install duti
      log_success "Installed duti"
      RESTART_REQUIRED=true
    fi

    local FORMATS=(
      public.json
      public.plain-text
      public.python-script
      public.shell-script
      public.source-code
      public.text
      public.unix-executable
      public.data
      public.xml
      .c
      .cpp
      .cs
      .css
      .sass
      .scss
      .less
      .go
      .java
      .js
      .jsx
      .json
      .log
      .md
      .php
      .pl
      .py
      .rb
      .ts
      .tsx
      .txt
      .conf
      .yaml
      .yml
      .toml
      .env
      .envrc
      .env.local
      .env.development
      .env.test
      .env.production
      .nvmrc
      .ruby-version
      .zshrc
      .zprofile
      .zlogin
      .zlogout
      .zshenv
      .zshrc.local
      .xml
      .svg
      .gql
      .graphql
      .vue
      .svelte
      .ini
      .csv
      .sql
      .gitignore
      .gitconfig
      .gitmodules
      .editorconfig
      .properties
      .dockerfile
      .dockerignore
      .bash
      .bat
      .sh
      .ps1
      .rs
      .swift
      .kt
      .kts
      .r
      .dart
      .lua
      .cmake
      .rake
      .builder
      .gemspec
      .lock
      .ru
      .tf
      .tfvars
      .hcl
      .mk
      .gradle
      .m
      .mm
      .ex
      .exs
      .hs
      .clj
      .cljs
      .scala
      .sol
      .proto
      .xsd
      .dtd
      .astro
      .prisma
    )

    for format in "${FORMATS[@]}"; do
      if ! duti -s "$ANTIGRAVITY_BUNDLE_ID" "$format" all; then
        duti -s "$ANTIGRAVITY_BUNDLE_ID" "$format" all
        log_success "Configured Antigravity as default editor for $format files"
      fi
    done
  fi
}

install_antigravity_extensions() {
  local extensions_file="${DOTFILES_DIR}/.antigravity/extensions.txt"

  if [ ! -f "$extensions_file" ]; then
    log_info "Antigravity extensions list not found in dotfiles repository, skipping installation."
    return
  fi

  log_info "Installing Antigravity extensions..."

  local installed_extensions
  installed_extensions=$(agy --list-extensions 2>/dev/null)

  while read -r extension; do
    if [ -z "$extension" ]; then
      continue
    fi

    if echo "$installed_extensions" | grep -qi "^$extension$"; then
      log_status "Using $extension"
    else
      log_status "Installing $extension"
      agy --install-extension "$extension" &>/dev/null
      log_success "Installed $extension"
    fi
  done <"$extensions_file"
}

update_antigravity_extensions_list() {
  local extensions_file="${DOTFILES_DIR}/.antigravity/extensions.txt"

  log_info "Updating Antigravity extensions list in dotfiles repository..."

  # Ensure the directory exists
  mkdir -p "$(dirname "$extensions_file")"

  # Redirect stderr to /dev/null because agy is currently emitting V8 fatal errors
  # but still successfully printing the list to stdout.
  agy --list-extensions >"$extensions_file" 2>/dev/null

  # Verify if updates were actually written (checking file size)
  if [[ -s "$extensions_file" ]]; then
    log_success "Extensions list updated: $(wc -l <"$extensions_file" | xargs) extensions saved."
  else
    log_error "Failed to update extensions list (file is empty)."
  fi
}
