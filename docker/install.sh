#!/bin/bash

# Create dir to store scripts locally
echo "Creating ~/.iddeal-scripts folder..."
mkdir -p ~/.iddeal-scripts

# Download scripts locally
echo "Downloading elixir scripts to ~/.iddeal-scripts..."
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-ex-up.sh)
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-ex-down.sh)
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-ex-new.sh)

echo "Downloading dotnet scripts to ~/.iddeal-scripts..."
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-dn-up.sh)
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-dn-down.sh)
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-dn-new.sh)

# Make executable
echo "Setting permissions..."
(cd ~/.iddeal-scripts/ && chmod a+x id-ex-up.sh id-ex-down.sh id-ex-new.sh id-dn-up.sh id-dn-down.sh id-dn-new.sh)

# Prepare scripts so you don't have to type the extension
echo "Preparing scripts..."
mv ~/.iddeal-scripts/id-ex-up.sh ~/.iddeal-scripts/id-ex-up
mv ~/.iddeal-scripts/id-ex-down.sh ~/.iddeal-scripts/id-ex-down
mv ~/.iddeal-scripts/id-ex-new.sh ~/.iddeal-scripts/id-ex-new
mv ~/.iddeal-scripts/id-dn-up.sh ~/.iddeal-scripts/id-dn-up
mv ~/.iddeal-scripts/id-dn-down.sh ~/.iddeal-scripts/id-dn-down
mv ~/.iddeal-scripts/id-dn-new.sh ~/.iddeal-scripts/id-dn-new

echo "Adding scripts to your path"
touch ~/.zprofile
grep -qF 'iddeal-scripts' ~/.zprofile || echo 'export PATH=~/.iddeal-scripts/:$PATH' >> ~/.zprofile


echo -e "\033[1;33m Please reload your shell to pickup changes to PATH.\033[0m"
echo -e "\033[0;32m Install complete.\033[0m"
