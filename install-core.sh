#!/bin/bash
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

read -p "Enter the Docker config root folder [default: $DOCKER_ROOT]: " USER_INPUT_DOCKER_ROOT
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

read -p "Enter the base DNS name (e.g., yourdomain.duckdns.org) [default: $BASE_DNS_NAME]: " USER_INPUT_BASE_DNS_NAME
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

# 3. Install Docker
print_info "=======================> Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
    print_success "Docker installed successfully. You may need to log out and back in for group changes to take effect."
else
    print_info "Docker is already installed."
fi

# 4. Install Tailscale
print_info "=======================> Installing Tailscale..."
if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
    print_success "Tailscale installed successfully."
else
    print_info "Tailscale is already installed."
fi

echo -e "\n\n"
print_success "All core installations are complete!"
print_info "Remember to log out and back in for Docker group changes to apply."
print_info "You may need to run 'tailscale up' to connect your machine to your Tailnet."

print_info "You will now be prompted to install any applications you want to use."
source ./install.sh