#!/bin/bash
export MYSQL_PWD='admin$@nT03'
for t in owner_wallets owner_wallet_transactions owner_income; do
  echo "Checking table $t"
  mysql -u wunthoadmin -D wunthofederalnet -e "SHOW TABLES LIKE '$t';"
done
