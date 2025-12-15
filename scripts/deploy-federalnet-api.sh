#!/usr/bin/env bash
set -Eeuo pipefail

# Deploy and restart the federalnet-api on a Linux VPS.
# - Builds the Rust binary from source on the VPS
# - Installs to /opt/federalnet/bin/federalnet-api
# - Restarts systemd unit `federalnet-api`
# - Verifies /api/health and (optionally) /api/admin/customers
#
# Usage (as root):
#   SRC_DIR=/opt/federalnet/src/backend/federalnet-api \
#   ADMIN_USER=testadmin ADMIN_PASS=adminpass \
#   ./deploy-federalnet-api.sh
#
# Optional env vars:
#   SRC_DIR   : Path to federalnet-api source (default: /opt/federalnet/src/backend/federalnet-api)
#   BIN_DIR   : Install dir (default: /opt/federalnet/bin)
#   SERVICE   : Systemd service name (default: federalnet-api)
#   HOST      : Host for curl checks (default: 127.0.0.1)
#   PORT      : Port for curl checks (default: 8080)
#   ADMIN_USER/ADMIN_PASS: If provided, script will login and query /api/admin/customers
#

SRC_DIR="${SRC_DIR:-/opt/federalnet/src/backend/federalnet-api}"
BIN_DIR="${BIN_DIR:-/opt/federalnet/bin}"
SERVICE="${SERVICE:-federalnet-api}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8080}"
BIN_NAME=federalnet-api

log() { echo -e "\e[1;34m[deploy]\e[0m $*"; }
err() { echo -e "\e[1;31m[error]\e[0m $*" >&2; }

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    err "Please run as root (use sudo)."; exit 1;
  fi
}

check_envfile() {
  local envfile=/etc/default/${SERVICE}
  if [[ ! -f "$envfile" ]]; then
    err "Missing $envfile (EnvironmentFile for systemd).";
    err "Create it with DATABASE_URL and JWT_SECRET before deploying.";
    exit 1
  fi
  if ! grep -q '^DATABASE_URL=' "$envfile"; then err "DATABASE_URL not set in $envfile"; exit 1; fi
  if ! grep -q '^JWT_SECRET=' "$envfile"; then err "JWT_SECRET not set in $envfile"; exit 1; fi
}

ensure_packages() {
  log "Installing required packages..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y --no-install-recommends \
    ca-certificates curl git pkg-config build-essential libssl-dev jq
}

ensure_rust() {
  if ! command -v cargo >/dev/null 2>&1; then
    log "Installing Rust toolchain..."
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
  else
    log "Rust toolchain already installed."
  fi
  rustup toolchain install stable --profile minimal
  rustup default stable
}

build_binary() {
  if [[ ! -d "$SRC_DIR" ]]; then
    err "Source directory not found: $SRC_DIR"; exit 1;
  fi
  log "Building release binary from $SRC_DIR ..."
  pushd "$SRC_DIR" >/dev/null
  cargo build --release
  popd >/dev/null
}

install_binary() {
  mkdir -p "$BIN_DIR"
  local src_bin="$SRC_DIR/target/release/$BIN_NAME"
  if [[ ! -f "$src_bin" ]]; then
    err "Built binary not found: $src_bin"; exit 1;
  fi

  if [[ -f "$BIN_DIR/$BIN_NAME" ]]; then
    local ts; ts=$(date +%Y%m%d-%H%M%S)
    cp -f "$BIN_DIR/$BIN_NAME" "$BIN_DIR/${BIN_NAME}.bak.$ts"
    log "Backed up existing binary to $BIN_DIR/${BIN_NAME}.bak.$ts"
  fi

  install -m 0755 "$src_bin" "$BIN_DIR/$BIN_NAME"
  log "Installed new binary to $BIN_DIR/$BIN_NAME"
}

restart_service() {
  log "Restarting systemd service: $SERVICE"
  systemctl restart "$SERVICE"
  sleep 1
  systemctl --no-pager --full status "$SERVICE" -l || true
}

wait_health() {
  log "Waiting for health endpoint..."
  local url="http://$HOST:$PORT/api/health"
  local tries=30
  while true; do
    if curl -fsS "$url" >/dev/null 2>&1; then
      break
    fi
    tries=$((tries-1))
    if [ "$tries" -le 0 ]; then
      err "Health check failed: $url"
      return 1
    fi
    sleep 1
  done
  curl -fsS -i "$url" | sed -n '1,5p'
}

try_admin_list() {
  local base="http://$HOST:$PORT/api"
  if [[ -n "${ADMIN_USER:-}" && -n "${ADMIN_PASS:-}" ]]; then
    log "Obtaining admin token for ${ADMIN_USER}..."
    local token
    token=$(curl -fsS -X POST "$base/admin/login" \
      -H 'Content-Type: application/json' \
      -d "{\"username\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}" | jq -r '.token') || true
    if [[ -z "$token" || "$token" == "null" ]]; then
      err "Failed to obtain admin token. Skipping /admin/customers check."
      return 0
    fi
    log "Querying /api/admin/customers ..."
    curl -fsS -X GET "$base/admin/customers" -H "Authorization: Bearer $token" | jq . || true
  else
    log "ADMIN_USER/ADMIN_PASS not set; skipping /admin/customers test."
  fi
}

main() {
  require_root
  check_envfile
  ensure_packages
  ensure_rust
  build_binary
  install_binary
  restart_service
  wait_health
  try_admin_list
  log "Deployment complete."
}

main "$@"
