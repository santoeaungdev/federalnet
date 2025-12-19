# Internet Plans and NAS (Router) Management API Documentation

This document describes the API endpoints for managing Internet Plans and NAS (Network Access Server/Router) entries in the FederalNet system.

## Base URL
```
http://localhost:8080/api
```

## Authentication
All endpoints require admin JWT authentication via `Authorization: Bearer <token>` header.

---

## NAS (Router) Management

### List NAS Entries
**GET** `/admin/nas`

Returns all NAS entries from the FreeRADIUS `nas` table.

**Response:**
```json
[
  {
    "id": 1,
    "nasname": "192.168.1.1",
    "shortname": "router1",
    "nas_type": "other",
    "ports": null,
    "secret": "mysecret123",
    "server": null,
    "community": null,
    "description": "Main Router",
    "routers": ""
  }
]
```

### Create NAS Entry
**POST** `/admin/nas`

Creates a new NAS entry in the FreeRADIUS `nas` table.

**Request Body:**
```json
{
  "nasname": "192.168.1.1",
  "shortname": "router1",
  "type": "other",
  "secret": "mysecret123",
  "description": "Main Router"
}
```

**Required Fields:**
- `nasname`: IP address or hostname of the NAS
- `secret`: RADIUS shared secret

**Optional Fields:**
- `shortname`: Short identifier for the NAS
- `type`: NAS type (default: "other")
- `description`: Human-readable description

**Response (201 Created):**
```json
{
  "id": 1,
  "nasname": "192.168.1.1"
}
```

### Update NAS Entry
**POST** `/admin/nas/{id}`

Updates an existing NAS entry.

**Request Body:**
```json
{
  "id": 1,
  "nasname": "192.168.1.1",
  "shortname": "router1",
  "type": "other",
  "secret": "newsecret456",
  "description": "Updated Main Router"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "nasname": "192.168.1.1"
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "nas_not_found"
}
```

---

## Internet Plans Management

### List Internet Plans
**GET** `/admin/internet_plans`

Returns all internet plans from the `tbl_internet_plans` table.

**Response:**
```json
[
  {
    "id": 1,
    "name": "Home 10Mbps",
    "category": "Personal",
    "price": "25000.00",
    "currency": "MMK",
    "validity_unit": "months",
    "validity_value": 1,
    "download_mbps": 10,
    "upload_mbps": 10,
    "radius_groupname": "HOME_10M",
    "status": "Active"
  }
]
```

### Create Internet Plan
**POST** `/admin/internet_plans`

Creates a new internet plan.

**Request Body:**
```json
{
  "name": "Home 10Mbps",
  "category": "Personal",
  "price": "25000.00",
  "currency": "MMK",
  "validity_unit": "months",
  "validity_value": 1,
  "download_mbps": 10,
  "upload_mbps": 10,
  "radius_groupname": "HOME_10M",
  "status": "Active"
}
```

**Required Fields:**
- `name`: Plan name
- `category`: "Personal" or "Business"
- `price`: Plan price (decimal)
- `validity_unit`: "minutes", "hours", "days", or "months"
- `validity_value`: Number of validity units
- `download_mbps`: Download speed in Mbps
- `upload_mbps`: Upload speed in Mbps
- `radius_groupname`: RADIUS group name for mapping

**Optional Fields:**
- `currency`: Currency code (default: "MMK")
- `status`: "Active" or "Inactive" (default: "Active")

**Response (201 Created):**
```json
{
  "id": 1,
  "name": "Home 10Mbps",
  "radius_groupname": "HOME_10M"
}
```

### Update Internet Plan
**POST** `/admin/internet_plans/{id}`

Updates an existing internet plan.

**Request Body:**
```json
{
  "id": 1,
  "name": "Home 15Mbps",
  "category": "Personal",
  "price": "30000.00",
  "currency": "MMK",
  "validity_unit": "months",
  "validity_value": 1,
  "download_mbps": 15,
  "upload_mbps": 15,
  "radius_groupname": "HOME_15M",
  "status": "Active"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "Home 15Mbps",
  "radius_groupname": "HOME_15M"
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "plan_not_found"
}
```

---

## Customer Registration/Update with Internet Plan

### Customer Registration
**POST** `/admin/customer/register`

The existing customer registration endpoint now accepts an optional `internet_plan_id` field.

**Request Body:**
```json
{
  "username": "johndoe",
  "password": "SecurePass123",
  "fullname": "John Doe",
  "nrc_no": "12/KaMaNa(N)123456",
  "phonenumber": "09123456789",
  "email": "john@example.com",
  "service_type": "PPPoE",
  "pppoe_username": "johndoe",
  "pppoe_password": "pppoepass123",
  "router_tag": "",
  "internet_plan_id": 1
}
```

**Behavior:**
- If `internet_plan_id` is provided, the system fetches the `radius_groupname` from the corresponding plan and assigns it to the customer via `radusergroup` table.
- If `internet_plan_id` is not provided or null, the system falls back to using `router_tag` if present.
- The RADIUS group assignment enables automatic authentication and authorization based on the plan's configuration.

### Customer Update
**POST** `/admin/customer/update`

