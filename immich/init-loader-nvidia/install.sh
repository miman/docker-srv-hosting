#!/bin/bash
set -e

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Immich Machine Learning has been installed."
echo "It can be used to train models for Immich."
echo "You can access it at http://<your-ip>:3003"
