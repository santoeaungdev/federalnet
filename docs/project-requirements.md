Project Requirements — Roles and Access Control

Overview
- Purpose: document user roles, who can create/update/delete which entities, and API behavior for the FederalNet project.

Roles
- SuperAdmin: full system authority. Can perform all actions including deletes.
- Admin: high-level administrative role. Can create Admin/Report/Owner/Operator users, manage NAS, Owners, Operators, Customers.
- Operator: operational role. Can create and update Owners and NAS (but not delete). Cannot manage Operators.
- Owner: business user. Can create customers, top up their customers, view owner income (as implemented).
- Report: read-only/reporting user; may be added for dashboards.

User creation rules
- Endpoint: POST `/api/admin/users`
  - Auth: SuperAdmin or Admin only.
  - Payload: `{ username, password, fullname, user_type }` where `user_type` is one of: `Admin`, `Report`, `Owner`, `Operator`.
  - Result: creates a `tbl_users` row with `user_type` set accordingly.

Existing endpoints and access
- Admin-only endpoints: require `role=Admin` or `role=SuperAdmin` depending on sensitivity.
  - Delete functions (e.g., delete NAS, delete Owner, delete Operator) require `role=SuperAdmin` or `role=Admin`.
  - Operator CRUD endpoints require `role=SuperAdmin` or `role=Admin` to manage Operators.
- Operator privileges:
  - Can create and update Owners (`/admin/owners`) and NAS (`/admin/nas` update/create).
  - Cannot delete Owners/Operators/NAS.
- Owner privileges:
  - Can create customers and perform owner-topup for their own owner_id.

DB migrations
- `docker/add_user_types.sql` — ensure `tbl_users.user_type` enum includes `SuperAdmin, Admin, Report, Owner, Operator`.
- Apply migrations before creating users of new types.

Idempotency and audit
- Owner top-ups support `idempotency_key` to avoid duplicate charges.
- Top-ups write audit rows into `tbl_logs`.

Notes
- Token `role` claim is derived from `tbl_users.user_type`.
- Admin login endpoint returns a JWT with `role` = lowercased `user_type` value.

Next actions you may request
- Add frontend UI for Operator creation and Owner/Operator dropdowns.
- Seed initial SuperAdmin account migration.
- Add RBAC middleware to centralize role checks.
