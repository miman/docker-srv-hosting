@echo off
if not exist glance\docker-compose.yml (
    mkdir glance
    cd glance
    curl -sL https://github.com/glanceapp/docker-compose-template/archive/refs/heads/main.tar.gz | tar -xzf - --strip-components 2
    REM Update docker-compose.yml to change port mapping 8080:8080 to 4403:8080
    powershell -Command "(Get-Content docker-compose.yml) -replace '- 8080:8080', '- 4403:8080' | Set-Content docker-compose.yml"
    
) else (
  echo "Glance files already exist. Skipping download."
  cd glance
)

echo "edit the following files as desired:"
echo "- docker-compose.yml to configure the port, volumes and other containery things"
echo "- config/home.yml to configure the widgets or layout of the home page"
echo "- config/glance.yml if you want to change the theme or add more pages"

# Prompt user to adjust the configuration before continuing
echo
echo "Please adjust the configuration in ./headscale/config/config.yaml to suit your local environment."
echo Press Enter to continue after you have finished editing the configuration file...
pause >nul

REM Fetch the latest images
docker compose pull
REM Start the containers in detached mode
docker compose up -d

cd ..
echo "Glance Dashboard is now running. You can access it at http://localhost:4403"

