#!/bin/bash
set -e

# Determine script directory and source read-config for container engine settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../scripts/read-config.sh"

# Run the Docker compose file
$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d

echo "Immich Machine Learning has been installed."
echo "It can be used to train models for Immich."
echo "You can access it at http://<your-ip>:3003"
