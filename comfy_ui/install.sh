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

# Ensure data directories exist in DOCKER_FOLDER
echo "Ensuring data directories exist in $DOCKER_FOLDER/comfy_ui..."
mkdir -p "$DOCKER_FOLDER/comfy_ui/models"
mkdir -p "$DOCKER_FOLDER/comfy_ui/custom_nodes"
mkdir -p "$DOCKER_FOLDER/comfy_ui/input"
mkdir -p "$DOCKER_FOLDER/comfy_ui/output"
mkdir -p "$DOCKER_FOLDER/comfy_ui/user"
mkdir -p "$DOCKER_FOLDER/comfy_ui/templates"

# Deployment
echo "Deploying ComfyUI Docker container..."
docker compose down
docker compose build
docker compose up -d --force-recreate
echo "ComfyUI has been installed and is accessible on http://localhost:4515"

# Prompt the user if they want to download models
read -p "Do you want to download models for ComfyUI ? (y/N): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Models will be downloaded..."
    # Check if download-models.sh exists and is executable
    if [ -x "download-models.sh" ]; then
        ./download-models.sh
    else
        echo "Warning: download-models.sh not found or not executable."
    fi
else
    echo "No models will be downloaded."
fi

echo "Find the model ranking here:  https://imgsys.org"
echo "Find & download them here:  https://civitai.com/models"