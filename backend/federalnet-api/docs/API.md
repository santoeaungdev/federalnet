# FederalNet API Reference

Base path: `/api`

Overview: concise list of endpoints exposed by the `federalnet-api` service (grouped by area). Bearer JWT required where indicated.

## General
- GET /api/health — health check (public)

## Customer
- POST /api/customer/login — customer login (returns JWT)
- GET /api/customers/me — get current customer (requires customer JWT)
- POST /api/customer/register — register a new customer (dev/production guarded by DB and validations)
- POST /api/customer/purchase_plan — purchase an internet plan (customer JWT)

## Admin / Owner / Operator (prefix `/api/admin`)
- POST /api/admin/login — admin/operator/owner login (returns JWT)
- GET /api/admin/nrcs — list NRC codes (admin/operator/owner)
- POST /api/admin/customer/register — create customer (admin/operator/owner)
- POST /api/admin/customer/update — update customer (admin/operator/owner)
- POST /api/admin/assign_plan — assign PPPoE username to radgroup (admin/operator/owner)
- GET /api/admin/customers — list customers (admin only)
- GET /api/admin/customers/{id} — get customer detail (admin/operator/owner)

### NAS (FreeRADIUS)
- GET /api/admin/nas — list NAS entries
- POST /api/admin/nas — create NAS
- POST /api/admin/nas/{id} — update NAS
- DELETE /api/admin/nas/{id} — delete NAS

### Owners
- GET /api/admin/owners — list owners (owner can list self/family)
- POST /api/admin/owners — create owner / family member
- POST /api/admin/owners/{id} — update owner
- DELETE /api/admin/owners/{id} — delete owner
- POST /api/admin/owners/{id}/topup_customer — owner tops up a customer's wallet (owner or admin)

### Operators
- GET /api/admin/operators — list operators
- POST /api/admin/operators — create operator
- POST /api/admin/operators/{id} — update operator
- DELETE /api/admin/operators/{id} — delete operator

### Users
- POST /api/admin/users — create admin/report/owner/operator user

### Internet Plans
- GET /api/admin/internet_plans — list internet plans
- POST /api/admin/internet_plans — create internet plan
- POST /api/admin/internet_plans/{id} — update internet plan

### Owner Income
- POST /api/admin/owner_income/compute — compute owner income for a period (YYYY-MM)
- GET /api/admin/owner_income — query owner income (filters: owner_id, period)
- GET /api/admin/owner_income/history/{owner_id} — owner monthly income history

## Seed endpoints (dev only)
- POST /api/_seed_test_data — seed test admin/customer rows (enabled by `ENABLE_SEED_ENDPOINTS`)
- POST /api/_seed_more_customers — seed additional customers (dev only)

---
Notes:
- Many endpoints require JWT in `Authorization: Bearer <token>`; admin-scoped endpoints require admin/operator/owner roles as enforced in code.
- For request/response shapes, see `src/models.rs`.
- This file was generated from `src/main.rs` route declarations; update manually if you add new routes.

## Request / Response Schemas (from `src/models.rs`)

Where endpoints reference model names below, the struct is defined in `src/models.rs`.
Below are concise field lists for the most-used request/response types.

- `AdminLoginRequest` (request)
	- `username: String`
	- `password: String`

- `AdminLoginResponse` (response)
	- `token: String`
	- `admin: AdminPublic`

- `AdminPublic` (response)
	- `id: u32`, `username: String`, `fullname: String`, `user_type: String`

- `CustomerLoginRequest` (request)
	- `username: String`, `password: String`

- `CustomerLoginResponse` (response)
	- `token: String`, `customer: CustomerPublic`

- `CustomerPublic` (response)
	- `id: i32`, `username: String`, `fullname: String`, `balance: BigDecimal`

 - `CustomerRegisterRequest` (request)
 	- `username: String`, `password: String`, `fullname: String`, `nrc_no: String`, `phonenumber: String`, `email: String`,
 		`service_type: String`, `pppoe_username: String`, `pppoe_password: String`, `router_tag: String`,
 		`internet_plan_id: Option<i32>`

 - `CustomerUpdateRequest` (request)
 	- `id: i32`, `username: String`, `password: Option<String>`, `fullname: String`, `nrc_no: String`, `phonenumber: String`, `email: String`,
 		`service_type: String`, `pppoe_username: String`, `pppoe_password: Option<String>`, `router_tag: String`,
 		`internet_plan_id: Option<i32>`
 	- Additionally may include: `owner_type: Option<String>`, `main_owner_id: Option<i32>`

