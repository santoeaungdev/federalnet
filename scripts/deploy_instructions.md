# VPS deploy and DB setup instructions

1) Clone or pull the repo on the VPS (example path: /opt/federalnet)

```bash
# as root or sudo
mkdir -p /opt/federalnet/src
cd /opt/federalnet/src
git clone --depth 1 -b development https://github.com/santoeaungdev/federalnet.git .
```

2) Create the MySQL database and user

```bash
# Run as root or a MySQL user with CREATE/GRANT privileges
cd /opt/federalnet/src
sudo bash scripts/vps_setup_db.sh --user=root -p
# or to connect via TCP: sudo bash scripts/vps_setup_db.sh --host=127.0.0.1 --user=root -p
```

The SQL file `scripts/create_wunthofederalnet.sql` will create database `wunthofederalnet` and user `wunthoadmin` with password `admin$@nT03`.

3) Build the Rust backend

```bash
cd /opt/federalnet/src/backend/federalnet-api
source $HOME/.cargo/env || true
cargo build --release
```

4) Install the binary and systemd service

```bash
mkdir -p /opt/federalnet/bin
cp target/release/federalnet-api /opt/federalnet/bin/
useradd --system --no-create-home --shell /usr/sbin/nologin federalnet-api || true
cp scripts/systemd/federalnet-api.service.template /etc/systemd/system/federalnet-api.service

# Create /etc/default/federalnet-api with proper environment variables (example below)
cat > /etc/default/federalnet-api <<'EOF'
# DATABASE_URL must URL-encode special chars in the password. Example for password admin$@nT03:
# admin -> admin%24%401nT03 ($ -> %24, @ -> %40)
DATABASE_URL="mysql://wunthoadmin:admin%24%401nT03@127.0.0.1:3306/wunthofederalnet"
JWT_SECRET="replace_with_a_strong_random_secret"
EOF

systemctl daemon-reload
systemctl enable --now federalnet-api
systemctl status federalnet-api -l
```

5) Notes and debugging

- If MySQL runs on a different host, adjust `DATABASE_URL` host and port accordingly and create the user for that host (see `create_wunthofederalnet.sql`).
- Check logs: `journalctl -u federalnet-api -f` and backend stdout/stderr.
- If the binary fails to start due to missing env vars, ensure `/etc/default/federalnet-api` contains `DATABASE_URL` and `JWT_SECRET`.
