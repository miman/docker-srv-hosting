#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# Set the Beszel data root based on DOCKER_FOLDER
export BESZEL_DATA_ROOT="$DOCKER_FOLDER/beszel-agent"
mkdir -p "$BESZEL_DATA_ROOT/agent_data"

# Prompt for the KEY and TOKEN from the Hub
echo ""
echo "Beszel Agent requires a KEY and TOKEN from your Beszel Hub."
read -p "Enter your Beszel KEY: " BESZEL_KEY
export BESZEL_KEY

read -p "Enter your Beszel TOKEN: " BESZEL_TOKEN
export BESZEL_TOKEN

echo "Deploying Beszel Agent..."
echo "Data will be stored in: $BESZEL_DATA_ROOT/agent_data"

$COMPOSE_CMD down
$COMPOSE_CMD pull
$COMPOSE_CMD up -d --force-recreate

echo "Beszel Agent has been installed."
