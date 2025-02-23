#!/bin/bash

# Create a volume for the the Docker container
docker volume create home-assistant

# Run the Docker compose file
docker-compose down
docker-compose pull
docker-compose up -d

echo "Home Assistant has been installed and is accessible on http://localhost:8123"
