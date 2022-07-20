#!/bin/bash

# Create dir to store scripts locally
echo "Creating ~/.iddeal-scripts folder..."
mkdir -p ~/.iddeal-scripts

# Download scripts locally
echo "Downloading scripts to ~/.iddeal-scripts..."
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-up.sh)
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-down.sh)
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-new.sh)
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-install.sh)

# Make executable
echo "Setting permissions..."
(cd ~/.iddeal-scripts/ && chmod a+x id-up.sh id-down.sh id-new.sh id-install.sh)

# Prepare scripts so you don't have to type the extension
echo "Preparing scripts..."
mv ~/.iddeal-scripts/id-new.sh ~/.iddeal-scripts/id-new
mv ~/.iddeal-scripts/id-install.sh ~/.iddeal-scripts/id-install
mv ~/.iddeal-scripts/id-up.sh ~/.iddeal-scripts/id-up
mv ~/.iddeal-scripts/id-down.sh ~/.iddeal-scripts/id-down

echo "Adding scripts to your path"
touch ~/.zprofile
grep -qF 'iddeal-scripts' ~/.zprofile || echo 'export PATH=~/.iddeal-scripts/:$PATH' >> ~/.zprofile


echo -e "\033[1;33m Please reload your shell to pickup changes to PATH.\033[0m"
echo -e "\033[0;32m Install complete.\033[0m"
