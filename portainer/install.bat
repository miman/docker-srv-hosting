echo off

REM Run the Portainer Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo Portainer has been installed and is accessible on http://localhost:9000
