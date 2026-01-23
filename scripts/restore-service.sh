#!/bin/bash
# Restore Utility for Docker Service Hosting

# --- Helper Functions ---
function print_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
function print_success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
function print_error() { echo -e "\e[31m[ERROR]\e[0m $1" >&2; }

# --- Check Root ---
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# --- Main Logic ---
SERVICE_NAME=$1
BACKUP_SOURCE=$2

if [ -z "$SERVICE_NAME" ]; then
    echo "Usage: ./restore-service.sh <service_name> [backup_source_path]"
    echo "If [backup_source_path] is omitted, it attempts to read from config.json"
    exit 1
fi

# 1. Get Backup Path from Config if not provided
CONFIG_FILE="$HOME/.hsc/config.json"
if [ -z "$BACKUP_SOURCE" ]; then
    if [ -f "$CONFIG_FILE" ] && command -v jq &> /dev/null; then
        BACKUP_ROOT=$(jq -r '.backup_path' "$CONFIG_FILE")
        if [ -n "$BACKUP_ROOT" ] && [ "$BACKUP_ROOT" != "null" ]; then
            BACKUP_SOURCE="$BACKUP_ROOT/$SERVICE_NAME"
        fi
    fi
fi

if [ -z "$BACKUP_SOURCE" ] || [ ! -d "$BACKUP_SOURCE" ]; then
    print_error "Backup source not found: $BACKUP_SOURCE"
    exit 1
fi

echo "--- Restoring $SERVICE_NAME from $BACKUP_SOURCE ---"
echo "WARNING: This will overwrite current data for $SERVICE_NAME."
read -p "Are you sure? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    exit 0
fi

# 2. Determine Service Directory (Assume local to where script is run, or check running containers?)
# For now, assume we are in the repo root and service folders match names.
if [ -d "$SERVICE_NAME" ]; then
    TARGET_DIR="$PWD/$SERVICE_NAME"
else
    # Try finding it?
    TARGET_DIR=$(find . -maxdepth 2 -type d -name "$SERVICE_NAME" | head -n 1)
fi

if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
    print_error "Could not locate service directory for $SERVICE_NAME locally."
    exit 1
fi

print_info "Target Directory: $TARGET_DIR"

# 3. Stop Service
print_info "Stopping service..."
if [ -f "$TARGET_DIR/docker-compose.yml" ]; then
    cd "$TARGET_DIR" || exit 1
    docker compose down
    cd - > /dev/null || exit 1
fi

# 4. Restore Files
print_info "Restoring files..."
rsync -av "$BACKUP_SOURCE/" "$TARGET_DIR/"

# 5. Restore Database if dump exists
DB_DUMP_DIR="$TARGET_DIR/db-dumps" # Assuming rsync copied it back here
if [ -d "$DB_DUMP_DIR" ]; then
    LATEST_DUMP=$(find "$DB_DUMP_DIR" -name "*.sql" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")
    
    if [ -f "$LATEST_DUMP" ]; then
        print_info "Database dump found: $LATEST_DUMP"
        
        # We need to start the DB container first!
        # This is tricky because `docker compose up` might start everything.
        # Let's try to find the Postgres container name from docker-compose.
        
        DB_CONTAINER=$(grep -oE "container_name:.*postgres.*" "$TARGET_DIR/docker-compose.yml" | head -n 1 | awk '{print $2}')
        if [ -z "$DB_CONTAINER" ]; then
             DB_CONTAINER="${SERVICE_NAME}_postgres" # Guess
        fi
        
        print_info "Starting database container ($DB_CONTAINER) for restore..."
        cd "$TARGET_DIR" || exit 1
        
        # Start only the DB service? hard to know the service name from here without parsing yaml properly.
        # Usually it's 'db' or 'database' or 'postgres'.
        # Fallback: Start all, but detached.
        docker compose up -d
        
        print_info "Waiting for database to initialize..."
        sleep 10 # Crude wait
        
        print_info "Restoring Database..."
        # Drop and Re-create??
        # Usually `psql < file.sql` is enough if dump was clean.
        cat "$LATEST_DUMP" | docker exec -i "$DB_CONTAINER" psql -U postgres
        
        cd - > /dev/null || exit 1
        print_success "Database restored."
    fi
fi

# 6. Restart Service
print_info "Restarting service..."
cd "$TARGET_DIR" || exit 1
docker compose up -d
cd - > /dev/null || exit 1

print_success "Restore complete for $SERVICE_NAME"
