#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure the docker network "local-ai-network" exists
if ! docker network ls --filter name=local-ai-network --format '{{.Name}}' | grep -q "^local-ai-network$"; then
  docker network create local-ai-network
else
  echo "The network local-ai-network already exists."
fi

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Watchtower has been installed"
