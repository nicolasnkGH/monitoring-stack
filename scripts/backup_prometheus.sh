#!/bin/bash

# 1. Trigger the snapshot
echo "Creating Prometheus snapshot..."
SNAPSHOT_NAME=$(curl --silent -X POST http://localhost:9090/api/v1/admin/tsdb/snapshot | jq -r '.data.name')

if [ -z "$SNAPSHOT_NAME" ] || [ "$SNAPSHOT_NAME" == "null" ]; then
    echo "❌ Failed to create snapshot"
    exit 1
fi

# 2. Absolute Paths
SOURCE_DIR="/home/ubuntu/docker/monitoring/prometheus_data/data/snapshots/$SNAPSHOT_NAME"
TARGET_DIR="/mnt/monitoring/backups/prometheus/$SNAPSHOT_NAME"

# 3. NAS Mount Guard
if ! mountpoint -q /mnt/monitoring; then
    echo "❌ Error: NAS is not mounted. Aborting sync."
    exit 1
fi

echo "Syncing $SNAPSHOT_NAME to NAS..."
mkdir -p "/mnt/monitoring/backups/prometheus"

# 4. Sync the data
if [ -d "$SOURCE_DIR" ]; then
    sudo rsync -av "$SOURCE_DIR/" "$TARGET_DIR/"
    
    # --- THIS IS THE NEW PART ---
    # Fix ownership on the NAS so the 'ubuntu' user owns the backup
    sudo chown -R ubuntu:ubuntu "$TARGET_DIR"
    # ----------------------------
    
    echo "Cleaning up local snapshot..."
    sudo rm -rf "$SOURCE_DIR"
    echo "✅ Backup complete: $TARGET_DIR"
else
    echo "❌ Source snapshot directory not found: $SOURCE_DIR"
    exit 1
fi