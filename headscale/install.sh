#!/bin/bash

# Ask user for the Headscale version to use, default to 0.26.1 if not provided
read -p "Enter the Headscale version to use [default: 0.26.1]: " HS_VERSION
HS_VERSION=${HS_VERSION:-0.26.1}

read -p "Enter your domain name: " DOMAIN_NAME
DOMAIN_NAME=${DOMAIN_NAME}

# Set HEADSCALE_PATH to the absolute path of the current directory
HEADSCALE_PATH=$(pwd)

# Create a .env file for docker-compose variable substitution
cat > .env <<EOF
HS_VERSION=${HS_VERSION}
DOMAIN_NAME=${DOMAIN_NAME}
HEADSCALE_PATH=${HEADSCALE_PATH}
EOF

# Create a directory on the Docker host to store headscale's configuration and the SQLite database:
mkdir -p ./headscale/{config,lib,run}

# Download the example configuration for your chosen version and save it as: $(pwd)/config/config.yaml. Adjust the configuration to suit your local environment. 
wget -O ./headscale/config/config.yaml https://raw.githubusercontent.com/juanfont/headscale/v${HS_VERSION}/config-example.yaml

# Replace server_url in the config file with the provided domain name
sed -i "s|server_url: http://127.0.0.1:8080|server_url: https://${DOMAIN_NAME}|" ./headscale/config/config.yaml
# Replace listen_addr in the config file
sed -i "s|listen_addr: 127.0.0.1:8080|listen_addr: 0.0.0.0:8080|" ./headscale/config/config.yaml
# Replace metrics_listen_addr in the config file
sed -i "s|metrics_listen_addr: 127.0.0.1:9090|metrics_listen_addr: 0.0.0.0:9090|" ./headscale/config/config.yaml

# Prompt user to adjust the configuration before continuing
echo
echo "Please adjust the configuration in ./headscale/config/config.yaml to suit your local environment."
read -p "Press Enter to continue after you have finished editing the configuration file..."

echo "HS_VERSION=${HS_VERSION}"
echo "DOMAIN_NAME=${DOMAIN_NAME}"
echo "HEADSCALE_PATH=${HEADSCALE_PATH}"
# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Headscale has been installed and is accessible on http://localhost:8080"
echo "For more information on how to continue, see: https://headscale.net/stable/setup/install/container/#configure-and-run-headscale"
