#!/bin/bash
set -e

# --- Configuration ---
CONFIG_DIR="$HOME/.hsc"
CONFIG_FILE="$CONFIG_DIR/config.json"
DEFAULT_DOCKER_ROOT="$HOME/docker_stacks"
BACKUP_MODE="none" # none, disk, folder
BACKUP_PATH=""
SERVICES_TO_INSTALL=()
# List of availalble services (folder_name:Display Name)
AVAILABLE_SERVICES=(
    "portainer:Portainer"
    "portainer/portainer-agent:Portainer Agent"
    "ollama:Ollama"
    "docmost:Docmost"
    "glance-dashboard:Glance Dashboard"
    "headscale:Headscale"
    "home-assistant:Home Assistant"
    "immich:Immich"
    "linux-in-docker:Linux in Docker"
    "nextcloud-aio:Nextcloud AIO"
    "nginx-reverse-proxy:Nginx Reverse Proxy"
    "registry:Registry"
    "traccar:Traccar"
    "vaultwarden:Vaultwarden"
    "verdaccio:Verdaccio"
)

# --- Helper Functions ---
function print_header() {
    clear
    echo "=================================================================="
    echo "       Home Server Center - Streamlined Installer"
    echo "=================================================================="
    echo ""
}

function print_info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

function print_success() {
    echo -e "\e[32m[SUCCESS]\e[0m $1"
}

function print_warning() {
    echo -e "\e[33m[WARNING]\e[0m $1"
}

function check_jq() {
     if ! command -v jq &> /dev/null; then
        print_info "jq not found, installing..."
        sudo apt-get update && sudo apt-get install -y jq
    fi
}

function get_config_val() {
    jq -r ".$1" "$CONFIG_FILE" 2>/dev/null
}

# --- Main Logic ---
print_header

# 1. Configuration Phase
mkdir -p "$CONFIG_DIR"

EXISTING_CONFIG=false
if [ -f "$CONFIG_FILE" ]; then
    check_jq
    EXISTING_DOCKER_ROOT=$(get_config_val "docker_root")
    EXISTING_DNS=$(get_config_val "base_dns_name")
    
    if [ -n "$EXISTING_DOCKER_ROOT" ] && [ "$EXISTING_DOCKER_ROOT" != "null" ]; then
        echo "Existing configuration found:"
        echo "  Docker Root: $EXISTING_DOCKER_ROOT"
        echo "  Base DNS:    $EXISTING_DNS"
        echo ""
        read -p "Do you want to use this configuration? [Y/n] " use_existing
        if [[ "$use_existing" =~ ^[Nn]$ ]]; then
             EXISTING_CONFIG=false
        else
             EXISTING_CONFIG=true
             DOCKER_ROOT="$EXISTING_DOCKER_ROOT"
             BASE_DNS_NAME="$EXISTING_DNS"
             # Load backup config if present
             BACKUP_MODE=$(get_config_val "backup_mode" || echo "none")
             BACKUP_PATH=$(get_config_val "backup_path" || echo "")
        fi
    fi
fi

