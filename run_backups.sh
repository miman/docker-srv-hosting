#!/bin/bash
# ==================================================================
#       Home Server Center - Interactive On-Demand Backup Utility
# ==================================================================
# This script enables manual, on-demand backups for installed services.
# It can dynamically generate smart backup scripts (Rsync/DB Dumps)
# for any service, execute them, and keep your daily cron schedule
# perfectly clean and untouched.

# Set colors for modern, premium terminal aesthetics
COLOR_HEADER="\e[1;36m"   # Bright Cyan
COLOR_INFO="\e[1;34m"     # Bright Blue
COLOR_SUCCESS="\e[1;32m"  # Bright Green
COLOR_WARNING="\e[1;33m"  # Bright Yellow
COLOR_ERROR="\e[1;31m"    # Bright Red
COLOR_RESET="\e[0m"

# Print a beautiful header
echo -e "${COLOR_HEADER}=================================================================="${COLOR_RESET}
echo -e "${COLOR_HEADER}       Home Server Center - Interactive On-Demand Backup          "${COLOR_RESET}
echo -e "${COLOR_HEADER}=================================================================="${COLOR_RESET}
echo ""

# Determine script root and navigate to it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Determine the target user's home (handles running via sudo)
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
export HSC_CONFIG_PATH="$TARGET_HOME/.hsc/config.yaml"

# Source read-config to get central configuration environment variables
if [ -f "./scripts/read-config.sh" ]; then
    # Sourcing this will automatically setup DOCKER_FOLDER, CONTAINER_CMD, CONTAINER_ENGINE, etc.
    # We redirect only stdout to keep it clean, but let stderr print any configuration errors.
    source "./scripts/read-config.sh" > /dev/null
else
    echo -e "${COLOR_ERROR}[ERROR] Could not find scripts/read-config.sh.${COLOR_RESET}"
    exit 1
fi

# Validate that DOCKER_FOLDER is configured and exists
if [ -z "$DOCKER_FOLDER" ] || [ ! -d "$DOCKER_FOLDER" ]; then
    echo -e "${COLOR_ERROR}[ERROR] Docker root folder '$DOCKER_FOLDER' is not configured or does not exist.${COLOR_RESET}"
    echo -e "${COLOR_INFO}[INFO] Please run ./install.sh first to configure your home server environments.${COLOR_RESET}"
    exit 1
fi

