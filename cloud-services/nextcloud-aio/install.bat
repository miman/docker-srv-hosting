echo off
echo Deploying Nextcloud AIO to Docker
docker compose down
docker compose pull
docker compose up -d
echo Nextcloud AIO has been installed and is accessible on http://localhost:4504
