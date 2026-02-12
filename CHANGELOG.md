# Changelog

## [1.0.1](https://github.com/ghepting/dev-setup/compare/v1.0.0...v1.0.1) (2026-01-21)


### Bug Fixes

* ensure agy alias is setup for dists without it (dnf on fedora for example seems to only come with antigravity bin, unlike homebrew formula) ([f9d37b9](https://github.com/ghepting/dev-setup/commit/f9d37b9236bb0212a3adc71f2422745074f551a1))

## [1.0.0](https://github.com/ghepting/dev-setup/compare/v0.2.0...v1.0.0) (2026-01-20)


### ⚠ BREAKING CHANGES

* major cleanup and refactoring. removes ghostty & gdrive/rclone stuff for now (leaves gdrive brew install on mac only). adds yubikey configuration on osx

### Features

* adds 1password GUI installation support for fedora and arch ([ab8705b](https://github.com/ghepting/dev-setup/commit/ab8705b57c5a9b122834f2f0aae4cf6c92f3534a))
* adds automated setup for yubikey on OSX ([d4a781d](https://github.com/ghepting/dev-setup/commit/d4a781d94e804d0fdb323563f5a8951e23211384))
* adds dynamic git signing for environment context adapation (dev on mac os, linux, or ssh context) ([c01c9a8](https://github.com/ghepting/dev-setup/commit/c01c9a825a1afb10dca9b61c6586adfdb1b55765))
* adds recovery instructions if anything goes wrong with PAM sudo configuration, moves yubikey/pam tests into test/ dir ([7e7baa2](https://github.com/ghepting/dev-setup/commit/7e7baa2e79dc1bda085604bf6115998cf87885bd))
* adds step to optionally update .ruby-version to ruby.sh ([d94730b](https://github.com/ghepting/dev-setup/commit/d94730b925fb50f1e9db1176f3714d3e6139f801))
* major cleanup and refactoring. removes ghostty & gdrive/rclone stuff for now (leaves gdrive brew install on mac only). adds yubikey configuration on osx ([800a6bf](https://github.com/ghepting/dev-setup/commit/800a6bf4b0cb0da32a96071931f2f733355a6e36))
* refactors to create ~/.zshrc.dev that holds all of the dev-setup module stuff leaving the user's ~/.zshrc simply sourcing this for functionality ([24d205b](https://github.com/ghepting/dev-setup/commit/24d205b3d2f143ac6ad27e96c6a15ea4f90fdb40))
* use new dotfiles git repo in favor of gdrive for dotfiles management ([3595af3](https://github.com/ghepting/dev-setup/commit/3595af3c6ccebc1774590f423678ee278ecc42b5))


### Bug Fixes

* adds ephemeral ~/.local/bin to PATH for claude CLI installation to remove noisy warnings (we ensure this is in the path in ~/.zshrc.dev that gets sourced) ([83893be](https://github.com/ghepting/dev-setup/commit/83893be6606ff7702162772911e51154b803315f))
* adds mac-os check for tmux user namespace attachment (not needed on linux) ([b947995](https://github.com/ghepting/dev-setup/commit/b9479953c16e9637a0269c272d710294aa51a905))
* fine tuning output (color, messaging) ([010f40f](https://github.com/ghepting/dev-setup/commit/010f40fe3285802405e39f54a71c177a28d60499))
* fix output issues and formatting after prompts ([8b7626e](https://github.com/ghepting/dev-setup/commit/8b7626ea4318042fa20bd5be9829cc366a06b346))
* git script path output ([23aa088](https://github.com/ghepting/dev-setup/commit/23aa0883aff78729eef7faa78a72fc6a3a58996c))
* removes non-functioning macos integration tests ([fbb01d7](https://github.com/ghepting/dev-setup/commit/fbb01d762b159879d013515e8a4d53d371e232f7))
* removes non-functioning macos integration tests ([d3cdd81](https://github.com/ghepting/dev-setup/commit/d3cdd81e8e0cf79689a3f899234105bdbaa86b5e))

## [0.2.0](https://github.com/ghepting/dev-setup/compare/v0.1.0...v0.2.0) (2026-01-11)


### Features

* adds pre-commit checks and bin/bootstrap for repo contributors ([28a09c2](https://github.com/ghepting/dev-setup/commit/28a09c2d13997ef75e8fcb3a77fc9da6e6718f7a))
* defaults to N for modify config promt ([3e7edfb](https://github.com/ghepting/dev-setup/commit/3e7edfb343d0e4363f19e4bcd980e33beed5d206))
* splits 1password, op (1password CLI) and 1password ssh configuration into separate options for better server environment support (op + ssh only, no GUI) ([dfff187](https://github.com/ghepting/dev-setup/commit/dfff18773e53e76337afd4a8c8934b52520fe763))
* use official docker-ce repositories and package suite for debian/fedora (arch/macos already use these by default) ([f1f6c3f](https://github.com/ghepting/dev-setup/commit/f1f6c3f3144008988c5a59f8dc92324e7002058c))
