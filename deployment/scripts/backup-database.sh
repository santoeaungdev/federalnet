#!/bin/bash
# Database backup script for FederalNet
# Can be run manually or via cron

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/var/backups/federalnet}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-federalnet-mysql}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Load environment variables
if [ -f /opt/federalnet/.env.production ]; then
    source /opt/federalnet/.env.production
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting database backup..."

# Backup database
if docker ps | grep -q "$MYSQL_CONTAINER"; then
    # Use MYSQL_PWD environment variable to avoid password in process list
    # Pipe directly to gzip to avoid storing sensitive data uncompressed
    docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" "$MYSQL_CONTAINER" mysqldump \
        -u root \
        --all-databases \
        --single-transaction \
        --quick \
        --lock-tables=false \
        | gzip > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql.gz"
    
    echo "[$(date)] Backup created: $BACKUP_DIR/db_backup_$TIMESTAMP.sql.gz"
    
    # Calculate backup size
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/db_backup_$TIMESTAMP.sql.gz" | cut -f1)
    echo "[$(date)] Backup size: $BACKUP_SIZE"
    
    # Remove old backups
    find "$BACKUP_DIR" -name "db_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete
    echo "[$(date)] Removed backups older than $RETENTION_DAYS days"
    
    # List current backups
    echo "[$(date)] Current backups:"
    ls -lh "$BACKUP_DIR"/db_backup_*.sql.gz 2>/dev/null || echo "No backups found"
    
    echo "[$(date)] Backup completed successfully!"
else
    echo "[$(date)] ERROR: MySQL container $MYSQL_CONTAINER is not running"
    exit 1
fi
