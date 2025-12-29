echo off

REM Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo Nginx reverse-proxy has been installed and is accessible on http://localhost:81
