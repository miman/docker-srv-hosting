#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure the docker network "local-ai-network" exists
if ! docker network ls --filter name=local-ai-network --format '{{.Name}}' | grep -q "^local-ai-network$"; then
  docker network create local-ai-network
else
  echo "The network local-ai-network already exists."
fi

# Check if .env exists and has matrix info
if [ -f .env ]; then
  # Source .env to get MATRIX variables. Using set -a to export them.
  set -a
  source .env
  set +a
  
  if [ -n "$MATRIX_USER" ] && [ -n "$MATRIX_PASS" ] && [ -n "$MATRIX_HOST" ] && [ -n "$MATRIX_ROOM_ID" ]; then
    export WATCHTOWER_NOTIFICATIONS="shoutrrr"
    export WATCHTOWER_NOTIFICATION_URL="matrix://${MATRIX_USER}:${MATRIX_PASS}@${MATRIX_HOST}/?rooms=${MATRIX_ROOM_ID}"
    echo "Found .env with matrix credentials. Notifications enabled."
  else
    echo "Notice: .env file found but matrix credentials (MATRIX_USER, etc.) are incomplete. Notifications disabled."
  fi
else
  echo "Notice: No .env file found. Notifications disabled (refer to readme.md to enable them)."
fi

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Watchtower has been installed"
