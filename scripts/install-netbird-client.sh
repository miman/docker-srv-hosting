#!/bin/bash
set -e

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
print_info "=======================> Installing NetBird Client (Host Machine)..."

# 1. Check if NetBird is already installed
if command -v netbird &> /dev/null; then
    print_info "NetBird client is already installed."
    netbird version
    exit 0
fi

# 2. Check for required utilities
if ! command -v curl &> /dev/null; then
    print_info "curl is required. Installing curl..."
    sudo apt-get update && sudo apt-get install -y curl
fi

# 3. Download and run the official NetBird automated installation script
# This handles adding the repository and installing the native package for your distribution
if curl -fsSL https://pkgs.netbird.io/install.sh | sh; then
    print_success "NetBird client packages installed successfully."
else
    print_error "Failed to install NetBird client using the official script."
fi

# 4. Verify installation and start service if necessary
# 4. Verify installation and start service if necessary
if command -v netbird &> /dev/null; then
    print_success "NetBird client is now available!"
    echo ""
    print_info "To connect this machine to your NetBird network:"
    echo ""
    echo -e "  \e[1mIf using NetBird Cloud (default):\e[0m"
    echo -e "    \e[33mnetbird up\e[0m"
    echo ""
    echo -e "  \e[1mIf using your own self-hosted NetBird Server:\e[0m"
    echo -e "    \e[33mnetbird up --management-url <YOUR_NETBIRD_URL>\e[0m"
    echo ""
else
    print_error "NetBird binary not found after installation loop."
fi