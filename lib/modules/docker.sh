#!/usr/bin/env zsh

setup_docker() {
  # check if docker is installed/running
  if ! command -v docker &> /dev/null; then
    if is_macos; then
      echo -e "${YELLOW}Installing Docker Desktop...${NC}"
      brew install --cask docker
    elif is_linux; then
      echo -e "${YELLOW}Installing Docker...${NC}"
      if is_debian; then
        echo -e "${YELLOW}Setting up Docker CE repository for Debian...${NC}"
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        local codename
        codename=$(grep VERSION_CODENAME /etc/os-release 2> /dev/null | cut -d= -f2 | tr -d '"')
        codename=${codename:-$(lsb_release -cs 2> /dev/null || echo "stable")}

        echo "deb [arch=$(dpkg --print-architecture 2> /dev/null || echo "amd64") signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $codename stable" |
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
        install_pkg "docker-ce"
        install_pkg "docker-ce-cli"
        install_pkg "containerd.io"
        install_pkg "docker-buildx-plugin"
        install_pkg "docker-compose-plugin"
      elif is_arch; then
        install_pkg "docker"
        install_pkg "docker-compose"
      elif is_fedora; then
        echo -e "${YELLOW}Setting up Docker CE repository for Fedora...${NC}"
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

        install_pkg "docker-ce"
        install_pkg "docker-ce-cli"
        install_pkg "containerd.io"
        install_pkg "docker-buildx-plugin"
        install_pkg "docker-compose-plugin"
      fi
      sudo usermod -aG docker "$(whoami)"
      echo -e "${YELLOW}Note: You may need to logout and login for docker group changes to take effect.${NC}"
    fi
  fi

  if is_macos; then
    echo -e "${BLUE}Using $(docker --version)${NC}"
    echo -e "${BLUE}Using $(docker compose version)${NC}"

    # run command "docker info" and grep for "failed to connect to the docker API"
    if ! docker info &> /dev/null; then
      echo -e "${YELLOW}Starting Docker daemon...${NC}"
      open /Applications/Docker.app
      read "?Press [Enter] after logging in to Docker..."
    fi
  elif is_linux; then
    # Only try to start via systemctl if systemd is running (not in a container)
    if [ -d /run/systemd/system ]; then
      sudo systemctl start docker
    fi
    echo -e "${BLUE}Using $(docker --version)${NC}"
  fi
}
