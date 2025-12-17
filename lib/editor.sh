configure_editor() {
  # configure Antigravity as EDITOR in ~/.zshrc
  if ! grep -q "export EDITOR" "$ZSHRC_FILE"
  then
    echo "export EDITOR=\"agy --wait\"" >> "$ZSHRC_FILE"
    echo -e "${GREEN}Configured Antigravity as EDITOR in $ZSHRC_FILE${NC}"
  fi

  # verify duti is installed
  ANTIGRAVITY_BUNDLE_ID=$(mdls -name kMDItemCFBundleIdentifier -r /Applications/Antigravity.app)

  if ! command -v duti &> /dev/null
  then
    brew install duti
    echo -e "${GREEN}Installed duti${NC}"
    RESTART_REQUIRED=true
  fi

  FORMATS=(
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

  for format in "${FORMATS[@]}"
  do
    if ! duti -s "$ANTIGRAVITY_BUNDLE_ID" "$format" all
    then
      duti -s "$ANTIGRAVITY_BUNDLE_ID" "$format" all
      echo -e "${GREEN}Configured Antigravity as default editor for $format files${NC}"
    fi
  done
}
