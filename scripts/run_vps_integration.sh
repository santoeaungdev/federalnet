#!/usr/bin/env bash
set -euo pipefail

BASE=${1:-http://143.110.185.159:8080/api}
SEED=${2:-0}

echo "Running VPS integration test against $BASE"
export RUN_VPS_INTEGRATION=1
export VPS_BASE_URL="$BASE"

if [ "$SEED" = "1" ]; then
  echo "Seeding test data..."
  curl -fsS -X POST "$BASE/_seed_test_data" || { echo "Seed failed"; exit 1; }
fi

cargo test -p federalnet-api --test integration_vps -- --nocapture
