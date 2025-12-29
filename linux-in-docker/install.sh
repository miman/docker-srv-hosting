#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/read-config.sh

# Set the config path based on DOCKER_FOLDER
CONFIG_PATH="$DOCKER_FOLDER/linux-in-docker"
mkdir -p "$CONFIG_PATH"
echo "Using $CONFIG_PATH for container's /config volume."

echo "Removing old container if it exists..."
# -f stops it if it's running and removes it in one go. 
# 2>/dev/null hides the error message if the container doesn't exist yet.
docker rm -f local-linux 2>/dev/null || true

# The following lines can be removed from the docker run command below if you don't want to test tailscale on the machine:
#  --privileged \
#  --cap-add=NET_ADMIN \
#  --device /dev/net/tun:/dev/net/tun \

docker run -d \
  --name=local-linux \
  -p 3000:3000 \
  -p 3001:3001 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Stockholm \
  -e DOCKER_MODS="linuxserver/mods:webtop-firefox,linuxserver/mods:webtop-vscode" \
  -v "$CONFIG_PATH:/config" \
  --shm-size="1gb" \
  --restart unless-stopped \
  --privileged \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  lscr.io/linuxserver/webtop:ubuntu-xfce

echo "Linux-in-Docker (webtop) is being installed."
echo "You can access it at http://<your-ip>:3000"
