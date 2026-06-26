#!/bin/bash
# Updates generated scripts (like backup.sh) for already installed services 
# using the latest templates from the repository.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source configuration to get DOCKER_FOLDER
source "$SCRIPT_DIR/read-config.sh"

echo "=========================================================="
echo "Updating scripts for installed services in: $DOCKER_FOLDER"
echo "=========================================================="

if [ ! -d "$DOCKER_FOLDER" ]; then
    echo "Error: Docker root folder not found at $DOCKER_FOLDER"
    exit 1
fi

UPDATED_COUNT=0

for service_dir in "$DOCKER_FOLDER"/*; do
    if [ -d "$service_dir" ] && [ -f "$service_dir/backup.sh" ]; then
        service_name=$(basename "$service_dir")
        
        # Extract the original backup destination from the existing script
        original_dest=$(grep '^DESTINATION=' "$service_dir/backup.sh" | head -n 1 | cut -d= -f2- | tr -d '"')
        
        if [ -n "$original_dest" ]; then
            # Reconstruct the backup_root by removing the trailing /service_name
            backup_root="${original_dest%/$service_name}"
            
            echo "Updating backup.sh for $service_name..."
            # Run the backup utility configure_service command
            "$SCRIPT_DIR/backup-utils.sh" configure_service "$service_dir" "$backup_root"
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
        else
            echo "Warning: Could not determine original backup destination for $service_name. Skipping."
        fi
    fi
done

echo "=========================================================="
if [ $UPDATED_COUNT -gt 0 ]; then
    echo "Successfully updated scripts for $UPDATED_COUNT services!"
    echo "Finalizing master backup schedule..."
    "$SCRIPT_DIR/backup-utils.sh" finalize
else
    echo "No services with existing backup scripts were found."
fi
echo "=========================================================="
