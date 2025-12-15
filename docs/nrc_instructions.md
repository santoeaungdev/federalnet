# NRC Dataset Import Instructions

You provided the Myanmar NRC SQL at:

https://github.com/htetoozin/Myanmar-NRC/blob/master/nrc.sql

To import the NRC dataset into the local MySQL dev DB, copy `nrc.sql` into the project (e.g., `docker/nrc.sql`) and run:

```powershell
# from project root
docker exec -i mysql-federalnet-dev mysql -uroot -p<root_password> federalnetwuntho < docker\nrc.sql
```

Notes:
- The `nrc.sql` file creates a table with NRC states/regions and codes that you can reference for validating and normalizing `nrc_no` at registration time.
- After import, you can join/lookup during registration, e.g. `SELECT * FROM nrc WHERE code = '12'`.
- If you want the backend to validate using this table, I can add a lookup step in `admin_customer_register` and `customer_register` to verify the given `nrc_no` components exist.

If you want, I can also import the file into the running container now if you place `nrc.sql` under `docker/`.
