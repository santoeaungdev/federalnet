<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# can you update schema documentation with table format?

Yes. Here is an updated schema documentation in Markdown table format for the most important tables in your dump.

## RADIUS core tables

### `nas`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(10) | PK, auto increment | NAS row ID |
| nasname | varchar(128) | not null, index | NAS IP or hostname |
| shortname | varchar(32) | nullable | Short label for NAS |
| type | varchar(30) | default 'other' | NAS type |
| ports | int(5) | nullable | Port count |
| secret | varchar(60) | not null, default 'secret' | RADIUS shared secret |
| server | varchar(64) | nullable | Virtual server name |
| community | varchar(50) | nullable | SNMP community |
| description | varchar(200) | default 'RADIUS Client' | Human description |
| routers | varchar(32) | not null, default '' | Link to PHPNuxBill router name/id |

### `radacct`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| radacctid | bigint(21) | PK, auto inc | Accounting record ID |
| acctsessionid | varchar(64) | not null, index | NAS session ID |
| acctuniqueid | varchar(32) | not null, unique | Unique session key |
| username | varchar(64) | not null, index | User name |
| realm | varchar(64) | nullable | Realm/domain |
| nasipaddress | varchar(15) | not null, index | NAS IP address |
| nasportid | varchar(32) | nullable | NAS port ID |
| nasporttype | varchar(32) | nullable | NAS port type |
| acctstarttime | datetime | nullable, index | Session start |
| acctupdatetime | datetime | nullable | Last interim update |
| acctstoptime | datetime | nullable, index | Session stop |
| acctinterval | int(12) | nullable, index | Interim interval seconds |
| acctsessiontime | int(12) UNSIGNED | nullable, index | Session duration seconds |
| acctauthentic | varchar(32) | nullable | Authentication type |
| connectinfo_start | varchar(128) | nullable | Start info |
| connectinfo_stop | varchar(128) | nullable | Stop info |
| acctinputoctets | bigint(20) | nullable | Bytes in |
| acctoutputoctets | bigint(20) | nullable | Bytes out |
| calledstationid | varchar(50) | not null | Called station ID (AP/SSID) |
| callingstationid | varchar(50) | not null | Calling station ID (MAC) |
| acctterminatecause | varchar(32) | not null | Terminate cause |
| servicetype | varchar(32) | nullable | Service type |
| framedprotocol | varchar(32) | nullable | Protocol |
| framedipaddress | varchar(15) | not null, index | IPv4 address |
| framedipv6address | varchar(45) | not null, index | IPv6 address |
| framedipv6prefix | varchar(45) | not null, index | IPv6 prefix |
| framedinterfaceid | varchar(44) | not null, index | Interface ID |
| delegatedipv6prefix | varchar(45) | not null, index | Delegated prefix |
| class | varchar(64) | nullable, index | Session class tag |

### `radcheck` / `radreply` (same structure)

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) UNSIGNED | PK, auto inc | Row ID |
| username | varchar(64) | not null, index(32) | Username |
| attribute | varchar(64) | not null | RADIUS attribute |
| op | char(2) | not null (default '==' / '=') | Operator |
| value | varchar(253) | not null | Attribute value |

### `radgroupcheck` / `radgroupreply`

`radgroupcheck` is same as `radgroupcheck` above but keyed on `groupname` instead of username.

`radgroupreply` adds `plan_id`:


| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) UNSIGNED | PK, auto inc | Row ID |
| groupname | varchar(64) | not null, index(32) | Group name |
| attribute | varchar(64) | not null | RADIUS attribute |
| op | char(2) | not null, default '=' | Operator |
| value | varchar(253) | not null | Attribute value |
| plan_id | int(11) | not null, default 0 | Link to `tbl_plans.id` |


# continue from Billing and network tables to end of schema file

Continuing the Markdown documentation for the rest of the schema you pasted (billing, customers, users, logs, meta, etc.).[^1]

## Billing and network tables

