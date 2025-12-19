# Internet Plans and NAS Management - Usage Guide

This guide explains how to use the phpNuxBill-style Internet Plan and Router (NAS) management features in FederalNet.

## Overview

The Internet Plan management system allows administrators to:
- Define reusable internet service plans with pricing, speed, and validity
- Manage RADIUS Network Access Servers (routers)
- Automatically assign RADIUS groups to customers based on their selected plan
- Track and update customer plans through the admin interface

## Prerequisites

1. **Database Setup**: Ensure the `tbl_internet_plans` table is created:
   ```bash
   mysql -u root -p federalnetwuntho < docker/add_internet_plans_table.sql
   ```

2. **Backend Running**: The Actix-web backend should be running on port 8080.

3. **Admin Credentials**: You need admin credentials to access the management features.

## Feature 1: NAS (Router) Management

### What is NAS?

NAS (Network Access Server) entries are routers or access points that communicate with the RADIUS server for authentication. Each NAS needs to be registered with:
- **NAS Name**: IP address or hostname (e.g., `192.168.1.1`)
- **Short Name**: A friendly identifier (e.g., `router1`)
- **Secret**: A shared secret for RADIUS authentication
- **Type**: Usually `other` (default)

### Using the Admin UI

1. **Navigate to NAS Management**:
   - Open the admin app
   - Tap the menu icon (☰)
   - Select "NAS (Routers)"

2. **View Existing NAS**:
   - The list shows all registered routers with their details

3. **Add a New NAS**:
   - Tap the floating action button (+)
   - Fill in the form:
     - **NAS Name**: Enter the router's IP address (e.g., `192.168.10.1`)
     - **Short Name**: Enter a friendly name (e.g., `main-router`)
     - **RADIUS Secret**: Enter a secure shared secret
     - **Description**: Optional description
   - Tap "Create"

### API Usage

**List NAS Entries:**
```bash
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  http://localhost:8080/api/admin/nas
```

**Create NAS:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "nasname": "192.168.1.1",
    "shortname": "router1",
    "secret": "mysecret123",
    "type": "other",
    "description": "Main Router"
  }' \
  http://localhost:8080/api/admin/nas
```

## Feature 2: Internet Plans Management

### Creating Plans

Internet plans define the service packages you offer to customers. Each plan includes:
- **Name**: Descriptive name (e.g., "Home 10Mbps")
- **Category**: "Personal" or "Business"
- **Price**: Monthly/periodic price
- **Currency**: e.g., "MMK", "USD"
- **Validity**: Duration (value + unit: minutes/hours/days/months)
- **Speed**: Download and upload speeds in Mbps
- **RADIUS Group**: The group name to assign in RADIUS
- **Status**: "Active" or "Inactive"

### Using the Admin UI

1. **Navigate to Internet Plans**:
   - Open the admin app
   - Tap the menu icon (☰)
   - Select "Internet Plans"

2. **View Existing Plans**:
   - The list shows all plans with their details:
     - Name, category, price
     - Speed (download/upload)
     - Validity period
     - RADIUS group
     - Status

3. **Create a New Plan**:
   - Tap the floating action button (+)
   - Fill in the form:
     - **Plan Name**: e.g., "Home 10Mbps"
     - **Category**: Select "Personal" or "Business"
     - **Price**: e.g., "25000"
     - **Currency**: e.g., "MMK"
     - **Validity Unit**: Select "months"
     - **Validity Value**: e.g., "1"
     - **Download Speed**: e.g., "10" Mbps
     - **Upload Speed**: e.g., "10" Mbps
     - **RADIUS Group Name**: e.g., "HOME_10M"
     - **Status**: Select "Active"
   - Tap "Create"

### API Usage

**List Plans:**
```bash
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  http://localhost:8080/api/admin/internet_plans
```

**Create Plan:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
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
  }' \
  http://localhost:8080/api/admin/internet_plans
```

## Feature 3: Assigning Plans to Customers

### During Customer Registration

1. **Navigate to Register Customer**:
   - Open the admin app
   - Tap the menu icon (☰)
   - Select "Register Customer"

2. **Fill Customer Details**:
   - Username, password, full name
   - NRC details (state, township, type, number)
   - Phone, email

