# VPS FreeRADIUS Setup & Import Guide

This page contains ready-to-run steps to transfer `radcheck`/`radusergroup` data from the dev environment and configure FreeRADIUS on your VPS.

1) Copy the SQL dump (from your dev machine) to the VPS (example uses port 22):

```powershell
# from project root on developer Windows host
scp -P 22 docker\tmp_dump\rad_dump.sql root@143.110.185.159:/root/
```

Or use the helper script:

```powershell
.\scripts\scp_rad_dump.ps1
```

2) (Optional) Copy the DB-user creation SQL to VPS as well:

```powershell
scp -P 22 docker\rad_db_user.sql root@143.110.185.159:/root/
```

3) On the VPS: import the dump into the FreeRADIUS DB and create limited DB user

```bash
# on VPS
mysql -u root -p -D radius < /root/rad_dump.sql
# optionally run the prepared user creation file
mysql -u root -p < /root/rad_db_user.sql
```

4) FreeRADIUS SQL module config (example snippet for `/etc/freeradius/3.0/mods-available/sql`). Replace placeholders with actual values:

```
driver = "rlm_sql_mysql"

server = "localhost"
port = 3306
login = "radiususer"
password = "STRONG_PASSWORD"
radius_db = "radius"

radius_table_users = "radcheck"
radius_table_groups = "radusergroup"
```

After editing, enable + restart:

```bash
ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql
systemctl restart freeradius
```

5) Verify authentication locally on VPS (example):

```bash
# replace shared_secret with the client's secret configured in clients.conf
radtest pppoe_nrc2 pppass2 127.0.0.1 0 shared_secret
```

Security notes:
- Use a non-root DB user for FreeRADIUS (we provided `docker/rad_db_user.sql` to create one).
- Restrict the DB user to localhost if FreeRADIUS runs on the same host.
- Use strong passwords and avoid embedding secrets in repo files.
