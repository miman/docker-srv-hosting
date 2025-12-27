#!/bin/bash

# This file restores Headscale configuration from a backup location

# Exit immediately if a command exits with a non-zero status.
set -e

# Define DOCKER_FOLDER if not already set (e.g., for direct execution)
source ../scripts/ensure-DOCKER_FOLDER.sh

echo "Restoring Headscal config using DOCKER_FOLDER: ${DOCKER_FOLDER}"

# Go to backup folder
cd ../backup/headscale

echo "Restoring Headscale configuration and data from $(pwd)"

# Copy backed-up config and lib directories to the active Headscale volume locations
# Ensure target directories exist before copying
mkdir -p "${DOCKER_FOLDER}/headscale/config"
mkdir -p "${DOCKER_FOLDER}/headscale/lib"

sudo cp -r ./config/. "${DOCKER_FOLDER}/headscale/config/." || true # Use || true to prevent script exit if source is empty
sudo cp -r ./lib/. "${DOCKER_FOLDER}/headscale/lib/." || true # Use || true to prevent script exit if source is empty


# Ensure the current user is the owner of the files
echo "Setting ownership for ${DOCKER_FOLDER}/headscale"
sudo chown -R $USER:$USER "${DOCKER_FOLDER}/headscale"

echo "Headscale data restore complete. You may need to restart the Headscale container."
echo "Example: docker compose restart headscale"

# Go back to previous folder
cd -
