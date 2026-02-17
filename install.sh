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
    "open-webui:Open WebUI"
    "watchtower:Watchtower"
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

function print_error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
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

function run_configuration_phase() {
    # This function is now idempotent and can be re-run safely.
    # It will use existing config if found, otherwise it will prompt the user.
    mkdir -p "$CONFIG_DIR"

    EXISTING_CONFIG=false
    if [ -f "$CONFIG_FILE" ]; then
        check_jq
        EXISTING_DOCKER_ROOT=$(get_config_val "docker_root")
        EXISTING_DNS=$(get_config_val "base_dns_name")
        EXISTING_BACKUP_MODE=$(get_config_val "backup_mode" || echo "none")
        EXISTING_BACKUP_PATH=$(get_config_val "backup_path" || echo "")
        EXISTING_BACKUP_TIME=$(get_config_val "backup_time" || echo "03:00")
        
        if [ -n "$EXISTING_DOCKER_ROOT" ] && [ "$EXISTING_DOCKER_ROOT" != "null" ]; then
            echo "Existing configuration found:"
            echo "  Docker Root: $EXISTING_DOCKER_ROOT"
            echo "  Base DNS:    $EXISTING_DNS"
            if [ "$EXISTING_BACKUP_MODE" != "none" ] && [ "$EXISTING_BACKUP_MODE" != "null" ]; then
                 echo "  Backup:      $EXISTING_BACKUP_MODE -> $EXISTING_BACKUP_PATH (@ $EXISTING_BACKUP_TIME)"
            fi
            echo ""
            read -p "Do you want to use this configuration? [Y/n] " use_existing
            if [[ "$use_existing" =~ ^[Nn]$ ]]; then
                 EXISTING_CONFIG=false
            else
                 EXISTING_CONFIG=true
                 DOCKER_ROOT="$EXISTING_DOCKER_ROOT"
                 BASE_DNS_NAME="$EXISTING_DNS"
                 BACKUP_MODE="$EXISTING_BACKUP_MODE"
                 BACKUP_PATH="$EXISTING_BACKUP_PATH"
                 BACKUP_TIME="$EXISTING_BACKUP_TIME"
            fi
        fi
    fi

    if [ "$EXISTING_CONFIG" = false ]; then
        read -p "Enter the Docker config root folder [default: $DEFAULT_DOCKER_ROOT]: " USER_INPUT_DOCKER_ROOT
        DOCKER_ROOT="${USER_INPUT_DOCKER_ROOT:-$DEFAULT_DOCKER_ROOT}"
        DOCKER_ROOT="${DOCKER_ROOT/#\~/$HOME}" 
        [[ "$DOCKER_ROOT" != /* ]] && DOCKER_ROOT="$HOME/$DOCKER_ROOT"

        read -p "Enter the base DNS name (e.g., yourdomain.duckdns.org): " BASE_DNS_NAME
        
        # --- Backup Configuration ---
        BACKUP_MODE="none"
        BACKUP_PATH=""
        BACKUP_TIME="03:00"

        read -p "Do you want to enable automatic backups? [y/N] " ENABLE_BACKUP
        if [[ "$ENABLE_BACKUP" =~ ^[Yy]$ ]]; then
            echo ""
            echo "Select Backup Destination Type:"
            echo "1) Dedicated Disk (Will be formatted!)"
            echo "2) Local Folder"
            read -p "Enter choice [1/2]: " BACKUP_TYPE_CHOICE
            
            if [ "$BACKUP_TYPE_CHOICE" == "1" ]; then
                BACKUP_MODE="disk"
                echo ""
                echo "Available Block Devices:"
                # Try to list disks, fallback if lsblk not found
                if command -v lsblk &> /dev/null; then
                    lsblk -dpn -o NAME,SIZE,MODEL,TYPE | grep -E 'disk|part' || echo "No suitable devices found."
                else
                     echo "lsblk not found. Please enter device path manually."
                fi
                echo ""
                read -p "Enter the full path of the device to use (e.g., /dev/sdb): " BACKUP_DEVICE
                
                # Check blocks
                if [ ! -b "$BACKUP_DEVICE" ]; then
                    print_error "Device $BACKUP_DEVICE not found or not a block device. Disabling backup."
                    BACKUP_MODE="none"
                else
                    read -p "Enter mount point for backup drive [default: /mnt/backup-drive]: " BACKUP_MOUNT
                    BACKUP_PATH="${BACKUP_MOUNT:-/mnt/backup-drive}"
                    
                    # Prepare the disk immediately
                    print_info "Preparing backup disk (requires sudo)..."
                    sudo ./scripts/backup-utils.sh setup_disk "$BACKUP_DEVICE" "$BACKUP_PATH"
                fi
            elif [ "$BACKUP_TYPE_CHOICE" == "2" ]; then
                BACKUP_MODE="folder"
                read -p "Enter the backup directory path [default: $HOME/backups]: " BACKUP_FOLDER
                BACKUP_PATH="${BACKUP_FOLDER:-$HOME/backups}"
                BACKUP_PATH="${BACKUP_PATH/#\~/$HOME}"
                mkdir -p "$BACKUP_PATH"
            else
                print_warning "Invalid choice. Disabling backup."
            fi
            
            if [ "$BACKUP_MODE" != "none" ]; then
                read -p "Enter daily backup time (HH:MM) [default: 03:00]: " USER_TIME
                BACKUP_TIME="${USER_TIME:-03:00}"
                print_success "Backup enabled: $BACKUP_MODE -> $BACKUP_PATH at $BACKUP_TIME"
            fi
        fi

        check_jq
        # Initialize with empty backups array if creating new
        jq -n \
          --arg dr "$DOCKER_ROOT" \
          --arg dns "$BASE_DNS_NAME" \
          --arg bm "$BACKUP_MODE" \
          --arg bp "$BACKUP_PATH" \
          --arg bt "$BACKUP_TIME" \
          --argjson bk "[]" \
          '{docker_root: $dr, base_dns_name: $dns, backup_mode: $bm, backup_path: $bp, backup_time: $bt, backups: $bk}' > "$CONFIG_FILE"
        print_success "Configuration saved."
    fi
}

function run_service_installation_phase() {
    # Service Selection
    echo ""
    echo "--- Service Selection ---"
    for service_entry in "${AVAILABLE_SERVICES[@]}"; do
        KEY="${service_entry%%:*}"
        NAME="${service_entry#*:}"
        [ ! -d "$KEY" ] && continue
        read -p "Install $NAME? [y/N] " INSTALL_SRV
        if [[ "$INSTALL_SRV" =~ ^[Yy]$ ]]; then
            SERVICES_TO_INSTALL+=("$KEY")
        fi
    done

    # Installation Execution
    echo ""
    echo "--- Ready to Install ---"
    echo "Docker Root: $DOCKER_ROOT"
    echo "Base DNS:    $BASE_DNS_NAME"
    echo "Services:    ${SERVICES_TO_INSTALL[*]}"
    if [ "$BACKUP_MODE" != "none" ]; then
        echo "Backup:      $BACKUP_MODE -> $BACKUP_PATH (@ $BACKUP_TIME)"
    fi
    echo ""
    read -p "Press Enter to start installation..."

    if [ ${#SERVICES_TO_INSTALL[@]} -eq 0 ]; then
        print_info "No services selected. Exiting."
        exit 0
    fi

    print_info "Installing Services..."
    export DOCKER_FOLDER="$DOCKER_ROOT"
    export BASE_DNS_NAME="$BASE_DNS_NAME"
    
    # Capture current repo root to call scripts absolutely
    REPO_ROOT=$(pwd)

    export HSC_CONFIG_PATH="$CONFIG_FILE"
    for SERVICE_DIR in "${SERVICES_TO_INSTALL[@]}"; do
        print_info "Installing $SERVICE_DIR..."
        if [ -d "$SERVICE_DIR" ]; then
            cd "$SERVICE_DIR"
            # The sub-scripts will source read-config.sh to get config
            # and detect if they need to use sudo for docker commands.
            if [ -f "install.sh" ]; then
                chmod +x install.sh && ./install.sh
            elif [ -f "install-portainer-agent.sh" ]; then 
                chmod +x install-portainer-agent.sh && ./install-portainer-agent.sh
            else
                print_warning "No install script found in $SERVICE_DIR"
            fi
            
            # Configure Backup for this Service if enabled
            if [ "$BACKUP_MODE" != "none" ]; then
                 # Construct absolute path to the likely data location in DOCKER_ROOT
                 TARGET_DATA_DIR="$DOCKER_ROOT/$SERVICE_DIR"
                 
                 # Ensure directory exists (might be owned by root if created by docker daemon)
                 # but we try to create it as user first if it doesn't exist
                 [ ! -d "$TARGET_DATA_DIR" ] && mkdir -p "$TARGET_DATA_DIR" 2>/dev/null || true

                 if [ -d "$TARGET_DATA_DIR" ]; then
                      print_info "Configuring backup for $SERVICE_DIR..."
                      sudo -E "$REPO_ROOT/scripts/backup-utils.sh" configure_service "$TARGET_DATA_DIR" "$BACKUP_PATH"
                 else
                      print_warning "Could not locate service data at $TARGET_DATA_DIR for backup configuration."
                 fi
            fi


            cd - > /dev/null
        else
            print_error "Directory $SERVICE_DIR not found!"
        fi
    done
    
    # Finalize Backup Schedule
    if [ "$BACKUP_MODE" != "none" ]; then
        print_info "Finalizing backup schedule..."
        sudo "$REPO_ROOT/scripts/backup-utils.sh" finalize "$BACKUP_TIME"
    fi

    print_success "Service installation complete!"
}


# --- Main Logic ---

print_header

# Case 1: Running inside a Docker container
if [ -f "/.dockerenv" ]; then
    print_info "Installer is running inside a Docker container."
    
    if ! command -v docker &> /dev/null; then
         print_error "Docker command is not available inside this container."
         echo "Please make sure the container has docker client installed and the docker socket is mounted."
         exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_error "Cannot connect to the Docker daemon."
        print_info "If you are running the installer inside a container, you must mount the host's Docker socket."
        print_info "Example: docker run -v /var/run/docker.sock:/var/run/docker.sock ..."
        exit 1
    fi
    
    print_success "Docker connection is working. Proceeding with service installation."
    run_configuration_phase
    run_service_installation_phase

# Case 2: Running on a host, Docker is not installed
elif ! command -v docker &> /dev/null; then
    print_info "Docker is not detected on this system. Starting initial setup."
    
    run_configuration_phase
    
    print_info "Running Core Installation (Docker, Tailscale, etc.)..."
    ./install-core.sh

    echo ""
    print_success "Core system setup is complete!"
    print_warning "------------------------------------------------------------------"
    print_warning " IMPORTANT: You must now log out and log back in."
    print_warning "------------------------------------------------------------------"
    print_info "This is required for Docker permissions to apply correctly."
    print_info "After logging back in, run this script again ('./install.sh') to install your services."
    echo ""
    exit 0

# Case 3: Running on a host, Docker is already installed
else
    print_info "Docker is detected. Proceeding with service installation."
    
    run_configuration_phase
    run_service_installation_phase
fi
