echo off
echo Deploying Verdaccio to Docker
docker compose down
docker compose pull
docker compose up -d
echo Verdaccio has been installed and is accessible on http://localhost:4873
