#!/bin/bash
# Restore Utility for Docker Service Hosting

# Source config for container engine settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/read-config.sh"

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
    echo "If [backup_source_path] is omitted, it attempts to read from config.yaml"
    exit 1
fi

# 1. Get Backup Path from Config if not provided
CONFIG_FILE="$HOME/.hsc/config.yaml"
if [ -z "$BACKUP_SOURCE" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        BACKUP_ROOT=$(grep "^backup_path:" "$CONFIG_FILE" | sed -e "s/^backup_path:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
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
if [ -f "$TARGET_DIR/docker-compose.yml" ] || [ -f "$TARGET_DIR/docker-compose.yaml" ]; then
    cd "$TARGET_DIR" || exit 1
    $COMPOSE_CMD down
    cd - > /dev/null || exit 1
fi

# 4. Restore Files
print_info "Restoring files..."
rsync -av --no-HARDLINKS "$BACKUP_SOURCE/" "$TARGET_DIR/"

# 5. Database Restore (Postgres specific)
if [ -f "$TARGET_DIR/docker-compose.yml" ] || [ -f "$TARGET_DIR/docker-compose.yaml" ]; then
    LATEST_DUMP="$BACKUP_SOURCE/db_dump.sql"
    if [ -f "$LATEST_DUMP" ]; then
        print_info "Database dump found: $LATEST_DUMP"
        
        # Starta stacken temporärt för att få igång DB
        cd "$TARGET_DIR" || exit 1
        $COMPOSE_CMD up -d
        
        # Hitta container-namnet dynamiskt via Docker/Podman
        DB_CONTAINER=$($CONTAINER_CMD ps --filter "label=com.docker.compose.project=${SERVICE_NAME}" --filter "ancestor=*postgres*" --format "{{.Names}}" | head -n 1)
        if [ -z "$DB_CONTAINER" ]; then
            DB_CONTAINER=$($CONTAINER_CMD ps --format "{{.Names}}" | grep -E "${SERVICE_NAME}.*db|postgres" | head -n 1)
        fi
        
        if [ -z "$DB_CONTAINER" ]; then
            print_error "Could not find Postgres container for $SERVICE_NAME automatically."
            print_warning "Attempting fallback guess..."
            DB_CONTAINER="${SERVICE_NAME}_postgres"
        fi
        
        print_info "Found database container: $DB_CONTAINER"
        
        # Vänta på att Postgres har initierat den tomma mappen
        print_info "Waiting for database to become ready..."
        for i in {1..30}; do
            if $CONTAINER_CMD exec "$DB_CONTAINER" pg_isready -U postgres &>/dev/null; then
                break
            fi
            sleep 1
        done
        
        # Stoppa resten av applikationen så att ingen låser databasen under restore
        print_info "Stopping application containers, leaving DB online..."
        # Vi stoppar allt utom DB (eller stoppar allt och startar enbart DB-containern)
        $COMPOSE_CMD stop
        $CONTAINER_CMD start "$DB_CONTAINER"
        sleep 2
        
        print_info "Restoring Database dump..."
        if $CONTAINER_CMD exec -i "$DB_CONTAINER" psql -U postgres -d template1 < "$LATEST_DUMP"; then
            print_success "Database SQL dump successfully restored."
        else
            print_error "Database restore failed!"
        fi
        
        cd - > /dev/null || exit 1
    fi
fi

# 6. Restart Service (Starta allt ordentligt igen)
print_info "Starting full service stack..."
cd "$TARGET_DIR" || exit 1
$COMPOSE_CMD up -d
cd - > /dev/null || exit 1

print_success "Restore process for $SERVICE_NAME completed successfully!"
