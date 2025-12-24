#!/bin/bash
export MYSQL_PWD='admin$@nT03'
set -e
files=(
  /opt/federalnet/src/docker/add_owner_wallets.sql
  /opt/federalnet/src/docker/add_owner_wallet_idempotency.sql
  /opt/federalnet/src/docker/create_owner_income.sql
  /opt/federalnet/src/docker/add_plan_billing.sql
  /opt/federalnet/src/docker/add_user_types.sql
  /opt/federalnet/src/docker/owner_gateways.sql
  /opt/federalnet/src/docker/add_nas_owner_id.sql
)
for f in "${files[@]}"; do
  echo "Applying $f"
  mysql -u wunthoadmin wunthofederalnet < "$f"
  echo "exit:$?"
done
echo "All migrations applied"
