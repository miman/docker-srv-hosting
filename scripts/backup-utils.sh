#!/bin/bash
# Backup Utilities for Docker Service Hosting

BACKUP_SCRIPT_TEMPLATE_GENERIC="./scripts/templates/backup-generic.sh"
BACKUP_SCRIPT_TEMPLATE_POSTGRES="./scripts/templates/backup-postgres.sh"
MASTER_BACKUP_SCRIPT="backup/master-backup.sh"

# --- Helper Functions ---
function print_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
function print_success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
function print_error() { echo -e "\e[31m[ERROR]\e[0m $1" >&2; }

# --- Check Root ---
function check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root (use sudo)"
        exit 1
    fi
}

# --- 1. Disk Setup Logic ---
function setup_backup_disk() {
    local target_dev=$1
    local mount_point=$2
    
    check_root

    if [ -z "$target_dev" ] || [ -z "$mount_point" ]; then
        print_error "Usage: setup_backup_disk <device> <mount_point>"
        exit 1
    fi

    echo "WARNING: THIS WILL FORMAT $target_dev AND DELETE ALL DATA."
    echo "         This is non-interactive mode assumed from install.sh"
    # Verify device exists
    if [ ! -b "$target_dev" ]; then
        print_error "Device $target_dev not found."
        exit 1
    fi

    # Unmount if mounted
    umount "$target_dev"* 2>/dev/null || true
    
    # Simple formatting (one partition, ext4)
    echo "Partitioning $target_dev..."
    echo -e "g\nn\n\n\n\nw" | fdisk "$target_dev"
    
    local partition="${target_dev}1"
    # Handle NVMe naming convention (p1)
    if [[ "$target_dev" == *"nvme"* ]] || [[ "$target_dev" == *"mmcblk"* ]]; then
        partition="${target_dev}p1"
    fi
    
    # Wait for partition
    sleep 2
    
    echo "Formatting $partition..."
    mkfs.ext4 -F "$partition"
    
    mkdir -p "$mount_point"
    
    # Get UUID
    local uuid=$(blkid -s UUID -o value "$partition")
    if [ -z "$uuid" ]; then
        print_error "Could not retrieve UUID."
        exit 1
    fi
    
    # Add to fstab
    if ! grep -q "$uuid" /etc/fstab; then
        echo "UUID=$uuid $mount_point ext4 defaults,nofail 0 2" >> /etc/fstab
        echo "Added to /etc/fstab"
    fi
    
    mount -a
    print_success "Disk setup complete at $mount_point"
}

# --- 2. Service Backup Configuration ---
function configure_service_backup() {
    local service_dir=$1
    local backup_root=$2
    
    local service_name=$(basename "$service_dir")
    local backup_script_path="$service_dir/backup.sh"
    
    # Determine type of backup
    local template="$BACKUP_SCRIPT_TEMPLATE_GENERIC"
    
    # Simple heuristic: check for docker-compose.yml content or directory structure
    # If it has a postgres container, use postgres template.
    # ideally we check specific services known to use postgres.
    if grep -q "postgres" "$service_dir/docker-compose.yml" 2>/dev/null; then
         template="$BACKUP_SCRIPT_TEMPLATE_POSTGRES"
    fi
    
    # Check if templates exist, if not, create dummy content or error out?
    # We will assume templates are created in next steps.
    
    if [ ! -f "$template" ]; then
        print_error "Template $template not found. Skipping backup gen for $service_name"
        return
    fi
    
    # Generate Script
    cp "$template" "$backup_script_path"
    
    # Replace Placeholders
    # We need to know: 
    #   SOURCE_DIR (absolute path to service data) -> usually $DOCKER_ROOT/$service_name/ ?? No, data is usually mapped.
    #   Assume standard structure: $DOCKER_ROOT/$service_name mapped to local folders.
    #   Wait, install-services.sh installs to $DOCKER_ROOT/$service_name
    
    # We are usually running this from the root of the repo, but the service runs in DOCKER_ROOT.
    # Wait, the repo is cloned to X, but services are copied? OR does the repo become the DOCKER_ROOT?
    # Looking at install-core.sh: "mkdir -p $DOCKER_FOLDER", and install-services.sh cd's into `portainer` etc. but 
    # DOES NOT COPY. It runs `./install.sh` inside the repo.
    # MOST install.sh scripts in this repo likely do `docker compose up`. 
    # If they use relative paths (./data), then the data is IN THE REPO FOLDER.
    # BUT `install-core.sh` defines `DOCKER_FOLDER`. 
    # Let's check `immich/install.sh` later. 
    # Assumption: The user wants to backup the RUNNING SERVICE DATA.
    # If services use named volumes, valid backup is harder (needs `docker run --rm -v volume:/backup ...`).
    # If bind mounts, we backup the folder.
    
    # For now, let's assume we backup the folder where the service is installed.
    # If the user sets DOCKER_ROOT, usually that's where things live if properly set up?
    # Actually, `install-core.sh` sets `DOCKER_ROOT` env var, but `install-services.sh` just cd's into the local folders.
    # IT DOES NOT COPY THEM to DOCKER_ROOT.
    # So the "Repo" IS the "Docker Root"? No, `install-core` creates a separate folder.
    # This implies the existing scripts might be creating things in DOCKER_ROOT or using it.
    
    # Let's stick to: We backup the current directory of the service.
    # We need absolute path.
    local service_abs_path="$(cd "$service_dir" && pwd)"
    local backup_dest="$backup_root/$service_name"
    
    sed -i "s|{{SOURCE_DIR}}|$service_abs_path|g" "$backup_script_path"
    sed -i "s|{{BACKUP_DEST}}|$backup_dest|g" "$backup_script_path"
    sed -i "s|{{SERVICE_NAME}}|$service_name|g" "$backup_script_path"
    
    # DB Specific replacements?
    # We might need to parse docker-compose to find container name.
    # Fallback: prompt or simple "grep"
    local db_container=$(grep -oE "container_name:.*postgres.*" "$service_dir/docker-compose.yml" | head -n 1 | awk '{print $2}')
    if [ -z "$db_container" ]; then
         # Try to guess based on service name
         db_container="${service_name}_postgres"
    fi
     sed -i "s|{{DB_CONTAINER}}|$db_container|g" "$backup_script_path"
     
    chmod +x "$backup_script_path"
    print_success "Created backup script for $service_name"
    
    # Update config.json with this service backup
    # Structure: { name: "service", script_path: "...", data_path: "..." }
    local config_file="$HOME/.hsc/config.json"
    
    # Ensure config file exists
    if [ ! -f "$config_file" ]; then
         print_warning "Config file not found at $config_file. Skipping backup registration."
         return
    fi
    
    # We use a temporary file to avoid partial writes
    local tmp_file=$(mktemp)
    
    # Use jq to update or append the entry. 
    # We filter out existing entry for this service name if it exists, then add the new one.
    jq --arg name "$service_name" \
       --arg script "$backup_script_path" \
       --arg data "$service_abs_path" \
       '.backups = [.backups[] | select(.name != $name)] + [{name: $name, script_path: $script, data_path: $data}]' \
       "$config_file" > "$tmp_file" && mv "$tmp_file" "$config_file"
       
    print_success "Registered $service_name in backup configuration."
}

