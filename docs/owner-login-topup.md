Owner login and top-up endpoint documentation

Overview
- Owners are stored in `tbl_users` with `user_type` set to a value mapped to `owner` role by the API.
- The API shares the same `/admin/login` endpoint for admins and owners. The returned JWT contains a `role` claim set to either `admin` or `owner`.

Login (admins and owners)
- Endpoint: POST /api/admin/login
- Payload: { "username": "...", "password": "..." }
- Response: { "token": "...", "admin": { ... } }
- Notes: The `role` inside the token's claims will be `owner` for owner accounts. Owners should use this token for owner actions.

Owner-only actions
- Owners can call the owner-specific endpoints that accept owner tokens.
- Admin-only endpoints require `role=admin` or `role=operator` and will be rejected for owners.

- Top-up a customer (owner or admin)
- Endpoint: POST /api/admin/owners/{owner_id}/topup_customer
- Auth: Bearer token in `Authorization` header. Owners may only top up for their own `owner_id` (token `sub` must equal path `owner_id`). Admins may top up any owner.
- Payload (JSON):
  - `customer_id` (int) — target customer id
  - `amount` (decimal|string) — amount to credit
  - `note` (string, optional)
  - `idempotency_key` (string, optional) — client-provided key to make the request idempotent
- Success response: { "owner_id": <id>, "customer_id": <id>, "amount": "<amount>" }

- Idempotency behavior
- If `idempotency_key` is provided the server checks `owner_wallet_transactions` for an existing record with the same (`owner_id`, `idempotency_key`). If found, the existing transaction is returned and no duplicate is applied.
- The database migration `docker/add_owner_wallet_idempotency.sql` adds the `idempotency_key` column and index.

Audit logging
- Each top-up creates an audit entry in `tbl_logs` with type `owner_topup` and the owner id as `userid`.

Notes and deployment
- Ensure your `tbl_users.user_type` includes a value for owners or update `admin_login` mapping to recognize your owner user_type.
- Apply migrations in `docker/` before using owner top-ups (especially `add_owner_wallets.sql` and the new `add_owner_wallet_idempotency.sql`).
 - To allow Operator accounts, apply `docker/add_user_types.sql` to add `Operator` and `Owner` values to the `user_type` enum.

Operator creation
- Admins can create Operators via POST `/api/admin/operators` with same payload as owner creation (username, password, fullname). Operators appear in `tbl_users` with `user_type='Operator'`.
