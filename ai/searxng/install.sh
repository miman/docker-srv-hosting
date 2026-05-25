#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure the docker network "local-ai-network" exists
if ! $CONTAINER_CMD network ls --filter name=local-ai-network --format '{{.Name}}' | grep -q "^local-ai-network$"; then
  $CONTAINER_CMD network create local-ai-network
else
  echo "The network local-ai-network already exists."
fi

# Ensure data directory exists and settings are copied
mkdir -p "$DOCKER_FOLDER/searxng"
cp settings.yml "$DOCKER_FOLDER/searxng/settings.yml"

# Deployment
echo "Deploying SearXNG Docker container..."
$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d --force-recreate --build
echo "SearXNG has been installed and is accessible on http://localhost:4522"