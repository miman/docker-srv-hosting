#!/bin/bash

if [ ! -f glance/docker-compose.yml ]; then
    mkdir -p glance
    cd glance
    curl -sL https://github.com/glanceapp/docker-compose-template/archive/refs/heads/main.tar.gz | tar -xzf - --strip-components 2
    # Update docker-compose.yml to change port mapping 8080:8080 to 4403:8080
    grep -q "- 8080:8080" docker-compose.yml && sed -i 's/- 8080:8080/- 4403:8080/' docker-compose.yml
else
    echo "Glance files already exist. Skipping download."
    cd glance
fi

echo "Edit the following files as desired:"
echo "- docker-compose.yml to configure the port, volumes and other containery things"
echo "- config/home.yml to configure the widgets or layout of the home page"
echo "- config/glance.yml if you want to change the theme or add more pages"

echo
echo "Please adjust the configuration in ./headscale/config/config.yaml to suit your local environment."
read -p "Press Enter to continue after you have finished editing the configuration file..."

# Fetch the latest images
docker compose pull
# Start the containers in detached mode
docker compose up -d

cd ..
echo "Glance Dashboard is now running. You can access it at http://localhost:4403"
