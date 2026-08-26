#!/bin/bash

# Check if -askwatchtower flag is present in command line arguments
# This allows forcing a re-ask of the Watchtower preference for installed services.
for arg in "$@"; do
    if [[ "$arg" == "-askwatchtower" || "$arg" == "--askwatchtower" ]]; then
        export HSC_ASK_WATCHTOWER=true
        break
    fi
done
# This script ensures that the DOCKER_FOLDER environment variable is set.
# It first checks if the variable is already set. If not, it attempts to
# read it from the central configuration file ~/.hsc/config.yaml.
#
# This script is intended to be sourced by other scripts, e.g.:
# source scripts/read-config.sh

# Source Watchtower utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/watchtower-utils.sh" ]; then
    source "$SCRIPT_DIR/watchtower-utils.sh"
elif [ -f "$SCRIPT_DIR/scripts/watchtower-utils.sh" ]; then
    source "$SCRIPT_DIR/scripts/watchtower-utils.sh"
fi

# Define config file path
export HSC_CONFIG_PATH="${HSC_CONFIG_PATH:-$HOME/.hsc/config.yaml}"

# Check if DOCKER_FOLDER is set, otherwise read from config
if [ -z "$DOCKER_FOLDER" ]; then
    echo "DOCKER_FOLDER not set, attempting to read from $HSC_CONFIG_PATH"
    if [ -f "$HSC_CONFIG_PATH" ]; then
        DOCKER_FOLDER=$(grep "^docker_root:" "$HSC_CONFIG_PATH" | sed -e "s/^docker_root:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
        if [ -z "$DOCKER_FOLDER" ] || [ "$DOCKER_FOLDER" == "null" ]; then
            echo "Error: 'docker_root' not found or is null in $HSC_CONFIG_PATH." >&2
            exit 1
        fi
        echo "Successfully read DOCKER_FOLDER from config: $DOCKER_FOLDER"
    else
        echo "Error: DOCKER_FOLDER is not set and $HSC_CONFIG_PATH was not found." >&2
        exit 1
    fi
fi

# Export the variable so it's available to sub-processes like docker-compose
export DOCKER_FOLDER

# Socket and volume locations will be dynamically exported based on the CONTAINER_ENGINE below.

# Read and export BASE_DNS_NAME
if [ -z "$BASE_DNS_NAME" ]; then
    if [ -f "$HSC_CONFIG_PATH" ]; then
        BASE_DNS_NAME=$(grep "^base_dns_name:" "$HSC_CONFIG_PATH" | sed -e "s/^base_dns_name:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
        if [ -z "$BASE_DNS_NAME" ] || [ "$BASE_DNS_NAME" == "null" ]; then
            echo "Error: 'base_dns_name' not found or is null in $HSC_CONFIG_PATH." >&2
            exit 1
        fi
        echo "Successfully read BASE_DNS_NAME from config: $BASE_DNS_NAME"
    else
        echo "Error: BASE_DNS_NAME is not set and $HSC_CONFIG_PATH was not found." >&2
        exit 1
    fi
fi
export BASE_DNS_NAME

# Read and export EXTERNAL_DUCKDNS_NAME
if [ -z "$EXTERNAL_DUCKDNS_NAME" ]; then
    if [ -f "$HSC_CONFIG_PATH" ]; then
        EXTERNAL_DUCKDNS_NAME=$(grep "^external_duckdns_name:" "$HSC_CONFIG_PATH" | sed -e "s/^external_duckdns_name:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
        if [ "$EXTERNAL_DUCKDNS_NAME" == "null" ]; then
            EXTERNAL_DUCKDNS_NAME=""
        fi
    fi
fi
export EXTERNAL_DUCKDNS_NAME

# Read and export CONTAINER_ENGINE (docker or podman)
# This determines which container runtime commands to use throughout the project.
if [ -z "$CONTAINER_ENGINE" ]; then
    if [ -f "$HSC_CONFIG_PATH" ]; then
        CONTAINER_ENGINE=$(grep "^container_engine:" "$HSC_CONFIG_PATH" | sed -e "s/^container_engine:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
    fi

    if [ -z "$CONTAINER_ENGINE" ] || [ "$CONTAINER_ENGINE" == "null" ]; then
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
fi
export CONTAINER_ENGINE

# Define a wrapper function for Compose commands to support dynamic Podman overrides
run_compose() {
    local cmd=()
    if [ "$CONTAINER_ENGINE" == "podman" ]; then
        cmd=("podman" "compose")
        
        # Logic: Choose ONLY the podman file if it exists, otherwise fallback to yaml
        local main_file="docker-compose.yaml"
        local podman_file="docker-compose.podman.yaml"

        if [ -f "$podman_file" ]; then
            cmd+=("-f" "$podman_file")
        elif [ -f "$main_file" ]; then
            cmd+=("-f" "$main_file")
        fi

        # Handle arguments (skip the ones we already handled)
        local args=()
        local i=1
        while [ $i -le $# ]; do
            local arg="${!i}"
            if [ "$arg" == "-f" ] || [ "$arg" == "--file" ]; then
                local next_idx=$((i + 1))
                local file="${!next_idx}"
                args+=("$arg" "$file")
                i=$((i + 2))
            else
                args+=("$arg")
                i=$((i + 1))
            fi
        done
        cmd+=("${args[@]}")
    else
        # Standard Docker logic: Just use the main file
        cmd=("docker" "compose")
        local main_file="docker-compose.yaml"
        if [ -f "$main_file" ]; then
            cmd+=("-f" "$main_file")
        fi
        
        # Add remaining arguments
        local args=()
        local i=1
        while [ $i -le $# ]; do
            local arg="${!i}"
            if [ "$arg" == "-f" ] || [ "$arg" == "--file" ]; then
                local next_idx=$((i + 1))
                local file="${!next_idx}"
                args+=("$arg" "$file")
                i=$((i + 2))
            else
                args+=("$arg")
                i=$((i + 1))
            fi
        done
        cmd+=("${args[@]}")
    fi
    
    # Execute actual command
    "${cmd[@]}"
}
export -f run_compose

# Set the container command variables based on the chosen engine
if [ "$CONTAINER_ENGINE" == "podman" ]; then
    export CONTAINER_CMD="podman"
    export COMPOSE_CMD="run_compose"
    export RESTART_POLICY="always"

    # Try to start/enable rootless user socket if using systemd and not active
    if ! systemctl --user is-active --quiet podman.socket 2>/dev/null; then
        systemctl --user enable --now podman.socket &>/dev/null || true
    fi

    # Set dynamic DOCKER_SOCK location
    if [ -n "$XDG_RUNTIME_DIR" ] && [ -S "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
        export DOCKER_SOCK="$XDG_RUNTIME_DIR/podman/podman.sock"
    elif [ -S "/run/user/$(id -u)/podman/podman.sock" ]; then
        export DOCKER_SOCK="/run/user/$(id -u)/podman/podman.sock"
    elif [ -S "/run/podman/podman.sock" ]; then
        export DOCKER_SOCK="/run/podman/podman.sock"
    fi
    
    # Set dynamic DOCKER_VOLUMES location
    if [ -d "$HOME/.local/share/containers/storage/volumes" ]; then
        export DOCKER_VOLUMES="$HOME/.local/share/containers/storage/volumes"
    elif [ -d "/var/lib/containers/storage/volumes" ]; then
        export DOCKER_VOLUMES="/var/lib/containers/storage/volumes"
    else
        # If directories don't exist yet (clean install), default based on root/rootless user
        if [ "$(id -u)" -ne 0 ]; then
            export DOCKER_VOLUMES="$HOME/.local/share/containers/storage/volumes"
        else
            export DOCKER_VOLUMES="/var/lib/containers/storage/volumes"
        fi
    fi
    
    echo "Podman configuration applied."
    echo "  -> DOCKER_SOCK set to: ${DOCKER_SOCK:-Not Found}"
    echo "  -> DOCKER_VOLUMES set to: ${DOCKER_VOLUMES:-Not Found}"
else
    export CONTAINER_CMD="docker"
    export COMPOSE_CMD="run_compose"
    export RESTART_POLICY="unless-stopped"

    # Default Docker values
    export DOCKER_SOCK="${DOCKER_SOCK:-/var/run/docker.sock}"
    export DOCKER_VOLUMES="${DOCKER_VOLUMES:-/var/lib/docker/volumes}"
fi


# Helper function to set a value in config.yaml
# Usage: set_config_value "some_key" "some_value"
set_config_value() {
    local key=$1
    local value=$2
    local tmp_file=$(mktemp)
    
    # Strip leading dot for backward compatibility with old jq syntax
    key="${key#.}"
    
    # Ensure config directory exists
    mkdir -p "$(dirname "$HSC_CONFIG_PATH")"
    
    if [ ! -f "$HSC_CONFIG_PATH" ]; then
        echo "${key}: \"${value}\"" > "$HSC_CONFIG_PATH"
        chmod 600 "$HSC_CONFIG_PATH"
        return
    fi
    
    if grep -q "^${key}:" "$HSC_CONFIG_PATH"; then
        sed "s|^${key}:.*|${key}: \"${value}\"|" "$HSC_CONFIG_PATH" > "$tmp_file" && mv "$tmp_file" "$HSC_CONFIG_PATH"
    else
        echo "${key}: \"${value}\"" >> "$HSC_CONFIG_PATH"
    fi
    chmod 600 "$HSC_CONFIG_PATH"
}

ensure_nvidia_drivers() {
    if ! command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA GPU support enabled, but nvidia-smi (driver) is not found."
        echo "Attempting to install NVIDIA drivers..."
        local installed=false

        if command -v ubuntu-drivers &> /dev/null; then
            sudo apt-get update
            if sudo ubuntu-drivers install; then
                installed=true
            fi
        fi

        # Fallback to standard apt packages if ubuntu-drivers didn't make nvidia-smi available
        if ! command -v nvidia-smi &> /dev/null && command -v apt-get &> /dev/null; then
            echo "Installing standard NVIDIA drivers via apt..."
            sudo apt-get update
            sudo apt-get install -y nvidia-driver-535 || sudo apt-get install -y nvidia-driver-550 || sudo apt-get install -y nvidia-headless-535
        elif ! command -v nvidia-smi &> /dev/null && command -v dnf &> /dev/null; then
            sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia
        fi

        # Re-check after installation attempt
        if ! command -v nvidia-smi &> /dev/null; then
            echo ""
            echo -e "\e[33m[WARNING] NVIDIA driver installation completed, but 'nvidia-smi' is not active yet.\e[0m"
            echo "A system reboot is usually required to load the NVIDIA kernel modules."
            echo "Please reboot your system ('sudo reboot') and re-run the installer."
            echo ""
            read -p "Press Enter to exit..." _
            exit 1
        fi
    fi
}

# Read and export USE_NVIDIA_GPU
check_nvidia_gpu_config() {
    if [ -z "$USE_NVIDIA_GPU" ]; then
        if [ -f "$HSC_CONFIG_PATH" ]; then
            USE_NVIDIA_GPU=$(grep "^use_nvidia_gpu:" "$HSC_CONFIG_PATH" | sed -e "s/^use_nvidia_gpu:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
        fi

        if [ -z "$USE_NVIDIA_GPU" ] || [ "$USE_NVIDIA_GPU" == "null" ]; then
            read -p "Do any of the images use an NVIDIA graphics card? [y/N] " nvidia_choice
            if [[ "$nvidia_choice" =~ ^[Yy]$ ]]; then
                USE_NVIDIA_GPU="true"
            else
                USE_NVIDIA_GPU="false"
            fi
            set_config_value "use_nvidia_gpu" "$USE_NVIDIA_GPU"
            echo "Saved NVIDIA GPU preference: $USE_NVIDIA_GPU"
        fi
    fi
    export USE_NVIDIA_GPU

    if [ "$USE_NVIDIA_GPU" == "true" ]; then
        ensure_nvidia_drivers
    fi
}

check_nvidia_gpu_config
