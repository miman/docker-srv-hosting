#!/bin/bash

# Create a volume for the the Docker container
docker volume create reverse-proxy

# Run the Docker compose file
docker-compose down
docker-compose pull
docker-compose up -d --force-recreate --build

echo "reverse-proxy has been installed and is accessible on http://localhost:8123"
