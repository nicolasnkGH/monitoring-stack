#!/bin/bash
# ============================================================================
# Prometheus TSDB Backup Script
# Copies daily snapshots to NAS for 3-2-1 backup strategy
# ============================================================================

set -euo pipefail

# --- Configuration ---
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
BACKUP_DIR="${BACKUP_DIR:-/mnt/monitoring/backups/prometheus}"
PROMETHEUS_DATA_DIR="${PROMETHEUS_DATA_DIR:-/var/lib/docker/volumes/monitoring_stack_prometheus_data/_data}"
SNAPSHOTS_TO_KEEP=7  # Keep 7 days of local snapshots
LOG_FILE="${LOG_FILE:-/var/log/monitoring_stack/backup.log}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_NAME="snapshot_${TIMESTAMP}"

# --- Colors for logging ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Logging function ---
log() {
    local level="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*" | tee -a "$LOG_FILE"
}

log_info()  { log "INFO"  "$@"; }
log_warn()  { log "WARN"  "$@"; }
log_error() { log "ERROR" "$@"; }

# --- Ensure directories exist ---
mkdir -p "$(dirname "$LOG_FILE")" "$BACKUP_DIR" 2>/dev/null || true

log_info "=========================================="
log_info "Starting Prometheus TSDB backup"
log_info "=========================================="

# --- Step 1: Verify NAS mount (if applicable) ---
if [[ "$BACKUP_DIR" == /mnt/* ]]; then
    if ! mountpoint -q "$BACKUP_DIR"; then
        log_error "NAS mount $BACKUP_DIR is not accessible!"
        exit 1
    fi
    log_info "✅ NAS mount verified: $BACKUP_DIR"
else
    log_info "ℹ️ Using local backup directory: $BACKUP_DIR"
fi

# --- Step 2: Trigger Prometheus snapshot via Admin API ---
log_info "Triggering Prometheus snapshot: $SNAPSHOT_NAME"
SNAPSHOT_RESPONSE=$(curl -s -X POST \
    "${PROMETHEUS_URL}/api/v1/admin/tsdb/snapshot" \
    -d "name=${SNAPSHOT_NAME}" 2>&1)

if echo "$SNAPSHOT_RESPONSE" | grep -q '"success"'; then
    log_info "✅ Snapshot created: $SNAPSHOT_NAME"
else
    log_error "❌ Failed to create snapshot: $SNAPSHOT_RESPONSE"
    exit 1
fi

# --- Step 3: Copy snapshot to backup location ---
SNAPSHOT_SOURCE="${PROMETHEUS_DATA_DIR}/snapshots/${SNAPSHOT_NAME}"

if [[ -d "$SNAPSHOT_SOURCE" ]]; then
    log_info "Copying snapshot to $BACKUP_DIR..."
    rsync -av --progress \
        "${SNAPSHOT_SOURCE}/" \
        "${BACKUP_DIR}/${SNAPSHOT_NAME}/" 2>&1 | tee -a "$LOG_FILE"
    
    # Fix ownership for backup files
    if [[ "$BACKUP_DIR" == /mnt/* ]]; then
        chown -R nobody:nogroup "${BACKUP_DIR}/${SNAPSHOT_NAME}" 2>/dev/null || true
    fi
    
    SNAPSHOT_SIZE=$(du -sh "${BACKUP_DIR}/${SNAPSHOT_NAME}" 2>/dev/null | cut -f1)
    log_info "✅ Backup completed: ${SNAPSHOT_NAME} (${SNAPSHOT_SIZE})"
else
    log_error "❌ Snapshot directory not found: $SNAPSHOT_SOURCE"
    exit 1
fi

# --- Step 4: Cleanup old snapshots ---
log_info "Cleaning up snapshots older than $SNAPSHOTS_TO_KEEP days..."
CLEANED=0
while IFS= read -r old_snapshot; do
    if [[ -d "${BACKUP_DIR}/${old_snapshot}" ]]; then
        log_info "Removing old snapshot: $old_snapshot"
        rm -rf "${BACKUP_DIR}/${old_snapshot}"
        CLEANED=$((CLEANED + 1))
    fi
done < <(ls -1t "${BACKUP_DIR}" 2>/dev/null | tail -n +$((SNAPSHOTS_TO_KEEP + 1)))

log_info "Cleaned up $CLEANED old snapshot(s)"

# --- Step 5: Verify latest backup ---
LATEST_BACKUP=$(ls -1t "${BACKUP_DIR}" 2>/dev/null | head -1)
if [[ -n "$LATEST_BACKUP" ]]; then
    BACKUP_SIZE=$(du -sh "${BACKUP_DIR}/${LATEST_BACKUP}" 2>/dev/null | cut -f1)
    BACKUP_DATE=$(stat -c '%y' "${BACKUP_DIR}/${LATEST_BACKUP}" 2>/dev/null | cut -d' ' -f1 || stat -f '%Sm' "${BACKUP_DIR}/${LATEST_BACKUP}" 2>/dev/null | cut -d' ' -f1)
    log_info "=========================================="
    log_info "Latest backup: $LATEST_BACKUP"
    log_info "Size: $BACKUP_SIZE"
    log_info "Date: $BACKUP_DATE"
    log_info "=========================================="
else
    log_warn "No backups found in $BACKUP_DIR"
fi

log_info "Prometheus TSDB backup completed successfully"
exit 0