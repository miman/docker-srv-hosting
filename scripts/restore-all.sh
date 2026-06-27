#!/bin/bash
# Bulk Restore Utility for Docker Service Hosting

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/read-config.sh"

# --- Helper Functions ---
function print_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
function print_success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
function print_warning() { echo -e "\e[33m[WARNING]\e[0m $1"; }
function print_error() { echo -e "\e[31m[ERROR]\e[0m $1" >&2; }

# --- Check Root ---
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "=================================================================="
echo "       Home Server Center - Bulk Restore Utility"
echo "=================================================================="
echo ""

# 1. Get Backup Path
if [ -n "$HSC_CONFIG_PATH" ]; then
    CONFIG_FILE="$HSC_CONFIG_PATH"
else
    TARGET_USER="${SUDO_USER:-$USER}"
    TARGET_HOME=$(eval echo "~$TARGET_USER")
    CONFIG_FILE="$TARGET_HOME/.hsc/config.yaml"
fi
BACKUP_ROOT=""

if [ -f "$CONFIG_FILE" ]; then
    BACKUP_ROOT=$(grep "^backup_path:" "$CONFIG_FILE" | sed -e "s/^backup_path:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
fi

if [ -z "$BACKUP_ROOT" ] || [ "$BACKUP_ROOT" == "null" ]; then
    read -p "Enter the backup root directory (e.g., /mnt/backup-drive): " BACKUP_ROOT
fi

if [ ! -d "$BACKUP_ROOT" ]; then
    print_error "Backup root directory not found: $BACKUP_ROOT"
    exit 1
fi

print_info "Looking for backed-up services in: $BACKUP_ROOT"

# 2. Find Services to Restore
SERVICES=()
for dir in "$BACKUP_ROOT"/*; do
    if [ -d "$dir" ] && [ -d "$dir/latest" ]; then
        SERVICES+=("$(basename "$dir")")
    fi
done

if [ ${#SERVICES[@]} -eq 0 ]; then
    print_warning "No valid service backups found in $BACKUP_ROOT."
    echo "Make sure the backup directories contain a 'latest' symlink."
    exit 0
fi

echo ""
echo "Found backups for the following services:"
for srv in "${SERVICES[@]}"; do
    echo "  - $srv"
done
echo ""

read -p "Do you want to restore ALL of these services now? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    print_info "Aborting."
    exit 0
fi

echo ""
# 3. Restore Each Service
SUCCESS_COUNT=0
FAIL_COUNT=0

for srv in "${SERVICES[@]}"; do
    echo "--------------------------------------------------------"
    print_info "Initiating restore for: $srv"
    # Execute with the -y flag to auto-confirm each individual restore
    if "$SCRIPT_DIR/restore-service.sh" -y "$srv" "$BACKUP_ROOT/$srv"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        print_error "Restore failed for: $srv"
    fi
done

echo "--------------------------------------------------------"
echo "Bulk Restore Completed!"
echo "Successful restorations: $SUCCESS_COUNT"
if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "\e[31mFailed restorations: $FAIL_COUNT\e[0m"
else
    echo "Failed restorations: $FAIL_COUNT"
fi
echo "=================================================================="
