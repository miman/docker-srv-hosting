#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../../scripts/read-config.sh

# Ask if Watchtower should manage this service
ask_watchtower_label

# --- Handle Registry Proxy URL via Central Config ---
# Check if it already exists in config.yaml
REGISTRY_PROXY_URL=$(grep "^registry_proxy_url:" "$HSC_CONFIG_PATH" | sed -e "s/^registry_proxy_url:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")

if [ -z "$REGISTRY_PROXY_URL" ] || [ "$REGISTRY_PROXY_URL" == "null" ]; then
    # Try to dynamically fallback to an environment or localhost
    DEFAULT_PROXY="http://localhost:5000/v2"
    echo ""
    echo "Configure NGINX_PROXY_PASS_URL for the Registry UI:"
    echo "1) Use default (this machine): $DEFAULT_PROXY"
    echo "2) Enter a manual URL (e.g., http://192.168.68.118:5000/v2)"
    read -p "Enter choice [1-2, default: 1]: " url_choice
    
    if [ "$url_choice" == "2" ]; then
        read -p "Enter full manual URL: " REGISTRY_PROXY_URL
    else
        REGISTRY_PROXY_URL="$DEFAULT_PROXY"
    fi
    # Save the decision to config.yaml for future runs
    set_config_value "registry_proxy_url" "$REGISTRY_PROXY_URL"
fi
# --- End of Config Logic ---

echo "Installing registry on port 5000..."

# Create data directory
mkdir -p "${DOCKER_FOLDER}/registry/data"

# Remove existing containers if they exist to prevent name collision errors
$CONTAINER_CMD rm -f registry registry-ui 2>/dev/null || true

$CONTAINER_CMD run -d \
  -p 5000:5000 \
  --restart=$RESTART_POLICY \
  --name registry \
  -v "${DOCKER_FOLDER}/registry/data:/var/lib/registry" \
  registry:2

echo "Installing joxit/docker-registry-ui on port 6001..."
$CONTAINER_CMD run -d \
  -p 6001:80 \
  --name registry-ui \
  --restart=$RESTART_POLICY \
  -e NGINX_PROXY_PASS_URL="$REGISTRY_PROXY_URL" \
  -e SINGLE_REGISTRY=true \
  -e DELETE_IMAGES=true \
  -e CATALOG_MIN_BRANCHES=1 \
  joxit/docker-registry-ui:latest

echo ""
echo "Registry and UI have been installed."
echo "Registry is on port 5000."
echo "Registry UI is on port 6001 (Proxying to: $REGISTRY_PROXY_URL)."