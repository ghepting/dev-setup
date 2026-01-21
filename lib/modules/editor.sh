configure_editor() {
  preferred_editor="vim"

  # configure vim as EDITOR in ~/.zshrc.dev
  install_zsh_config "editor"
  # configure agy bin PATH or alias in ~/.zshrc.dev
  install_zsh_config "agy"
  ensure_zshrc_dev_sourced

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
