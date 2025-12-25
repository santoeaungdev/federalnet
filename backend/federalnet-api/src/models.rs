use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use bigdecimal::BigDecimal;

#[derive(sqlx::FromRow, serde::Serialize)]
pub struct Customer {
    pub id: i32,
    pub username: String,
    pub password: String, // existing tbl_customers.password
    pub fullname: String,
    pub balance: BigDecimal,
    pub status: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CustomerLoginRequest {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CustomerLoginResponse {
    pub token: String,
    pub customer: CustomerPublic,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CustomerPublic {
    pub id: i32,
    pub username: String,
    pub fullname: String,
    pub balance: BigDecimal,
}

impl From<Customer> for CustomerPublic {
    fn from(c: Customer) -> Self {
        Self {
            id: c.id,
            username: c.username,
            fullname: c.fullname,
            balance: c.balance,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CustomerClaims {
    pub sub: i32,
    pub role: String,
    pub exp: i64,
}

// models.rs
#[derive(sqlx::FromRow, serde::Serialize)]
pub struct AdminUser {
    pub id: u32,
    pub username: String,
    pub password: String,     // hashed later
    pub fullname: String,
    pub user_type: String,    // SuperAdmin/Admin/...
    pub status: String,       // Active/Inactive
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct AdminLoginRequest {
    pub username: String,
    pub password: String,
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct AdminLoginResponse {
    pub token: String,
    pub admin: AdminPublic,
}

#[derive(Debug, serde::Serialize, serde::Deserialize, Clone)]
pub struct AdminPublic {
    pub id: u32,
    pub username: String,
    pub fullname: String,
    pub user_type: String,
}

impl From<AdminUser> for AdminPublic {
    fn from(a: AdminUser) -> Self {
        Self {
            id: a.id,
            username: a.username,
            fullname: a.fullname,
            user_type: a.user_type,
        }
    }
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct AdminClaims {
    pub sub: u32,
    pub role: String,  // "admin"
    pub exp: i64,
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct AssignPlanRequest {
    pub pppoe_username: String,
    pub router_tag: String,        // target radgroup name
}

#[derive(Debug, sqlx::FromRow, serde::Serialize, serde::Deserialize)]
pub struct AdminCustomerListItem {
    pub id: i32,
    pub username: String,
    pub fullname: String,
    pub pppoe_username: String,
    pub groupname: Option<String>,
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct CustomerRegisterRequest {
    pub username: String,
    pub password: String,
    pub fullname: String,
    pub nrc_no: String,
    pub phonenumber: String,
    pub email: String,
    pub service_type: String,  // e.g. "PPPoE"
    pub pppoe_username: String,
    pub pppoe_password: String,
    pub router_tag: String,    // optional: maps to routers/groupname
    pub internet_plan_id: Option<i32>,  // optional: ID of internet plan to assign
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct CustomerUpdateRequest {
    pub id: i32,
    pub username: String,
    pub password: String,
    pub fullname: String,
    pub nrc_no: String,
    pub phonenumber: String,
    pub email: String,
    pub service_type: String,
    pub pppoe_username: String,
    pub pppoe_password: String,
    pub router_tag: String,
    pub internet_plan_id: Option<i32>,  // optional: ID of internet plan to assign
}

#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct NrcRow {
    pub id: i32,
    pub name_en: String,
    pub name_mm: String,
    pub nrc_code: i32,
}

#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct AdminCustomerDetail {
    pub id: i32,
    pub username: String,
    pub fullname: String,
    pub nrc_no: String,
    pub phonenumber: String,
    pub email: String,
    pub service_type: String,
    pub pppoe_username: String,
    pub pppoe_password: String,
    pub status: String,
    pub groupname: Option<String>,
    #[serde(skip)]
    pub internet_plan_id: Option<i32>,
}

// NAS (Router) model - maps to FreeRADIUS `nas` table
#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct Nas {
    pub id: i32,
    pub owner_id: Option<i32>,
    pub nasname: String,
    pub shortname: Option<String>,
    #[serde(rename = "type")]
    pub nas_type: String,
    pub ports: Option<i32>,
    pub secret: String,
    pub server: Option<String>,
    pub community: Option<String>,
    pub description: String,
    pub routers: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct NasCreateRequest {
    pub owner_id: Option<i32>,
    pub nasname: String,
    pub shortname: Option<String>,
    #[serde(default = "default_nas_type")]
    #[serde(rename = "type")]
    pub nas_type: String,
    pub secret: String,
    pub description: Option<String>,
}

fn default_nas_type() -> String {
    "other".to_string()
}

#[derive(Debug, Serialize, Deserialize)]
pub struct NasUpdateRequest {
    pub id: i32,
    pub owner_id: Option<i32>,
    pub nasname: String,
    pub shortname: Option<String>,
    #[serde(rename = "type")]
    pub nas_type: String,
    pub secret: String,
    pub description: Option<String>,
}

// Owner (business user) models - mapped to `tbl_users` rows with user_type='Owner'
#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct OwnerPublic {
    pub id: u32,
    pub username: String,
    pub fullname: String,
    pub status: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OwnerCreateRequest {
    pub username: String,
    pub password: String,
    pub fullname: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UserCreateRequest {
    pub username: String,
    pub password: String,
    pub fullname: String,
    pub user_type: String, // Admin | Report | Owner | Operator
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OwnerUpdateRequest {
    pub id: u32,
    pub username: String,
    pub password: Option<String>,
    pub fullname: String,
    pub status: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OwnerTopupRequest {
    pub customer_id: i32,
    pub amount: BigDecimal,
    pub note: Option<String>,
    pub idempotency_key: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PurchasePlanRequest {
    pub plan_id: i32,
}

#[allow(dead_code)]
#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct OwnerWallet {
    pub owner_id: i32,
    pub balance: BigDecimal,
}

#[allow(dead_code)]
#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct OwnerWalletTransaction {
    pub id: i64,
    pub owner_id: i32,
    pub customer_id: i32,
    pub amount: BigDecimal,
    pub note: Option<String>,
    pub idempotency_key: Option<String>,
    pub created_at: chrono::NaiveDateTime,
}

#[allow(dead_code)]
#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct OwnerIncome {
    pub id: i64,
    pub owner_id: i32,
    pub customer_id: Option<i32>,
    pub nas_id: Option<i32>,
    pub period: String,
    pub usage_bytes: i64,
    pub revenue: bigdecimal::BigDecimal,
    pub tax: bigdecimal::BigDecimal,
    pub created_at: chrono::NaiveDateTime,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct OwnerIncomeComputeRequest {
    pub period: String, // YYYY-MM
}

// InternetPlan model - maps to `tbl_internet_plans` table
#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct InternetPlan {
    pub id: i32,
    pub name: String,
    pub category: String,
    pub price: BigDecimal,
    pub currency: String,
    pub validity_unit: String,
    pub validity_value: i32,
    pub download_mbps: i32,
    pub upload_mbps: i32,
    pub radius_groupname: String,
    pub status: String,
}

#[allow(dead_code)]
#[derive(Debug, FromRow, Serialize, Deserialize)]
pub struct InternetPlanBilling {
    pub id: i32,
    pub billing_mode: Option<String>,
    pub price_per_unit: Option<BigDecimal>,
    pub billing_unit: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct InternetPlanCreateRequest {
    pub name: String,
    pub category: String,
    pub price: BigDecimal,
    pub currency: Option<String>,
    pub validity_unit: String,
    pub validity_value: i32,
    pub download_mbps: i32,
    pub upload_mbps: i32,
    pub radius_groupname: String,
    pub status: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct InternetPlanUpdateRequest {
    pub id: i32,
    pub name: String,
    pub category: String,
    pub price: BigDecimal,
    pub currency: String,
    pub validity_unit: String,
    pub validity_value: i32,
    pub download_mbps: i32,
    pub upload_mbps: i32,
    pub radius_groupname: String,
    pub status: String,
}