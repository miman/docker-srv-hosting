echo off

REM Run the Docker compose file
echo Deploying Immich to Docker
docker compose down
docker compose pull
docker compose up -d

echo Immich Machine Learning has been installed and is accessible on http://localhost:3003
