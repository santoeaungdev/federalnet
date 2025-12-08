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