Notes:
- Password update contract: For update endpoints (`CustomerUpdateRequest`, `OwnerUpdateRequest`, operator updates), the `password` and `pppoe_password` fields are optional (`null` or omitted). If the field is omitted or `null` or an empty string, the backend will treat it as "unchanged" and preserve the existing password. To change a password, provide a non-empty string value.

Integration tests:
- A simple integration test that can hit a running VPS API is included under `tests/integration_vps.rs` in the backend crate. It is guarded by the `RUN_VPS_INTEGRATION` environment variable. To run it against your VPS at `143.110.185.159`, run:

```bash
export RUN_VPS_INTEGRATION=1
export VPS_BASE_URL="http://143.110.185.159:8080/api"
cargo test -p federalnet-api --test integration_vps -- --nocapture
```

The test checks `/health` and `/internet_plans` endpoints and will be skipped unless `RUN_VPS_INTEGRATION` is set.

- `AdminCustomerListItem` (response)
	- `id: i32`, `username: String`, `fullname: String`, `pppoe_username: String`, `groupname: Option<String>`

- `AdminCustomerDetail` (response)
	- `id, username, fullname, nrc_no, phonenumber, email, service_type, pppoe_username, pppoe_password, status, groupname: Option<String>`,
		`internet_plan_id: Option<i32>` (note: `internet_plan_id` may be filled after lookup)

- `NasCreateRequest` / `NasUpdateRequest` (request)
	- `owner_id: Option<i32>`, `nasname: String`, `shortname: Option<String>`, `type: String (nas_type)`, `secret: String`, `description: Option<String>`

- `Nas` (response)
	- `id: i32`, `owner_id: Option<i32>`, `nasname: String`, `shortname: Option<String>`, `nas_type: String`, `ports: Option<i32>`,
		`secret: String`, `server: Option<String>`, `community: Option<String>`, `description: String`, `routers: String`

- `OwnerPublic` / `OwnerCreateRequest` / `OwnerUpdateRequest`
	- `OwnerPublic`: `id: u32`, `username`, `fullname`, `status`, `owner_type`, `main_owner_id: Option<i32>`
	- `OwnerCreateRequest`: `username`, `password`, `fullname`, `owner_type: Option<String>`, `main_owner_id: Option<i32>`
	- `OwnerUpdateRequest`: `id`, `username`, `password: Option<String>`, `fullname`, `status: Option<String>`, `owner_type: Option<String>`, `main_owner_id: Option<i32>`

- `OwnerTopupRequest` (request)
	- `customer_id: i32`, `amount: BigDecimal`, `note: Option<String>`, `idempotency_key: Option<String>`

- `PurchasePlanRequest` (request)
	- `plan_id: i32`

- `InternetPlan` / `InternetPlanCreateRequest` / `InternetPlanUpdateRequest`
	- `InternetPlan` (response): `id: i32`, `name: String`, `category: String`, `price: BigDecimal`, `currency: String`,
		`validity_unit: String`, `validity_value: i32`, `download_mbps: i32`, `upload_mbps: i32`, `radius_groupname: String`, `status: String`
	- `InternetPlanCreateRequest`: `name`, `category`, `price`, `currency: Option<String>`, `validity_unit`, `validity_value`, `download_mbps`, `upload_mbps`, `radius_groupname`, `status: Option<String>`
	- `InternetPlanUpdateRequest`: includes `id` and same fields as `InternetPlanCreateRequest` (non-optional where applicable)

- `OwnerIncomeComputeRequest` (request)
	- `period: String` (format: `YYYY-MM`)

- `UserCreateRequest` (request)
	- `username: String`, `password: String`, `fullname: String`, `user_type: String` (allowed: admin/report/owner/operator)

## Examples

Below are concise JSON request/response examples for common flows.

1) Admin login

Request (POST /api/admin/login):

{
	"username": "admin",
	"password": "adminpass"
}

Response:

