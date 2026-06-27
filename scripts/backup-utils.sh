#!/bin/bash
# Backup Utilities for Docker Service Hosting

# Determine the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

BACKUP_SCRIPT_TEMPLATE_GENERIC="$REPO_ROOT/scripts/templates/backup-generic.sh"
BACKUP_SCRIPT_TEMPLATE_POSTGRES="$REPO_ROOT/scripts/templates/backup-postgres.sh"

# --- 1. First, establish the core config file paths ---
if [ -n "$HSC_CONFIG_PATH" ]; then
    CONFIG_FILE="$HSC_CONFIG_PATH"
    BACKUPS_FILE="$(dirname "$HSC_CONFIG_PATH")/backups.yaml"
else
    # Fallback: if run via sudo, SUDO_USER might be set. 
    # Otherwise use current HOME.
    TARGET_USER="${SUDO_USER:-$USER}"
    TARGET_HOME=$(eval echo "~$TARGET_USER")
    CONFIG_FILE="$TARGET_HOME/.hsc/config.yaml"
    BACKUPS_FILE="$TARGET_HOME/.hsc/backups.yaml"
fi

# --- 2. Now it is safe to dynamically extract the operational directory ---
if [ -z "$DOCKER_FOLDER" ] && [ -f "$CONFIG_FILE" ]; then
    # Look up 'docker_root' as designated by the setup configuration
    DOCKER_FOLDER=$(grep -E "^docker_root:" "$CONFIG_FILE" | sed -e "s/^docker_root:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
fi

# --- 2b. Extract central backup path from config.yaml ---
if [ -f "$CONFIG_FILE" ] && [ -z "$BACKUP_PATH_CONFIG" ]; then
    BACKUP_PATH_CONFIG=$(grep -E "^backup_path:" "$CONFIG_FILE" | sed -e "s/^backup_path:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
fi

# Fallback to standard home directory if lookup fails
PERMANENT_STACKS_DIR="${DOCKER_FOLDER:-$HOME/docker_stacks}"
SYSTEM_BACKUP_DIR="${BACKUP_PATH_CONFIG:-$HOME/backups}" # <--- Add this fallback path

# Set the final absolute master script path automatically
MASTER_BACKUP_SCRIPT="$PERMANENT_STACKS_DIR/master-backup.sh"

# --- Helper Functions ---
function print_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
function print_success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
function print_error() { echo -e "\e[31m[ERROR]\e[0m $1" >&2; }

function get_backup_retention() {
    local retention=5
    if [ -f "$CONFIG_FILE" ]; then
        local val=$(grep "^backup_retention:" "$CONFIG_FILE" | sed 's/backup_retention:[[:space:]]*"\?\([^"]*\)"\?/\1/')
        if [ -n "$val" ] && [ "$val" != "null" ]; then
            retention="$val"
        fi
    fi
    echo "$retention"
}

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
    
    # 1. Define the service name and script targets first
    local service_name=$(basename "$service_dir")
    local backup_script_path="$service_dir/backup.sh"
    
    # 2. Determine the safe fallback path using the extracted $SYSTEM_BACKUP_DIR
    # Determine the safe fallback path using the extracted $SYSTEM_BACKUP_DIR
    # If backup_root is empty OR contains a legacy tilde (~), use the absolute path variable
    if [ -z "$backup_root" ] || [[ "$backup_root" == "~"* ]]; then
        local destination_dir="$SYSTEM_BACKUP_DIR/$service_name"
    else
        local destination_dir="$backup_root/$service_name"
    fi
    
    # Determine type of backup
    local template="$BACKUP_SCRIPT_TEMPLATE_GENERIC"
    
    local compose_file="$service_dir/docker-compose.yml"
    [ ! -f "$compose_file" ] && compose_file="$service_dir/docker-compose.yaml"

    if [ -f "$compose_file" ] && grep -q "postgres" "$compose_file" 2>/dev/null; then
         template="$BACKUP_SCRIPT_TEMPLATE_POSTGRES"
    fi
    
    if [ ! -f "$template" ]; then
        print_error "Template $template not found. Skipping backup gen for $service_name"
        return
    fi
    
    # Generate Script
    cp "$template" "$backup_script_path"
    
    # Replace Placeholders
    local service_abs_path="$(cd "$service_dir" && pwd)"
    
    sed -i "s|{{SOURCE_DIR}}|$service_abs_path|g" "$backup_script_path"
    sed -i "s|{{BACKUP_DEST}}|$destination_dir|g" "$backup_script_path" # <--- Fixed to use destination_dir
    sed -i "s|{{SERVICE_NAME}}|$service_name|g" "$backup_script_path"
    
    # Retention count from config
    local retention=$(get_backup_retention)
    sed -i "s|{{BACKUP_RETENTION}}|$retention|g" "$backup_script_path"
    
    # DB Specific replacements
    local db_container=$(grep -oE "container_name:.*postgres.*" "$compose_file" 2>/dev/null | head -n 1 | awk '{print $2}')
    if [ -z "$db_container" ]; then
         db_container="${service_name}_postgres"
    fi
    sed -i "s|{{DB_CONTAINER}}|$db_container|g" "$backup_script_path"
     
    chmod +x "$backup_script_path"
    if [ -n "$SUDO_USER" ]; then
        chown "$SUDO_USER:$SUDO_USER" "$backup_script_path" 2>/dev/null || true
    fi
    print_success "Created backup script for $service_name"
    
    # Update backups.yaml with this service backup
    if [ ! -f "$BACKUPS_FILE" ]; then
         touch "$BACKUPS_FILE"
         if [ -n "$SUDO_USER" ]; then
             chown "$SUDO_USER:$SUDO_USER" "$BACKUPS_FILE" 2>/dev/null || true
         fi
    fi
    
    local tmp_file=$(mktemp)
    
    awk -v name="$service_name" '
        $0 ~ "^"name":" { skip=1; next }
        /^[^ ]/ && skip { skip=0 }
        !skip { print $0 }
    ' "$BACKUPS_FILE" > "$tmp_file"
    
    echo "${service_name}:" >> "$tmp_file"
    echo "  script_path: \"${backup_script_path}\"" >> "$tmp_file"
    echo "  data_path: \"${service_abs_path}\"" >> "$tmp_file"
    
    mv "$tmp_file" "$BACKUPS_FILE"
    if [ -n "$SUDO_USER" ]; then
        chown "$SUDO_USER:$SUDO_USER" "$BACKUPS_FILE" 2>/dev/null || true
    fi
    print_success "Registered $service_name in backup configuration."
}

function finalize_backup() {
    local schedule_time=$1

    if [ -z "$schedule_time" ] || [ "$schedule_time" == "null" ]; then
        schedule_time="03:00"
    fi
    
    # Generate the Dynamic Master Backup Script
    local master_dir="$(dirname "$MASTER_BACKUP_SCRIPT")"
    mkdir -p "$master_dir"
    if [ -n "$SUDO_USER" ]; then
        chown "$SUDO_USER:$SUDO_USER" "$master_dir" 2>/dev/null || true
    fi
    
    cat > "$MASTER_BACKUP_SCRIPT" <<EOF
#!/bin/bash
# Master Backup Script - Dynamically runs backups from backups.yaml

BACKUPS_FILE="$BACKUPS_FILE"

LOG_FILE="/var/log/master_backup.log"

if [ ! -f "\$BACKUPS_FILE" ]; then
    echo "Backups file not found: \$BACKUPS_FILE"
    exit 1
fi

echo "=========================================="
echo "Starting Master Backup at \$(date)"
echo "=========================================="

current_service=""
current_script=""
current_data=""

while IFS= read -r line || [ -n "\$line" ]; do
    if [[ \$line =~ ^([a-zA-Z0-9_-]+):$ ]]; then
        current_service="\${BASH_REMATCH[1]}"
    elif [[ \$line =~ ^[[:space:]]+script_path:[[:space:]]*\"([^#\"]*)\" ]]; then
        current_script="\${BASH_REMATCH[1]}"
    elif [[ \$line =~ ^[[:space:]]+data_path:[[:space:]]*\"([^#\"]*)\" ]]; then
        current_data="\${BASH_REMATCH[1]}"
    fi

    # Execute as soon as we have the pair, then clear them
    if [ -n "\$current_service" ] && [ -n "\$current_script" ]; then
        echo "--- Backing up \$current_service ---"
        if [ -f "\$current_script" ]; then
            if "\$current_script"; then
                    echo "SUCCESS: \$current_service backup completed."
            else
                    echo "ERROR: \$current_service backup failed."
            fi
        else
            echo "WARNING: Backup script not found for \$current_service at \$current_script"
        fi
        echo ""
        # Reset variables for the next block
        current_service=""
        current_script=""
        current_data=""
    fi
done < "\$BACKUPS_FILE"

echo "Master Backup Completed at \$(date)"
echo "=========================================="
EOF

    chmod +x "$MASTER_BACKUP_SCRIPT"
    if [ -n "$SUDO_USER" ]; then
        chown "$SUDO_USER:$SUDO_USER" "$MASTER_BACKUP_SCRIPT" 2>/dev/null || true
    fi
    print_success "Master backup script updated at $MASTER_BACKUP_SCRIPT"

    # Convert HH:MM to Cron (assuming daily)
    local hour=$(echo "$schedule_time" | cut -d: -f1)
    local min=$(echo "$schedule_time" | cut -d: -f2)
    
    # Remove leading zeros
    hour=$((10#$hour))
    min=$((10#$min))
    
    local cron_schedule="$min $hour * * * $MASTER_BACKUP_SCRIPT >> /var/log/master_backup.log 2>&1"
    
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
