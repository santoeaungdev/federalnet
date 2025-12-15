#!/usr/bin/env bash
# Deploy FederalNet backend on an Ubuntu VPS (idempotent-ish)
# Usage: upload repo tarball or run from checked-out repo on VPS as root
# Example (from your workstation): scp -r ./ c:/tmp/federalnet-src root@143.110.185.159:/root/
# Then on VPS: sudo bash /root/federalnet-src/scripts/vps_deploy_backend.sh

set -euo pipefail

REPO_DIR=${1:-/root/federalnet-src}
SERVICE_NAME=federalnet-api
INSTALL_DIR=/opt/federalnet
BIN_NAME=federalnet-api

echo "Deploy script starting; using repo dir: $REPO_DIR"

if [ ! -d "$REPO_DIR" ]; then
  echo "Repo directory $REPO_DIR not found. Exiting." >&2
  exit 2
fi

echo "Updating apt and installing prerequisites..."
apt-get update -y
apt-get install -y build-essential pkg-config libssl-dev git curl ca-certificates mysql-client

if ! command -v rustc >/dev/null 2>&1; then
  echo "Installing rustup and toolchain..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
else
  echo "Rust already installed"
fi

echo "Building backend in release mode..."
cd "$REPO_DIR/backend/federalnet-api"
export PATH="$HOME/.cargo/bin:$PATH"
source "$HOME/.cargo/env" 2>/dev/null || true
cargo build --release

echo "Installing binary to $INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/bin"
cp target/release/$BIN_NAME "$INSTALL_DIR/bin/" || { echo "Build output not found; check cargo build"; exit 3; }
chmod +x "$INSTALL_DIR/bin/$BIN_NAME"

echo "Creating system user and service..."
id -u $SERVICE_NAME >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin $SERVICE_NAME || true

SERVICE_FILE=/etc/systemd/system/$SERVICE_NAME.service
cat > "$SERVICE_FILE" <<'EOF'
[Unit]
Description=FederalNet API (Actix)
After=network.target

[Service]
User=federalnet-api
Group=federalnet-api
WorkingDirectory=/opt/federalnet
ExecStart=/opt/federalnet/bin/federalnet-api
Restart=on-failure
Environment=RUST_LOG=info
# Set DATABASE_URL and JWT_SECRET in /etc/default/federalnet-api or via systemctl edit
EnvironmentFile=-/etc/default/federalnet-api

[Install]
WantedBy=multi-user.target
EOF

echo "Creating /etc/default/federalnet-api (edit as needed)..."
cat > /etc/default/federalnet-api <<'EOF'
# Example environment file for systemd service
# DATABASE_URL and JWT_SECRET must be set for the service
# DATABASE_URL=mysql://wunthoadmin:admin$@nT03@127.0.0.1:3306/federalnetwuntho
# JWT_SECRET=change_me
EOF

systemctl daemon-reload
systemctl enable --now $SERVICE_NAME || systemctl restart $SERVICE_NAME || true

echo "Service $SERVICE_NAME installed (or restarted). Check status with: systemctl status $SERVICE_NAME -l"
echo "Deployment complete."
