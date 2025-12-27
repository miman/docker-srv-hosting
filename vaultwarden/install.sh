#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# Set the config path based on DOCKER_FOLDER
CONFIG_PATH="$DOCKER_FOLDER/vaultwarden"
mkdir -p "$CONFIG_PATH"
echo "Using $CONFIG_PATH for Vaultwarden data."

read -p "Enter the domain for Vaultwarden (e.g. https://vw.domain.tld), or leave blank for none: " DOMAIN

docker pull vaultwarden/server:latest

DOMAIN_ARG=""
if [ -n "$DOMAIN" ]; then
  DOMAIN_ARG="--env DOMAIN=$DOMAIN"
fi

docker run -d \
  --name vaultwarden \
  $DOMAIN_ARG \
  -v "$CONFIG_PATH:/data" \
  --restart unless-stopped \
  -p 4410:80 \
  vaultwarden/server:latest

echo "Vaultwarden is now running. You can access it at http://localhost:4410"
