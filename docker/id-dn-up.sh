#!/bin/bash

# Start dev container
echo "Starting dev container..."
docker run -d \
       -p 8000:8000 \
       -v $(pwd):/$(basename $PWD) \
       -w /$(basename $PWD) \
       -e ASPNETCORE_URLS=http://+:8000 \
       -e ASPNETCORE_ENVIRONMENT=Development \
       --name dotnet \
       --rm \
       iddmichael/dotnet6.0-dev:1
