#!/bin/bash

# Create a new container to run mix phx.new inside
docker run -v $(pwd):/app --rm --name="idx-gen-new-phx-temp" iddmichael/phx1.6.10-elixir1.13.4-erlang-25.0.2-dev:2 yes | mix phx.new $1 && docker stop idx-gen-new-phx-temp