if [ "$EXISTING_CONFIG" = false ]; then
    # Docker Root
    read -p "Enter the Docker config root folder [default: $DEFAULT_DOCKER_ROOT]: " USER_INPUT_DOCKER_ROOT
    DOCKER_ROOT="${USER_INPUT_DOCKER_ROOT:-$DEFAULT_DOCKER_ROOT}"
    # Expand tilde
    DOCKER_ROOT="${DOCKER_ROOT/#\~/$HOME}" 
    # Ensure absolute path
    [[ "$DOCKER_ROOT" != /* ]] && DOCKER_ROOT="$HOME/$DOCKER_ROOT"

    # Base DNS
    read -p "Enter the base DNS name (e.g., yourdomain.duckdns.org): " BASE_DNS_NAME

    # Backup Configuration
    echo ""
    echo "--- Backup Configuration ---"
    read -p "Do you want to enable automatic backups? [y/N] " ENABLE_BACKUP
    if [[ "$ENABLE_BACKUP" =~ ^[Yy]$ ]]; then
        echo "Select backup target:"
        echo "  1) Specific Disk (Will be formatted if not already set up)"
        echo "  2) Existing Folder"
        read -p "Select option [1-2]: " BACKUP_OPT
        
        if [ "$BACKUP_OPT" == "1" ]; then
            BACKUP_MODE="disk"
            # Logic to select disk will happen in executing phase via backup-utils script to avoid sudo here if possible, 
            # OR we do it here. Let's do it here to save config.
            echo "Scanning for disks..."
            lsblk -dno NAME,SIZE,MODEL | grep -vE "boot|loop|rpmb" | awk '{print NR") /dev/"$1" ("$2", "$3")"}'
            read -p "Enter the number of the disk to use (e.g. 1): " DISK_NUM
            # Mapping number to device is tricky without array persistence reliable across shells in simple read.
            # Let's simple ask for device name for now or improve filtering.
            echo "Enter the device path (e.g., /dev/sda). WARNING: THIS DISK WILL BE USED FOR BACKUPS."
            read -p "Device Path: " BACKUP_PATH
        elif [ "$BACKUP_OPT" == "2" ]; then
            BACKUP_MODE="folder"
            read -p "Enter absolute path to backup folder: " BACKUP_PATH
        else
            echo "Invalid option, disabling backups."
            BACKUP_MODE="none"
        fi
    fi
    
    # Save Config
    check_jq
    # Create JSON using jq
    jq -n \
      --arg dr "$DOCKER_ROOT" \
      --arg dns "$BASE_DNS_NAME" \
      --arg bm "$BACKUP_MODE" \
      --arg bp "$BACKUP_PATH" \
      '{docker_root: $dr, base_dns_name: $dns, backup_mode: $bm, backup_path: $bp}' > "$CONFIG_FILE"
      
    print_success "Configuration saved."
fi

# 2. Service Selection Phase
echo ""
echo "--- Service Selection ---"
echo "Select services to install:"

# If we are re-running, we might want to check what is already installed.
# For now, just ask what to install newly.

for service_entry in "${AVAILABLE_SERVICES[@]}"; do
    KEY="${service_entry%%:*}"
    NAME="${service_entry#*:}"
    
    # Check if folder exists
    if [ ! -d "$KEY" ]; then
        continue 
    fi

    read -p "Install $NAME? [y/N] " INSTALL_SRV
    if [[ "$INSTALL_SRV" =~ ^[Yy]$ ]]; then
        SERVICES_TO_INSTALL+=("$KEY")
    fi
done

# 3. Execution Phase
echo ""
echo "--- Ready to Install ---"
echo "Docker Root: $DOCKER_ROOT"
echo "Base DNS:    $BASE_DNS_NAME"
echo "Backup Mode: $BACKUP_MODE ($BACKUP_PATH)"
echo "Services:    ${SERVICES_TO_INSTALL[*]}"
echo ""
read -p "Press Enter to start installation..."

# Run Core Install (Non-Interactive)
# We need to export variables so install-core doesn't prompt
export DOCKER_FOLDER="$DOCKER_ROOT" # install-core uses DOCKER_FOLDER logic internally via config check, but being explicit helps
# install-core reads from config.json, which we just wrote. 

print_header
print_info "Running Core Installation..."
./install-core.sh

# Run Service Installs
if [ ${#SERVICES_TO_INSTALL[@]} -eq 0 ]; then
    print_info "No specific services selected."
else
    print_info "Installing Services..."
    export DOCKER_FOLDER="$DOCKER_ROOT"
    
    for SERVICE_DIR in "${SERVICES_TO_INSTALL[@]}"; do
        print_info "Installing $SERVICE_DIR..."
        if [ -d "$SERVICE_DIR" ]; then
            cd "$SERVICE_DIR"
            if [ -f "install.sh" ]; then
                chmod +x install.sh
                ./install.sh
            elif [ -f "install-portainer-agent.sh" ]; then 
                chmod +x install-portainer-agent.sh
                ./install-portainer-agent.sh
            else
                print_warning "No install.sh found in $SERVICE_DIR"
            fi
            cd - > /dev/null
            
            # Hook for Backup Setup
            if [ "$BACKUP_MODE" != "none" ] && [ -n "$BACKUP_PATH" ]; then
                print_info "Configuring backup for $SERVICE_DIR..."
                # Calls the backup utility to generate/copy backup script for this service
                ./scripts/backup-utils.sh configure_service "$SERVICE_DIR" "$BACKUP_PATH"
            fi
            
        else
            print_error "Directory $SERVICE_DIR not found!"
        fi
    done
fi

# Finalize Backup
if [ "$BACKUP_MODE" != "none" ]; then
    print_info "Finalizing Backup Configuration..."
    ./scripts/backup-utils.sh finalize "$BACKUP_MODE" "$BACKUP_PATH"
fi

print_success "Installation Complete!"
