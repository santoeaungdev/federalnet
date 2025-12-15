# Development Runbook — working terminal commands

This file collects the terminal commands that were used successfully while developing and testing the FederalNet project locally. Use these as copy-paste commands for local reproduction.

## Docker & MySQL

- Start MySQL dev container (from project root):

```powershell
docker compose -f docker-compose.dev.yml up -d
```

- Check running containers and service status:

```powershell
docker compose -f docker-compose.dev.yml ps
```

- Enter the running MySQL container shell:

```powershell
docker exec -it mysql-federalnet-dev bash
```

- Inside container: connect to MySQL as root (you will be prompted for the password):

```sh
mysql -u root -p
# (enter the root password from docker-compose, e.g. admin$@nT03)
```

- Example SQL in MySQL prompt:

```sql
SHOW DATABASES;
USE federalnetwuntho;
SELECT COUNT(*) FROM tbl_customers;
SELECT * FROM tbl_users LIMIT 5;
```

## Backend (Rust) — build and run

- Build in release mode:

```powershell
cd backend\federalnet-api
cargo build --release
```

- Run the backend (starts Actix-web server on 0.0.0.0:8080):

```powershell
Start-Process -FilePath .\target\release\federalnet-api -WorkingDirectory C:\dev\federalnet\backend\federalnet-api -PassThru
# or run in foreground for logs:
./target/release/federalnet-api
```

- Health check (from host):

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8080/api/health -Method Get
# OR curl
curl http://127.0.0.1:8080/api/health
```

## Seeding test data (temporary endpoint used during dev)

- Seed test admin/customer (temporary internal endpoint added for convenience):

```powershell
Invoke-RestMethod -Uri http://127.0.0.1:8080/api/_seed_test_data -Method Post -ContentType "application/json"
# OR using curl.exe
curl.exe -s -X POST http://127.0.0.1:8080/api/_seed_test_data -H "Content-Type: application/json"
```

## Testing auth endpoints

- Admin login (example with PowerShell):

```powershell
$body = @{username='testadmin'; password='adminpass'} | ConvertTo-Json
Invoke-RestMethod -Uri http://127.0.0.1:8080/api/admin/login -Method Post -Body $body -ContentType "application/json"
```

- Customer login (example):

```powershell
$body = @{username='testuser2'; password='custpass'} | ConvertTo-Json
Invoke-RestMethod -Uri http://127.0.0.1:8080/api/customer/login -Method Post -Body $body -ContentType "application/json"
```

## Flutter (frontend) — install deps and run web server

- Get dependencies for each app:

```powershell
cd frontend\admin_app; flutter pub get
cd ../customer_app; flutter pub get
cd ../owner_app; flutter pub get
```

- Run a Flutter app as a web-server (example admin on port 8081):

```powershell
cd frontend\admin_app
flutter run -d web-server --web-port=8081 --web-hostname=0.0.0.0
```

- Build web release (to verify compile):

```powershell
cd frontend\admin_app
flutter build web --web-renderer=html
```

## Password migration (one-time)

- Build and run the migration binary (created in `backend/federalnet-api/src/bin/migrate_passwords.rs`):

```powershell
cd backend\federalnet-api
# ensure .env has DATABASE_URL and other env vars
cargo run --bin migrate_passwords
```

The migration script scans `tbl_customers` for non-bcrypt passwords and replaces them with bcrypt hashes.

## Useful Windows host commands used during debugging

- List processes listening on port 8080:

```powershell
netstat -ano | findstr ":8080"
tasklist /FI "PID eq <pid>"
taskkill /F /IM federalnet-api.exe
```

## Notes & references
- Myanmar NRC data source used for registration validation: https://github.com/htetoozin/Myanmar-NRC

Additions/edits made during this session:
- Added temporary backend route `/_seed_test_data` to insert test accounts.
- Added `migrate_passwords` migration binary to hash existing plaintext customer passwords.

## Admin-driven customer registration & FreeRADIUS integration

- New admin endpoint (requires admin JWT):

```powershell
POST http://127.0.0.1:8080/api/admin/customer/register
# Authorization: Bearer <admin-jwt>
```

- The endpoint validates `nrc_no` (mandatory), creates the `tbl_customers` row (bcrypt-hashed password), and inserts a `radcheck` entry:

```sql
INSERT INTO radcheck (username, attribute, op, value)
VALUES (<pppoe_username>, 'Cleartext-Password', ':=', <pppoe_password>);
```

- This matches the typical phpnuxbill workflow where customers are added to FreeRADIUS `radcheck` and optionally `radusergroup` for plan mapping (the backend includes a placeholder to add `radusergroup`).

- Notes:
	- `nrc_no` column was added to `tbl_customers` during this session.
	- `tbl_customers.password` column was expanded to `VARCHAR(128)` to store bcrypt hashes.
	- For production, consider: validating NRC against the Myanmar NRC dataset, syncing radcheck changes via an atomic transaction, and making sure FreeRADIUS reads the same database (or use raddb modules to sync).


---
If you'd like, I can also:
- Remove the temporary seed endpoint from `backend/federalnet-api` and keep the seeded DB rows,
- Run the migration script now and append the command output here,
- Or wire the Flutter registration UI to perform NRC validation using the referenced NRC dataset.

End of commands and notes.
