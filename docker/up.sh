#!/bin/bash

# Create ~/.db if needed
if [ -d ~/.db ]; then
  echo "~/..db already exists...skipping create."
else
  echo "Creating ~/.db database folder..."
  mkdir -p ~/.db
fi

# Create the local dev network
echo "Creating iddev network..."
docker network inspect iddev --format {{.Id}} 2>/dev/null || docker network create --driver bridge iddev

# Start postgres container
echo "Starting postgres container..."
docker run -d \
       -p 5432:5432 \
       -v ~/.db:/var/lib/postgresql/data \
       --name db \
       --network="iddev" \
       -e POSTGRES_PASSWORD=postgres \
       --rm \
       postgres:9.6

# Start dev container
echo "Starting dev container..."
docker run -d \
       -p 4000:4000 \
       -v $(pwd):/$(basename $PWD) \
       -w /$(basename $PWD) \
       --name phoenix \
       --network="iddev" \
       --rm \
       iddmichael/phx1.6.10-elixir1.13.4-erlang-25.0.2-dev:2
