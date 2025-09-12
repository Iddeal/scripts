#!/usr/bin/env bash

# Define ANSI color codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "🚀 ${GREEN}Starting setup for MSSQL on Apple Silicon with Docker...${NC}"

#################
# Rosetta Check #
#################

echo -e "🔎 Checking for Rosetta..."

if /usr/bin/pgrep oahd &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Rosetta is already installed."
else
  echo -e "  ${YELLOW}✦${NC} Installing Rosetta..."
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license
  if [ $? -ne 0 ]; then
    echo -e "❌ ${RED}Failed to install Rosetta.${NC}"
    exit 1
  fi
fi

#########################
# Database folder check #
#########################

echo -e "🔎 Checking for databases folder..."

# Create a databases folder in the user's home directory
DATABASES_HOME="$HOME/databases"
mkdir -p "$DATABASES_HOME"
export DATABASES_HOME
echo -e "  ${GREEN}✓${NC} Databases exists at $DATABASES_HOME."

#######################
# Apple Silicon check #
#######################

echo -e "🔎 Checking for Apple Silicon..."

# Ensure the script is running on an Apple Silicon machine
if [[ "$(uname -m)" != "arm64" ]]; then
    echo -e "  ❌ ${RED}This script is only for Apple Silicon machines.${NC}"
    exit 1
else
    echo -e "  ${GREEN}✓${NC} Apple Silicon detected."
fi

##################
# Homebrew check #
##################

echo -e "🔎 Checking for Homebrew..."

