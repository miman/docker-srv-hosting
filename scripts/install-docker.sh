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
print_info "=======================> Installing Docker..."
if ! command -v docker &> /dev/null; then
    echo "Choose your Docker installation preference:"
    echo "1) Install for Ubuntu"
    echo "2) Install for Raspberry Pi (Debian)"
    echo "3) Don\'t install Docker"
    read -p "Enter your choice [1-3]: " docker_choice

    DOCKER_REPO_URL_PART=""
    CODENAME=""

    case $docker_choice in
        1) 
            print_info "Preparing to install Docker for Ubuntu..."
            DOCKER_REPO_URL_PART="ubuntu"
            CODENAME=$(lsb_release -cs)
            ;; 
        2) 
            print_info "Preparing to install Docker for Raspberry Pi (Debian)..."
            DOCKER_REPO_URL_PART="debian"
            CODENAME=$(lsb_release -cs)
            if [[ "$CODENAME" == "trixie" ]]; then
                CODENAME="bookworm"
            fi
            ;; 
        3) 
            print_info "Skipping Docker installation."
            ;; 
        *) 
            print_info "Invalid choice. Skipping Docker installation."
            ;; 
    esac

    if [[ "$docker_choice" == "1" || "$docker_choice" == "2" ]]; then
        print_info "Installing Docker..."
        # Remove existing docker list to avoid conflicts
        sudo rm -f /etc/apt/sources.list.d/docker.list
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL "https://download.docker.com/linux/${DOCKER_REPO_URL_PART}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_REPO_URL_PART} ${CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker $USER
        print_success "Docker installed successfully. You may need to log out and back in for group changes to take effect."
    fi
else
    print_info "Docker is already installed."
fi