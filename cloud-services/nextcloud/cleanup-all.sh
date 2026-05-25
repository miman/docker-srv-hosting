#!/bin/bash

# This script removes all created docker containers, networks & volumes

# Source config for container engine settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/read-config.sh"

# Uninstall the Docker container
$COMPOSE_CMD down -v --rmi all

# Remove the volumes used by the Docker container
$CONTAINER_CMD volume rm nextcloud_nextcloud_db 2>/dev/null || true
$CONTAINER_CMD volume rm nextcloud_nextcloud_data 2>/dev/null || true
$CONTAINER_CMD volume rm nextcloud_redis_data 2>/dev/null || true