### `tbl_plans`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Plan ID |
| name_plan | varchar(40) | not null | Plan name |
| id_bw | int(11) | not null | FK to `tbl_bandwidth.id` |
| price | varchar(40) | not null | Current price (string) |
| price_old | varchar(40) | not null, default '' | Previous price |
| type | enum('Hotspot','PPPOE','VPN','Balance') | not null | Service type |
| typebp | enum('Unlimited','Limited') | nullable | Bandwidth profile type |
| limit_type | enum('Time_Limit','Data_Limit','Both_Limit') | nullable | What is limited |
| time_limit | int(10) UNSIGNED | nullable | Time limit value |
| time_unit | enum('Mins','Hrs') | nullable | Time unit |
| data_limit | int(10) UNSIGNED | nullable | Data limit value |
| data_unit | enum('MB','GB') | nullable | Data unit |
| validity | int(11) | not null | Validity amount |
| validity_unit | enum('Mins','Hrs','Days','Months','Period') | not null | Validity unit |
| shared_users | int(11) | nullable | Concurrent user limit |
| routers | varchar(32) | not null | Router name/id |
| is_radius | tinyint(1) | not null, default 0 | 1 if pushed via RADIUS |
| pool | varchar(40) | nullable | IP pool name |
| plan_expired | int(11) | not null, default 0 | Extra flag for expiry |
| expired_date | tinyint(1) | not null, default 20 | Days until plan expired (legacy usage) |
| enabled | tinyint(1) | not null, default 1 | 0 = disabled |
| allow_purchase | enum('yes','no') | default 'yes' | Show in ?buy package? |
| prepaid | enum('yes','no') | default 'yes' | Prepaid plan flag |
| plan_type | enum('Business','Personal') | default 'Personal' | Customer segment |
| device | varchar(32) | not null, default '' | Device type or tag |
| on_login | text | nullable | Script/commands on login |
| on_logout | text | nullable | Script/commands on logout |

### `tbl_bandwidth`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(10) UNSIGNED | PK, auto increment | Bandwidth profile ID |
| name_bw | varchar(255) | not null | Profile name |
| rate_down | int(10) UNSIGNED | not null | Download rate value |
| rate_down_unit | enum('Kbps','Mbps') | not null | Download unit |
| rate_up | int(10) UNSIGNED | not null | Upload rate value |
| rate_up_unit | enum('Kbps','Mbps') | not null | Upload unit |
| burst | varchar(128) | not null, default '' | Burst parameters (if any) |

### `tbl_pool`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Pool ID |
| pool_name | varchar(40) | not null | Pool name |
| local_ip | varchar(40) | not null, default '' | Local/gateway IP |
| range_ip | varchar(40) | not null | IP range |
| routers | varchar(40) | not null | Router name/id |

### `tbl_port_pool`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(10) | PK, auto increment | Port pool ID |
| public_ip | varchar(40) | not null | Public IP |
| port_name | varchar(40) | not null | Label for port group |
| range_port | varchar(40) | not null | Port range |
| routers | varchar(40) | not null | Router name/id |

### `tbl_routers`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Router ID |
| name | varchar(32) | not null | Router name |
| ip_address | varchar(128) | not null | Management IP |
| username | varchar(50) | not null | Router login username |
| password | varchar(60) | not null | Router login password (hashed/plain) |
| description | varchar(256) | nullable | Description |
| coordinates | varchar(50) | not null, default '' | GPS coordinates |
| status | enum('Online','Offline') | default 'Online' | Status |
| last_seen | datetime | nullable | Last seen time |
| coverage | varchar(8) | not null, default '0' | Coverage radius/area |
| enabled | tinyint(1) | not null, default 1 | 0 = disabled |

## Billing and recharge tables

### `tbl_transactions`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Transaction ID |
| invoice | varchar(25) | not null | Invoice number |
| username | varchar(32) | not null | Customer username |
| user_id | int(11) | not null, default 0 | Customer ID (if linked) |
| plan_name | varchar(40) | not null | Purchased plan name |
| price | varchar(40) | not null | Plan price (string) |
| recharged_on | date | not null | Recharge date |
| recharged_time | time | not null, default '00:00:00' | Recharge time |
| expiration | date | not null | Plan expiry date |
| time | time | not null | Expiry time |
| method | varchar(128) | not null | Payment method description |
| routers | varchar(32) | not null | Router name/id |
| type | enum('Hotspot','PPPOE','VPN','Balance') | not null | Service type |
| note | varchar(256) | not null, default '' | Extra note |
| admin_id | int(11) | not null, default 1 | Admin who processed |

### `tbl_user_recharges`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Recharge row ID |
| customer_id | int(11) | not null | FK to `tbl_customers.id` |
| username | varchar(32) | not null | Customer username |
| plan_id | int(11) | not null | FK to `tbl_plans.id` |
| namebp | varchar(40) | not null | Plan/bandwidth profile name |
| recharged_on | date | not null | Recharge date |
| recharged_time | time | not null, default '00:00:00' | Recharge time |
| expiration | date | not null | Expiry date |
| time | time | not null | Expiry time |
| status | varchar(20) | not null | Status text |
| method | varchar(128) | not null, default '' | Method text |
| routers | varchar(32) | not null | Router name/id |
| type | varchar(15) | not null | Type text (Hotspot/PPPoE/etc) |
| admin_id | int(11) | not null, default 1 | Admin who processed |

