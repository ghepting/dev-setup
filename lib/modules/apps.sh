#!/usr/bin/env zsh

install_optional_apps() {
  if is_macos; then
    if is_enabled "google_chrome"; then
      echo -e "${WHITE}Installing Google Chrome...${NC}"
      brew bundle --file=lib/packages/chrome/Brewfile -q
    fi

    if is_enabled "slack"; then
      echo -e "${WHITE}Installing Slack...${NC}"
      brew bundle --file=lib/packages/slack/Brewfile -q
    fi

    if is_enabled "linear"; then
      echo -e "${WHITE}Installing Linear...${NC}"
      brew bundle --file=lib/packages/linear/Brewfile -q
    fi

    if is_enabled "ngrok"; then
      echo -e "${WHITE}Installing Ngrok...${NC}"
      brew bundle --file=lib/packages/ngrok/Brewfile -q
    fi

    if is_enabled "fonts"; then
      echo -e "${WHITE}Installing Fonts (JetBrains Mono)...${NC}"
      brew bundle --file=lib/packages/fonts/Brewfile -q
    fi
  elif is_linux; then
      if is_enabled "google_chrome"; then
        if is_debian; then
          echo -e "${WHITE}Installing Google Chrome for Debian...${NC}"
          if ! command -v google-chrome &> /dev/null; then
             wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome.deb
             sudo apt-get update && sudo apt-get install -y /tmp/google-chrome.deb
             rm /tmp/google-chrome.deb
          else
             echo -e "${BLUE}Google Chrome already installed${NC}"
          fi
        elif is_fedora; then
          echo -e "${WHITE}Installing Google Chrome for Fedora...${NC}"
          if ! command -v google-chrome &> /dev/null; then
             sudo dnf install -y fedora-workstation-repositories
             sudo dnf config-manager --set-enabled google-chrome
             install_pkg "google-chrome-stable"
          else
             echo -e "${BLUE}Google Chrome already installed${NC}"
          fi
        else
          echo -e "${YELLOW}Google Chrome installation not supported on this distro.${NC}"
        fi
      fi

      if is_enabled "slack"; then
        if is_debian; then
           echo -e "${WHITE}Installing Slack for Debian...${NC}"
           # Dynamic versioning is hard, manual download link for now or snap?
           # Using Snap is easiest for Slack on Linux if snapd is there, but let's assume no snap for now and warn
           echo -e "${YELLOW}Please install Slack manually from https://slack.com/downloads/linux${NC}"
        elif is_fedora; then
           echo -e "${WHITE}Installing Slack for Fedora...${NC}"
           echo -e "${YELLOW}Please install Slack manually from https://slack.com/downloads/linux${NC}"
        fi
      fi

      if is_enabled "ngrok"; then
         echo -e "${WHITE}Installing Ngrok for Linux...${NC}"
         if is_debian; then
            if ! command -v ngrok &> /dev/null; then
               curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
               echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
               sudo apt-get update && sudo apt-get install -y ngrok
            fi
         elif is_fedora; then
            if ! command -v ngrok &> /dev/null; then
               sudo dnf config-manager --add-repo https://ngrok-agent.s3.amazonaws.com/ngrok.repo
               sudo dnf install -y ngrok
            fi
         elif is_arch; then
            install_pkg "ngrok" # usually in AUR, but maybe community? If not, user might need yay.
            # Fallback to manual? Arch users usually handle AUR.
            echo -e "${YELLOW}Ngrok on Arch: If not in community repos, please install via AUR (e.g., 'yay -S ngrok').${NC}"
         fi
      fi

      if is_enabled "linear"; then
        echo -e "${YELLOW}Linear is not officially supported on Linux package managers.${NC}"
        echo -e "${YELLOW}Please use the Web App or check for AppImage/Snap community packages.${NC}"
      fi
  fi
}
