#!/bin/bash
set -e

# Check if we can connect to Docker
if ! docker info >/dev/null 2>&1; then
    echo "Error: Could not connect to the Docker daemon."
    echo "Please ensure Docker is running and that your user has permission to access it."
    echo "You may need to run this script with 'sudo' or add your user to the 'docker' group:"
    echo "  sudo usermod -aG \$USER"
    echo "After adding your user to the group, you must log out and log back in for the changes to take effect."
    exit 1
fi

# Function to prompt for installation
prompt_install() {
  local name="$1"
  local dir="$2"
  local script="$3"

  read -p "Do you want to install ${name} (y/N)? " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Installing ${name} as a Docker container..."
    if cd "$dir"; then
      eval "$script"
      cd ..
    else
      echo "Failed to enter directory: ${dir}"
    fi
  else
    echo "Not installing ${name}"
  fi
}

# Ensure DOCKER_FOLDER is set
source ./scripts/read-config.sh

# Ask for Portainer Agent
read -p "Do you want to install Portainer Agent (y/N)? " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  echo "Installing Portainer Agent as a Docker container..."
  if cd infrastructure/portainer/portainer-agent; then
    ./install-portainer-agent.sh
    cd ../../..
  else
    echo "Failed to enter directory: portainer/portainer-agent"
  fi
else
  echo "Not installing Portainer Agent"
fi

prompt_install "Ollama" "ai/ollama" "./install.sh"
prompt_install "open-webui" "ai/open-webui" "./install.sh"
prompt_install "SearXNG" "ai/searxng" "./install.sh"
prompt_install "ComfyUI" "ai/comfy_ui" "./install.sh"
prompt_install "Synapse" "cloud-services/synapse" "./install.sh"
prompt_install "Nextcloud AIO" "cloud-services/nextcloud-aio" "./install.sh"
prompt_install "nginx reverse-proxy" "infrastructure/nginx-reverse-proxy" "./install.sh"
prompt_install "Home Assistant" "cloud-services/home-assistant" "./install.sh"
prompt_install "DuckDNS" "infrastructure/duckdns-updater" "./install.sh"
prompt_install "Immich" "cloud-services/immich" "./install.sh"
prompt_install "Portainer" "infrastructure/portainer" "./install.sh"
prompt_install "Glance Dashboard" "cloud-services/glance-dashboard" "./install.sh"
prompt_install "Headscale" "infrastructure/headscale" "./install.sh"
prompt_install "Netbird" "infrastructure/netbird" "./install.sh"
prompt_install "Traccar" "cloud-services/traccar" "./install.sh"
prompt_install "Vaultwarden" "cloud-services/vaultwarden" "./install.sh"
prompt_install "Docmost" "cloud-services/docmost" "./install.sh"

prompt_install "Linux in Docker" "cloud-services/linux-in-docker" "./install.sh"
prompt_install "Registry" "infrastructure/registry" "./install.sh"
prompt_install "Verdaccio" "development/verdaccio" "./install.sh"
prompt_install "Watchtower" "infrastructure/watchtower" "./install.sh"
