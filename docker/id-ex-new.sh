#!/bin/bash

# Create a new container to run mix phx.new inside
echo "Creating app using Phoenix container..."
docker run -v $(pwd):/app --rm --name="idx-gen-new-phx-temp" iddmichael/phx1.6.10-elixir1.13.4-erlang-25.0.2-dev:2 yes | mix phx.new "$@"
docker stop idx-gen-new-phx-temp

echo -e "\033[0;32m Generated $1.\033[0m"
