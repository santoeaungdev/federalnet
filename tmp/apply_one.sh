#!/bin/bash
export MYSQL_PWD='admin$@nT03'
set -x
mysql -u wunthoadmin wunthofederalnet < /opt/federalnet/src/docker/add_owner_wallets.sql
echo "mysql exit status: $?"
mysql -u wunthoadmin -D wunthofederalnet -e "SHOW TABLES LIKE 'owner_wallets';"
