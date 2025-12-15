#!/bin/bash
# Run on the VPS after copying /root/rad_dump.sql
# Adjust DB name, user and passwords as needed.

set -euo pipefail

# Example variables — edit accordingly
RADIUS_DB=radius
SQL_DUMP=/root/rad_dump.sql
DB_ROOT_USER=root
# If using password auth, omit -p or provide securely
# mysql -u root -p

echo "Importing rad dump into $RADIUS_DB..."
mysql -u $DB_ROOT_USER -p -D $RADIUS_DB < $SQL_DUMP

echo "Creating limited DB user (edit 'radiususer' and password in rad_db_user.sql if needed)."
if [ -f /root/rad_db_user.sql ]; then
  mysql -u $DB_ROOT_USER -p < /root/rad_db_user.sql
else
  echo "Warning: /root/rad_db_user.sql not found; create DB user manually if needed."
fi

echo "Enable FreeRADIUS SQL module and restart FreeRADIUS"
ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql || true
systemctl restart freeradius || service freeradius restart

echo "Done. Test with radtest or radclient."
