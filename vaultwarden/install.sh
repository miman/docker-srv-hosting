#!/bin/bash

read -p "Enter the absolute path to the config folder to use for Vaultwarden data: " CONFIG_PATH
# Replace backslashes with forward slashes for Docker compatibility
CONFIG_PATH="${CONFIG_PATH//\\/\/}"

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
