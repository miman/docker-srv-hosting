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

# Store the absolute path of the Git repository root before switching directories
REPO_ROOT_DIR=$(pwd)

print_info "=======================> Starting Service Removal Phase..."

# Track what is actually found dynamically on the drive
INSTALLED_SERVICES=()
INSTALLED_PATHS=()

# 3. Detect which services from the shared array have active data directories inside ~/docker_stacks
for service_info in "${AVAILABLE_SERVICES[@]}"; do
    IFS=":" read -r service_path service_name <<< "$service_info"
    
    # Extract the base folder name (e.g., converts "cloud-services/immich" -> "immich")
    flat_folder_name=$(basename "$service_path")
    
    # Checks directly in your flat data root folder
    if [ -d "$DOCKER_FOLDER/$flat_folder_name" ]; then
        INSTALLED_SERVICES+=("$service_name")
        INSTALLED_PATHS+=("$service_path") # Keep repo path track intact
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
    repo_service_path="${INSTALLED_PATHS[$i]}"
    flat_folder_name=$(basename "$repo_service_path")
    
    echo ""
    read -p "Do you want to completely remove '$service_name'? (y/N): " remove_choice
    case "$remove_choice" in
        [yY][eE][sS]|[yY])
            print_warning "Stopping and removing containers for $service_name..."
            
            # Locate the correct compose file in the repo (prioritize Podman variant if engine is Podman)
            GIT_COMPOSE_FILE=""
            TARGET_DIR="$REPO_ROOT_DIR/$repo_service_path"
            
            if [ "$CONTAINER_ENGINE" == "podman" ] && [ -f "$TARGET_DIR/docker-compose.podman.yaml" ]; then
                GIT_COMPOSE_FILE="$TARGET_DIR/docker-compose.podman.yaml"
            elif [ -f "$TARGET_DIR/docker-compose.yaml" ]; then
                GIT_COMPOSE_FILE="$TARGET_DIR/docker-compose.yaml"
            elif [ -f "$TARGET_DIR/docker-compose.yml" ]; then
                GIT_COMPOSE_FILE="$TARGET_DIR/docker-compose.yml"
            elif [ -f "$TARGET_DIR/compose.yaml" ]; then
                GIT_COMPOSE_FILE="$TARGET_DIR/compose.yaml"
            fi

            if [ -n "$GIT_COMPOSE_FILE" ]; then
                # Navigate into the target app's data directory so volumes map correctly
                if [ -d "$DOCKER_FOLDER/$flat_folder_name" ]; then
                    pushd "$DOCKER_FOLDER/$flat_folder_name" > /dev/null
                    
                    print_info "Using Git repository configuration: $GIT_COMPOSE_FILE"
                    # -p forces podman/docker to target the specific project name matching your flat folder
                    $COMPOSE_CMD -f "$GIT_COMPOSE_FILE" -p "$flat_folder_name" down -v || true
                    
                    popd > /dev/null
                fi
            else
                print_error "Could not find a valid compose file (*.yaml/*.yml) inside the repository path: $repo_service_path"
            fi
            
            # Safe separation: Prompt before wiping permanent configurations out of your directory
            echo ""
            read -p "Do you also want to delete all configuration/data folders for $service_name? (y/N): " purge_data
            if [[ "$purge_data" =~ ^[yY]$ ]]; then
                sudo rm -rf "$DOCKER_FOLDER/$flat_folder_name"
                print_success "Data folder cleared."
            fi
            
            print_success "Successfully uninstalled $service_name."
            ;;
        *)
            print_info "Skipping removal for $service_name."
            ;;
    esac
done

print_success "Service removal routine completed successfully."