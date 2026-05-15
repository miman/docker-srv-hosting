#!/bin/bash

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# Check for openssl
if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is not installed. Please install it to generate secrets."
    exit 1
fi

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure data directory exists
mkdir -p "$DOCKER_FOLDER/netbird/management"
mkdir -p "$DOCKER_FOLDER/netbird/signal"

if [ ! -f "config.yaml" ]; then
    echo "Configuring Netbird Server..."
    read -p "Enter your Netbird domain (e.g. netbird.example.com): " NETBIRD_DOMAIN
    
    if [ -z "$NETBIRD_DOMAIN" ]; then
        echo "Error: Domain cannot be empty"
        exit 1
    fi

    # Generate secrets
    NETBIRD_RELAY_AUTH_SECRET=$(openssl rand -base64 32 | sed 's/=//g')
    DATASTORE_ENCRYPTION_KEY=$(openssl rand -base64 32)

    # Create config.yaml
    cat <<EOF > config.yaml
# Netbird Combined Server Configuration
HttpConfig:
  AuthAny: true # Allows /setup page to work
  ListenAddr: ":80"
  ProxyConfig:
    UseFrontendProxy: true
Signal:
  ListenAddr: ":80"
Management:
  ListenAddr: ":80"
  DataDir: "/var/lib/netbird"
  DatastoreEncryptionKey: "$DATASTORE_ENCRYPTION_KEY"
Relay:
  ListenAddr: ":80"
  AuthSecret: "$NETBIRD_RELAY_AUTH_SECRET"
EOF

    # Create dashboard.env
    cat <<EOF > dashboard.env
NETBIRD_MGMT_API_ENDPOINT=https://$NETBIRD_DOMAIN/api
NETBIRD_MGMT_GRPC_API_ENDPOINT=https://$NETBIRD_DOMAIN:443
EOF

    echo "Configuration generated for $NETBIRD_DOMAIN"
fi

# Run the Docker compose file
docker compose down
docker compose pull
docker compose up -d

echo "Netbird Control Plane has been installed"
echo "Access it at https://<your-domain>/setup to create the first admin user."
