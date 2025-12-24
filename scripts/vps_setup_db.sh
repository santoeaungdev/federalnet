#!/usr/bin/env bash
set -euo pipefail

# Simple helper to apply the DB creation SQL on a VPS where you have mysql client
# Usage: sudo bash scripts/vps_setup_db.sh /path/to/mysql.sock
# If MySQL listens on TCP (127.0.0.1) use: sudo bash scripts/vps_setup_db.sh --host=127.0.0.1 --port=3306

SQL_FILE="$(dirname "$0")/create_wunthofederalnet.sql"

if [ ! -f "$SQL_FILE" ]; then
  echo "SQL file not found: $SQL_FILE"
  exit 2
fi

MYSQL_CMD="mysql"

# If user provided args, pass them to mysql (e.g., --host, --user, -p)
echo "About to run SQL to create database and user. You will be prompted if mysql requires a password."

"$MYSQL_CMD" "$@" < "$SQL_FILE"

echo "Database and user creation SQL applied. Verify with: mysql $@ -e '\"SHOW DATABASES LIKE \\\"wunthofederalnet\\\"\"'"
