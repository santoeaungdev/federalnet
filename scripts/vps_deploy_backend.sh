#!/usr/bin/env bash
# Deploy FederalNet backend on an Ubuntu VPS (idempotent)
# This script can work from a local checked-out repo OR it can clone/pull the repo itself.
#
# Usage examples (on the VPS):
#   # Auto-clone/pull from GitHub to /opt/federalnet/src and deploy
#   sudo GIT_URL="https://github.com/santoeaungdev/federalnet.git" GIT_BRANCH="main" bash -c "curl -fsSL https://raw.githubusercontent.com/santoeaungdev/federalnet/main/scripts/vps_deploy_backend.sh | bash"
#
#   # Or, if the repo is already on disk
#   sudo bash /opt/federalnet/src/scripts/vps_deploy_backend.sh /opt/federalnet/src

set -euo pipefail

# Config
SERVICE_NAME=federalnet-api
INSTALL_DIR=/opt/federalnet
SRC_DIR_DEFAULT=/opt/federalnet/src
BIN_NAME=federalnet-api

# Input args/env
REPO_DIR=${1:-}
GIT_URL=${GIT_URL:-https://github.com/santoeaungdev/federalnet.git}
GIT_BRANCH=${GIT_BRANCH:-main}

if [ -z "${REPO_DIR}" ]; then
  REPO_DIR="$SRC_DIR_DEFAULT"
fi

echo "Deploy script starting"
echo "  REPO_DIR   : $REPO_DIR"
echo "  GIT_URL    : $GIT_URL"
echo "  GIT_BRANCH : $GIT_BRANCH"

echo "Updating apt and installing prerequisites..."
apt-get update -y
apt-get install -y build-essential pkg-config libssl-dev git curl ca-certificates mysql-client

echo "Ensuring source present at $REPO_DIR ..."
if [ -d "$REPO_DIR/.git" ]; then
  echo "Repo exists. Pulling latest..."
  git -C "$REPO_DIR" fetch origin "$GIT_BRANCH"
  git -C "$REPO_DIR" reset --hard "origin/$GIT_BRANCH"
else
  echo "Cloning repo..."
  install -d "$REPO_DIR"
  rm -rf "$REPO_DIR"/* 2>/dev/null || true
  git clone --depth 1 -b "$GIT_BRANCH" "$GIT_URL" "$REPO_DIR"
fi

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
echo "Stopping service if running to avoid 'Text file busy'..."
systemctl stop $SERVICE_NAME 2>/dev/null || true
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
systemctl enable $SERVICE_NAME || true
systemctl start $SERVICE_NAME || systemctl restart $SERVICE_NAME || true

echo "Service $SERVICE_NAME installed (or restarted). Check status with: systemctl status $SERVICE_NAME -l"
echo "Deployment complete."
