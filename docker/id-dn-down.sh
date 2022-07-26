#!/bin/bash

echo "Stopping dev container..."
docker ps -q --filter "name=dotnet" | grep -q . && docker stop dotnet