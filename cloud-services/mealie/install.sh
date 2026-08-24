#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Create persistent data directory in DOCKER_FOLDER
mkdir -p "$DOCKER_FOLDER/mealie/data"

# Create or update .env file
if [ -f .env ]; then
    echo ".env file already exists, skipping generation."
else
    echo "Creating .env file with default settings..."
    
    # Detect local network IP and configure BASE_URL
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    DEFAULT_BASE_URL="http://${SERVER_IP}:4418"
    if [ -n "$BASE_DNS_NAME" ]; then
        DEFAULT_BASE_URL="http://${BASE_DNS_NAME}:4418"
    fi

    echo "Configure Mealie URL endpoint:"
    read -p "Enter Mealie BASE_URL [default: $DEFAULT_BASE_URL]: " USER_BASE_URL
    BASE_URL="${USER_BASE_URL:-$DEFAULT_BASE_URL}"

    cat > .env <<EOF
#--- MEALIE SETTINGS ---#
BASE_URL=${BASE_URL}
ALLOW_SIGNUP=true
TZ=UTC
PUID=1000
PGID=1000
EOF
    echo "!!! IMPORTANT: .env file created. !!!"
fi

# Run the Docker compose file
echo "Stopping existing containers..."
$COMPOSE_CMD down

echo "Pulling latest images..."
$COMPOSE_CMD pull

echo "Starting Mealie container..."
$COMPOSE_CMD up -d

echo
echo "Mealie has been installed successfully!"
echo "Access Mealie at: ${BASE_URL:-http://localhost:4418}"
echo "Default credentials:"
echo "  Username: admin@example.com"
echo "  Password: MyPassword123"
echo "Please change the admin credentials immediately after logging in!"
echo
