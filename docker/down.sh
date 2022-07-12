#!/bin/bash

echo "Stoping dev container..."
docker ps -q --filter "name=phoenix" | grep -q . && docker stop phoenix

echo "Stoping postgres container..."
docker ps -q --filter "name=db" | grep -q . && docker stop db
