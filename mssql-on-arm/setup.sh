#!/usr/bin/env bash

# Define ANSI color codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "🚀 ${GREEN}Starting setup for MSSQL on Apple Silicon...${NC}"

#################
# Rosetta Check #
#################

echo -e "🔎 ${GREEN}Checking for rosetta...${NC}"

if /usr/bin/pgrep oahd &>/dev/null; then
  echo "✅ ${GREEN}Rosetta is already installed.${NC}"
else
  echo "🛠️ ${YELLOW}Installing Rosetta...${NC}"
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

#########################
# Database folder check #
#########################

echo -e "🔎 ${GREEN}Checking for databases folder...${NC}"

# Create a databases folder in the user's home directory (must run before SUDO)
DATABASES_HOME="$HOME/databases"
mkdir -p "$DATABASES_HOME"
export DATABASES_HOME
echo -e "✅ ${GREEN}Databases exists at $DATABASES_HOME.${NC}"

#######################
# Apple Silicon check #
#######################

echo -e "🔎 ${GREEN}Checking for Apple Silicon...${NC}"

# Ensure the script is running on an Apple Silicon machine
if [[ "$(uname -m)" != "arm64" ]]; then
    echo -e "❌ ${RED}This script is only for Apple Silicon machines.${NC}"
    exit 1
else
    echo -e "✅ ${GREEN}Apple Silicon detected.${NC}"
fi

##################
# Homebrew check #
##################

echo -e "🔎 ${GREEN}Checking for Homebrew...${NC}"