### `tbl_voucher`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Voucher ID |
| type | enum('Hotspot','PPPOE') | not null | Voucher service type |
| routers | varchar(32) | not null | Router name/id |
| id_plan | int(11) | not null | FK to `tbl_plans.id` |
| code | varchar(55) | not null | Voucher code |
| user | varchar(45) | not null | User who used/generated |
| status | varchar(25) | not null | Status (unused, used, etc.) |
| created_at | timestamp | not null, default CURRENT_TIMESTAMP | Created timestamp |
| used_date | datetime | nullable | When voucher was used |
| generated_by | int(11) | not null, default 0 | Admin ID who generated |

### `tbl_payment_gateway`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Payment gateway row ID |
| username | varchar(32) | not null | Customer username |
| user_id | int(11) | not null, default 0 | Customer ID |
| gateway | varchar(32) | not null | Gateway code (xendit, midtrans, etc.) |
| gateway_trx_id | varchar(512) | not null, default '' | Gateway transaction ID |
| plan_id | int(11) | not null | FK to `tbl_plans.id` |
| plan_name | varchar(40) | not null | Plan name |
| routers_id | int(11) | not null | Router ID |
| routers | varchar(32) | not null | Router name |
| price | varchar(40) | not null | Price |
| pg_url_payment | varchar(512) | not null, default '' | Payment URL |
| payment_method | varchar(32) | not null, default '' | Payment method |
| payment_channel | varchar(32) | not null, default '' | Channel |
| pg_request | text | nullable | Raw request payload |
| pg_paid_response | text | nullable | Raw paid/notify payload |
| expired_date | datetime | nullable | Payment link expiry |
| created_date | datetime | not null | Created date |
| paid_date | datetime | nullable | When paid |
| trx_invoice | varchar(25) | not null, default '' | Link to `tbl_transactions.invoice` |
| status | tinyint(1) | not null, default 1 | 1 unpaid, 2 paid, 3 failed, 4 canceled |

## Customer tables

### `tbl_customers`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Customer ID |
| username | varchar(45) | not null | Login username |
| password | varchar(45) | not null | Password (hashed/plain) |
| photo | varchar(128) | not null, default '/user.default.jpg' | Avatar path |
| nrc_no | varchar(45) | not null | National ID card |
| pppoe_username | varchar(32) | not null, default '' | PPPoE username |
| pppoe_password | varchar(45) | not null, default '' | PPPoE password |
| pppoe_ip | varchar(32) | not null, default '' | PPPoE IP |
| fullname | varchar(45) | not null | Full name |
| address | mediumtext | nullable | Address |
| city | varchar(255) | nullable | City |
| district | varchar(255) | nullable | District |
| state | varchar(255) | nullable | State |
| zip | varchar(10) | nullable | ZIP/post code |
| phonenumber | varchar(20) | default '0' | Phone |
| email | varchar(128) | not null, default '1' | Email |
| coordinates | varchar(50) | not null, default '' | GPS coordinates |
| account_type | enum('Business','Personal') | default 'Personal' | Account type |
| balance | decimal(15,2) | not null, default 0.00 | Wallet balance |
| service_type | enum('Hotspot','PPPoE','VPN','Others') | default 'Others' | Primary service type |
| auto_renewal | tinyint(1) | not null, default 1 | Auto renew from balance |
| status | enum('Active','Banned','Disabled','Inactive','Limited','Suspended') | not null, default 'Active' | Status |
| created_by | int(11) | not null, default 0 | Creator admin ID |
| created_at | timestamp | not null, default CURRENT_TIMESTAMP | Created time |
| last_login | datetime | nullable | Last login |

### `tbl_customers_fields`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Row ID |
| customer_id | int(11) | not null, index | FK to `tbl_customers.id` |
| field_name | varchar(255) | not null | Extra field name |
| field_value | varchar(255) | not null | Extra field value |

### `tbl_customers_inbox`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(10) UNSIGNED | PK, auto increment | Message ID |
| customer_id | int(11) | not null | FK to `tbl_customers.id` |
| date_created | datetime | not null | When message created |
| date_read | datetime | nullable | When read |
| subject | varchar(64) | not null | Subject |
| body | text | nullable | Body |
| from | varchar(8) | not null, default 'System' | Sender tag (System/Admin/other) |
| admin_id | int(11) | not null, default 0 | Admin ID (0 = system) |

