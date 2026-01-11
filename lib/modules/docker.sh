#!/usr/bin/env zsh

setup_docker() {
  # check if docker is installed/running
  if ! command -v docker &> /dev/null
  then
    if is_macos; then
      echo -e "${YELLOW}Installing Docker Desktop...${NC}"
      brew install --cask docker
    elif is_linux; then
      echo -e "${YELLOW}Installing Docker...${NC}"
      if is_debian; then
        install_pkg "docker.io"
        install_pkg "docker-compose"
      elif is_arch; then
        install_pkg "docker"
        install_pkg "docker-compose"
      elif is_fedora; then
        install_pkg "docker"
        # docker-compose is usually a separate package or part of docker-ce
      fi
      sudo usermod -aG docker "$(whoami)"
      echo -e "${YELLOW}Note: You may need to logout and login for docker group changes to take effect.${NC}"
    fi
  fi

  if is_macos; then
    echo -e "${BLUE}Using $(docker --version)${NC}"
    echo -e "${BLUE}Using $(docker compose version)${NC}"

    # run command "docker info" and grep for "failed to connect to the docker API"
    if ! docker info &> /dev/null
    then
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
