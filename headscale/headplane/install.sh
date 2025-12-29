#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

HEADSCALE_DATA_PATH="$DOCKER_FOLDER/headscale"
HEADPLANE_CONFIG_DIR="$HEADSCALE_DATA_PATH/headplane-config"
HEADPLANE_CONFIG_FILE="$HEADPLANE_CONFIG_DIR/config.yaml"

# Create a default config & secret only if none exists
if [ ! -f "$HEADPLANE_CONFIG_FILE" ]; then
    echo "Creating directory $HEADPLANE_CONFIG_DIR..."
    mkdir -p "$HEADPLANE_CONFIG_DIR"

    echo "Generating HP_SERVER_COOKIE_SECRET..."
    HP_SERVER_COOKIE_SECRET=$(openssl rand -hex 16)

    # Create a .env file for docker-compose variable substitution
    cat > .env <<EOF
HP_SERVER_COOKIE_SECRET=${HP_SERVER_COOKIE_SECRET}
EOF

    echo "Creating default config for Headplane..."
    cat > "$HEADPLANE_CONFIG_FILE" <<EOF
headscale:
  url: "https://headscale.$BASE_DNS_NAME"
  config_strict: false
server:
  cookie_secret: "${HP_SERVER_COOKIE_SECRET}"
  cookie_secure: false
  host: "0.0.0.0"
  port: 3000
EOF
fi

# Pull & start the container
echo "Deploying Headplane..."
docker compose down
docker compose pull
docker compose up -d

echo "Headplane deployment complete."
