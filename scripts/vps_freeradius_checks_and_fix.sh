#!/usr/bin/env bash
# FreeRADIUS checks and lightweight fixes for Ubuntu 24.04
# Run on VPS as root. This script will:
# - check freeradius service
# - show recent logs
# - verify sql module is enabled and print sql config
# - query the radius DB for `nas` rows and sample counts
# - (optional) enable sql module symlink if missing (will backup files)

set -euo pipefail

MYSQL_USER=${MYSQL_USER:-wunthoadmin}
MYSQL_PASS=${MYSQL_PASS:-'admin$@nT03'}
MYSQL_DB=${MYSQL_DB:-federalnetwuntho}

echo "1) FreeRADIUS service status"
systemctl status freeradius -l --no-pager || true

echo "\n2) Last 200 lines of FreeRADIUS journal"
journalctl -u freeradius --no-pager -n 200 || true

echo "\n3) Check listener sockets for RADIUS ports"
ss -tunlp | grep -E '1812|1813|radius' || ss -ulnp | grep -E '1812|1813|radius' || true

echo "\n4) List mods-enabled and sql config preview"
ls -l /etc/freeradius/3.0/mods-enabled || true
if [ -f /etc/freeradius/3.0/mods-available/sql ]; then
  echo "\n--- /etc/freeradius/3.0/mods-available/sql (first 120 lines) ---"
  sed -n '1,120p' /etc/freeradius/3.0/mods-available/sql || true
fi

echo "\n5) Test SQL connectivity and show counts"
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "USE $MYSQL_DB; SELECT COUNT(*) AS radcheck_count FROM radcheck; SELECT COUNT(*) AS radusergroup_count FROM radusergroup; SELECT id,nasname,secret,routers FROM nas LIMIT 50;" || true

echo "\n6) Ensure sql module is enabled (create symlink if missing)"
if [ ! -e /etc/freeradius/3.0/mods-enabled/sql ] && [ -e /etc/freeradius/3.0/mods-available/sql ]; then
  echo "Backing up and enabling sql module..."
  cp -a /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-available/sql.bak-$(date +%s)
  ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql
  echo "sql module enabled (symlink created)"
  systemctl restart freeradius || true
else
  echo "sql module already enabled or missing config"
fi

echo "\n7) If you want to run an auth test with radtest, pick a NAS secret from the list above and run locally like:"
echo "radtest <username> <password> 127.0.0.1 0 '<NAS_SECRET>'"

echo "Script finished. Provide outputs if you want me to interpret logs or fix specific errors."
