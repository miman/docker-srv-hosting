#!/bin/bash
set -e

# --- Configuration ---
CONFIG_DIR="$HOME/.hsc"
CONFIG_FILE="$CONFIG_DIR/config.yaml"
DEFAULT_DOCKER_ROOT="$HOME/docker_stacks"
BACKUP_MODE="none" # none, disk, folder
BACKUP_PATH=""
SERVICES_TO_INSTALL=()

# Source read-config.sh to get container engine settings (CONTAINER_CMD, COMPOSE_CMD)
# This will also prompt the user for container engine choice if not configured.
# Only source if config already exists (first-run will go through install-core.sh instead)
if [ -f "$CONFIG_FILE" ] && [ -f "./scripts/read-config.sh" ]; then
    source ./scripts/read-config.sh
else
    # Config doesn't exist yet (first run), but we still need to determine the container engine.
    # Prompt the user now and save it so install-core.sh and sub-scripts can use it.
    export HSC_CONFIG_PATH="${HSC_CONFIG_PATH:-$HOME/.hsc/config.yaml}"
    if [ -z "$CONTAINER_ENGINE" ]; then
        echo ""
        echo "No container engine configured. Which container engine do you want to use?"
        echo "1) docker"
        echo "2) podman"
        read -p "Enter your choice [1-2]: " engine_choice
        case $engine_choice in
            1) CONTAINER_ENGINE="docker" ;;
            2) CONTAINER_ENGINE="podman" ;;
            *) echo "Invalid choice, defaulting to docker."; CONTAINER_ENGINE="docker" ;;
        esac
        # Save the choice to config
        mkdir -p "$(dirname "$HSC_CONFIG_PATH")"
        if [ ! -f "$HSC_CONFIG_PATH" ]; then
            echo "container_engine: \"${CONTAINER_ENGINE}\"" > "$HSC_CONFIG_PATH"
            chmod 600 "$HSC_CONFIG_PATH"
        elif grep -q "^container_engine:" "$HSC_CONFIG_PATH"; then
            _tmp_file=$(mktemp)
            sed "s|^container_engine:.*|container_engine: \"${CONTAINER_ENGINE}\"|" "$HSC_CONFIG_PATH" > "$_tmp_file" && mv "$_tmp_file" "$HSC_CONFIG_PATH"
        else
            echo "container_engine: \"${CONTAINER_ENGINE}\"" >> "$HSC_CONFIG_PATH"
        fi
        echo "Saved container engine preference: $CONTAINER_ENGINE"
    fi
    export CONTAINER_ENGINE

    # Define a wrapper function for Compose commands to support dynamic Podman overrides
    run_compose() {
        local cmd=()
        if [ "$CONTAINER_ENGINE" == "podman" ]; then
            cmd=("podman" "compose")
            local args=()
            local has_f=false
            
            # Parse arguments to find any explicit compose file (-f or --file)
            local i=1
            while [ $i -le $# ]; do
                local arg="${!i}"
                if [ "$arg" == "-f" ] || [ "$arg" == "--file" ]; then
                    has_f=true
                    local next_idx=$((i + 1))
                    local file="${!next_idx}"
                    args+=("$arg" "$file")
                    
                    # Check if there is a podman override file for this specific compose file
                    # e.g., docker-compose.yml -> docker-compose.podman.yml
                    local ext="${file##*.}"
                    local base="${file%.*}"
                    local podman_file="${base}.podman.${ext}"
                    if [ -f "$podman_file" ]; then
                        args+=("-f" "$podman_file")
                    fi
                    i=$((i + 2))
                else
                    args+=("$arg")
                    i=$((i + 1))
                fi
            done
            
            # If no explicit -f flag was passed, look for default compose files and their overrides
            if [ "$has_f" = false ]; then
                local main_file=""
                local podman_file=""
                if [ -f "docker-compose.yml" ]; then
                    main_file="docker-compose.yml"
                    [ -f "docker-compose.podman.yml" ] && podman_file="docker-compose.podman.yml"
                elif [ -f "docker-compose.yaml" ]; then
                    main_file="docker-compose.yaml"
                    [ -f "docker-compose.podman.yaml" ] && podman_file="docker-compose.podman.yaml"
                fi
                
                if [ -n "$main_file" ]; then
                    cmd+=("-f" "$main_file")
                    [ -n "$podman_file" ] && cmd+=("-f" "$podman_file")
                fi
            fi
            
            cmd+=("${args[@]}")
        else
            cmd=("docker" "compose")
            cmd+=("$@")
        fi
        "${cmd[@]}"
    }
    export -f run_compose

    if [ "$CONTAINER_ENGINE" == "podman" ]; then
        export CONTAINER_CMD="podman"
        export COMPOSE_CMD="run_compose"
        export RESTART_POLICY="always"
    else
        export CONTAINER_CMD="docker"
        export COMPOSE_CMD="run_compose"
        export RESTART_POLICY="unless-stopped"
    fi
fi
# List of availalble services (folder_name:Display Name)
AVAILABLE_SERVICES=(
    "infrastructure/portainer:Portainer"
    "infrastructure/portainer/portainer-agent:Portainer Agent"
    "ai/ollama:Ollama"
    "ai/open-webui:Open WebUI"
    "infrastructure/watchtower:Watchtower"
    "cloud-services/docmost:Docmost"
    "cloud-services/glance-dashboard:Glance Dashboard"
    "infrastructure/headscale:Headscale"
    "infrastructure/netbird/client:Netbird Client"
    "infrastructure/netbird/server:Netbird Server"
    "cloud-services/home-assistant:Home Assistant"
    "cloud-services/immich:Immich"
    "cloud-services/linux-in-docker:Linux in Docker"
    "cloud-services/nextcloud:Nextcloud"
    "cloud-services/nextcloud-aio:Nextcloud AIO"
    "infrastructure/nginx-reverse-proxy:Nginx Reverse Proxy"
    "infrastructure/duckdns-updater:DuckDNS"
    "infrastructure/registry:Registry"
    "ai/searxng:SearXNG"
    "ai/comfy_ui:ComfyUI"
    "cloud-services/synapse:Synapse"
    "cloud-services/traccar:Traccar"
    "cloud-services/vaultwarden:Vaultwarden"
    "development/verdaccio:Verdaccio"
    "infrastructure/uptime-kuma:Uptime Kuma"
    "infrastructure/beszel:Beszel"
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



function get_config_val() {
    local key="$1"
    if [ -f "$CONFIG_FILE" ]; then
        grep "^${key}:" "$CONFIG_FILE" | sed -e "s/^${key}:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//"
    fi
}

function run_configuration_phase() {
    # This function is now idempotent and can be re-run safely.
    # It will use existing config if found, otherwise it will prompt the user.
    mkdir -p "$CONFIG_DIR"

    EXISTING_CONFIG=false
    if [ -f "$CONFIG_FILE" ]; then
        EXISTING_DOCKER_ROOT=$(get_config_val "docker_root")
        EXISTING_DNS=$(get_config_val "base_dns_name")
        EXISTING_BACKUP_MODE=$(get_config_val "backup_mode")
        [ -z "$EXISTING_BACKUP_MODE" ] || [ "$EXISTING_BACKUP_MODE" == "null" ] && EXISTING_BACKUP_MODE="none"
        EXISTING_BACKUP_PATH=$(get_config_val "backup_path")
        [ -z "$EXISTING_BACKUP_PATH" ] || [ "$EXISTING_BACKUP_PATH" == "null" ] && EXISTING_BACKUP_PATH=""
        EXISTING_BACKUP_TIME=$(get_config_val "backup_time")
        [ -z "$EXISTING_BACKUP_TIME" ] || [ "$EXISTING_BACKUP_TIME" == "null" ] && EXISTING_BACKUP_TIME="03:00"
        EXISTING_BACKUP_RETENTION=$(get_config_val "backup_retention")
        [ -z "$EXISTING_BACKUP_RETENTION" ] || [ "$EXISTING_BACKUP_RETENTION" == "null" ] && EXISTING_BACKUP_RETENTION="5"
        EXISTING_EXTERNAL_DUCKDNS=$(get_config_val "external_duckdns_name")
        
        if [ -n "$EXISTING_DOCKER_ROOT" ] && [ "$EXISTING_DOCKER_ROOT" != "null" ]; then
            echo "Existing configuration found:"
            echo "  Docker Root: $EXISTING_DOCKER_ROOT"
            echo "  Base DNS:    $EXISTING_DNS"
            if [ "$EXISTING_BACKUP_MODE" != "none" ] && [ "$EXISTING_BACKUP_MODE" != "null" ]; then
                 echo "  Backup:      $EXISTING_BACKUP_MODE -> $EXISTING_BACKUP_PATH (@ $EXISTING_BACKUP_TIME, keep $EXISTING_BACKUP_RETENTION)"
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
                 BACKUP_RETENTION="$EXISTING_BACKUP_RETENTION"
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
        BACKUP_RETENTION=5

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
                    SUDO_CMD="sudo "
                    case "$(uname -s)" in CYGWIN*|MINGW*|MSYS*) SUDO_CMD="" ;; esac
                    $SUDO_CMD ./scripts/backup-utils.sh setup_disk "$BACKUP_DEVICE" "$BACKUP_PATH"
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
                read -p "Max backup snapshots to keep per service [default: 5]: " USER_RETENTION
                BACKUP_RETENTION="${USER_RETENTION:-5}"
                print_success "Backup enabled: $BACKUP_MODE -> $BACKUP_PATH at $BACKUP_TIME (keeping $BACKUP_RETENTION snapshots)"
            fi
        fi

        # Write config.yaml
        echo "docker_root: \"$DOCKER_ROOT\"" > "$CONFIG_FILE"
        echo "base_dns_name: \"$BASE_DNS_NAME\"" >> "$CONFIG_FILE"
        echo "backup_mode: \"$BACKUP_MODE\"" >> "$CONFIG_FILE"
        echo "backup_path: \"$BACKUP_PATH\"" >> "$CONFIG_FILE"
        echo "backup_time: \"$BACKUP_TIME\"" >> "$CONFIG_FILE"
        echo "backup_retention: \"$BACKUP_RETENTION\"" >> "$CONFIG_FILE"
        if [ -n "$EXISTING_EXTERNAL_DUCKDNS" ] && [ "$EXISTING_EXTERNAL_DUCKDNS" != "null" ]; then
             echo "external_duckdns_name: \"$EXISTING_EXTERNAL_DUCKDNS\"" >> "$CONFIG_FILE"
        fi
        touch "$CONFIG_DIR/backups.yaml"
        touch "$CONFIG_DIR/watchtower_configs.yaml"
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
        echo "Backup:      $BACKUP_MODE -> $BACKUP_PATH (@ $BACKUP_TIME, keep $BACKUP_RETENTION)"
    fi
    echo ""
    read -p "Press Enter to start installation..."

    if [ ${#SERVICES_TO_INSTALL[@]} -eq 0 ] && [ "$BACKUP_MODE" == "none" ]; then
        print_info "No services selected. Exiting."
        exit 0
    fi

    # Capture current repo root to call scripts absolutely
    REPO_ROOT=$(pwd)
    export HSC_CONFIG_PATH="$CONFIG_FILE"

    if [ ${#SERVICES_TO_INSTALL[@]} -gt 0 ]; then
        print_info "Installing Services..."
        export DOCKER_FOLDER="$DOCKER_ROOT"
        export BASE_DNS_NAME="$BASE_DNS_NAME"
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
                 SERVICE_NAME=$(basename "$SERVICE_DIR")
                 TARGET_DATA_DIR="$DOCKER_ROOT/$SERVICE_NAME"
                 
                 # Ensure directory exists (might be owned by root if created by docker daemon)
                 # but we try to create it as user first if it doesn't exist
                 [ ! -d "$TARGET_DATA_DIR" ] && mkdir -p "$TARGET_DATA_DIR" 2>/dev/null || true

                 if [ -d "$TARGET_DATA_DIR" ]; then
                      print_info "Configuring backup for $SERVICE_NAME..."
                      SUDO_CMD="sudo -E "
                      case "$(uname -s)" in CYGWIN*|MINGW*|MSYS*) SUDO_CMD="" ;; esac
                      $SUDO_CMD "$REPO_ROOT/scripts/backup-utils.sh" configure_service "$TARGET_DATA_DIR" "$BACKUP_PATH"
                 else
                      print_warning "Could not locate service data at $TARGET_DATA_DIR for backup configuration."
                 fi
            fi


            cd - > /dev/null
        else
            print_error "Directory $SERVICE_DIR not found!"
        fi
    done
    fi
    
    # Finalize Backup Schedule
    if [ "$BACKUP_MODE" != "none" ]; then
        print_info "Finalizing backup schedule..."
        SUDO_CMD="sudo "
        case "$(uname -s)" in CYGWIN*|MINGW*|MSYS*) SUDO_CMD="" ;; esac
        $SUDO_CMD "$REPO_ROOT/scripts/backup-utils.sh" finalize "$BACKUP_TIME"
    fi

    print_success "Service installation complete!"
}


# --- Main Logic ---

print_header

# Case 1: Running inside a Docker container
if [ -f "/.dockerenv" ]; then
    print_info "Installer is running inside a Docker container."
    
    if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
         print_error "Neither docker nor podman command is available inside this container."
         echo "Please make sure the container has a container client installed and the socket is mounted."
         exit 1
    fi
    
    if ! $CONTAINER_CMD info >/dev/null 2>&1; then
        print_error "Cannot connect to the container daemon ($CONTAINER_CMD)."
        print_info "If you are running the installer inside a container, you must mount the host's socket."
        print_info "Example: docker run -v /var/run/docker.sock:/var/run/docker.sock ..."
        exit 1
    fi
    
    print_success "Container engine connection is working. Proceeding with service installation."
    run_configuration_phase
    run_service_installation_phase

# Case 2: Running on a host, container engine is not installed
elif ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
    print_info "No container engine (docker/podman) detected on this system. Starting initial setup."
    
    run_configuration_phase
    
    print_info "Running Core Installation (container engine, etc.)..."
    ./scripts/install-core.sh

    echo ""
    print_success "Core system setup is complete!"
    print_warning "------------------------------------------------------------------"
    print_warning " IMPORTANT: You must now log out and log back in."
    print_warning "------------------------------------------------------------------"
    print_info "This is required for container engine permissions to apply correctly."
    print_info "After logging back in, run this script again ('./install.sh') to install your services."
    echo ""
    exit 0

# Case 3: Running on a host, container engine is already installed
else
    print_info "Container engine ($CONTAINER_ENGINE) is detected. Proceeding with service installation."
    
    run_configuration_phase
    run_service_installation_phase
fi
