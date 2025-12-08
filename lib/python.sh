install_python_and_pip() {
  # install python/pip3
  PYTHON_EXECUTABLE="$(brew --prefix)/bin/python3"
  if ! command -v $PYTHON_EXECUTABLE &> /dev/null
  then
    echo -e "${WHITE}Installing python...${NC}"
    if brew install python -q &> /dev/null
    then
      echo -e "${GREEN}Successfully installed python${NC}"
      RESTART_REQUIRED=true
    else
      echo -e "${RED}Failed to install python${NC}"
      exit 1
    fi
  else
    PYTHON_VERSION=$($PYTHON_EXECUTABLE -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')")
    PIP_VERSION=$($PYTHON_EXECUTABLE -c "import pip; print(pip.__version__)")
    echo -e "${BLUE}Using python $PYTHON_VERSION / pip $PIP_VERSION${NC}"
  fi
}