if ! command -v brew &> /dev/null; then
    echo -e "🛠️ ${YELLOW}Installing Homebrew (Apple Silicon)...${NC}"

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        || { echo -e "❌ ${RED}Failed to install Homebrew.${NC}"; exit 1; }

    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Even if Homebrew is installed, ensure it’s on PATH for this Apple Silicon setup
    if [[ -d "/opt/homebrew/bin" && ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    fi
    echo -e "✅ ${GREEN}Homebrew already installed and in PATH.${NC}"
fi

# Always (re)init brew
eval "$(/opt/homebrew/bin/brew shellenv)"

#################
# Podman check  #
#################

echo -e "🔎 ${GREEN}Checking for Podman...${NC}"

if ! command -v podman &> /dev/null; then
    echo -e "🛠️ ${YELLOW}Installing Podman...${NC}"
    brew install podman || {
        echo -e "❌ ${RED}Failed to install Podman.${NC}"
        exit 1
    }
else
    echo -e "✅ ${GREEN}Podman already installed.${NC}"
fi

########################
# Podman Desktop check #
########################

echo -e "🔎 ${GREEN}Checking for Podman Desktop...${NC}"

# Checking via brew cask is straightforward:
if ! brew list --cask --versions podman-desktop &>/dev/null; then
    echo -e "🛠️ ${YELLOW}Installing Podman Desktop...${NC}"
    brew install --cask podman-desktop || {
        echo -e "❌ ${RED}Failed to install Podman Desktop.${NC}"
        exit 1
    }
else
    echo -e "✅ ${GREEN}Podman Desktop already installed.${NC}"
fi

##############################
# Initialize/Start Podman VM #
##############################

echo -e "🔎 ${GREEN}Checking for Podman machine...${NC}"

# Ensure Podman machine has been created
if ! podman machine list | grep -q '^podman-machine-default'; then
    echo -e "🛠️ ${YELLOW}Initializing default Podman machine...${NC}"
    podman machine init || {
        echo -e "❌ ${RED}Failed to initialize Podman machine.${NC}"
        exit 1
    }
else
    echo -e "✅ ${GREEN}Podman machine already exists.${NC}"
fi

# Ensure Podman machine is started.
if ! podman machine info | grep -q 'Running'; then
    echo -e "🛠️ ${YELLOW}Starting the Podman machine...${NC}"
    podman machine start || {
        echo -e "❌ ${RED}Failed to start Podman machine.${NC}"
        exit 1
    }
else
    echo -e "✅ ${GREEN}Podman machine is already running.${NC}"
fi

#####################
# Host files update #
#####################
function request_sudo() {
    sudo -v
    # Keep the sudo session alive
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

echo -e "🔎 ${GREEN}Checking host files...${NC}"

HOST_ENTRY="10.211.55.2 sql2019"
if ! grep -q "10.211.55.2" /etc/hosts; then
    echo -e "❓ ${YELLOW}Host entry not found.${NC}"
    echo -e ""
    echo -e "🖐 ${YELLOW}This script requires admin rights to modify the /etc/hosts.${NC}"
    echo -e "🔑 ${YELLOW}Please enter your macOS password to continue.${NC}"
    echo -e ""
    request_sudo
    sudo sh -c "echo '$HOST_ENTRY' >> /etc/hosts"
    if [ $? -eq 0 ]; then
        echo -e "✅ ${GREEN}Successfully added $HOST_ENTRY to /etc/hosts.${NC}"
    else
        echo -e "❌ ${RED}Failed to add $HOST_ENTRY to /etc/hosts.${NC}"
        exit 1
    fi
else
    echo -e "✅ ${GREEN}Host entry $HOST_ENTRY already exists in /etc/hosts.${NC}"
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
        echo -e "✅ ${GREEN}SA_PASSWORD is already set and valid. Using the existing value.${NC}"
    else
        echo -e "❌ ${YELLOW}SA_PASSWORD is set but contains invalid characters. Prompting for a new password...${NC}"
        unset SA_PASSWORD
    fi
fi

# Prompt for SA password, if needed
if [[ -z "$SA_PASSWORD" ]]; then
    while true; do
        echo "🔐 Enter SA password (Allowed special chars @, <, >):"
        read -s INPUT_SA_PASSWORD
        
        if is_valid_password "$INPUT_SA_PASSWORD"; then
            export SA_PASSWORD="$INPUT_SA_PASSWORD"
            echo -e "\n✅ ${GREEN}Password accepted.${NC}"
            break
        else
            echo -e "\n❌ ${RED}Password contains invalid special characters. Only @, <, and > are allowed. Please try again.${NC}"
        fi
    done
fi

# Update SA password ENV variable in .zshrc, if needed
ZSHRC_FILE="$HOME/.zshrc"

# If there's no line starting with export SA_PASSWORD=, add it.
if ! grep -q '^export SA_PASSWORD=' "$ZSHRC_FILE" 2>/dev/null; then
    echo "export SA_PASSWORD=\"$SA_PASSWORD\"" >> "$ZSHRC_FILE"
    echo -e "✅ ${GREEN}SA_PASSWORD added to $ZSHRC_FILE.${NC}"
else
    echo -e "✅ ${GREEN}SA_PASSWORD already defined in $ZSHRC_FILE.${NC}"
fi

##########################
# Create MSSQL container #
##########################

echo -e "🔎 ${GREEN}Creating MSSQL container...${NC}"

# Install MSSQL via Docker
# Check if already isntalled
if ! podman container exists sql2019 &> /dev/null; then
    echo -e "🛠️ ${YELLOW}Creating MSSQL container...${NC}"
    podman run -e MSSQL_MEMORYLIMIT_MB=10240 \
               -e "ACCEPT_EULA=Y" \
               -e "MSSQL_SA_PASSWORD=$SA_PASSWORD" \
               -p 1433:1433 \
               -v "$DATABASES_HOME:/var/opt/mssql" \
               --name sql2019 \
               --hostname sql2019 \
               -d mcr.microsoft.com/mssql/server:2019-latest

    if [ $? -ne 0 ]; then
        echo -e "❌ ${RED}Podman run command failed.${NC}"
        exit 1
    fi
else
    echo -e "✅ ${GREEN}Container already exists${NC}"
fi

# Check if the container is running
podman ps | grep -q sql2019
if [ $? -ne 0 ]; then
    echo -e "❌ ${RED}MSSQL container did not start successfully.${NC}"
    exit 1
else
    echo -e "✅ ${GREEN}MSSQL container running!${NC}"
    echo -e "✅ ${GREEN}Setup complete.${NC}"
fi

