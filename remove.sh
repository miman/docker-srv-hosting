#!/bin/bash
set -e

# --- Configuration & Paths ---
CONFIG_DIR="$HOME/.hsc"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

# Helper Functions for UI styling
function print_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
function print_success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
function print_warning() { echo -e "\e[33m[WARNING]\e[0m $1"; }
function print_error() { echo -e "\e[31m[ERROR]\e[0m $1" >&2; exit 1; }

# 1. Source core system configuration to get CONTAINER_ENGINE and DOCKER_FOLDER
if [ -f "$CONFIG_FILE" ] && [ -f "./scripts/read-config.sh" ]; then
    source "./scripts/read-config.sh"
else
    print_error "Configuration file not found. Have you completed the installation phase yet?"
fi

# 2. Source the shared services definition file (One Source of Truth)
if [ -f "./scripts/services.sh" ]; then
    source "./scripts/services.sh"
else
    print_error "Shared services definition file missing at './scripts/services.sh'."
fi

print_info "=======================> Starting Service Removal Phase..."

# Track what is actually found dynamically on the drive
INSTALLED_SERVICES=()
INSTALLED_PATHS=()

# 3. Detect which services from the shared array have active directories inside ~/docker_stacks
for service_info in "${AVAILABLE_SERVICES[@]}"; do
    IFS=":" read -r service_path service_name <<< "$service_info"
    
    # Checks directly in your flat root folder
    if [ -d "$DOCKER_FOLDER/$service_path" ]; then
        INSTALLED_SERVICES+=("$service_name")
        INSTALLED_PATHS+=("$service_path")
    fi
done

# If nothing matches, exit safely
if [ ${#INSTALLED_SERVICES[@]} -eq 0 ]; then
    print_warning "No installed services detected inside your data stack ($DOCKER_FOLDER)."
    exit 0
fi

# 4. Prompt user dynamically for each detected service
for i in "${!INSTALLED_SERVICES[@]}"; do
    service_name="${INSTALLED_SERVICES[$i]}"
    service_path="${INSTALLED_PATHS[$i]}"
    
    echo ""
    read -p "Do you want to completely remove '$service_name'? (y/N): " remove_choice
    case "$remove_choice" in
        [yY][eE][sS]|[yY])
            print_warning "Stopping and removing containers for $service_name..."
            
            if [ -d "$DOCKER_FOLDER/$service_path" ]; then
                pushd "$DOCKER_FOLDER/$service_path" > /dev/null
                
                # Use your config's engine profile (Podman-compose vs Docker compose)
                if [ "$CONTAINER_ENGINE" == "podman" ]; then
                    podman-compose down -v || true
                else
                    docker compose down -v || true
                fi
                
                popd > /dev/null
                
                # Safe separation: Prompt before wiping permanent configurations out of your directory
                read -p "Do you also want to delete all configuration/data folders for $service_name? (y/N): " purge_data
                if [[ "$purge_data" =~ ^[yY]$ ]]; then
                    sudo rm -rf "$DOCKER_FOLDER/$service_path"
                    print_success "Data folder cleared."
                fi
                
                print_success "Successfully uninstalled $service_name."
            else
                print_error "Target folder went missing mid-execution."
            fi
            ;;
        *)
            print_info "Skipping removal for $service_name."
            ;;
    esac
done

print_success "Service removal routine completed successfully."