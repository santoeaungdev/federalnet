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

Execution:
- Use Postman (FederalNet Postman collection) or curl/PowerShell scripts to run the above tests.
