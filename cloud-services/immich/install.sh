#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# --- Handle Immich Custom Folders via Central Config ---

# 1. Resolve Upload/Library Location
# Check if it already exists in config.yaml
UPLOAD_LOCATION=$(grep "^immich_upload_location:" "$HSC_CONFIG_PATH" | sed -e "s/^immich_upload_location:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")

if [ -z "$UPLOAD_LOCATION" ] || [ "$UPLOAD_LOCATION" == "null" ]; then
    DEFAULT_UPLOAD="${DOCKER_FOLDER}/immich/library"
    echo ""
    echo "Where should Immich store your uploaded media?"
    echo "1) Use default: $DEFAULT_UPLOAD"
    echo "2) Enter a manual path"
    read -p "Enter choice [1-2, default: 1]: " upload_choice
    
    if [ "$upload_choice" == "2" ]; then
        read -p "Enter manual absolute path for media: " UPLOAD_LOCATION
    else
        UPLOAD_LOCATION="$DEFAULT_UPLOAD"
    fi
    # Save the decision to config.yaml for future runs
    set_config_value "immich_upload_location" "$UPLOAD_LOCATION"
fi

# 2. Resolve Database Data Location
DB_DATA_LOCATION=$(grep "^immich_db_location:" "$HSC_CONFIG_PATH" | sed -e "s/^immich_db_location:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")

if [ -z "$DB_DATA_LOCATION" ] || [ "$DB_DATA_LOCATION" == "null" ]; then
    DEFAULT_DB="${DOCKER_FOLDER}/immich/postgres"
    echo ""
    echo "Where should Immich store its database data?"
    echo "1) Use default: $DEFAULT_DB"
    echo "2) Enter a manual path"
    read -p "Enter choice [1-2, default: 1]: " db_choice
    
    if [ "$db_choice" == "2" ]; then
        read -p "Enter manual absolute path for database: " DB_DATA_LOCATION
    else
        DB_DATA_LOCATION="$DEFAULT_DB"
    fi
    set_config_value "immich_db_location" "$DB_DATA_LOCATION"
fi

# Export paths so docker-compose/env substitutions pick them up seamlessly
export UPLOAD_LOCATION
export DB_DATA_LOCATION

# --- End of Config/Manual Folder Logic ---

# Ask for installation type
echo ""
echo "Choose Immich installation type:"
echo "1) Full (recommended, includes machine learning)"
echo "2) Minimal (for devices with limited memory, no machine learning)"
read -p "Enter choice [1 or 2, default: 1]: " choice

case $choice in
    2)
        echo "Selected: Minimal installation"
        IMMICH_PROFILES=""
        ;;
    *)
        echo "Selected: Full installation"
        IMMICH_PROFILES="full"
        ;;
esac

# Ensure directories exist (whether custom or default)
mkdir -p "$UPLOAD_LOCATION"
mkdir -p "$DB_DATA_LOCATION"
mkdir -p "$DOCKER_FOLDER/immich/model-cache"

# Create or update .env file
if [ -f .env ]; then
    echo ".env file already exists, updating COMPOSE_PROFILES and locations..."
    sed "s|^COMPOSE_PROFILES=.*|COMPOSE_PROFILES=${IMMICH_PROFILES}|" .env > .env.tmp && mv .env.tmp .env
    sed "s|^UPLOAD_LOCATION=.*|UPLOAD_LOCATION=${UPLOAD_LOCATION}|" .env > .env.tmp && mv .env.tmp .env
    sed "s|^DB_DATA_LOCATION=.*|DB_DATA_LOCATION=${DB_DATA_LOCATION}|" .env > .env.tmp && mv .env.tmp .env
else
    echo "Creating .env file with your settings..."
    cat > .env <<EOF
# The location where your uploaded files are stored
UPLOAD_LOCATION=${UPLOAD_LOCATION}

# The location where the database data is stored
DB_DATA_LOCATION=${DB_DATA_LOCATION}

# PostgreSQL credentials - CHANGE THIS
DB_USERNAME=postgres
DB_PASSWORD=changeme
DB_DATABASE_NAME=immich

# The version of Immich to use
IMMICH_VERSION=release

# Profiles to run (empty for minimal, 'full' for machine learning)
COMPOSE_PROFILES=${IMMICH_PROFILES}
EOF
    echo "!!! IMPORTANT: .env file created with a default password. Please change DB_PASSWORD in immich/.env for security. !!!"
fi

# Run the Docker compose file
$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d

echo "Immich has been installed ($([ "$IMMICH_PROFILES" = "full" ] && echo "Full" || echo "Minimal") version)."
echo "You can access it at http://<your-ip>:2283"