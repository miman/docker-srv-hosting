#!/bin/bash
set -e

# Dynamically find the user's central configuration file
HSC_CONFIG_PATH="$HOME/.hsc/config.yaml"

if [ -f "$HSC_CONFIG_PATH" ]; then
    # 1. Parse your exact custom secondary HDD or folder location from config.yaml
    IMMICH_MEDIA_DIR=$(grep "^immich_upload_location:" "$HSC_CONFIG_PATH" | sed -e "s/^immich_upload_location:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
    
    # 2. If the key doesn't exist yet, gracefully fall back to parsing docker_root
    if [ -z "$IMMICH_MEDIA_DIR" ] || [ "$IMMICH_MEDIA_DIR" == "null" ]; then
        DOCKER_FOLDER=$(grep "^docker_root:" "$HSC_CONFIG_PATH" | sed -e "s/^docker_root:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
        IMMICH_MEDIA_DIR="${DOCKER_FOLDER:-$HOME/docker_stacks}/immich/library"
    fi
else
    # Ultimate fallback if running completely independent of the .hsc directory structure
    IMMICH_MEDIA_DIR="$HOME/docker_stacks/immich/library"
fi

# Define your exact USB targets
USB_MOUNT_DIR="/mnt/backup_usb"                  
USB_BACKUP_TARGET="${USB_MOUNT_DIR}/immich_backups"

echo "Checking if USB Backup disk is mounted..."

# Verify if the folder is an active mountpoint
if mountpoint -q "$USB_MOUNT_DIR"; then
    echo "[SUCCESS] USB Drive detected. Backing up from: $IMMICH_MEDIA_DIR"
    
    # Ensure target directory exists on the USB drive
    mkdir -p "$USB_BACKUP_TARGET"
    
    # Use rsync to copy new/changed files safely (Nothing is ever deleted from the USB)
    rsync -a "$IMMICH_MEDIA_DIR/" "$USB_BACKUP_TARGET/"
    
    echo "Backup completed successfully."
else
    echo "[WARNING] USB Backup disk is not online. Skipping target backup safely."
    exit 0
fi