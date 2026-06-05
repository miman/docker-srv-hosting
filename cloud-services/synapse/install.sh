#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Ensure the docker network "local-ai-network" exists
if ! $CONTAINER_CMD network ls --filter name=local-ai-network --format '{{.Name}}' | grep -q "^local-ai-network$"; then
  $CONTAINER_CMD network create local-ai-network
else
  echo "The network local-ai-network already exists."
fi

# Ensure data directory exists
DATA_DIR="$DOCKER_FOLDER/synapse/data"
mkdir -p "$DATA_DIR"

# Generate configuration if it doesn't exist
if [ ! -f "$DATA_DIR/homeserver.yaml" ]; then
    echo "Generating Synapse configuration for $BASE_DNS_NAME..."
    MSYS_NO_PATHCONV=1 $CONTAINER_CMD run --rm \
        -v "$DATA_DIR:/data" \
        -e SYNAPSE_SERVER_NAME="$BASE_DNS_NAME" \
        -e SYNAPSE_REPORT_STATS=yes \
        docker.io/matrixdotorg/synapse:latest generate
    
    echo "Configuration generated. Please review $DATA_DIR/homeserver.yaml before deployment."
fi

# Ask if user wants to install Element Web client
ELEMENT_WEB_DIR="$DOCKER_FOLDER/synapse/element-web"
INSTALL_ELEMENT_WEB="no"
if [ ! -f "$ELEMENT_WEB_DIR/config.json" ]; then
    echo ""
    read -p "Would you like to install Element Web (self-hosted Matrix web client)? [y/N]: " ELEMENT_CHOICE
    if [[ "$ELEMENT_CHOICE" =~ ^[Yy]$ ]]; then
        INSTALL_ELEMENT_WEB="yes"
        mkdir -p "$ELEMENT_WEB_DIR"
        cat > "$ELEMENT_WEB_DIR/config.json" <<EOF
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "http://localhost:4530",
            "server_name": "$BASE_DNS_NAME"
        }
    },
    "brand": "Element",
    "integrations_ui_url": "",
    "integrations_rest_url": "",
    "disable_custom_urls": false,
    "disable_guests": true,
    "disable_3pid_login": false,
    "show_labs_settings": true
}
EOF
        echo "Element Web configuration created."
    fi
else
    # Config already exists, include Element Web in deployment
    INSTALL_ELEMENT_WEB="yes"
fi

# Deployment
COMPOSE_FILES="-f docker-compose.yaml"
if [ "$INSTALL_ELEMENT_WEB" == "yes" ]; then
    COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.element-web.yaml"
fi

echo "Deploying Matrix Synapse Docker containers..."
$COMPOSE_CMD $COMPOSE_FILES down
$COMPOSE_CMD $COMPOSE_FILES pull
$COMPOSE_CMD $COMPOSE_FILES up -d --force-recreate
echo "Synapse has been installed and is accessible on http://localhost:4530"
echo "Synapse Admin is accessible on http://localhost:4531"
if [ "$INSTALL_ELEMENT_WEB" == "yes" ]; then
    echo "Element Web is accessible on http://localhost:4532"
fi

# First-time admin user creation
# Check if admin setup has already been completed
TASKS_DONE_FILE="$(dirname "$HSC_CONFIG_PATH")/tasks_done.yaml"
if [ ! -f "$TASKS_DONE_FILE" ] || ! grep -q "^synapse_admin_setup_completed: true" "$TASKS_DONE_FILE"; then
    echo ""
    echo "=== First-Time Admin User Setup ==="
    echo "No admin user has been created yet. Let's create one now."
    echo ""
    read -p "Enter admin username: " ADMIN_USER
    read -sp "Enter admin password: " ADMIN_PASS
    echo ""
    read -sp "Confirm admin password: " ADMIN_PASS_CONFIRM
    echo ""

    if [ "$ADMIN_PASS" != "$ADMIN_PASS_CONFIRM" ]; then
        echo "Error: Passwords do not match. Skipping admin user creation."
        echo "You can create an admin user manually later with:"
        echo "  $COMPOSE_CMD exec synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008"
        exit 0
    fi

    # Wait a moment for Synapse to fully start
    echo "Waiting for Synapse to be ready..."
    sleep 5

    # Create the admin user using the register_new_matrix_user CLI
    echo "Creating admin user '$ADMIN_USER'..."
    set +e
    MSYS_NO_PATHCONV=1 $COMPOSE_CMD exec synapse register_new_matrix_user \
        -u "$ADMIN_USER" \
        -p "$ADMIN_PASS" \
        -a \
        -c /data/homeserver.yaml \
        http://localhost:8008
    REGISTER_EXIT=$?
    set -e

    if [ $REGISTER_EXIT -eq 0 ]; then
        echo "Admin user '$ADMIN_USER' created successfully!"
        # Mark admin setup as completed in tasks_done.yaml
        mkdir -p "$(dirname "$TASKS_DONE_FILE")"
        if [ ! -f "$TASKS_DONE_FILE" ]; then
          echo "synapse_admin_setup_completed: true" > "$TASKS_DONE_FILE"
        else
          echo "synapse_admin_setup_completed: true" >> "$TASKS_DONE_FILE"
        fi
    else
        echo "Error: Failed to create admin user."
        echo "You can try again manually with:"
        echo "  $COMPOSE_CMD exec synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008"
    fi
else
    echo ""
    echo "Admin user setup was already completed previously. Skipping."
fi
