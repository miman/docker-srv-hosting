#!/bin/bash
# This script initializes the core environment for the docker-srv-hosting stack.
# It performs the following tasks:
# 1. Sets up the Docker root directory and base DNS name in a local config file.
# 2. Updates and upgrades the system's package list.
# 3. Installs Docker and the Tailscale client.
# 4. Sources the main install.sh script to allow for application-specific setups.

set -e

# --- Configuration ---
CONFIG_DIR="$HOME/.hsc"
CONFIG_FILE="$CONFIG_DIR/config.json"
DEFAULT_DOCKER_ROOT="$HOME/docker_stacks"

# --- Helper Functions ---
function print_info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

function print_success() {
    echo -e "\e[32m[SUCCESS]\e[0m $1"
}

function print_error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
    exit 1
}

# --- Main Logic ---

# 1. Configure Docker Root Folder
print_info "Configuring Docker root folder..."
mkdir -p "$CONFIG_DIR"

DOCKER_ROOT=""
if [ -f "$CONFIG_FILE" ]; then
    # Using jq to parse JSON, check if it's installed
    if ! command -v jq &> /dev/null; then
        print_info "jq not found, installing..."
        sudo apt-get update && sudo apt-get install -y jq
    fi
    DOCKER_ROOT=$(jq -r '.docker_root' "$CONFIG_FILE")
fi

# If DOCKER_ROOT is empty, use the default
if [ -z "$DOCKER_ROOT" ]; then
    DOCKER_ROOT=$DEFAULT_DOCKER_ROOT
fi

if [ -z "$USER_INPUT_DOCKER_ROOT" ] && [ -z "$DOCKER_ROOT_PRESET" ]; then # Check for preset env var or interactive
    read -p "Enter the Docker config root folder [default: $DOCKER_ROOT]: " USER_INPUT_DOCKER_ROOT
fi

if [ -n "$USER_INPUT_DOCKER_ROOT" ]; then
    # Expand path if it starts with ~
    USER_INPUT_DOCKER_ROOT="${USER_INPUT_DOCKER_ROOT/#\~/$HOME}"
    DOCKER_ROOT="$USER_INPUT_DOCKER_ROOT"
fi

# Ensure DOCKER_ROOT is an absolute path
if [[ ! "$DOCKER_ROOT" = /* ]]; then
    # Handle relative paths by prepending the home directory
    DOCKER_ROOT="$HOME/$DOCKER_ROOT"
fi


# Store DOCKER_ROOT in config file
echo "{\"docker_root\": \"$DOCKER_ROOT\"}" > "$CONFIG_FILE"
export DOCKER_FOLDER="$DOCKER_ROOT" # Export for sub-scripts
mkdir -p "$DOCKER_FOLDER"
print_success "Docker root folder set to: $DOCKER_FOLDER"

# 1.5 Configure Base DNS Name
print_info "Configuring base DNS name..."
BASE_DNS_NAME=""
if [ -f "$CONFIG_FILE" ]; then
    # Ensure jq is installed
    if ! command -v jq &> /dev/null; then
        print_info "jq not found, installing..."
        sudo apt-get update && sudo apt-get install -y jq
    fi
    BASE_DNS_NAME=$(jq -r '.base_dns_name // ""' "$CONFIG_FILE") # Use // "" to handle null/missing key
fi

# Set a default if not found or empty
if [ -z "$BASE_DNS_NAME" ]; then
    BASE_DNS_NAME="yourdomain.duckdns.org" # Example default
fi

if [ -z "$USER_INPUT_BASE_DNS_NAME" ]; then
     # Only prompt if not already set via config or env
     # We check if it equals the default literal, which implies it wasn't customized
    if [ "$BASE_DNS_NAME" == "yourdomain.duckdns.org" ] || [ -z "$BASE_DNS_NAME" ]; then
         read -p "Enter the base DNS name (e.g., yourdomain.duckdns.org) [default: $BASE_DNS_NAME]: " USER_INPUT_BASE_DNS_NAME
    fi
fi

if [ -n "$USER_INPUT_BASE_DNS_NAME" ]; then
    BASE_DNS_NAME="$USER_INPUT_BASE_DNS_NAME"
fi

# Update config.json with BASE_DNS_NAME using jq
jq --arg dns "$BASE_DNS_NAME" '.base_dns_name = $dns' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
export BASE_DNS_NAME="$BASE_DNS_NAME" # Export for sub-scripts
print_success "Base DNS name set to: $BASE_DNS_NAME"

# 2. Update and upgrade OS
print_info "=======================> Updating and upgrading OS..."
sudo apt-get update
sudo apt-get upgrade -y
print_success "=======================> OS is up to date."

# 3. Make scripts executable
print_info "=======================> Making scripts executable..."
chmod +x ./scripts/install-docker.sh
chmod +x ./scripts/install-tailscale-client.sh

# 4. Install Docker
./scripts/install-docker.sh

# 5. Install Tailscale
./scripts/install-tailscale-client.sh

echo -e "\n\n"
print_success "All core installations are complete!"
print_info "Remember to log out and back in for Docker group changes to apply."
print_info "You may need to run 'tailscale up' to connect your machine to your Tailnet."

print_info "You will now be prompted to install any applications you want to use."
if [ "${SKIP_SERVICES}" != "true" ]; then
    source ./install-services.sh
else
    print_info "Skipping interactive service selection (handled by parent script)."
fi