#!/usr/bin/env bash

# Define ANSI color code for red
YELLOW='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "🍎 ${GREEN}Starting setup for Apple Silicon environment...${NC}"

#####################
# 0. Homebrew Check #
#####################

# Create a databases folder in the user's home directory (must run before SUDO)
DATABASES_HOME="$HOME/databases"
mkdir -p "$DATABASES_HOME"
export DATABASES_HOME
echo -e "📁 ${GREEN}Databases folder created at $DATABASES_HOME.${NC}"

# Ensure the script is running on an Apple Silicon machine
if [[ "$(uname -m)" != "arm64" ]]; then
    echo -e "${RED}❌ This script is only for Apple Silicon machines.${NC}"
    exit 1
else
    echo -e "${GREEN}Apple Silicon detected.${NC}"
fi

#####################
# 1. Homebrew Check #
#####################

if ! command -v brew &> /dev/null; then
    echo -e "${GREEN}Homebrew not found. Installing Homebrew (Apple Silicon)...${NC}"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        || { echo -e "${RED}Failed to install Homebrew.${NC}"; exit 1; }

    # For Apple Silicon, Homebrew installs to /opt/homebrew by default.
    # We need to ensure it’s in our PATH immediately.
    echo -e "${GREEN}Adding Homebrew to current shell environment...${NC}"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Even if Homebrew is installed, ensure it’s on PATH for this Apple Silicon setup
    if [[ -d "/opt/homebrew/bin" && ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo -e "${GREEN}Homebrew already installed and in PATH.${NC}"
fi

####################
# 2. Podman Check  #
####################

if ! command -v podman &> /dev/null; then
    echo -e "${GREEN}Podman not found. Installing Podman...${NC}"
    brew install podman || {
        echo -e "${RED}Failed to install Podman.${NC}"
        exit 1
    }
else
    echo -e "${GREEN}Podman already installed.${NC}"
fi

########################
# 3. Podman Desktop Check #
########################

# Checking via brew cask is straightforward:
if ! brew list --cask --versions podman-desktop &>/dev/null; then
    echo -e "${GREEN}Podman Desktop not found. Installing Podman Desktop...${NC}"
    brew install --cask podman-desktop || {
        echo -e "${RED}Failed to install Podman Desktop.${NC}"
        exit 1
    }
else
    echo -e "${GREEN}Podman Desktop already installed.${NC}"
fi

################################
# 4. Initialize/Start Podman VM #
################################

# Ensure Podman machine is initialized and started.
if ! podman machine list | grep -q 'Running'; then
    echo -e "${GREEN}Initializing and/or starting Podman machine...${NC}"
    podman machine init || {
        echo -e "${RED}Failed to initialize Podman machine.${NC}"
        exit 1
    }
    podman machine start || {
        echo -e "${RED}Failed to start Podman machine.${NC}"
        exit 1
    }
else
    echo -e "${GREEN}Podman machine is already running.${NC}"
fi

echo ""
echo "This script modifies the /etc/hosts file and requires admin permissions."
echo -e "${YELLOW}Please enter your macOS password to continue.${NC}"
echo ""

request_sudo

# Check if the entry already exists in /etc/hosts
HOST_ENTRY="10.211.55.2 sql2019"
if ! grep -q "10.211.55.2" /etc/hosts; then
    sudo sh -c "echo '$HOST_ENTRY' >> /etc/hosts"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successfully added $HOST_ENTRY to /etc/hosts.${NC}"
    else
        echo -e "${RED}Failed to add $HOST_ENTRY to /etc/hosts.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Host entry $HOST_ENTRY already exists in /etc/hosts.${NC}"
fi

# Function to check if the password is valid
is_valid_password() {
    local password="$1"
    if [[ "$password" =~ ^[a-zA-Z0-9@\<\>]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Prompt the user for a password
while true; do
    echo "Enter SA password (Allowed special chars @, <, >):"
    read -s SA_PASSWORD
    
    if is_valid_password "$SA_PASSWORD"; then
        export SA_PASSWORD
        echo -e "${GREEN}Password accepted.${NC}"
        break
    else
        echo -e "${RED}❌ Password contains invalid special characters. Only @, <, and > are allowed. Please try again.${NC}"
    fi
done

# Install MSSQL via Docker
# Check if already isntalled
if ! podman container exists sql2019 &> /dev/null; then
    echo "Creating MSSQL container..."
    podman run -e MSSQL_MEMORYLIMIT_MB=10240 \
               -e "ACCEPT_EULA=Y" \
               -e "MSSQL_SA_PASSWORD=$SA_PASSWORD" \
               -p 1433:1433 \
               -v "$DATABASES_HOME:/var/opt/mssql" \
               --name sql2019 \
               --hostname sql2019 \
               -d mcr.microsoft.com/mssql/server:2019-latest

    if [ $? -ne 0 ]; then
        echo -e "${RED}Podman run command failed.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Container setup${NC}"
fi

# Check if the container is running
podman ps | grep -q sql2019
if [ $? -ne 0 ]; then
    echo -e "${RED}MSSQL container did not start successfully.${NC}"
    exit 1
else
    echo -e "${GREEN}MSSQL container running!${NC}"
fi

echo -e "${GREEN}✅ Setup complete.${NC}"