The existing customer update endpoint now accepts an optional `internet_plan_id` field.

**Request Body:**
```json
{
  "id": 1,
  "username": "johndoe",
  "password": "SecurePass123",
  "fullname": "John Doe",
  "nrc_no": "12/KaMaNa(N)123456",
  "phonenumber": "09123456789",
  "email": "john@example.com",
  "service_type": "PPPoE",
  "pppoe_username": "johndoe",
  "pppoe_password": "pppoepass123",
  "router_tag": "",
  "internet_plan_id": 2
}
```

**Behavior:**
- Changing the `internet_plan_id` updates the customer's RADIUS group assignment to match the new plan's `radius_groupname`.
- Setting `internet_plan_id` to null removes the plan-based group assignment.

### Get Customer Detail
**GET** `/admin/customers/{id}`

The customer detail response now includes the `internet_plan_id` field if the customer has a plan assigned.

**Response:**
```json
{
  "id": 1,
  "username": "johndoe",
  "fullname": "John Doe",
  "nrc_no": "12/KaMaNa(N)123456",
  "phonenumber": "09123456789",
  "email": "john@example.com",
  "service_type": "PPPoE",
  "pppoe_username": "johndoe",
  "pppoe_password": "pppoepass123",
  "status": "Active",
  "groupname": "HOME_10M",
  "internet_plan_id": 1
}
```

---

## Database Schema

### tbl_internet_plans Table
```sql
CREATE TABLE `tbl_internet_plans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `category` varchar(50) NOT NULL DEFAULT 'Personal',
  `price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `currency` varchar(10) NOT NULL DEFAULT 'MMK',
  `validity_unit` enum('minutes','hours','days','months') NOT NULL DEFAULT 'months',
  `validity_value` int(11) NOT NULL DEFAULT 1,
  `download_mbps` int(11) NOT NULL DEFAULT 10,
  `upload_mbps` int(11) NOT NULL DEFAULT 10,
  `radius_groupname` varchar(64) NOT NULL,
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `status_idx` (`status`),
  KEY `radius_groupname_idx` (`radius_groupname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### nas Table (FreeRADIUS)
The `nas` table is part of the standard FreeRADIUS schema and is used directly without a custom wrapper table.

---

## Integration with RADIUS

### Group-Based Plan Assignment

When a customer is assigned an internet plan:

1. The system looks up the plan's `radius_groupname` from `tbl_internet_plans`.
2. An entry is created/updated in the `radusergroup` table:
   ```sql
   INSERT INTO radusergroup (username, groupname, priority) 
   VALUES ('pppoe_username', 'HOME_10M', 1);
   ```
3. FreeRADIUS uses this group mapping during authentication to apply any group-specific attributes (via `radgroupcheck` and `radgroupreply` tables).

### Future Enhancements

Currently, the system only maps customers to RADIUS groups. Future enhancements may include:
- Automatic creation of rate-limit entries in `radgroupreply` based on plan speeds
- MikroTik-specific attribute generation for bandwidth shaping
- Plan expiration tracking and automatic status updates

---

## Error Codes

| Error Code | Description |
|------------|-------------|
| `nas_not_found` | NAS entry with the specified ID does not exist |
| `plan_not_found` | Internet plan with the specified ID does not exist |
| `invalid_token` | JWT token is invalid or expired |
| `missing_token` | No authorization token provided |
| `bad_header` | Authorization header is malformed |

---

## Example Workflows

### Workflow 1: Create a New Internet Plan and Assign to Customer

1. **Create the plan:**
   ```bash
   POST /api/admin/internet_plans
   {
     "name": "Business 50Mbps",
     "category": "Business",
     "price": "75000.00",
     "currency": "MMK",
     "validity_unit": "months",
     "validity_value": 1,
     "download_mbps": 50,
     "upload_mbps": 50,
     "radius_groupname": "BIZ_50M",
     "status": "Active"
   }
   # Returns: { "id": 3, ... }
   ```

2. **Register a customer with this plan:**
   ```bash
   POST /api/admin/customer/register
   {
     "username": "business_user",
     "password": "pass123",
     "fullname": "Business User",
     "nrc_no": "12/KaMaNa(N)789012",
     "phonenumber": "09987654321",
     "email": "business@example.com",
     "service_type": "PPPoE",
     "pppoe_username": "biz_user",
     "pppoe_password": "pppoepass",
     "router_tag": "",
     "internet_plan_id": 3
   }
   ```

3. **Result:** Customer can now authenticate via PPPoE, and FreeRADIUS will see them as member of the "BIZ_50M" group.

### Workflow 2: Change Customer's Plan

1. **Fetch customer detail to see current plan:**
   ```bash
   GET /api/admin/customers/1
   # Returns: { ..., "internet_plan_id": 1, "groupname": "HOME_10M" }
   ```

2. **Update customer with new plan:**
   ```bash
   POST /api/admin/customer/update
   {
     "id": 1,
     "internet_plan_id": 3,
     ... (other fields)
   }
   ```

3. **Result:** Customer's RADIUS group is updated from "HOME_10M" to "BIZ_50M".
