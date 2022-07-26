#!/bin/bash

# Create a new container to run dotnet new inside
echo "Creating app using Dotnet container..."
docker run -v $(pwd):/app --rm --name="idx-gen-new-dotnet-temp" iddmichael/dotnet6.0-dev:1 dotnet new "$@"
echo -e "\033[0;32m Generated\033[0m"
