echo off

REM Run the Docker compose file
docker-compose down
docker-compose pull
docker-compose up -d --force-recreate --build

echo Home Assistant has been installed and is accessible on http://localhost:8123
