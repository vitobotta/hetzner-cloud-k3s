#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --hetzner-token)
    HETZNER_TOKEN="$2"
    shift # past argument
    shift # past value
  ;;
  *)
    POSITIONAL+=("$1")
    shift
  ;;
esac
done
set -- "${POSITIONAL[@]}"

[[ -z "$HETZNER_TOKEN" ]] && { echo "Please specify the Hetzner token with '--hetzner-token <token>'" ; exit 1; }

curl -H "Authorization: Bearer $HETZNER_TOKEN" 'https://api.hetzner.cloud/v1/server_types'

