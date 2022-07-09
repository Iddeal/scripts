#!/bin/bash

# Create code folder at ~/dev
if [ -d ~/dev ]; then
  echo "~/.dev already exists...skipping create."
else
  echo "Creating ~/.dev code folder..."
  mkdir -p ~/dev
fi

# Clean existing installation
if [ -d ~/.dat ]; then
  read -p "Existing installation found. Replace it? [Yn]" -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
      echo
      echo "Nuking the existing installation..."
      rm -rf ~/.dat
  else
    echo
    echo "Install aborted."
    exit 1
  fi
fi

# Clone the repo
echo "Cloning into ~/.dat"
git clone -q git@github.com:Iddeal/docker-at-iddeal.git ~/.dat

# Symlink to ~/dev
echo "Symlinking to ~/dev/docker-compose.yml"
ln -sf ~/.dat/docker-compose.yml ~/dev/docker-compose.yml

# Create alias 
echo "Creating dev-up alias"
alias dev-up="docker-compose run phoenix bash"
grep -qxF 'alias dev-up="docker-compose run phoenix bash"' ~/.zprofile || echo 'alias dev-up="docker-compose run phoenix bash"' >> ~/.zprofile

echo "Install complete."
