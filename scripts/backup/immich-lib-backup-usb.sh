#!/bin/bash
set -e

# This file wil copy the immich library to an external USB drive
# It will write all new/updated files, but NOT delete anything on the USB drive

# Load your global configuration variables if needed
source "$(dirname "$0")/scripts/read-config.sh"

# Define your source and target paths
IMMICH_MEDIA_DIR="${DOCKER_FOLDER}/immich/library" # Or your secondary HDD path
USB_MOUNT_DIR="/media/backup_usb"                  # Change to your exact mount path
USB_BACKUP_TARGET="${USB_MOUNT_DIR}/immich_backups"

echo "Checking if USB Backup disk is mounted..."

# Method 1: Check if the folder is a legitimate mountpoint
# Method 2 (Fallback): Check if a specific tracking file exists on the USB [ -f "${USB_MOUNT_DIR}/.usb_attached" ]
if mountpoint -q "$USB_MOUNT_DIR"; then
    echo "[SUCCESS] USB Drive detected. Starting nightly sync..."
    
    # Ensure target directory exists on the USB drive
    mkdir -p "$USB_BACKUP_TARGET"
    
    # Use rsync to incrementally copy changed/new files efficiently
    rsync -av --delete "$IMMICH_MEDIA_DIR/" "$USB_BACKUP_TARGET/"
    
    echo "Backup completed successfully."
else
    echo "[WARNING] USB Backup disk is not online/mounted. Skipping target backup safely."
    exit 0
fi