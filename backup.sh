#!/bin/bash

set -e

BACKUP_DIR="$HOME/bkp"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="homelab_backup_${TIMESTAMP}.zip"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
TEMP_DIR=$(mktemp -d)

echo "=========================================="
echo "Homelab Backup Script"
echo "=========================================="
echo "Backup will be saved to: ${BACKUP_PATH}"
echo ""

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

echo "Step 1/4: Checking Docker containers status..."
RUNNING_CONTAINERS=$(docker ps -q)
if [ -n "$RUNNING_CONTAINERS" ]; then
    echo "WARNING: Some containers are running. It's recommended to stop them before backup."
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Backup cancelled."
        exit 1
    fi
fi

echo ""
echo "Step 2/4: Copying data directories..."
BACKUP_DATA_DIR="${TEMP_DIR}/homelab_backup"
mkdir -p "$BACKUP_DATA_DIR"

DATA_DIRS=(
    "data"
    "db"
    "nginx"
    "landing"
    "logs"
)

for dir in "${DATA_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "  - Backing up $dir..."
        cp -r "$dir" "$BACKUP_DATA_DIR/"
    else
        echo "  - Skipping $dir (not found)"
    fi
done

echo ""
echo "Step 3/4: Backing up configuration files..."
CONFIG_FILES=(
    ".env"
    "index.html"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  - Backing up $file..."
        cp "$file" "$BACKUP_DATA_DIR/"
    else
        echo "  - Skipping $file (not found)"
    fi
done

echo ""
echo "Step 4/4: Creating compressed archive..."
cd "$TEMP_DIR"
zip -r -q "$BACKUP_PATH" "homelab_backup"

BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)

echo ""
echo "=========================================="
echo "Backup completed successfully!"
echo "=========================================="
echo "Backup file: ${BACKUP_NAME}"
echo "Location: ${BACKUP_PATH}"
echo "Size: ${BACKUP_SIZE}"
echo ""
echo "To restore this backup, run: ./restore.sh"
echo "=========================================="
