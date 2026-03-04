#!/bin/bash
set -e

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

# Ensure data directory exists and settings are copied
mkdir -p "$DOCKER_FOLDER/searxng"
cp settings.yml "$DOCKER_FOLDER/searxng/settings.yml"

# Deployment
echo "Deploying SearXNG Docker container..."
docker compose down
docker compose pull
docker compose up -d --force-recreate --build
echo "SearXNG has been installed and is accessible on http://localhost:4520"