# Retrieve default backup path from central config
BACKUP_PATH=""
if [ -f "$HSC_CONFIG_PATH" ]; then
    BACKUP_PATH=$(grep "^backup_path:" "$HSC_CONFIG_PATH" | sed -e "s/^backup_path:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
fi

# Fallback/Prompt if backup path is not defined
if [ -z "$BACKUP_PATH" ] || [ "$BACKUP_PATH" == "null" ]; then
    echo -e "${COLOR_WARNING}[WARNING] No default backup path found in config.yaml.${COLOR_RESET}"
    read -p "Enter backup destination directory [default: $TARGET_HOME/backups]: " USER_BACKUP_PATH
    BACKUP_PATH="${USER_BACKUP_PATH:-$TARGET_HOME/backups}"
fi

# Expand home tilde, create destination folder
BACKUP_PATH="${BACKUP_PATH/#\~/$TARGET_HOME}"
mkdir -p "$BACKUP_PATH"

echo -e "${COLOR_INFO}[INFO] Docker Stacks Root: ${COLOR_RESET}$DOCKER_FOLDER"
echo -e "${COLOR_INFO}[INFO] Backup Destination: ${COLOR_RESET}$BACKUP_PATH"
echo ""

# Setup elevated privileges command if not running as root
SUDO_CMD=""
if [ "$EUID" -ne 0 ]; then
    SUDO_CMD="sudo -E "
fi

# Scan DOCKER_FOLDER for first-level subdirectories (representing installed services)
INSTALLED_SERVICES=()
while IFS= read -r -d $'\0' service_path; do
    service_name=$(basename "$service_path")
    # Exclude hidden directories and standard system directories like lost+found
    if [[ "$service_name" != .* && "$service_name" != "lost+found" ]]; then
        INSTALLED_SERVICES+=("$service_name")
    fi
done < <($SUDO_CMD find "$DOCKER_FOLDER" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

if [ ${#INSTALLED_SERVICES[@]} -eq 0 ]; then
    echo -e "${COLOR_WARNING}[WARNING] No installed services/containers detected in $DOCKER_FOLDER.${COLOR_RESET}"
    exit 0
fi

# Display interactive list of installed services
echo -e "${COLOR_HEADER}--- Available Installed Services ---${COLOR_RESET}"
for i in "${!INSTALLED_SERVICES[@]}"; do
    service_name="${INSTALLED_SERVICES[$i]}"
    if [ -f "$DOCKER_FOLDER/$service_name/backup.sh" ]; then
        status_text="[Backup ready]"
        status_color="$COLOR_SUCCESS"
    else
        status_text="[No backup script - will generate on-demand]"
        status_color="$COLOR_WARNING"
    fi
    printf "  %2d) %-25s ${status_color}%s${COLOR_RESET}\n" "$((i+1))" "$service_name" "$status_text"
done
echo ""

# Prompt user for their selection
echo -e "Enter the numbers of the services you want to backup (separated by spaces, e.g., ${COLOR_HEADER}1 3 5${COLOR_RESET}), or type ${COLOR_HEADER}all${COLOR_RESET}:"
read -p "> " selection

SELECTED_SERVICES=()
if [ "$selection" == "all" ]; then
    SELECTED_SERVICES=("${INSTALLED_SERVICES[@]}")
else
    for item in $selection; do
        if [[ "$item" =~ ^[0-9]+$ ]] && [ "$item" -ge 1 ] && [ "$item" -le "${#INSTALLED_SERVICES[@]}" ]; then
            SELECTED_SERVICES+=("${INSTALLED_SERVICES[$((item-1))]}")
        else
            echo -e "${COLOR_WARNING}[WARNING] Ignoring invalid selection '$item'.${COLOR_RESET}"
        fi
    done
fi

if [ ${#SELECTED_SERVICES[@]} -eq 0 ]; then
    echo -e "${COLOR_WARNING}No valid services selected. Exiting.${COLOR_RESET}"
    exit 0
fi

# Ask if they want to retain generated scripts locally or perform a pure one-session run
echo ""
read -p "Keep newly generated backup scripts in service directories for future manual runs? [Y/n] " KEEP_SCRIPTS
if [[ "$KEEP_SCRIPTS" =~ ^[Nn]$ ]]; then
    CLEANUP_SCRIPTS=true
else
    CLEANUP_SCRIPTS=false
fi

echo ""
echo -e "${COLOR_INFO}Starting manual backup process...${COLOR_RESET}"
echo -e "${COLOR_HEADER}==================================================================${COLOR_RESET}"

# Identify the backups registration file path
BACKUPS_FILE=""
if [ -n "$HSC_CONFIG_PATH" ]; then
    BACKUPS_FILE="$(dirname "$HSC_CONFIG_PATH")/backups.yaml"
else
    TARGET_USER="${SUDO_USER:-$USER}"
    TARGET_HOME=$(eval echo "~$TARGET_USER")
    BACKUPS_FILE="$TARGET_HOME/.hsc/backups.yaml"
fi

# Create a temporary backup of backups.yaml to keep the daily scheduler untouched
BACKUPS_YAML_BACKUP=""
if [ -f "$BACKUPS_FILE" ]; then
    BACKUPS_YAML_BACKUP=$(mktemp)
    cp "$BACKUPS_FILE" "$BACKUPS_YAML_BACKUP"
fi

# Track generated scripts to optionally remove them at the end
DECLARED_CLEANUP_PATHS=()

for service in "${SELECTED_SERVICES[@]}"; do
    echo -e "\n${COLOR_HEADER}>>> Backing up: $service${COLOR_RESET}"
    service_dir="$DOCKER_FOLDER/$service"
    backup_script="$service_dir/backup.sh"
    
    had_existing_script=true
    if [ ! -f "$backup_script" ]; then
        had_existing_script=false
        echo -e "${COLOR_INFO}[INFO] Automatically configuring smart backup script...${COLOR_RESET}"
        $SUDO_CMD "$SCRIPT_DIR/backup-utils.sh" configure_service "$service_dir" "$BACKUP_PATH"
        
        # Store for cleanup if requested
        if [ "$CLEANUP_SCRIPTS" = true ]; then
            DECLARED_CLEANUP_PATHS+=("$backup_script")
        fi
    fi
    
    # Run the backup script
    if [ -f "$backup_script" ]; then
        echo -e "${COLOR_INFO}[INFO] Executing backup script...${COLOR_RESET}"
        # Make sure it has execution permissions
        $SUDO_CMD chmod +x "$backup_script"
        
        if $SUDO_CMD "$backup_script"; then
            echo -e "${COLOR_SUCCESS}[SUCCESS] Backup for $service completed successfully!${COLOR_RESET}"
        else
            echo -e "${COLOR_ERROR}[ERROR] Backup for $service failed.${COLOR_RESET}"
        fi
    else
        echo -e "${COLOR_ERROR}[ERROR] Failed to locate or generate the backup script for $service.${COLOR_RESET}"
    fi
done

# --- CLEANUP / SESSION RESTORE ---
echo -e "\n${COLOR_HEADER}==================================================================${COLOR_RESET}"
echo -e "${COLOR_INFO}Cleaning up temporary session states...${COLOR_RESET}"

# 1. Restore backups.yaml to its original state so no new services are added to the daily cron schedule
if [ -n "$BACKUPS_YAML_BACKUP" ] && [ -f "$BACKUPS_YAML_BACKUP" ]; then
    $SUDO_CMD cp "$BACKUPS_YAML_BACKUP" "$BACKUPS_FILE"
    rm -f "$BACKUPS_YAML_BACKUP"
    echo -e "${COLOR_SUCCESS}[SUCCESS] Restored master backup schedule to keep cron clean.${COLOR_RESET}"
elif [ -f "$BACKUPS_FILE" ]; then
    # If backups.yaml didn't exist before this session, remove it completely
    $SUDO_CMD rm -f "$BACKUPS_FILE"
    echo -e "${COLOR_SUCCESS}[SUCCESS] Removed temporary master backup catalog.${COLOR_RESET}"
fi

# 2. Clean up newly generated backup scripts if selected
if [ "$CLEANUP_SCRIPTS" = true ] && [ ${#DECLARED_CLEANUP_PATHS[@]} -gt 0 ]; then
    for path in "${DECLARED_CLEANUP_PATHS[@]}"; do
        if [ -f "$path" ]; then
            $SUDO_CMD rm -f "$path"
        fi
    done
    echo -e "${COLOR_SUCCESS}[SUCCESS] Removed dynamically generated backup.sh scripts from stack folders.${COLOR_RESET}"
elif [ ${#DECLARED_CLEANUP_PATHS[@]} -gt 0 ]; then
    echo -e "${COLOR_INFO}[INFO] Kept new backup.sh scripts in your stack directories for future use.${COLOR_RESET}"
fi

echo -e "${COLOR_SUCCESS}On-demand backup process finished!${COLOR_RESET}"
echo ""
