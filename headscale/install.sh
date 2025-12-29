#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# --- Check for local Tailscale client and reconfigure port ---
# This is to avoid a port conflict if a local tailscale client is running,
# as Headscale also uses port 41641 for coordination.
if command -v tailscale >/dev/null 2>&1; then
  echo "Tailscale client is installed. Checking for port configuration..."
  if [ -f /etc/default/tailscaled ]; then
    echo "Changing local tailscaled port to 41642 to avoid conflict with Headscale..."
    # Change to use another port than 41641 for the local client
    sudo sed -i 's/^#*PORT=.*/PORT="41642"/' /etc/default/tailscaled
    sudo systemctl restart tailscaled
    echo "Local tailscaled client restarted on new port."
  else
    echo "/etc/default/tailscaled not found. No changes needs to be done"
  fi
fi
# --- End of Tailscale check ---

# Ask user for the Headscale version to use, default to 0.26.1 if not provided
read -p "Enter the Headscale version to use [default: 0.27.1]: " HS_VERSION
HS_VERSION=${HS_VERSION:-0.27.1}

if [ -z "${BASE_DNS_NAME}" ]; then
  read -p "Enter your domain name: " BASE_DNS_NAME
fi

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# Create a .env file for docker-compose variable substitution
echo "Generating .env file for Headscale..."

cat > .env <<EOF
HS_VERSION=${HS_VERSION}
DOMAIN_NAME=${BASE_DNS_NAME}
EOF

HEADSCALE_DATA_PATH="$DOCKER_FOLDER/headscale"

# Create a directory on the Docker host to store headscale's configuration and the SQLite database:
mkdir -p "$HEADSCALE_DATA_PATH"/{config,lib,run}

CONFIG_FILE="$HEADSCALE_DATA_PATH/config/config.yaml"

# Download the example configuration for your chosen version and save it as: $(pwd)/config/config.yaml. Adjust the configuration to suit your local environment. 
wget -O "$CONFIG_FILE" https://raw.githubusercontent.com/juanfont/headscale/v${HS_VERSION}/config-example.yaml

# Replace server_url in the config file with the provided domain name
sed -i "s|server_url: http://127.0.0.1:8080|server_url: https://${BASE_DNS_NAME}|" "$CONFIG_FILE"
# Replace listen_addr in the config file
sed -i "s|listen_addr: 127.0.0.1:8080|listen_addr: 0.0.0.0:8080|" "$CONFIG_FILE"
# Replace metrics_listen_addr in the config file
sed -i "s|metrics_listen_addr: 127.0.0.1:9090|metrics_listen_addr: 0.0.0.0:9090|" "$CONFIG_FILE"

# Prompt user to adjust the configuration before continuing
echo
echo "Please adjust the configuration in $CONFIG_FILE to suit your local environment."
read -p "Press Enter to continue after you have finished editing the configuration file..."

echo "HS_VERSION=${HS_VERSION}"
echo "DOMAIN_NAME=${BASE_DNS_NAME}"
echo "Headscale data path: $HEADSCALE_DATA_PATH"
# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Headscale has been installed and is accessible on http://${BASE_DNS_NAME}:8080"
echo "For more information on how to continue, see: https://headscale.net/stable/setup/install/container/#configure-and-run-headscale"

# Prompt to install Headplane UI
echo
read -p "Do you want to install Headplane UI (a web interface for Headscale)? (y/n) [default: n]: " INSTALL_HEADPLANE
INSTALL_HEADPLANE=${INSTALL_HEADPLANE:-n}

if [[ "$INSTALL_HEADPLANE" =~ ^[Yy]$ ]]; then
    echo "Starting Headplane installation..."
    cd headplane
    ./install.sh
fi
