#!/bin/bash

# Prompt user for the root folder for Portainer data
read -p "Enter the absolute path for Portainer data (e.g. /volume1/docker/portainer): " PORTAINER_DATA_ROOT

# Validate input (basic check)
if [ -z "$PORTAINER_DATA_ROOT" ]; then
  echo "Error: No path provided. Exiting."
  exit 1
fi

# Create a .env file for docker-compose variable substitution
cat > .env <<EOF
PORTAINER_DATA_ROOT=${PORTAINER_DATA_ROOT}
EOF

echo "PORTAINER_DATA_ROOT set to: $PORTAINER_DATA_ROOT"
echo "Installing into Docker..."

docker compose up -d