## Admin / staff tables

### `tbl_users`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(10) UNSIGNED | PK, auto increment | User ID |
| root | int(11) | not null, default 0 | Parent/root ID for sub???accounts |
| photo | varchar(128) | not null, default '/admin.default.png' | Avatar path |
| username | varchar(45) | not null, default '' | Login username |
| fullname | varchar(45) | not null, default '' | Full name |
| password | varchar(64) | not null | Password hash |
| phone | varchar(32) | not null, default '' | Phone |
| email | varchar(128) | not null, default '' | Email |
| city | varchar(64) | not null, default '' | City |
| subdistrict | varchar(64) | not null, default '' | Subdistrict |
| ward | varchar(64) | not null, default '' | Ward |
| user_type | enum('SuperAdmin','Admin','Report','Agent','Sales') | not null | Role |
| status | enum('Active','Inactive') | not null, default 'Active' | Status |
| data | text | nullable | Extra JSON/serialized data |
| last_login | datetime | nullable | Last login |
| login_token | varchar(40) | nullable | Login token |
| creationdate | datetime | not null | Creation date |

## System / logging / configuration

### `tbl_appconfig`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Row ID |
| setting | mediumtext | not null | Setting key |
| value | mediumtext | nullable | Setting value |

### `tbl_logs`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Log ID |
| date | datetime | nullable | Log date |
| type | varchar(50) | not null | Log type |
| description | mediumtext | not null | Description |
| userid | int(11) | not null | Related admin/user ID |
| ip | mediumtext | not null | IP address |

### `tbl_message_logs`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | bigint(20) UNSIGNED | PK, auto increment | Message log ID |
| message_type | varchar(50) | nullable | Type (SMS, email, etc.) |
| recipient | varchar(255) | nullable | Recipient address |
| message_content | text | nullable | Content |
| status | varchar(50) | nullable | Status (sent, failed, etc.) |
| error_message | text | nullable | Error details |
| sent_at | timestamp | nullable, default CURRENT_TIMESTAMP | Send time |

### `tbl_meta`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(10) UNSIGNED | PK, auto increment | Meta row ID |
| tbl | varchar(32) | not null | Target table name |
| tbl_id | int(11) | not null | Target row ID |
| name | varchar(32) | not null | Meta key |
| value | mediumtext | nullable | Meta value |

### `tbl_widgets`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Widget ID |
| orders | int(11) | not null, default 99 | Sort order |
| position | tinyint(1) | not null, default 1 | 1 top, 2 left, 3 right, 4 bottom |
| user | enum('Admin','Agent','Sales','Customer') | not null, default 'Admin' | Which user type sees it |
| enabled | tinyint(1) | not null, default 1 | 0 = hidden |
| title | varchar(64) | not null | Widget title |
| widget | varchar(64) | not null, default '' | Widget identifier |
| content | text | not null | Widget content/config |

### `tbl_coupons`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | Coupon ID |
| code | varchar(50) | not null, unique | Coupon code |
| type | enum('fixed','percent') | not null | Discount type |
| value | decimal(10,2) | not null | Discount value |
| description | text | not null | Description |
| max_usage | int(11) | not null, default 1 | Max global uses |
| usage_count | int(11) | not null, default 0 | Used count |
| status | enum('active','inactive') | not null | Status |
| min_order_amount | decimal(10,2) | not null | Min order total |
| max_discount_amount | decimal(10,2) | not null | Max discount amount |
| start_date | date | not null | Valid from |
| end_date | date | not null | Valid until |
| created_at | timestamp | nullable, default CURRENT_TIMESTAMP | Created time |
| updated_at | timestamp | nullable, auto-update CURRENT_TIMESTAMP | Updated time |

### `tbl_odps`

| Column | Type | Constraints | Description |
| :-- | :-- | :-- | :-- |
| id | int(11) | PK, auto increment | ODP ID |
| name | varchar(32) | not null | ODP name |
| port_amount | int(11) | not null | Port count |
| attenuation | decimal(15,2) | not null, default 0.00 | Optical attenuation |
| address | mediumtext | not null | Address |
| coordinates | varchar(50) | not null | GPS coordinates |
| coverage | int(11) | not null, default 0 | Coverage metric |


***



<div align="center">???</div>