function finalize_backup() {
    local schedule_time=$1

    if [ -z "$schedule_time" ]; then
        schedule_time="03:00"
    fi
    
    # Generate the Dynamic Master Backup Script
    mkdir -p "$(dirname "$MASTER_BACKUP_SCRIPT")"
    
    cat > "$MASTER_BACKUP_SCRIPT" <<EOF
#!/bin/bash
# Master Backup Script - Dynamically runs backups from config.json

CONFIG_FILE="\$HOME/.hsc/config.json"
LOG_FILE="/var/log/master_backup.log"

if [ ! -f "\$CONFIG_FILE" ]; then
    echo "Config file not found: \$CONFIG_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq is required but not found."
    exit 1
fi

echo "=========================================="
echo "Starting Master Backup at \$(date)"
echo "=========================================="

# Read backup entries and iterate
# We read row by row
jq -c '.backups[]' "\$CONFIG_FILE" | while read -r entry; do
    NAME=\$(echo "\$entry" | jq -r '.name')
    SCRIPT=\$(echo "\$entry" | jq -r '.script_path')
    DATA=\$(echo "\$entry" | jq -r '.data_path')
    
    echo "--- Backing up \$NAME ---"
    
    if [ -f "\$SCRIPT" ]; then
        # Execute the backup script
        # Note: If the backup script was generated with hardcoded paths, it uses them.
        # If we wanted to override, we'd pass args here.
        if "\$SCRIPT"; then
             echo "SUCCESS: \$NAME backup completed."
        else
             echo "ERROR: \$NAME backup failed."
        fi
    else
        echo "WARNING: Backup script not found for \$NAME at \$SCRIPT"
    fi
    echo ""
done

echo "Master Backup Completed at \$(date)"
echo "=========================================="
EOF

    chmod +x "$MASTER_BACKUP_SCRIPT"
    print_success "Master backup script updated at $PWD/$MASTER_BACKUP_SCRIPT"

    # Convert HH:MM to Cron (assuming daily)
    local hour=$(echo "$schedule_time" | cut -d: -f1)
    local min=$(echo "$schedule_time" | cut -d: -f2)
    
    # Remove leading zeros
    hour=$((10#$hour))
    min=$((10#$min))
    
    local cron_schedule="$min $hour * * * $PWD/$MASTER_BACKUP_SCRIPT >> /var/log/master_backup.log 2>&1"
    
    (crontab -l 2>/dev/null | grep -v "$MASTER_BACKUP_SCRIPT"; echo "$cron_schedule") | crontab -
    print_success "Backup scheduled daily at $schedule_time ($min $hour * * *)."
}

# --- CLI Dispatch ---
COMMAND=$1
shift

case "$COMMAND" in
    setup_disk)
        setup_backup_disk "$@"
        ;;
    configure_service)
        configure_service_backup "$@"
        ;;
    finalize)
        finalize_backup "$@"
        ;;
    *)
        echo "Usage: $0 {setup_disk|configure_service|finalize} ..."
        exit 1
        ;;
esac