3. **Select Internet Plan** (Optional):
   - Scroll down to the "Internet Plan" dropdown
   - Select a plan from the list
   - The plan's RADIUS group will be automatically assigned

4. **Complete Registration**:
   - Tap "Create"
   - The customer's PPPoE account is created with the selected plan

### During Customer Update

1. **Navigate to Customer List**:
   - Open the admin app
   - View the list of customers

2. **Select a Customer**:
   - Tap on the customer you want to edit

3. **View Current Plan**:
   - The edit form shows the current plan (if any)

4. **Change Plan**:
   - Select a different plan from the dropdown
   - Or select "-- No plan selected --" to remove the plan

5. **Save Changes**:
   - Tap "Update"
   - The customer's RADIUS group is updated immediately

### API Usage

**Register with Plan:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
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
  }' \
  http://localhost:8080/api/admin/customer/register
```

**Update Plan:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
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
  }' \
  http://localhost:8080/api/admin/customer/update
```

## How It Works: RADIUS Group Mapping

When you assign an internet plan to a customer:

1. **Backend fetches the plan's RADIUS group name** from `tbl_internet_plans`
2. **Creates/updates an entry in `radusergroup`**:
   ```sql
   username = customer's PPPoE username
   groupname = plan's radius_groupname
   priority = 1
   ```
3. **FreeRADIUS uses this mapping** during authentication to apply group-specific attributes

### Example Flow

1. Create plan "Home 10Mbps" with `radius_groupname = "HOME_10M"`
2. Register customer "johndoe" with `internet_plan_id = 1`
3. System creates:
   - Entry in `tbl_customers`
   - Entry in `radcheck` (username + password)
   - Entry in `radusergroup` (username = johndoe, groupname = HOME_10M)
4. When customer connects via PPPoE:
   - FreeRADIUS authenticates using `radcheck`
   - Applies group attributes from `radgroupcheck` and `radgroupreply` for "HOME_10M"

## Best Practices

### Plan Naming

Use clear, descriptive names that indicate:
- Target audience (Home, Business)
- Speed tier (10Mbps, 50Mbps)
- Any special features

Examples:
- `Home 10Mbps`
- `Business 50Mbps Unlimited`
- `Student 5Mbps Basic`

### RADIUS Group Naming

Use consistent naming conventions for RADIUS groups:
- All caps: `HOME_10M`, `BIZ_50M`
- Include speed: `_10M`, `_50M`
- Include type: `HOME_`, `BIZ_`

### Category Usage

- **Personal**: Plans for residential/home users
- **Business**: Plans for commercial/enterprise users

This helps with reporting and billing differentiation.

### Plan Status

- Set plans to "Inactive" when you want to stop offering them
- Inactive plans won't show in the dropdown for new customers
- Existing customers with inactive plans keep their current assignment

## Troubleshooting

### Customer Not Authenticating

1. Check `radcheck` table for the PPPoE username and password
2. Check `radusergroup` table for the group mapping
3. Verify the RADIUS group name matches the plan's `radius_groupname`
4. Check FreeRADIUS logs for authentication attempts

### Plan Not Showing in Dropdown

1. Verify the plan's status is "Active"
2. Refresh the customer registration/edit page
3. Check the backend logs for errors loading plans

### Wrong Group Assigned

1. Check the customer detail API response for `internet_plan_id` and `groupname`
2. Verify the plan's `radius_groupname` is correct
3. Update the customer to reassign the correct plan

## Future Enhancements

The current implementation provides RADIUS group mapping only. Future versions may include:

1. **Automatic Rate Limiting**: Generate `radgroupreply` entries with MikroTik rate-limit attributes based on plan speeds
2. **Plan Expiration**: Track plan validity and automatically update status
3. **Plan Change History**: Log all plan changes for auditing
4. **Bandwidth Usage Tracking**: Monitor customer usage against plan limits
5. **Plan Upgrades/Downgrades**: Streamlined workflows for changing plans

## Support

For issues or questions, refer to:
- [API Documentation](./api-internet-plans-nas.md)
- [Test Plan](./test-plan-api.md)
- GitHub Issues: https://github.com/santoeaungdev/federalnet/issues