{
	"token": "<JWT_TOKEN>",
	"admin": {
		"id": 1,
		"username": "admin",
		"fullname": "Admin User",
		"user_type": "Admin"
	}
}

2) Customer login

Request (POST /api/customer/login):

{
	"username": "testuser",
	"password": "custpass"
}

Response:

{
	"token": "<JWT_TOKEN>",
	"customer": {
		"id": 10,
		"username": "testuser",
		"fullname": "Test Customer",
		"balance": "100.00"
	}
}

3) Customer register

Request (POST /api/customer/register):

{
	"username": "newcust",
	"password": "Secret123",
	"fullname": "New Customer",
	"nrc_no": "12/ABC(N)123456",
	"phonenumber": "0912345678",
	"email": "new@example.com",
	"service_type": "PPPoE",
	"pppoe_username": "ppp-newcust",
	"pppoe_password": "ppp-secret",
	"router_tag": "",
	"internet_plan_id": null
}

Response (201 Created):

{
	"id": 123,
	"username": "newcust",
	"pppoe_username": "ppp-newcust"
}

4) Purchase plan (customer)

Request (POST /api/customer/purchase_plan) — Bearer token required:

{
	"plan_id": 5
}

Response (200 OK):

{
	"customer_id": 10,
	"plan_id": 5,
	"price": 9.99
}

5) Admin create customer

Request (POST /api/admin/customer/register) — Bearer admin token required:

{
	"username": "cust-by-admin",
	"password": "Pwd#1",
	"fullname": "Customer By Admin",
	"nrc_no": "22/DEF(N)987654",
	"phonenumber": "0922222222",
	"email": "byadmin@example.com",
	"service_type": "PPPoE",
	"pppoe_username": "ppp-cust-admin",
	"pppoe_password": "ppp-pass",
	"router_tag": "default",
	"internet_plan_id": null
}

Response (201 Created):

{
	"id": 124,
	"username": "cust-by-admin",
	"pppoe_username": "ppp-cust-admin"
}

6) Admin assign plan

Request (POST /api/admin/assign_plan) — Bearer admin token required:

{
	"pppoe_username": "ppp-newcust",
	"router_tag": "gold-plan"
}

Response (200 OK):

{
	"username": "ppp-newcust",
	"group": "gold-plan"
}

7) Owner topup customer

Request (POST /api/admin/owners/{id}/topup_customer) — Bearer owner/admin token required:

{
	"customer_id": 10,
	"amount": "50.00",
	"note": "Topup by owner",
	"idempotency_key": "abc-123"
}

Response (200 OK):

{
	"owner_id": 7,
	"customer_id": 10,
	"amount": "50.00"
}

8) Internet plan create

Request (POST /api/admin/internet_plans) — Bearer admin token required:

{
	"name": "Gold 100GB",
	"category": "Home",
	"price": "9.99",
	"currency": "USD",
	"validity_unit": "month",
	"validity_value": 1,
	"download_mbps": 100,
	"upload_mbps": 20,
	"radius_groupname": "gold-100",
	"status": "Active"
}

Response (201 Created):

{
	"id": 5,
	"name": "Gold 100GB",
	"radius_groupname": "gold-100"
}

---
If you'd like, I can expand these with full field descriptions or generate OpenAPI schema from `src/models.rs` next.

## Endpoint Details

Each endpoint below lists the request body fields (if any) and the response fields with short descriptions. Field types refer to Rust types in `src/models.rs`.

- POST /api/admin/login
	- Request: `AdminLoginRequest` — `username: String` (admin username), `password: String` (plaintext)
	- Response: `AdminLoginResponse` — `token: String` (JWT), `admin: AdminPublic` (public admin info)

- POST /api/customer/login
	- Request: `CustomerLoginRequest` — `username`, `password`
	- Response: `CustomerLoginResponse` — `token: String`, `customer: CustomerPublic` (`id`, `username`, `fullname`, `balance`)

- GET /api/customers/me
	- Request: Bearer token (customer)
	- Response: `CustomerPublic` — current customer details

- POST /api/customer/register
	- Request: `CustomerRegisterRequest` — `username`, `password`, `fullname`, `nrc_no`, `phonenumber`, `email`, `service_type`, `pppoe_username`, `pppoe_password`, `router_tag`, `internet_plan_id` (optional)
	- Response: Created object with `id`, `username`, `pppoe_username`

