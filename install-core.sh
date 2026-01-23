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

# 1. Source configuration
# This script reads from ~/.hsc/config.json and ensures DOCKER_FOLDER and BASE_DNS_NAME are set.
source ./scripts/read-config.sh

print_success "Docker root folder set to: $DOCKER_FOLDER"
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
read -p "Do you want to install the Tailscale client? (only relevant if you plan to use Tailscale or Headscale) [y/N] " INSTALL_TS
if [[ "$INSTALL_TS" =~ ^[Yy]$ ]]; then
    ./scripts/install-tailscale-client.sh
    print_info "You may need to run 'tailscale up' to connect your machine to your Tailnet."
else
    print_info "Skipping Tailscale installation."
fi

echo -e "\n\n"
print_success "All core installations are complete!"
print_warning "------------------------------------------------------------------"
print_warning " IMPORTANT: You must now log out and log back in."
print_warning "------------------------------------------------------------------"
print_info "This is required for Docker permissions to apply correctly."
print_info "After logging back in, run 'install.sh' again to install services."
echo ""
read -n 1 -s -r -p "Press any key to log out now..."
echo ""
logout
exit 0