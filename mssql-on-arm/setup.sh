#!/bin/bash

# Define ANSI color code for red
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Ensure the script is run with sudo permissions
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or use sudo to execute this script.${NC}"
    exit 1
fi

# Ensure the script is running on an Apple Silicon machine
if [[ "$(uname -m)" != "arm64" ]]; then
    echo -e "${RED}❌ This script is only for Apple Silicon machines.${NC}"
    exit 1
else
    echo -e "${GREEN}Apple Silicon detected.${NC}"
fi

# Check if Docker is installed by looking for Docker.app in the /Applications directory
DOCKER_APP_PATH="/Applications/Docker.app"
REQUIRED_VERSION="4.27.2"

if [ ! -d "$DOCKER_APP_PATH" ]; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker.app from https://www.docker.com/products/docker-desktop before running this script.${NC}"
    exit 1
else
    echo -e "${GREEN}Docker detected.${NC}"
fi

# Check Docker version
DOCKER_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$DOCKER_APP_PATH/Contents/Info.plist")

if [ "$DOCKER_VERSION" != "$REQUIRED_VERSION" ]; then
    echo -e "${RED}❌ Docker version $DOCKER_VERSION is installed. Please install Docker version $REQUIRED_VERSION.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker version $REQUIRED_VERSION confirmed.${NC}"

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

# Create a databases folder in the user's home directory
DATABASES_HOME="$HOME/databases"
mkdir -p "$DATABASES_HOME"
export DATABASES_HOME
echo -e "${GREEN}Databases folder created at $DATABASES_HOME.${NC}"

# Install MSSQL via Docker
# Check if already isntalled
docker ps | grep -q sql2019
if [ $? -ne 0 ]; then
    echo "Creating MSSQL container..."
    docker run -e MSSQL_MEMORYLIMIT_MB=10240 \
               -e "ACCEPT_EULA=Y" \
               -e "MSSQL_SA_PASSWORD=$SA_PASSWORD" \
               -p 1433:1433 \
               -v "$DATABASES_HOME:/var/opt/mssql" \
               --name sql2019 \
               --hostname sql2019 \
               -d mcr.microsoft.com/mssql/server:2019-latest

    if [ $? -ne 0 ]; then
        echo -e "${RED}Docker run command failed.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Container setup${NC}"
fi

# Check if the container is running
docker ps | grep -q sql2019
if [ $? -ne 0 ]; then
    echo -e "${RED}MSSQL container did not start successfully.${NC}"
    exit 1
else
    echo -e "${GREEN}MSSQL container running!${NC}"
fi

echo -e "${GREEN}✅ Setup complete.${NC}"
