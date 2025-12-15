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
}