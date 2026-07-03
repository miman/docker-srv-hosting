#!/bin/bash
# Custom Backup Script for Home Assistant
# Det här skriptet åsidosätter standardmallen.

# 1. Hämta centrala inställningar från ramverket
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../../scripts/read-config.sh" ]; then
    source "$SCRIPT_DIR/../../scripts/read-config.sh"
fi

# Fallback-hantering för miljövariabler om de saknas
if [ -z "$DOCKER_FOLDER" ] && [ -f "$HOME/.hsc/config.yaml" ]; then
    DOCKER_FOLDER=$(grep -E "^docker_root:" "$HOME/.hsc/config.yaml" | sed -e "s/^docker_root:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
fi
if [ -z "$BACKUP_PATH_CONFIG" ] && [ -f "$HOME/.hsc/config.yaml" ]; then
    BACKUP_PATH_CONFIG=$(grep -E "^backup_path:" "$HOME/.hsc/config.yaml" | sed -e "s/^backup_path:[[:space:]]*//;s/^[ \'\"]*//;s/[ \'\"]*$//")
fi

# Definiera källkod och slutdestination baserat på HSC-standard
SOURCE_DIR="${DOCKER_FOLDER}/home-assistant/config/backups"
FINAL_BACKUP_ROOT="${BACKUP_PATH_CONFIG:-$HOME/backups}"
DESTINATION_DIR="$FINAL_BACKUP_ROOT/home-assistant"

DATE=$(date +%Y-%m-%d_%H%M%S)
echo "--- Starting Custom Backup $DATE for home-assistant ---"

# 2. Validera att källmappen faktiskt existerar
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Källmappen hittades inte: $SOURCE_DIR"
    echo "Säkerställ att Home Assistant är installerat och körs."
    exit 1
fi

# 3. Skapa destinationsmappen om den inte finns
mkdir -p "$DESTINATION_DIR"

# 4. Kopiera filerna utan att skriva över existerande filer
echo "Kopierar nya Home Assistant-backuper..."
echo "Från: $SOURCE_DIR"
echo "Till: $DESTINATION_DIR"

# Förklaring av rsync-flaggor:
# -a               : Arkivläge (bevarar rättigheter, tidsstämplar, etc.)
# -v               : Verbose (visar vilka filer som kopieras)
# --ignore-existing: Skriver ALDRIG över filer som redan finns i målmappen
rsync -av --ignore-existing "$SOURCE_DIR/" "$DESTINATION_DIR/"

echo "--- Custom Backup Completed for home-assistant ---"
