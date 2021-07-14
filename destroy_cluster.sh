#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source $SCRIPT_DIR/lib/destroy/parse_arguments.sh

source $SCRIPT_DIR/lib/destroy/destroy_resources.sh

echo
echo "Cluster has been destroyed."

