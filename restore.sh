#!/bin/bash

set -e

BACKUP_DIR="$HOME/bkp"
TEMP_DIR=$(mktemp -d)

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "Homelab Restore Script"
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""

if [ ! -d "$BACKUP_DIR" ]; then
    echo "ERROR: Backup directory not found: $BACKUP_DIR"
    echo "Please create at least one backup first using ./backup.sh"
    exit 1
fi

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

echo "Searching for backups in: $BACKUP_DIR"
echo ""

BACKUPS=($(ls -t "$BACKUP_DIR"/homelab_backup_*.zip 2>/dev/null || true))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo "ERROR: No backups found in $BACKUP_DIR"
    echo "Please create a backup first using ./backup.sh"
    exit 1
fi

DISPLAY_COUNT=10
if [ ${#BACKUPS[@]} -lt $DISPLAY_COUNT ]; then
    DISPLAY_COUNT=${#BACKUPS[@]}
fi

echo "==============================="
echo "Found ${#BACKUPS[@]} backup(s). Showing the most recent $DISPLAY_COUNT:"
echo ""

for i in $(seq 0 $((DISPLAY_COUNT - 1))); do
    BACKUP_FILE="${BACKUPS[$i]}"
    BACKUP_NAME=$(basename "$BACKUP_FILE")
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    BACKUP_DATE=$(stat -c %y "$BACKUP_FILE" 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$BACKUP_FILE" 2>/dev/null || echo "Unknown")
    
    if [ $i -eq 0 ]; then
        echo "[$i] $BACKUP_NAME (LATEST - DEFAULT)"
    else
        echo "[$i] $BACKUP_NAME"
    fi
    echo "    Size: $BACKUP_SIZE | Date: $BACKUP_DATE"
    echo ""
done

echo "==============================="
echo ""
echo "Select backup to restore:"
echo "  - Press ENTER to restore the latest backup (default)"
echo "  - Enter a number (0-$((DISPLAY_COUNT - 1))) to restore a specific backup"
echo ""
read -p "Your choice: " CHOICE

if [ -z "$CHOICE" ]; then
    CHOICE=0
    echo "Using default: latest backup"
fi

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 0 ] || [ "$CHOICE" -ge $DISPLAY_COUNT ]; then
    echo "ERROR: Invalid selection. Please enter a number between 0 and $((DISPLAY_COUNT - 1))"
    exit 1
fi

SELECTED_BACKUP="${BACKUPS[$CHOICE]}"
SELECTED_NAME=$(basename "$SELECTED_BACKUP")

echo ""
echo "==============================="
echo "Selected backup: $SELECTED_NAME"
echo "==============================="
echo ""

RUNNING_CONTAINERS=$(docker ps -q)
if [ -n "$RUNNING_CONTAINERS" ]; then
    echo "WARNING: Some containers are currently running."
    echo "It's STRONGLY recommended to stop all containers before restoring."
    echo ""
    read -p "Do you want to stop all containers now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "Stopping containers..."
        if [ -f "./shutdown.sh" ]; then
            ./shutdown.sh
        else
            docker stop $(docker ps -q) 2>/dev/null || true
        fi
        echo "Containers stopped."
    else
        echo "WARNING: Continuing with running containers. This may cause issues!"
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Restore cancelled."
            exit 1
        fi
    fi
fi

echo ""
echo "==============================="
echo "WARNING: This will OVERWRITE all current data!"
echo "Current data directories will be backed up to: ${BACKUP_DIR}/pre_restore_backup_$(date +%Y%m%d_%H%M%S).zip"
echo ""
read -p "Are you sure you want to continue? (yes/NO): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 1
fi

echo ""
echo "==============================="
echo "Step 1/5: Creating safety backup of current data..."
PRE_RESTORE_BACKUP="${BACKUP_DIR}/pre_restore_backup_$(date +%Y%m%d_%H%M%S).zip"
SAFETY_TEMP=$(mktemp -d)

mkdir -p "${SAFETY_TEMP}/current_data"
for dir in data db nginx landing logs; do
    if [ -d "$dir" ]; then
        cp -r "$dir" "${SAFETY_TEMP}/current_data/" 2>/dev/null || true
    fi
done

for file in .env index.html; do
    if [ -f "$file" ]; then
        cp "$file" "${SAFETY_TEMP}/current_data/" 2>/dev/null || true
    fi
done

cd "$SAFETY_TEMP"
zip -r -q "$PRE_RESTORE_BACKUP" "current_data" 2>/dev/null || true
cd - > /dev/null
rm -rf "$SAFETY_TEMP"
echo ""
echo "==============================="
echo "Safety backup created: $(basename $PRE_RESTORE_BACKUP)"

echo ""
echo "==============================="
echo "Step 2/5: Extracting backup archive..."
unzip -q "$SELECTED_BACKUP" -d "$TEMP_DIR"

EXTRACT_DIR="${TEMP_DIR}/homelab_backup"
if [ ! -d "$EXTRACT_DIR" ]; then
    echo "ERROR: Invalid backup structure. Expected 'homelab_backup' directory not found."
    exit 1
fi

echo ""
echo "==============================="
echo "Step 3/5: Removing current data directories..."
for dir in data db nginx landing logs; do
    if [ -d "$dir" ]; then
        echo "  - Removing $dir..."
        rm -rf "$dir"
    fi
done

echo ""
echo "==============================="
echo "Step 4/5: Restoring data from backup..."
cd "$EXTRACT_DIR"

for dir in data db nginx landing logs; do
    if [ -d "$dir" ]; then
        echo "  - Restoring $dir..."
        cp -r "$dir" "$OLDPWD/"
    fi
done

for file in .env index.html; do
    if [ -f "$file" ]; then
        echo "  - Restoring $file..."
        cp "$file" "$OLDPWD/"
    fi
done

cd "$OLDPWD"

echo ""
echo "==============================="
echo "Step 5/5: Setting correct permissions..."
if [ -f ".env" ]; then
    source .env
    export HOST_UID=$(id -u)
    export HOST_GID=$(id -g)
    
    echo "  - Setting permissions for application data..."
    sudo chown -R $HOST_UID:$HOST_GID data/n8n data/gitea data/navidrome data/paperless data/authelia 2>/dev/null || true
    chmod -R 755 data/n8n data/gitea data/navidrome data/paperless data/authelia 2>/dev/null || true
    
    echo "  - Setting permissions for PostgreSQL..."
    sudo chown -R $HOST_UID:$HOST_GID db/postgres 2>/dev/null || true
    chmod -R 700 db/postgres 2>/dev/null || true
else
    echo "  - WARNING: .env file not found, skipping permission setup"
fi

echo ""
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo "Restore completed successfully!"
echo ""
echo "Restored from: $SELECTED_NAME"
echo "Safety backup: $(basename $PRE_RESTORE_BACKUP)"
echo ""
echo "Next steps:"
echo "  1. Review the restored configuration"
echo "  2. Start your containers with: ./startup.sh"
echo "~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*"
echo ""