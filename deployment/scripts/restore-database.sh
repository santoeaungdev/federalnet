#!/bin/bash
# Database restore script for FederalNet
# Usage: ./restore-database.sh /path/to/backup.sql.gz

set -euo pipefail

BACKUP_FILE="${1:-}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-federalnet-mysql}"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 /path/to/backup.sql.gz"
    echo ""
    echo "Available backups:"
    ls -lh /var/backups/federalnet/db_backup_*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Load environment variables
if [ -f /opt/federalnet/.env.production ]; then
    source /opt/federalnet/.env.production
fi

echo "WARNING: This will restore the database from backup."
echo "All current data will be replaced!"
echo "Backup file: $BACKUP_FILE"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

echo "[$(date)] Starting database restore..."

# Check if file is compressed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "[$(date)] Decompressing backup file..."
    gunzip -c "$BACKUP_FILE" | docker exec -i "$MYSQL_CONTAINER" mysql -u root -p"${MYSQL_ROOT_PASSWORD}"
else
    cat "$BACKUP_FILE" | docker exec -i "$MYSQL_CONTAINER" mysql -u root -p"${MYSQL_ROOT_PASSWORD}"
fi

echo "[$(date)] Database restored successfully!"
echo "[$(date)] Restarting API service..."

# Restart API to reconnect to database
if [ -f /opt/federalnet/docker-compose.prod.yml ]; then
    cd /opt/federalnet
    docker compose -f docker-compose.prod.yml restart api
fi

echo "[$(date)] Restore completed!"
