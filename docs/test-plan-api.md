# API Test Plan — FederalNet

This document lists tests to verify the backend API endpoints (auth, customer management, FreeRADIUS integration).

Prereqs:
- Backend running at `http://127.0.0.1:8080`
- MySQL dev container running and accessible
- FreeRADIUS configured to read `radcheck`/`radusergroup` tables (or a test instance)

Tests:

1) Health check
- GET `/api/health` → 200 OK, body `OK`.

2) Admin login
- POST `/api/admin/login` with seed admin credentials (`testadmin`/`adminpass`) → 200 OK with token and admin public info.

3) Admin create customer (happy path)
- POST `/api/admin/customer/register` with valid body and `Authorization: Bearer <admin-token>`
- Required fields: `username`, `password`, `pppoe_username`, `pppoe_password`, `nrc_no` (non-empty)
- Expected: 201 Created, response contains `id`, `username`, `pppoe_username`.
- Verify: `tbl_customers` row created, `radcheck` row created, `radusergroup` row created if `router_tag` provided.

4) Admin create customer (invalid NRC)
- POST with `nrc_no` missing or malformed → 400 Bad Request with `invalid_nrc`.

5) Duplicate username / pppoe_username
- POST with existing `username` or `pppoe_username` → 400 with `username_exists` or `pppoe_username_exists`.

6) Customer login
- POST `/api/customer/login` with created customer credentials → 200 OK with token and customer public info.

7) Customer `customers/me`
- GET `/api/customers/me` with `Authorization: Bearer <customer-token>` → 200 OK with customer public data.

8) Edge cases
- Attempt register without admin token → 401 unauthorized.
- Long passwords → ensure stored bcrypt hash fits `VARCHAR(128)` and login still works.

9) NAS Management
- GET `/api/admin/nas` with admin token → 200 OK with list of NAS entries.
- POST `/api/admin/nas` with valid data (nasname, secret) → 201 Created with nas ID.
- POST `/api/admin/nas/{id}` to update → 200 OK.
- POST `/api/admin/nas/{invalid_id}` → 404 with `nas_not_found`.

10) Internet Plans Management
- GET `/api/admin/internet_plans` with admin token → 200 OK with list of plans.
- POST `/api/admin/internet_plans` with valid data → 201 Created with plan ID.
- Verify required fields: name, radius_groupname.
- POST `/api/admin/internet_plans/{id}` to update → 200 OK.
- POST `/api/admin/internet_plans/{invalid_id}` → 404 with `plan_not_found`.

11) Customer Registration with Internet Plan
- Create an internet plan first (e.g., plan_id = 1 with radius_groupname = "TEST_PLAN").
- POST `/api/admin/customer/register` with `internet_plan_id: 1` → 201 Created.
- Verify: `radusergroup` table has entry mapping pppoe_username to "TEST_PLAN".
- GET `/api/admin/customers/{id}` → returns `internet_plan_id: 1`.

12) Customer Update with Plan Change
- GET `/api/admin/customers/{id}` to see current plan.
- Create another plan (plan_id = 2 with different radius_groupname).
- POST `/api/admin/customer/update` with `internet_plan_id: 2` → 200 OK.
- Verify: `radusergroup` updated to new radius_groupname.
- POST `/api/admin/customer/update` with `internet_plan_id: null` → removes group assignment.

Execution:
- Use Postman (FederalNet Postman collection) or curl/PowerShell scripts to run the above tests.
- For new features, ensure database has the `tbl_internet_plans` table created (run migration SQL first).
