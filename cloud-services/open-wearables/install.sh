#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Clone the Open Wearables repository if it doesn't exist, otherwise update it
if [ ! -d src ]; then
    echo "Cloning the-momentum/open-wearables repository into ./src..."
    git clone https://github.com/the-momentum/open-wearables.git src
else
    echo "Updating the-momentum/open-wearables repository..."
    if [ -d src/.git ]; then
        cd src && git pull && cd ..
    else
        echo "Warning: 'src' folder exists but is not a Git repository. Skipping git pull."
    fi
fi

# Create persistent data directories in DOCKER_FOLDER
mkdir -p "$DOCKER_FOLDER/open-wearables/postgres-data"
mkdir -p "$DOCKER_FOLDER/open-wearables/redis"

# Create or update .env file
if [ -f .env ]; then
    echo ".env file already exists, skipping generation."
else
    echo "Creating .env file with default settings and secure credentials..."
    
    # Generate random credentials
    DB_PASSWORD=$(openssl rand -hex 16 2>/dev/null || cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 20)
    SECRET_KEY=$(openssl rand -hex 32 2>/dev/null || cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 40)
    ADMIN_PASSWORD=$(openssl rand -hex 12 2>/dev/null || cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 16)

    # Detect local network IP and configure backend/frontend endpoints
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    DEFAULT_API_URL="http://${SERVER_IP}:4416"
    if [ -n "$BASE_DNS_NAME" ]; then
        DEFAULT_API_URL="http://${BASE_DNS_NAME}:4416"
    fi
    DEFAULT_FRONTEND_URL="http://${SERVER_IP}:4415"
    if [ -n "$BASE_DNS_NAME" ]; then
        DEFAULT_FRONTEND_URL="http://${BASE_DNS_NAME}:4415"
    fi

    echo "Configure Open Wearables endpoints:"
    echo "  1. Backend API Endpoint: the URL client browsers use to talk to the backend."
    read -p "Enter API URL [default: $DEFAULT_API_URL]: " USER_API_URL
    API_URL="${USER_API_URL:-$DEFAULT_API_URL}"

    echo "  2. Frontend Dashboard Endpoint: the URL you will access the UI from."
    read -p "Enter Frontend URL [default: $DEFAULT_FRONTEND_URL]: " USER_FRONTEND_URL
    FRONTEND_URL="${USER_FRONTEND_URL:-$DEFAULT_FRONTEND_URL}"

    cat > .env <<EOF
#--- APP ---#
ENVIRONMENT="production"
API_PORT=8000
FRONTEND_URL=${FRONTEND_URL}
CORS_ORIGINS=["${FRONTEND_URL}"]

#--- DB ---#
DB_HOST=db
DB_PORT=5432
DB_NAME=open-wearables
DB_USER=open-wearables
DB_PASSWORD=${DB_PASSWORD}

#--- REDIS ---#
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0

#--- AUTH ---#
SECRET_KEY=${SECRET_KEY}

#--- ADMIN SEED ---#
ADMIN_EMAIL=admin@admin.com
ADMIN_PASSWORD=${ADMIN_PASSWORD}

#--- OUTGOING WEBHOOKS (Svix) ---#
SVIX_SERVER_URL=http://svix-server:8071

#--- Providers ---#
API_BASE_URL=${API_URL}
VITE_API_URL=${API_URL}

#--- Sync Settings ---#
SYNC_INTERVAL_SECONDS=3600
SLEEP_SCORE_INTERVAL_SECONDS=600
RESILIENCE_SCORE_INTERVAL_SECONDS=600
HISTORICAL_SYNC_ON_CONNECT=true
INGEST_WORKOUT_SAMPLES=false
STORE_FIT_FILES=false
EOF
    echo "!!! IMPORTANT: .env file created. Open Wearables developer portal credentials:"
    echo "    Email: admin@admin.com"
    echo "    Password: ${ADMIN_PASSWORD}"
    echo "!!! Note: If you need to add integration secrets (Garmin, Whoop, etc.), please edit open-wearables/.env manually. !!!"
fi

# Run the Docker compose file
echo "Stopping existing containers..."
$COMPOSE_CMD down

echo "Building local images..."
$COMPOSE_CMD build

echo "Starting Open Wearables containers..."
$COMPOSE_CMD up -d

echo
echo "Open Wearables has been installed successfully!"
echo "- Frontend Dashboard: ${FRONTEND_URL:-http://localhost:4415}"
echo "- Backend API: ${API_URL:-http://localhost:4416}"
echo "- Celery Flower Dashboard: http://localhost:4417"
echo