- POST /api/customer/purchase_plan
	- Request: `PurchasePlanRequest` — `plan_id: i32`
	- Response: `{ customer_id: i32, plan_id: i32, price: f64 }` on success

- GET /api/admin/nrcs
	- Response: list of `NrcRow` — `id`, `name_en`, `name_mm`, `nrc_code`

- POST /api/admin/customer/register
	- Request: same as `CustomerRegisterRequest` (admin may set `created_by` indirectly)
	- Response: Created customer info (`id`, `username`, `pppoe_username`)

- POST /api/admin/customer/update
	- Request: `CustomerUpdateRequest` — includes `id` and fields to update; may include `owner_type` and `main_owner_id` for owner-managed customers
	- Response: updated minimal customer info (`id`, `username`, `pppoe_username`)

- POST /api/admin/assign_plan
	- Request: `AssignPlanRequest` — `pppoe_username: String`, `router_tag: String` (radgroup)
	- Response: `{ username: String, group: String }`

- GET /api/admin/customers
	- Response: list of `AdminCustomerListItem` — `id`, `username`, `fullname`, `pppoe_username`, `groupname` (optional)

- GET /api/admin/customers/{id}
	- Response: `AdminCustomerDetail` — detailed customer row including `nrc_no`, `pppoe_password`, `status`, and `internet_plan_id` (optional)

- NAS endpoints (`/api/admin/nas`)
	- GET: returns list of `Nas` rows
	- POST `/api/admin/nas`: Request `NasCreateRequest` — `owner_id` (opt), `nasname`, `shortname`, `type` (nas_type), `secret`, `description` (opt)
	- POST `/api/admin/nas/{id}`: Request `NasUpdateRequest` (same fields plus `id`)
	- DELETE `/api/admin/nas/{id}`: Response `{ id: i32 }` on success

- Owners endpoints (`/api/admin/owners`)
	- GET: returns list of `OwnerPublic` entries (owner scoped behavior applies)
	- POST: `OwnerCreateRequest` — `username`, `password`, `fullname`, optional `owner_type`, optional `main_owner_id`
	- POST `/api/admin/owners/{id}`: `OwnerUpdateRequest` — fields to update (password optional)
	- DELETE `/api/admin/owners/{id}`: deletes owner
	- POST `/api/admin/owners/{id}/topup_customer`: `OwnerTopupRequest` — `customer_id`, `amount: BigDecimal`, optional `note`, optional `idempotency_key`; Response contains recorded transaction id and amounts

- Operators endpoints (`/api/admin/operators`)
	- Similar to owners: create/update/delete operator records. Requests use `OwnerCreateRequest`/`OwnerUpdateRequest` shapes for username/password/fullname/status.

- POST /api/admin/users
	- Request: `UserCreateRequest` — `username`, `password`, `fullname`, `user_type` (must be one of `admin|report|owner|operator`)

- Internet Plans (`/api/admin/internet_plans`)
	- GET: list `InternetPlan`
	- POST: `InternetPlanCreateRequest` — `name`, `category`, `price`, optional `currency`, `validity_unit`, `validity_value`, `download_mbps`, `upload_mbps`, `radius_groupname`, optional `status`
	- POST `/api/admin/internet_plans/{id}`: `InternetPlanUpdateRequest` (includes `id`)

- Owner income endpoints
	- POST `/api/admin/owner_income/compute`: `OwnerIncomeComputeRequest` — `period: String` (YYYY-MM). Response: `{ period: String, status: "computed" }`.
	- GET `/api/admin/owner_income`: returns owner_income rows with `id`, `owner_id`, `customer_id`, `nas_id`, `period`, `usage_bytes`, `revenue`, `tax`, `created_at`.
	- GET `/api/admin/owner_income/history/{owner_id}`: monthly aggregates for an owner.

- Seed endpoints (dev only)
	- POST `/api/_seed_test_data` and `/api/_seed_more_customers` — no request body, return seeded status

---
If you'd like, I can now (A) expand each endpoint with example request/response bodies for all fields, (B) generate an OpenAPI JSON/YAML from these schemas, or (C) commit the documentation changes. Which should I do next?
