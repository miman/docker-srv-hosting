#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Set the config path based on DOCKER_FOLDER
CONFIG_PATH="$DOCKER_FOLDER/vaultwarden"
mkdir -p "$CONFIG_PATH"
echo "Using $CONFIG_PATH for Vaultwarden data."

read -p "Enter the domain for Vaultwarden (e.g. https://vaultwarden.yourname.duckdns.org), or leave blank for none: " DOMAIN

# Stop and remove existing container if it exists to avoid conflicts
$CONTAINER_CMD stop vaultwarden &>/dev/null || true
$CONTAINER_CMD rm vaultwarden &>/dev/null || true

$CONTAINER_CMD pull docker.io/vaultwarden/server:latest

DOMAIN_ARG=""
if [ -n "$DOMAIN" ]; then
  DOMAIN_ARG="--env DOMAIN=$DOMAIN"
fi

$CONTAINER_CMD run -d \
  --name vaultwarden \
  $DOMAIN_ARG \
  -v "$CONFIG_PATH:/data" \
  --restart unless-stopped \
  -p 4410:80 \
  docker.io/vaultwarden/server:latest

echo "Vaultwarden is now running. You can access it at http://localhost:4410"
