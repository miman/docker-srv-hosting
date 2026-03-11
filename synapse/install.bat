echo off
echo Deploying Synapse to Docker
docker compose down
docker compose pull
docker compose up -d
echo Synapse has been installed and is accessible on http://localhost:4530
echo Synapse Admin will be accessible at: http://localhost:4531
