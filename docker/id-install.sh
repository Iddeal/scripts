#!/bin/bash

# Install the up.sh and down.sh scripts into the specified folder
(cd $1 && cp ~/.iddeal-scripts/up.sh . && chmod a+x up.sh)
(cd $1 && cp ~/.iddeal-scripts/down.sh . && chmod a+x down.sh)

echo "Scripts installed to $1."
