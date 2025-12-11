setup_docker() {
  # check if docker is installed/running
  if ! command -v docker &> /dev/null
  then
    echo -e "${YELLOW}Installing Docker...${NC}"
    brew install --cask docker
  fi

  # run command "docker info" and grep for "failed to connect to the docker API"
  if ! docker info &> /dev/null
  then
    echo -e "${YELLOW}Starting Docker daemon...${NC}"
    open /Applications/Docker.app
    read "?Press [Enter] after logging in to Docker..."
  fi
}
