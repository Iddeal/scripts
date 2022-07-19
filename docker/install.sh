#!/bin/bash

# Create dir to store scripts locally
echo "Creating ~/.iddeal-scripts folder..."
mkdir -p ~/.iddeal-scripts

# Download scripts locally
echo "Downloading scripts to ~/.iddeal-scripts..."
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/up.sh)
(cd ~/.iddeal-scripts/ && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/down.sh)


# Download scripts
echo "Downloading new and install scripts to ~/dev..."
(cd ~/dev && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-new.sh && chmod a+x id-new.sh)
(cd ~/dev && curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/id-install.sh && chmod a+x id-install.sh)

echo "Install complete."
