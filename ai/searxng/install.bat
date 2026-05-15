echo off
REM Ensure the docker network "local-ai-network" exists
docker network ls | findstr /r /c:"local-ai-network" >nul
IF ERRORLEVEL 1 (
    docker network create local-ai-network
)

echo Preparing SearXNG configuration
if not exist "%DOCKER_FOLDER%\searxng" mkdir "%DOCKER_FOLDER%\searxng"
copy settings.yml "%DOCKER_FOLDER%\searxng\settings.yml"

echo Deploying SearXNG to Docker
docker compose down
docker compose pull
docker compose up -d --force-recreate --build
echo SearXNG has been installed and is accessible on http://localhost:4522
