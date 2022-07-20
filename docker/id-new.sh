#!/bin/bash

# Create a new container to run mix phx.new inside
echo "Creating app using Phoenix container..."
docker run -v $(pwd):/app --rm --name="idx-gen-new-phx-temp" iddmichael/phx1.6.10-elixir1.13.4-erlang-25.0.2-dev:2 yes | mix phx.new $1 && docker stop idx-gen-new-phx-temp

# Install the up.sh and down.sh scripts into the specified folder
(cd $1 && cp ~/.iddeal-scripts/up.sh . && chmod a+x up.sh)
(cd $1 && cp ~/.iddeal-scripts/down.sh . && chmod a+x down.sh)

echo "Scripts installed to $1."
