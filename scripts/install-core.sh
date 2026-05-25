#!/bin/bash
# This script initializes the core environment for the docker-srv-hosting stack.
# It performs the following tasks:
# 1. Sets up the Docker root directory and base DNS name in a local config file.
# 2. Updates and upgrades the system's package list.
# 3. Installs the chosen container engine (Docker or Podman).
# 4. Sources the main install.sh script to allow for application-specific setups.

set -e

# --- Configuration ---
CONFIG_DIR="$HOME/.hsc"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
DEFAULT_DOCKER_ROOT="$HOME/docker_stacks"

# --- Helper Functions ---
function print_info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

function print_success() {
    echo -e "\e[32m[SUCCESS]\e[0m $1"
}

function print_warning() {
    echo -e "\e[33m[WARNING]\e[0m $1"
}

function print_error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
    exit 1
}

# --- Main Logic ---

# 1. Source configuration
# This script reads from ~/.hsc/config.yaml and ensures DOCKER_FOLDER and BASE_DNS_NAME are set.
source ./scripts/read-config.sh

print_success "Docker root folder set to: $DOCKER_FOLDER"
print_success "Base DNS name set to: $BASE_DNS_NAME"

is_windows=false
case "$(uname -s)" in
    CYGWIN*|MINGW*|MSYS*) is_windows=true ;;
esac

# 2. Update and upgrade OS
if [ "$is_windows" = false ]; then
    print_info "=======================> Updating and upgrading OS..."
    sudo apt-get update
    sudo apt-get upgrade -y
    print_success "=======================> OS is up to date."
else
    print_info "=======================> Skipping OS update on Windows Git Bash."
fi

# 3. Make scripts executable
if [ "$is_windows" = false ]; then
    print_info "=======================> Making scripts executable..."
    chmod +x ./scripts/install-container-engine.sh
    # 4. Install container engine (Docker or Podman)
    print_info "=======================> Installing container engine: $CONTAINER_ENGINE..."
    ./scripts/install-container-engine.sh
else
    print_info "=======================> Skipping container engine installation on Windows."
    print_info "Please ensure Docker Desktop or Podman Desktop is installed manually."
fi

echo -e "\n\n"
print_success "All core installations are complete!"
print_warning "------------------------------------------------------------------"
print_warning " IMPORTANT: You must now log out and log back in."
print_warning "------------------------------------------------------------------"
if [ "$CONTAINER_ENGINE" == "podman" ]; then
    print_info "This is required for Podman permissions to apply correctly."
else
    print_info "This is required for Docker permissions to apply correctly."
fi
print_info "After logging back in, run 'install.sh' again to install services."
echo ""
read -n 1 -s -r -p "Press any key to log out now..."
echo ""
logout
exit 0