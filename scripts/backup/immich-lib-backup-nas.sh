#!/bin/bash
set -e

# Dynamically find the user's central configuration file
HSC_CONFIG_PATH="$HOME/.hsc/config.yaml"
KUMA_URL="http://YOUR_KUMA_IP:3001/api/push/abcdef1234" # Optional: Replace with your actual Kuma Push URL

if [ -f "$HSC_CONFIG_PATH" ]; then
    IMMICH_MEDIA_DIR=$(grep "^immich_upload_location:" "$HSC_CONFIG_PATH" | sed -e "s/^immich_upload_location:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
    if [ -z "$IMMICH_MEDIA_DIR" ] || [ "$IMMICH_MEDIA_DIR" == "null" ]; then
        DOCKER_FOLDER=$(grep "^docker_root:" "$HSC_CONFIG_PATH" | sed -e "s/^docker_root:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
        IMMICH_MEDIA_DIR="${DOCKER_FOLDER:-$HOME/docker_stacks}/immich/library"
    fi
else
    IMMICH_MEDIA_DIR="$HOME/docker_stacks/immich/library"
fi

# Configuration for your NAS Target
NAS_IP="192.168.68.XXX"                     # ⚠️ CHANGE THIS: Your NAS IP address
NAS_MOUNT_DIR="/mnt/backup_nas"             # ⚠️ CHANGE THIS: Your local network mount point
NAS_BACKUP_TARGET="${NAS_MOUNT_DIR}/immich_backups"

echo "Probing if network NAS ($NAS_IP) is online..."

# 1. Network Guard: Fast ping test (2 packets, 2-second timeout)
if ! ping -c 2 -W 2 "$NAS_IP" > /dev/null 2>&1; then
    echo "[WARNING] NAS at $NAS_IP is unreachable. Skipping target network backup safely."
    if [ -n "$KUMA_URL" ]; then
        curl -s "${KUMA_URL}?status=down&msg=NAS+Host+Offline+Backup+Skipped" > /dev/null || true
    fi
    exit 0
fi

# 2. Check if the folder is already an active network mountpoint
if ! mountpoint -q "$NAS_MOUNT_DIR"; then
    echo "[INFO] NAS directory not mounted at $NAS_MOUNT_DIR. Attemping system mount refresh..."
    
    # Ensure the mount point directory exists locally
    mkdir -p "$NAS_MOUNT_DIR"
    
    # Force Linux to mount targets defined in /etc/fstab (like your NFS/SMB share)
    sudo mount "$NAS_MOUNT_DIR" > /dev/null 2>&1 || true
fi

# 3. Verify if mount succeeded, then execute rsync sync
if mountpoint -q "$NAS_MOUNT_DIR"; then
    echo "[SUCCESS] NAS storage array is mounted and ready."
    echo "Syncing data from: $IMMICH_MEDIA_DIR -> $NAS_BACKUP_TARGET"
    
    # Ensure target subdirectory directory exists on the network share
    mkdir -p "$NAS_BACKUP_TARGET"
    
    # Sync new/changed files safely (Unchanged files are skipped; nothing is deleted)
    rsync -a "$IMMICH_MEDIA_DIR/" "$NAS_BACKUP_TARGET/"
    
    echo "Network NAS Backup completed successfully."
    if [ -n "$KUMA_URL" ]; then
        curl -s "${KUMA_URL}?status=up&msg=NAS+Backup+Completed+Successfully" > /dev/null || true
    fi
else
    echo "[ERROR] NAS is online but failed to mount at $NAS_MOUNT_DIR. Check your /etc/fstab mappings."
    if [ -n "$KUMA_URL" ]; then
        curl -s "${KUMA_URL}?status=down&msg=NAS+Mount+Failed" > /dev/null || true
    fi
    exit 1
fi