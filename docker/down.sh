#!/bin/bash

echo "Stopping dev container..."
docker ps -q --filter "name=phoenix" | grep -q . && docker stop phoenix

echo "Stopping postgres container..."
docker ps -q --filter "name=db" | grep -q . && docker stop db
