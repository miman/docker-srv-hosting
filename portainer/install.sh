#!/bin/bash
echo "Deploying Portainer Docker container..."
docker-compose down
docker-compose pull
docker-compose $COMPOSE_PART up -d --force-recreate

echo "Portainer has been installed and is accessible on http://localhost:9000"
