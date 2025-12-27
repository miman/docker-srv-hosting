#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/ensure-DOCKER_FOLDER.sh

echo "installing registry on port 5000"

# Create data directory
mkdir -p "${DOCKER_FOLDER}/registry/data"

docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  -v "${DOCKER_FOLDER}/registry/data:/var/lib/registry" \
  registry:2


echo "installing joxit/docker-registry-ui on port 6001"
docker run -d \
  -p 6001:80 \
  --name registry-ui \
  --restart=always \
  -e NGINX_PROXY_PASS_URL=http://192.168.68.118:5000/v2 \
  -e SINGLE_REGISTRY=true \
  -e DELETE_IMAGES=true \
  -e CATALOG_MIN_BRANCHES=1 \
  joxit/docker-registry-ui:latest

echo "Registry and UI have been installed."
echo "Registry is on port 5000."
echo "Registry UI is on port 6001."
