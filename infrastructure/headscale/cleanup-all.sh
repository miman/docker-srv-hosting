#!/bin/bash

# This scripts removes all created docker containers, networks & volumes

# Source config for container engine settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/read-config.sh"

# OBS, this file will remove all volumes as well, if you want to keep these remove the -v flags in the rows below or run the cleanup.bat script

# Uninstall the Docker container
$COMPOSE_CMD down -v --rmi all

# ==============================================

# Remove the volume used by the Docker container
# $CONTAINER_CMD volume rm 	headscale_default
