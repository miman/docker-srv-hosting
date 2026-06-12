#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# --- PODMAN & DOCKER HYBRID LOGIC ---
# If running Podman, ensure the correct socket path is exported
if [[ "$COMPOSE_CMD" == *"podman"* ]]; then
    echo "Podman detected. Configuring environment variables..."
    
    # Ensure the user-level Podman socket is enabled and running
    systemctl --user enable --now podman.socket || true
    
    # Set the correct path to podman.sock based on the current user's UID
    export XDG_RUNTIME_DIR="/run/user/$UID"
else
    echo "Docker detected. Using default settings..."
    # In Docker, we want it to fall back to /var/run/docker.sock
    export XDG_RUNTIME_DIR="/var"
    # Reset HOME variable in the compose context to fall back to /var/lib/docker
    export HOME="/var/lib/docker"
fi
# -------------------------------------

echo "Deploying Portainer Agent..."

$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d --force-recreate

echo "Portainer Agent has been installed and is accessible on port 9001"