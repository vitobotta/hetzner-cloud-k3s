#!/bin/bash

curl --silent "https://api.github.com/repos/k3s-io/k3s/tags" | jq -r '.[].name'
