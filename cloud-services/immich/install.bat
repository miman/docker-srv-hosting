echo off

REM install instructions can be found here: https://immich.app/docs/install/docker-compose

REM fetch files if the files doesn't already exist
echo Fetching the latest version of Docker Compose file and .env
if not exist "docker-compose.yml" (
    echo Fetching the latest version of Docker Compose file
    curl -L -o docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
) else (
    echo Docker Compose file already exists, skipping download.
)
if not exist ".env" (
    echo Fetching the latest version of .env file
    curl -L -o .env https://github.com/immich-app/immich/releases/latest/download/example.env
) else (
    echo .env file already exists, skipping download.
)

REM Wait until the user has updated the .env file with their own configuration
echo Update the fetched .env file with your own configuration.
pause

REM Run the Docker compose file
echo Deploying Immich to Docker
docker compose down
docker compose pull
docker compose up -d

REM Cleanup fetched files
@REM del docker-compose.yml
@REM del .env

echo Immich has been installed and is accessible on http://localhost:2283
