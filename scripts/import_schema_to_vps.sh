#!/usr/bin/env bash
# Portable helper to import a SQL schema into a remote MySQL server (VPS)
# Usage examples:
# 1) Import via direct MySQL connection:
#    MYSQL_HOST=143.110.185.159 MYSQL_USER=wunthoadmin MYSQL_PASS="admin$@nT03" MYSQL_DB=federalnetwuntho \
#      ./import_schema_to_vps.sh c:/dev/federalnet/docker/federalnet_schema.sql
# 2) Or scp+ssh: copy file to VPS and run mysql there (requires SSH access):
#    VPS_USER=root VPS_HOST=143.110.185.159 VPS_SQL_PATH=/root/federalnet_schema.sql \
#      ./import_schema_to_vps.sh c:/dev/federalnet/docker/federalnet_schema.sql

set -euo pipefail

SQL_FILE=${1:-}
if [ -z "$SQL_FILE" ]; then
  echo "Usage: $0 path/to/file.sql" >&2
  exit 2
fi

if [ -n "${MYSQL_HOST:-}" ] && [ -n "${MYSQL_USER:-}" ] && [ -n "${MYSQL_PASS:-}" ] && [ -n "${MYSQL_DB:-}" ]; then
  echo "Importing $SQL_FILE to ${MYSQL_USER}@${MYSQL_HOST}/${MYSQL_DB}..."
  mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" < "$SQL_FILE"
  echo "Import finished."
  exit 0
fi

if [ -n "${VPS_HOST:-}" ] && [ -n "${VPS_USER:-}" ]; then
  REMOTE_PATH=${VPS_SQL_PATH:-/root/$(basename "$SQL_FILE")}
  echo "Copying $SQL_FILE -> ${VPS_USER}@${VPS_HOST}:${REMOTE_PATH}"
  scp "$SQL_FILE" "${VPS_USER}@${VPS_HOST}:${REMOTE_PATH}"
  echo "Running import on remote host..."
  ssh "${VPS_USER}@${VPS_HOST}" "mysql -u root -p < '${REMOTE_PATH}'"
  echo "Remote import finished."
  exit 0
fi

echo "No import method configured. Set either MYSQL_HOST/MYSQL_USER/MYSQL_PASS/MYSQL_DB or VPS_HOST/VPS_USER (and optionally VPS_SQL_PATH)." >&2
exit 3
