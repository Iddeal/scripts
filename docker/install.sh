#!/bin/bash

# Download scripts into local folder
echo "Downloading scripts..."
curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/up.sh
curl -fsSLO https://raw.githubusercontent.com/Iddeal/scripts/master/docker/down.sh

# Set as executable
echo "Setting file permissions..."
chmod a+x up.sh down.sh

echo "Install complete."