if ! command -v brew &> /dev/null; then
    echo -e "  ${YELLOW}✦${NC} Installing Homebrew (Apple Silicon)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ $? -ne 0 ]; then
      echo -e "❌ ${RED}Failed to install Homebrew.${NC}"
      exit 1
    fi
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Ensure Homebrew is on PATH for Apple Silicon
    if [[ -d "/opt/homebrew/bin" && ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    fi
    echo -e "  ${GREEN}✓${NC} Homebrew already installed and in PATH."
fi

# Always (re)init brew
eval "$(/opt/homebrew/bin/brew shellenv)"

########################
# Docker Desktop check #
########################

echo -e "🔎 Checking for Docker Desktop..."

if ! brew list --cask --versions docker &>/dev/null; then
    echo -e "  ${YELLOW}✦${NC} Installing Docker Desktop..."
    brew install --cask docker
    if [ $? -ne 0 ]; then
      echo -e "❌ ${RED}Failed to install Docker Desktop.${NC}"
      exit 1
    fi
    sleep 5 # Wait for Docker Desktop to start
    echo -e "  ${GREEN}✓${NC} Docker Desktop installed."
else
    echo -e "  ${YELLOW}✦${NC} Updating Docker Desktop..."
    brew upgrade --cask docker
    if [ $? -ne 0 ]; then
      echo -e "❌ ${RED}Failed to update Docker Desktop.${NC}"
      exit 1
    fi
    sleep 5 # Wait for Docker Desktop to start
    echo -e "  ${GREEN}✓${NC} Docker Desktop updated."
fi

############################
# Ensure Docker is Running #
############################

echo -e "🔎 Ensuring Docker Desktop is running..."

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "  ${YELLOW}✦${NC} Starting Docker Desktop..."
    open /Applications/Docker.app
    if [ $? -ne 0 ]; then
      echo -e "❌ ${RED}Failed to start Docker Desktop. Please open Docker Desktop manually.${NC}"
      exit 1
    fi
    # Wait for Docker Desktop to start (can take a moment)
    sleep 15
    if ! docker info &> /dev/null; then
      echo -e "❌ ${RED}Docker Desktop is not running. Please ensure it is started and try again.${NC}"
      exit 1
    fi
fi
echo -e "  ${GREEN}✓${NC} Docker Desktop is running."

#####################

#####################
# Host files update #
#####################

function request_sudo() {
    sudo -v
    # Keep the sudo session alive
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

echo -e "🔎 Checking host files..."

HOST_ENTRY="10.211.55.2 sql2019"
if ! grep -q "10.211.55.2" /etc/hosts; then
    echo -e "  ❓ ${YELLOW}Host entry not found.${NC}"
    echo -e ""
    echo -e "  🖐 ${YELLOW}This script requires admin rights to modify the /etc/hosts.${NC}"
    echo -e "  🔑 ${YELLOW}Please enter your macOS password to continue.${NC}"
    echo -e ""
    request_sudo
    sudo sh -c "echo '$HOST_ENTRY' >> /etc/hosts"
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} Successfully added $HOST_ENTRY to /etc/hosts."
    else
        echo -e "❌ ${RED}Failed to add $HOST_ENTRY to /etc/hosts.${NC}"
        exit 1
    fi
else
    echo -e "  ${GREEN}✓${NC} Host entry $HOST_ENTRY already exists in /etc/hosts."
fi

#######################
# Request SA password #
#######################

# Function to check if the SA password is valid
is_valid_password() {
    local password="$1"
    if [[ "$password" =~ ^[a-zA-Z0-9@\<\>]+$ ]]; then
        return 0
    else
        return 1
    fi
}

echo -e "🔎 ${GREEN}Checking for SA password...${NC}"

# Check for existing, valid SA password
if [[ -n "$SA_PASSWORD" ]]; then
    if is_valid_password "$SA_PASSWORD"; then
        echo -e "  ${GREEN}✓${NC} SA_PASSWORD is already set and valid. Using the existing value."
    else
        echo -e "  ❌ ${YELLOW}SA_PASSWORD is set but contains invalid characters. Prompting for a new password...${NC}"
        unset SA_PASSWORD
    fi
fi

# Prompt for SA password, if needed
if [[ -z "$SA_PASSWORD" ]]; then
    while true; do
        echo "  🔐 Enter SA password (Allowed special chars @, <, >):"
        read -s INPUT_SA_PASSWORD
        
        if is_valid_password "$INPUT_SA_PASSWORD"; then
            export SA_PASSWORD="$INPUT_SA_PASSWORD"
            echo -e "\n  ${GREEN}✓${NC} Password accepted."
            break
        else
            echo -e "\n  ❌ ${RED}Password contains invalid special characters. Only @, <, and > are allowed. Please try again.${NC}"
        fi
    done
fi

# Update SA password ENV variable in .zshrc, if needed
ZSHRC_FILE="$HOME/.zshrc"

# If there's no line starting with export SA_PASSWORD=, add it.
if ! grep -q '^export SA_PASSWORD=' "$ZSHRC_FILE" 2>/dev/null; then
    echo "export SA_PASSWORD=\"$SA_PASSWORD\"" >> "$ZSHRC_FILE"
    echo -e "  ${GREEN}✓${NC} SA_PASSWORD added to $ZSHRC_FILE."
else
    echo -e "  ${GREEN}✓${NC} SA_PASSWORD already defined in $ZSHRC_FILE."
fi

##########################
# Create MSSQL container #
##########################

echo -e "🔎 Checking for MSSQL container..."

# Install MSSQL via Docker
# Check if already installed
if ! docker container inspect sql2019 &> /dev/null; then
    echo -e "  ${YELLOW}✦${NC} Creating MSSQL container..."
    docker run --platform linux/amd64 \
               -e MSSQL_MEMORY_LIMIT_MB=10240 \
               -e "ACCEPT_EULA=Y" \
               -e "MSSQL_SA_PASSWORD=$SA_PASSWORD" \
               -p 1433:1433 \
               -v "$DATABASES_HOME:/var/opt/mssql" \
               --name sql2019 \
               --hostname sql2019 \
               -d mcr.microsoft.com/mssql/server:2019-latest

    if [ $? -ne 0 ]; then
        echo -e "❌ ${RED}Docker run command failed.${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}✓${NC} MSSQL container created."
else
    echo -e "  ${GREEN}✓${NC} Container already exists."
fi

# Check if the container is running
docker ps | grep -q sql2019
if [ $? -ne 0 ]; then
    echo -e "❌ ${RED}MSSQL container did not start successfully.${NC}"
    exit 1
else
    echo -e "  ${GREEN}✓${NC} MSSQL container running!"
    echo -e "✅ ${GREEN}Setup complete.${NC}"
fi