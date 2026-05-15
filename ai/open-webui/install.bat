echo off

REM The docker containers needs a common network to be able to communicate with each other
docker network ls | findstr /r /c:"local-ai-network" >nul
IF ERRORLEVEL 1 (
    docker network create local-ai-network
) ELSE (
    echo The network local-ai-network already exists.
)

REM Start in detached mode, ensuring the latest image is used & restarting container
set /p answer=Do you want to install the Open WebUI (y/N)? 
echo Deploying Docker container...
if /i "%answer%" EQU "Y" (
docker compose down
docker compose pull
docker compose up -d --force-recreate --build
echo "Open-webui has been installed and is accessible on http://localhost:4512"
) else (
 echo "The open-webui container is not installed."
)
