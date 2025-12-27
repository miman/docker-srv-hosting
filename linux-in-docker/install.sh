#!/bin/bash
set -e

# Ensure DOCKER_FOLDER is set
source ../scripts/ensure-DOCKER_FOLDER.sh

# Set the config path based on DOCKER_FOLDER
CONFIG_PATH="$DOCKER_FOLDER/linux-in-docker"
mkdir -p "$CONFIG_PATH"
echo "Using $CONFIG_PATH for container's /config volume."


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
  lscr.io/linuxserver/webtop:ubuntu-xfce

echo "Linux-in-Docker (webtop) is being installed."
echo "You can access it at http://<your-ip>:3000"
