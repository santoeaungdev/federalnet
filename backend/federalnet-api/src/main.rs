mod models;

use actix_cors::Cors;
use actix_web::{middleware::Logger, web, App, HttpRequest, HttpResponse, HttpServer};
use chrono::{Datelike, Duration, Utc};
use bcrypt::{hash, verify, DEFAULT_COST};
use sha1::Sha1;
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use models::{Customer, CustomerClaims, CustomerLoginRequest, CustomerLoginResponse, CustomerPublic, CustomerRegisterRequest,
CustomerUpdateRequest, AdminUser, AdminLoginRequest, AdminLoginResponse, AdminPublic, AdminClaims, AssignPlanRequest, AdminCustomerListItem, AdminCustomerDetail, NrcRow,
Nas, NasCreateRequest, NasUpdateRequest, InternetPlan, InternetPlanCreateRequest, InternetPlanUpdateRequest,
OwnerPublic, OwnerCreateRequest, OwnerUpdateRequest};
use serde::Deserialize;
use bigdecimal::BigDecimal;
use sqlx::{mysql::MySqlPoolOptions, MySqlPool, Row};
use std::env;
use serde_json::json;

// Backend API: FederalNet (overview, workflow & requirements)
//
// Workflow:
//  - The API exposes administrative and customer endpoints under /api.
//  - Admin endpoints (prefix /api/admin) require admin/owner/operator roles and JWT auth.
//  - Customer endpoints (prefix /api/customer or /api/customer/*) require customer JWT auth.
//  - Owner-related features implemented:
//      * owner_wallets and owner_wallet_transactions for owner-funded topups
//      * idempotency support via idempotency_key on owner_wallet_transactions
//      * owner_income table to record computed income per owner per period
//      * owner_gateways mapping and optional nas.owner_id column for owner<->gateway association
//  - Plan billing supports `billing_mode`, `price_per_unit`, and `billing_unit` on `tbl_internet_plans`.
//
// Requirements and operational notes:
//  - Environment: requires `DATABASE_URL` and `JWT_SECRET` environment variables (see /etc/default/federalnet-api in deployment).
//  - Database migrations are provided under docker directory and the consolidated file docs/federalnet.sql.
//  - Backup the database before applying migrations in production.
//  - The service runs as a systemd unit and binds to 0.0.0.0:8080 by default.
//  - Security: JWT signing uses `JWT_SECRET`; rotate and keep secret safe.
//  - Seed/test endpoints are gated by `ENABLE_SEED_ENDPOINTS` env var for dev only.
//
// Implementation comments:
//  - Routing is declared in `main()` using `web::scope("/api")` and handlers implemented in the same crate.
//  - Authentication/authorization uses JWT claims extracted in `extract_claims` helper.
//  - Owner wallet/topup flows expect server-side enforcement of owner id from token claims.
//  - See docker directory for SQL migrations and docs/federalnet.sql for a consolidated view of changes applied in development.

const DEFAULT_NAS_DESCRIPTION: &str = "RADIUS Client";

#[derive(Clone)]
struct AppState {
    db: MySqlPool,
    jwt_secret: String,
}

#[allow(dead_code)]
#[derive(Deserialize)]
struct DbConfig {
    database_url: String,
}

async fn health() -> HttpResponse {
    HttpResponse::Ok().body("OK")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenvy::dotenv().ok();
    env_logger::init();

    log::info!("Starting FederalNet API server...");

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let jwt_secret = env::var("JWT_SECRET").expect("JWT_SECRET must be set");
    let enable_seed = env::var("ENABLE_SEED_ENDPOINTS")
        .map(|v| matches!(v.as_str(), "1" | "true" | "TRUE" | "yes" | "YES"))
        .unwrap_or(false);

    log::info!("Connecting to database...");
    let pool = MySqlPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
        .unwrap_or_else(|e| {
            log::error!("Failed to connect to database: {}", e);
            panic!("Database connection failed. Please check DATABASE_URL and database availability.");
        });

    log::info!("Database connection established successfully");

    let state = AppState {
        db: pool,
        jwt_secret,
    };

    let bind_address = "0.0.0.0:8080";
    log::info!("Server will bind to {}", bind_address);

    HttpServer::new(move || {
        let mut scoped = web::scope("/api")
            .route("/health", web::get().to(health))
            .route("/admin/login", web::post().to(admin_login))
            .route("/customer/login", web::post().to(customer_login))
            .route("/customers/me", web::get().to(customers_me))
            .route("/customer/purchase_plan", web::post().to(customer_purchase_plan))
            .route("/customer/register", web::post().to(customer_register))
            .route("/admin/nrcs", web::get().to(admin_list_nrcs))
            .route("/admin/customer/register", web::post().to(admin_customer_register))
            .route("/admin/customer/update", web::post().to(admin_customer_update))
            .route("/admin/assign_plan", web::post().to(admin_assign_plan))
            .route("/admin/customers", web::get().to(admin_list_customers))
            .route("/admin/customers/{id}", web::get().to(admin_get_customer))
            .route("/admin/nas", web::get().to(admin_list_nas))
            .route("/admin/nas", web::post().to(admin_create_nas))
            .route("/admin/nas/{id}", web::post().to(admin_update_nas))
            .route("/admin/nas/{id}", web::delete().to(admin_delete_nas))
            .route("/admin/owners", web::get().to(admin_list_owners))
            .route("/admin/owners", web::post().to(admin_create_owner))
            .route("/admin/owners/{id}", web::post().to(admin_update_owner))
            .route("/admin/owners/{id}", web::delete().to(admin_delete_owner))
            .route("/admin/operators", web::get().to(admin_list_operators))
            .route("/admin/operators", web::post().to(admin_create_operator))
            .route("/admin/operators/{id}", web::post().to(admin_update_operator))
            .route("/admin/operators/{id}", web::delete().to(admin_delete_operator))
            .route("/admin/users", web::post().to(admin_create_user))
            .route("/admin/owners/{id}/topup_customer", web::post().to(admin_owner_topup_customer))
            .route("/admin/owner_income/compute", web::post().to(admin_compute_owner_income))
            .route("/admin/owner_income", web::get().to(admin_get_owner_income))
            .route("/admin/owner_income/history/{owner_id}", web::get().to(admin_owner_income_history))
            .route("/admin/internet_plans", web::get().to(admin_list_internet_plans))
            .route("/admin/internet_plans", web::post().to(admin_create_internet_plan))
            .route("/admin/internet_plans/{id}", web::post().to(admin_update_internet_plan));
            

        if enable_seed {
            scoped = scoped
                .route("/_seed_test_data", web::post().to(seed_test_data))
                .route("/_seed_more_customers", web::post().to(seed_more_customers));
        }

        App::new()
            .wrap(Logger::default())
            .wrap(Cors::permissive())
            .app_data(web::Data::new(state.clone()))
            .service(scoped)
    })
        .bind(bind_address)?
        .run()
        .await
}

    // POST /api/customer/purchase_plan
    async fn customer_purchase_plan(
        state: web::Data<AppState>,
        req: HttpRequest,
        payload: web::Json<models::PurchasePlanRequest>,
    ) -> actix_web::Result<HttpResponse> {
        let claims = extract_claims(&req, &state.jwt_secret)?;
        let customer_id = claims.sub;
        let data = payload.into_inner();

        // load plan price
        let plan_price: Option<String> = sqlx::query_scalar("SELECT price FROM tbl_internet_plans WHERE id = ? AND status = 'Active' LIMIT 1")
            .bind(data.plan_id)
            .fetch_optional(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;

        let price = match plan_price {
            Some(p) => p.parse::<f64>().unwrap_or(0.0),
            None => return Ok(HttpResponse::BadRequest().json(json!({"error": "plan_not_found"}))),
        };

        let mut tx = state.db.begin().await.map_err(actix_web::error::ErrorInternalServerError)?;

        // check customer balance
        let bal: f64 = sqlx::query_scalar::<_, String>("SELECT CAST(balance AS CHAR) FROM tbl_customers WHERE id = ? LIMIT 1")
            .bind(customer_id)
            .fetch_one(&mut *tx)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?
            .parse()
            .unwrap_or(0.0);

        if bal < price {
            return Ok(HttpResponse::BadRequest().json(json!({"error": "insufficient_balance"}))); 
        }

        // deduct customer balance
        sqlx::query("UPDATE tbl_customers SET balance = balance - ? WHERE id = ?")
            .bind(price)
            .bind(customer_id)
            .execute(&mut *tx)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;

        // map plan to radgroup and insert radusergroup mapping
        let groupname: Option<String> = sqlx::query_scalar("SELECT radius_groupname FROM tbl_internet_plans WHERE id = ? LIMIT 1")
            .bind(data.plan_id)
            .fetch_optional(&mut *tx)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;

        if let Some(g) = groupname {
            // delete existing mapping and insert new
            let pppoe_username: String = sqlx::query_scalar("SELECT pppoe_username FROM tbl_customers WHERE id = ? LIMIT 1")
                .bind(customer_id)
                .fetch_one(&mut *tx)
                .await
                .map_err(actix_web::error::ErrorInternalServerError)?;

            sqlx::query("DELETE FROM radusergroup WHERE username = ?")
                .bind(&pppoe_username)
                .execute(&mut *tx)
                .await
                .map_err(actix_web::error::ErrorInternalServerError)?;

            sqlx::query("INSERT INTO radusergroup (username, groupname, priority) VALUES (?, ?, 1)")
                .bind(&pppoe_username)
                .bind(&g)
                .execute(&mut *tx)
                .await
                .map_err(actix_web::error::ErrorInternalServerError)?;
        }

        // record transaction
        sqlx::query("INSERT INTO tbl_transactions (invoice, username, user_id, plan_name, price, recharged_on, recharged_time, expiration, time, method, routers, type, note, admin_id) VALUES (?, ?, ?, ?, ?, CURDATE(), CURTIME(), CURDATE(), '00:00:00', ?, '', ?, ?, 0)")
            .bind(format!("PUR-{}-{}", customer_id, data.plan_id))
            .bind("")
            .bind(customer_id)
            .bind("purchase_plan")
            .bind(price.to_string())
            .bind("wallet")
            .bind("")
            .bind("")
            .execute(&mut *tx)
            .await
            .ok();

        tx.commit().await.map_err(actix_web::error::ErrorInternalServerError)?;

        Ok(HttpResponse::Ok().json(json!({"customer_id": customer_id, "plan_id": data.plan_id, "price": price})))
    }


async fn admin_login(
    state: web::Data<AppState>,
    payload: web::Json<AdminLoginRequest>,
) -> actix_web::Result<HttpResponse> {
    let login = payload.into_inner();

    log::info!("Admin login attempt for username: {}", login.username);

    let admin = sqlx::query_as::<_, AdminUser>(
        r#"
        SELECT id, username, password, fullname, user_type, status
        FROM tbl_users
        WHERE username = ? LIMIT 1
        "#
    )
    .bind(&login.username)
    .fetch_optional(&state.db)
    .await
    .map_err(|e| {
        log::error!("Database error during admin login: {}", e);
        actix_web::error::ErrorInternalServerError(e)
    })?;

    let admin = match admin {
        Some(a) => a,
        None => {
            log::warn!("Admin login failed - invalid username: {}", login.username);
            return Ok(HttpResponse::Unauthorized().json(json!({"error": "invalid_credentials"})));
        }
    };

    if admin.status != "Active" {
        log::warn!("Admin login failed - inactive account: {}", login.username);
        return Ok(HttpResponse::Unauthorized().json(json!({"error": "inactive_admin"})));
    }

    // verify admin password with support for bcrypt, legacy SHA1, or plaintext
    let stored = admin.password.clone();
    let ok = if stored.starts_with("$2") {
        verify(&login.password, &stored).map_err(|e| {
            log::error!("Bcrypt verification error: {}", e);
            actix_web::error::ErrorInternalServerError(e)
        })?
    } else if stored.len() == 40 {
        // legacy SHA1 hex
        let bytes = Sha1::from(login.password.as_str()).digest().bytes();
        let hex = hex::encode(bytes);
        hex == stored
    } else {
        // fallback plaintext compare
        stored == login.password
    };

    if !ok {
        log::warn!("Admin login failed - invalid password: {}", login.username);
        return Ok(HttpResponse::Unauthorized().json(json!({"error": "invalid_credentials"})));
    }

    log::info!("Admin login successful: {} (role: {})", login.username, admin.user_type);

    let expiration = Utc::now() + Duration::minutes(60);
    let role = if admin.user_type.to_lowercase() == "owner" { "owner" } else { "admin" };
    let claims = AdminClaims {
        sub: admin.id,
        role: role.to_string(),
        exp: expiration.timestamp(),
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(state.jwt_secret.as_bytes()),
    )
    .map_err(|e| {
        log::error!("JWT token generation error: {}", e);
        actix_web::error::ErrorInternalServerError(e)
    })?;

    let public: AdminPublic = admin.into();
    let resp = AdminLoginResponse { token, admin: public };

    Ok(HttpResponse::Ok().json(resp))
}

// POST /api/customer/login
async fn customer_login(
    state: web::Data<AppState>,
    payload: web::Json<CustomerLoginRequest>,
) -> actix_web::Result<HttpResponse> {
    let login = payload.into_inner();

    log::info!("Customer login attempt for username: {}", login.username);

    let customer = sqlx::query_as::<_, Customer>(
        r#"
        SELECT id, username, password, fullname, balance, status
        FROM tbl_customers
        WHERE username = ? LIMIT 1
        "#,
    )
        .bind(&login.username)
        .fetch_optional(&state.db)
        .await
        .map_err(|e| {
            log::error!("Database error during customer login: {}", e);
            actix_web::error::ErrorInternalServerError(e)
        })?;

    let customer = match customer {
        Some(c) => c,
        None => {
            log::warn!("Customer login failed - invalid username: {}", login.username);
            return Ok(
                HttpResponse::Unauthorized().json(json!({"error": "invalid_credentials"}))
            );
        }
    };

    if customer.status != "Active" {
        log::warn!("Customer login failed - inactive account: {}", login.username);
        return Ok(
            HttpResponse::Unauthorized().json(json!({"error": "inactive_customer"}))
        );
    }

    // verify customer password with bcrypt, legacy SHA1, or plaintext
    let stored = customer.password.clone();
    let ok = if stored.starts_with("$2") {
        verify(&login.password, &stored).map_err(|e| {
            log::error!("Bcrypt verification error: {}", e);
            actix_web::error::ErrorInternalServerError(e)
        })?
    } else if stored.len() == 40 {
        let bytes = Sha1::from(login.password.as_str()).digest().bytes();
        let hex = hex::encode(bytes);
        hex == stored
    } else {
        stored == login.password
    };

    if !ok {
        log::warn!("Customer login failed - invalid password: {}", login.username);
        return Ok(
            HttpResponse::Unauthorized().json(json!({"error": "invalid_credentials"}))
        );
    }

    log::info!("Customer login successful: {}", login.username);

    let expiration = Utc::now() + Duration::minutes(60);
    let claims = CustomerClaims {
        sub: customer.id,
        role: "customer".to_string(),
        exp: expiration.timestamp(),
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(state.jwt_secret.as_bytes()),
    )
        .map_err(actix_web::error::ErrorInternalServerError)?;

    let public: CustomerPublic = customer.into();

    let resp = CustomerLoginResponse { token, customer: public };
    Ok(HttpResponse::Ok().json(resp))
}

// helper: get claims from Authorization header
fn extract_claims(req: &HttpRequest, secret: &str) -> Result<CustomerClaims, actix_web::Error> {
    let header = req
        .headers()
        .get("Authorization")
        .ok_or_else(|| actix_web::error::ErrorUnauthorized("missing_token"))?
        .to_str()
        .map_err(|_| actix_web::error::ErrorUnauthorized("bad_header"))?;

    if !header.starts_with("Bearer ") {
        return Err(actix_web::error::ErrorUnauthorized("bad_header"));
    }
    let token = &header[7..];

    let data = decode::<CustomerClaims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::new(Algorithm::HS256),
    )
        .map_err(|_| actix_web::error::ErrorUnauthorized("invalid_token"))?;

    Ok(data.claims)
}

// GET /api/customers/me
async fn customers_me(
    state: web::Data<AppState>,
    req: HttpRequest,
) -> actix_web::Result<HttpResponse> {
    let claims = extract_claims(&req, &state.jwt_secret)?;

    let customer = sqlx::query_as::<_, Customer>(
        r#"
        SELECT id, username, password, fullname, balance, status
        FROM tbl_customers
        WHERE id = ? LIMIT 1
        "#,
    )
        .bind(claims.sub)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    let public: CustomerPublic = customer.into();
    Ok(HttpResponse::Ok().json(public))
}

async fn customer_register(
    state: web::Data<AppState>,
    payload: web::Json<CustomerRegisterRequest>,
) -> actix_web::Result<HttpResponse> {
    let data = payload.into_inner();

    // validate NRC code using imported nrcs table
    if !nrc_code_exists(&state.db, &data.nrc_no).await? {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "invalid_nrc"}))); 
    }

    let mut tx = state.db.begin()
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    // Insert into tbl_customers
    sqlx::query(
        r#"
        INSERT INTO tbl_customers
            (username, password, fullname, nrc_no, phonenumber, email,
             pppoe_username, pppoe_password, service_type, status, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Active', 0)
        "#
    )
    .bind(&data.username)
    // hash user password before storing
    .bind(&hash(&data.password, DEFAULT_COST).map_err(actix_web::error::ErrorInternalServerError)?)
    .bind(&data.fullname)
    .bind(&data.nrc_no)
    .bind(&data.phonenumber)
    .bind(&data.email)
    .bind(&data.pppoe_username)
    .bind(&data.pppoe_password)
    .bind(&data.service_type)
    .execute(&mut *tx)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    // get last insert id
    let customer_id: i64 = sqlx::query_scalar("SELECT CAST(LAST_INSERT_ID() AS SIGNED)")
        .fetch_one(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    // Insert into radcheck: username + Cleartext-Password
    sqlx::query(
        r#"
        INSERT INTO radcheck (username, attribute, op, value)
        VALUES (?, 'Cleartext-Password', ':=', ?)
        "#
    )
    .bind(&data.pppoe_username)
    .bind(&data.pppoe_password)
    .execute(&mut *tx)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    // Optionally add group mapping for plan
    if !data.router_tag.trim().is_empty() {
        sqlx::query(
            r#"INSERT INTO radusergroup (username, groupname, priority) VALUES (?, ?, 1)"#
        )
        .bind(&data.pppoe_username)
        .bind(&data.router_tag)
        .execute(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    }

    tx.commit()
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Created().json(json!({
        "id": customer_id,
        "username": data.username,
        "pppoe_username": data.pppoe_username
    })))
}

// Temporary: seed test admin and customer rows for local testing
async fn seed_test_data(state: web::Data<AppState>) -> actix_web::Result<HttpResponse> {
    // add admin 'testadmin' with plaintext password 'adminpass' if not exists
    let admin_exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_users WHERE username = ?")
        .bind("testadmin")
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    if admin_exists == 0 {
        sqlx::query("INSERT INTO tbl_users (username, fullname, password, user_type, status, creationdate) VALUES (?, ?, ?, ?, ?, NOW())")
            .bind("testadmin")
            .bind("Test Admin")
            .bind("adminpass")
            .bind("Admin")
            .bind("Active")
            .execute(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;
    }

    // add customer 'testuser2' with plaintext password 'custpass' if not exists
    let cust_exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_customers WHERE username = ?")
        .bind("testuser2")
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    if cust_exists == 0 {
        sqlx::query("INSERT INTO tbl_customers (username, password, fullname, email, service_type, status, created_by) VALUES (?, ?, ?, ?, 'PPPoE', 'Active', 0)")
            .bind("testuser2")
            .bind("custpass")
            .bind("Test Customer")
            .bind("testcustomer@example.com")
            .execute(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;
    }

    Ok(HttpResponse::Ok().json(json!({"result": "ok"})))
}

// extract admin claims (for admin-only endpoints)
fn extract_admin_claims(req: &HttpRequest, secret: &str) -> Result<models::AdminClaims, actix_web::Error> {
    let header = req
        .headers()
        .get("Authorization")
        .ok_or_else(|| actix_web::error::ErrorUnauthorized("missing_token"))?
        .to_str()
        .map_err(|_| actix_web::error::ErrorUnauthorized("bad_header"))?;

    if !header.starts_with("Bearer ") {
        return Err(actix_web::error::ErrorUnauthorized("bad_header"));
    }
    let token = &header[7..];

    let data = decode::<models::AdminClaims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::new(Algorithm::HS256),
    )
    .map_err(|_| actix_web::error::ErrorUnauthorized("invalid_token"))?;

    // enforce admin or operator role
    let role = data.claims.role.to_lowercase();
    if !(role == "admin" || role == "operator") {
        return Err(actix_web::error::ErrorUnauthorized("admin_or_operator_only"));
    }

    Ok(data.claims)
}

// extract generic admin/user claims without role enforcement
fn extract_user_claims(req: &HttpRequest, secret: &str) -> Result<models::AdminClaims, actix_web::Error> {
    let header = req
        .headers()
        .get("Authorization")
        .ok_or_else(|| actix_web::error::ErrorUnauthorized("missing_token"))?
        .to_str()
        .map_err(|_| actix_web::error::ErrorUnauthorized("bad_header"))?;

    if !header.starts_with("Bearer ") {
        return Err(actix_web::error::ErrorUnauthorized("bad_header"));
    }
    let token = &header[7..];

    let data = decode::<models::AdminClaims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::new(Algorithm::HS256),
    )
    .map_err(|_| actix_web::error::ErrorUnauthorized("invalid_token"))?;

    Ok(data.claims)
}

// extract owner claims specifically
#[allow(dead_code)]
fn extract_owner_claims(req: &HttpRequest, secret: &str) -> Result<models::AdminClaims, actix_web::Error> {
    let claims = extract_user_claims(req, secret)?;
    if claims.role.to_lowercase() != "owner" {
        return Err(actix_web::error::ErrorUnauthorized("owner_only"));
    }
    Ok(claims)
}

// extract admin-only claims (reject operator/owner)
fn extract_admin_only_claims(req: &HttpRequest, secret: &str) -> Result<models::AdminClaims, actix_web::Error> {
    let claims = extract_user_claims(req, secret)?;
    let role = claims.role.to_lowercase();
    if !(role == "admin" || role == "superadmin") {
        return Err(actix_web::error::ErrorUnauthorized("admin_or_superadmin_only"));
    }
    Ok(claims)
}

// Admin-only: fetch NRC township codes from `nrcs` table for dropdowns.
async fn admin_list_nrcs(
    state: web::Data<AppState>,
    req: HttpRequest,
) -> actix_web::Result<HttpResponse> {
    // allow admin/operator/owner to list customers
    let claims = extract_user_claims(&req, &state.jwt_secret)?;
    let role = claims.role.to_lowercase();
    if !(role == "admin" || role == "operator" || role == "owner") {
        return Err(actix_web::error::ErrorUnauthorized("admin_operator_or_owner_only"));
    }

    let rows = sqlx::query_as::<_, NrcRow>(
        "SELECT id, name_en, name_mm, nrc_code FROM nrcs ORDER BY nrc_code, name_en",
    )
    .fetch_all(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(rows))
}

// Admin-only: create a customer (called from admin app). Validates NRC presence and inserts into radcheck.
async fn admin_customer_register(
    state: web::Data<AppState>,
    req: HttpRequest,
    payload: web::Json<CustomerRegisterRequest>,
) -> actix_web::Result<HttpResponse> {
    // allow admin/operator/owner to create customers
    let claims = extract_user_claims(&req, &state.jwt_secret)?;
    let role = claims.role.to_lowercase();
    if !(role == "admin" || role == "operator" || role == "owner") {
        return Err(actix_web::error::ErrorUnauthorized("admin_operator_or_owner_only"));
    }

    let data = payload.into_inner();

    // validate NRC code using imported nrcs table
    if !nrc_code_exists(&state.db, &data.nrc_no).await? {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "invalid_nrc"}))); 
    }

    // ensure unique username and pppoe_username
    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_customers WHERE username = ?")
        .bind(&data.username)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if exists > 0 {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "username_exists"}))); 
    }

    let pexist: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_customers WHERE pppoe_username = ?")
        .bind(&data.pppoe_username)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if pexist > 0 {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "pppoe_username_exists"}))); 
    }

    let mut tx = state.db.begin()
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    sqlx::query(
        r#"
        INSERT INTO tbl_customers
            (username, password, fullname, nrc_no, phonenumber, email,
             pppoe_username, pppoe_password, service_type, status, created_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Active', ?)
        "#
    )
    .bind(&data.username)
    .bind(&hash(&data.password, DEFAULT_COST).map_err(actix_web::error::ErrorInternalServerError)?)
    .bind(&data.fullname)
    .bind(&data.nrc_no)
    .bind(&data.phonenumber)
    .bind(&data.email)
    .bind(&data.pppoe_username)
    .bind(&data.pppoe_password)
    .bind(&data.service_type)
            .bind(claims.sub as i64)
    .execute(&mut *tx)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    let customer_id: i64 = sqlx::query_scalar("SELECT CAST(LAST_INSERT_ID() AS SIGNED)")
        .fetch_one(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    sqlx::query(
        r#"
        INSERT INTO radcheck (username, attribute, op, value)
        VALUES (?, 'Cleartext-Password', ':=', ?)
        "#
    )
    .bind(&data.pppoe_username)
    .bind(&data.pppoe_password)
    .execute(&mut *tx)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    // Add group mapping based on internet_plan_id or router_tag
    let groupname = if let Some(plan_id) = data.internet_plan_id {
        // Fetch radius_groupname from internet plan
        let plan_group: Option<String> = sqlx::query_scalar(
            "SELECT radius_groupname FROM tbl_internet_plans WHERE id = ? AND status = 'Active' LIMIT 1"
        )
        .bind(plan_id)
        .fetch_optional(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
        
        plan_group
    } else if !data.router_tag.trim().is_empty() {
        Some(data.router_tag.clone())
    } else {
        None
    };

    if let Some(group) = groupname {
        sqlx::query(
            r#"INSERT INTO radusergroup (username, groupname, priority) VALUES (?, ?, 1)"#
        )
        .bind(&data.pppoe_username)
        .bind(&group)
        .execute(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    }

    tx.commit()
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Created().json(json!({
        "id": customer_id,
        "username": data.username,
        "pppoe_username": data.pppoe_username
    })))
}

// check whether the leading NRC code exists in `nrcs` table
async fn nrc_code_exists(pool: &MySqlPool, nrc_no: &str) -> Result<bool, actix_web::Error> {
    let code_part = nrc_no.split('/').next().unwrap_or("").trim();
    if code_part.is_empty() { return Ok(false); }
    // try parse leading digits
    let digits: String = code_part.chars().take_while(|c| c.is_ascii_digit()).collect();
    if digits.is_empty() { return Ok(false); }
    let code: i64 = digits.parse().map_err(|_| actix_web::error::ErrorBadRequest("invalid_nrc"))?;
    let cnt: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM nrcs WHERE nrc_code = ?")
        .bind(code)
        .fetch_one(pool)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    Ok(cnt > 0)
}

// Seed multiple test customers for QA
async fn seed_more_customers(state: web::Data<AppState>) -> actix_web::Result<HttpResponse> {
    let customers = vec![
        ("cust02","CustPass#2024","Customer Two","22/ABCD(N)654321","0911111111","cust02@example.com","pppoe-cust02","pppoePass#2024","DEFAULT"),
        ("cust03","CustPass#2024","Customer Three","31/EFGH(N)987654","0922222222","cust03@example.com","pppoe-cust03","pppoePass#2024","DEFAULT"),
    ];

    for (username, pass, fullname, nrc_no, phone, email, pppoe_u, pppoe_p, group) in customers {
        let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_customers WHERE username = ?")
            .bind(username)
            .fetch_one(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;
        if exists > 0 { continue; }

        let mut tx = state.db.begin().await.map_err(actix_web::error::ErrorInternalServerError)?;
        sqlx::query(
            r#"INSERT INTO tbl_customers (username, password, fullname, nrc_no, phonenumber, email, pppoe_username, pppoe_password, service_type, status, created_by)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PPPoE', 'Active', 0)"#
        )
        .bind(username)
        .bind(&hash(pass, DEFAULT_COST).map_err(actix_web::error::ErrorInternalServerError)?)
        .bind(fullname)
        .bind(nrc_no)
        .bind(phone)
        .bind(email)
        .bind(pppoe_u)
        .bind(pppoe_p)
        .execute(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

        sqlx::query("INSERT INTO radcheck (username, attribute, op, value) VALUES (?, 'Cleartext-Password', ':=', ?)")
            .bind(pppoe_u)
            .bind(pppoe_p)
            .execute(&mut *tx)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;

        if !group.is_empty() {
            sqlx::query("INSERT INTO radusergroup (username, groupname, priority) VALUES (?, ?, 1)")
                .bind(pppoe_u)
                .bind(group)
                .execute(&mut *tx)
                .await
                .map_err(actix_web::error::ErrorInternalServerError)?;
        }

        tx.commit().await.map_err(actix_web::error::ErrorInternalServerError)?;
    }

    Ok(HttpResponse::Ok().json(json!({"seeded": true})))
}

// Admin-only: assign a plan by mapping PPPoE username to a radgroup
async fn admin_assign_plan(
    state: web::Data<AppState>,
    req: HttpRequest,
    payload: web::Json<AssignPlanRequest>,
) -> actix_web::Result<HttpResponse> {
    // allow admin/operator/owner to update customers
    let claims = extract_user_claims(&req, &state.jwt_secret)?;
    let role = claims.role.to_lowercase();
    if !(role == "admin" || role == "operator" || role == "owner") {
        return Err(actix_web::error::ErrorUnauthorized("admin_operator_or_owner_only"));
    }
    let data = payload.into_inner();

    let rcnt: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM radcheck WHERE username = ?")
        .bind(&data.pppoe_username)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if rcnt == 0 {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "pppoe_not_found"})));
    }

    sqlx::query("DELETE FROM radusergroup WHERE username = ?")
        .bind(&data.pppoe_username)
        .execute(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    sqlx::query("INSERT INTO radusergroup (username, groupname, priority) VALUES (?, ?, 1)")
        .bind(&data.pppoe_username)
        .bind(&data.router_tag)
        .execute(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(json!({"username": data.pppoe_username, "group": data.router_tag})))
}

// Admin-only: list customers with current radusergroup mapping
async fn admin_list_customers(
    state: web::Data<AppState>,
    req: HttpRequest,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_only_claims(&req, &state.jwt_secret)?;

    let rows = sqlx::query_as::<_, AdminCustomerListItem>(
        r#"
        SELECT c.id, c.username, c.fullname, c.pppoe_username,
               (SELECT groupname FROM radusergroup rug WHERE rug.username = c.pppoe_username ORDER BY priority ASC LIMIT 1) AS groupname
        FROM tbl_customers c
        ORDER BY c.id ASC
        "#
    )
    .fetch_all(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(rows))
}

// Admin-only: fetch a single customer with PPPoE and NRC details
async fn admin_get_customer(
    state: web::Data<AppState>,
    req: HttpRequest,
    path: web::Path<(i32,)>,
) -> actix_web::Result<HttpResponse> {
    // allow admin/operator/owner to fetch customer details
    let claims = extract_user_claims(&req, &state.jwt_secret)?;
    let role = claims.role.to_lowercase();
    if !(role == "admin" || role == "operator" || role == "owner") {
        return Err(actix_web::error::ErrorUnauthorized("admin_operator_or_owner_only"));
    }
    let customer_id = path.into_inner().0;

    let row = sqlx::query_as::<_, AdminCustomerDetail>(
        r#"
        SELECT c.id, c.username, c.fullname, c.nrc_no, c.phonenumber, c.email,
               c.service_type, c.pppoe_username, c.pppoe_password, c.status,
               (SELECT groupname FROM radusergroup rug WHERE rug.username = c.pppoe_username ORDER BY priority ASC LIMIT 1) AS groupname,
               NULL as internet_plan_id
        FROM tbl_customers c
        WHERE c.id = ? LIMIT 1
        "#
    )
    .bind(customer_id)
    .fetch_optional(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    let mut detail = match row {
        Some(r) => r,
        None => return Ok(HttpResponse::NotFound().json(json!({"error": "not_found"}))),
    };

    // Fetch internet_plan_id based on groupname
    if let Some(ref groupname) = detail.groupname {
        detail.internet_plan_id = sqlx::query_scalar(
            "SELECT id FROM tbl_internet_plans WHERE radius_groupname = ? LIMIT 1"
        )
        .bind(groupname)
        .fetch_optional(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    }

    Ok(HttpResponse::Ok().json(json!({
        "id": detail.id,
        "username": detail.username,
        "fullname": detail.fullname,
        "nrc_no": detail.nrc_no,
        "phonenumber": detail.phonenumber,
        "email": detail.email,
        "service_type": detail.service_type,
        "pppoe_username": detail.pppoe_username,
        "pppoe_password": detail.pppoe_password,
        "status": detail.status,
        "groupname": detail.groupname,
        "internet_plan_id": detail.internet_plan_id
    })))
}

// Admin-only: update a customer and related PPPoE credentials
async fn admin_customer_update(
    state: web::Data<AppState>,
    req: HttpRequest,
    payload: web::Json<CustomerUpdateRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_only_claims(&req, &state.jwt_secret)?;
    let data = payload.into_inner();

    // validate NRC code exists
    if !nrc_code_exists(&state.db, &data.nrc_no).await? {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "invalid_nrc"})));
    }

    // fetch current customer
    let current = sqlx::query_as::<_, AdminCustomerDetail>(
        r#"
        SELECT c.id, c.username, c.fullname, c.nrc_no, c.phonenumber, c.email,
               c.service_type, c.pppoe_username, c.pppoe_password, c.status,
               (SELECT groupname FROM radusergroup rug WHERE rug.username = c.pppoe_username ORDER BY priority ASC LIMIT 1) AS groupname
        FROM tbl_customers c
        WHERE c.id = ? LIMIT 1
        "#
    )
    .bind(data.id)
    .fetch_optional(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    let current = match current {
        Some(c) => c,
        None => return Ok(HttpResponse::NotFound().json(json!({"error": "not_found"}))),
    };

    // ensure unique username and pppoe_username (excluding current)
    let uname_exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_customers WHERE username = ? AND id <> ?")
        .bind(&data.username)
        .bind(data.id)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if uname_exists > 0 {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "username_exists"})));
    }

    let pppoe_exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_customers WHERE pppoe_username = ? AND id <> ?")
        .bind(&data.pppoe_username)
        .bind(data.id)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if pppoe_exists > 0 {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "pppoe_username_exists"})));
    }

    let mut tx = state.db.begin()
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    // update main customer row
    sqlx::query(
        r#"
        UPDATE tbl_customers
        SET username = ?, password = ?, fullname = ?, nrc_no = ?, phonenumber = ?, email = ?,
            pppoe_username = ?, pppoe_password = ?, service_type = ?
        WHERE id = ?
        "#
    )
    .bind(&data.username)
    .bind(&hash(&data.password, DEFAULT_COST).map_err(actix_web::error::ErrorInternalServerError)? )
    .bind(&data.fullname)
    .bind(&data.nrc_no)
    .bind(&data.phonenumber)
    .bind(&data.email)
    .bind(&data.pppoe_username)
    .bind(&data.pppoe_password)
    .bind(&data.service_type)
    .bind(data.id)
    .execute(&mut *tx)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    // update radcheck password, handling username changes
    sqlx::query("DELETE FROM radcheck WHERE username IN (?, ?)")
        .bind(&current.pppoe_username)
        .bind(&data.pppoe_username)
        .execute(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    sqlx::query("INSERT INTO radcheck (username, attribute, op, value) VALUES (?, 'Cleartext-Password', ':=', ?)")
        .bind(&data.pppoe_username)
        .bind(&data.pppoe_password)
        .execute(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    // update radusergroup mapping based on internet_plan_id or router_tag
    sqlx::query("DELETE FROM radusergroup WHERE username IN (?, ?)")
        .bind(&current.pppoe_username)
        .bind(&data.pppoe_username)
        .execute(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    let groupname = if let Some(plan_id) = data.internet_plan_id {
        // Fetch radius_groupname from internet plan
        let plan_group: Option<String> = sqlx::query_scalar(
            "SELECT radius_groupname FROM tbl_internet_plans WHERE id = ? AND status = 'Active' LIMIT 1"
        )
        .bind(plan_id)
        .fetch_optional(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
        
        plan_group
    } else if !data.router_tag.trim().is_empty() {
        Some(data.router_tag.clone())
    } else {
        None
    };

    if let Some(group) = groupname {
        sqlx::query("INSERT INTO radusergroup (username, groupname, priority) VALUES (?, ?, 1)")
            .bind(&data.pppoe_username)
            .bind(&group)
            .execute(&mut *tx)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;
    }

    tx.commit()
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(json!({
        "id": data.id,
        "username": data.username,
        "pppoe_username": data.pppoe_username
    })))
}

// Admin-only: list NAS entries from FreeRADIUS `nas` table
async fn admin_list_nas(
    state: web::Data<AppState>,
    req: HttpRequest,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_only_claims(&req, &state.jwt_secret)?;

    let rows = sqlx::query_as::<_, Nas>(
        "SELECT id, owner_id, nasname, shortname, `type` as nas_type, ports, secret, server, community, description, routers FROM nas ORDER BY id ASC"
    )
    .fetch_all(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(rows))
}

// Admin-only: create a new NAS entry
async fn admin_create_nas(
    state: web::Data<AppState>,
    req: HttpRequest,
    payload: web::Json<NasCreateRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let data = payload.into_inner();

    // Validate required fields
    if data.nasname.trim().is_empty() || data.secret.trim().is_empty() {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "nasname and secret are required"})));
    }

    let result = sqlx::query(
        r#"
        INSERT INTO nas (owner_id, nasname, shortname, `type`, secret, description, routers)
        VALUES (?, ?, ?, ?, ?, ?, '')
        "#
    )
    .bind(data.owner_id)
    .bind(&data.nasname)
    .bind(&data.shortname)
    .bind(&data.nas_type)
    .bind(&data.secret)
    .bind(data.description.unwrap_or_else(|| "RADIUS Client".to_string()))
    .execute(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    let nas_id = result.last_insert_id();

    Ok(HttpResponse::Created().json(json!({
        "id": nas_id,
        "nasname": data.nasname
    })))
}

// Admin-only: update a NAS entry
async fn admin_update_nas(
    state: web::Data<AppState>,
    req: HttpRequest,
    path: web::Path<(i32,)>,
    payload: web::Json<NasUpdateRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let nas_id = path.into_inner().0;
    let mut data = payload.into_inner();
    data.id = nas_id;

    // Check if NAS exists
    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM nas WHERE id = ?")
        .bind(data.id)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    if exists == 0 {
        return Ok(HttpResponse::NotFound().json(json!({"error": "nas_not_found"})));
    }
    sqlx::query(
        r#"
        UPDATE nas
        SET owner_id = ?, nasname = ?, shortname = ?, `type` = ?, secret = ?, description = ?
        WHERE id = ?
        "#
    )
    .bind(data.owner_id)
    .bind(&data.nasname)
    .bind(&data.shortname)
    .bind(&data.nas_type)
    .bind(&data.secret)
    .bind(data.description.unwrap_or_else(|| DEFAULT_NAS_DESCRIPTION.to_string()))
    .bind(data.id)
    .execute(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(json!({
        "id": data.id,
        "nasname": data.nasname
    })))
}

// Admin-only: delete a NAS entry
async fn admin_delete_nas(
    state: web::Data<AppState>,
    req: HttpRequest,
    path: web::Path<(i32,)>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_only_claims(&req, &state.jwt_secret)?;
    let nas_id = path.into_inner().0;

    // check exists
    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM nas WHERE id = ?")
        .bind(nas_id)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if exists == 0 {
        return Ok(HttpResponse::NotFound().json(json!({"error": "nas_not_found"})));
    }

    // remove any owner_gateways mapping to keep DB consistent (if table exists)
    let _ = sqlx::query("DELETE FROM owner_gateways WHERE nas_id = ?")
        .bind(nas_id)
        .execute(&state.db)
        .await;

    sqlx::query("DELETE FROM nas WHERE id = ?")
        .bind(nas_id)
        .execute(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(json!({"id": nas_id})))
}

// Admin-only: list owners
async fn admin_list_owners(
    state: web::Data<AppState>,
    req: HttpRequest,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;

    let rows = sqlx::query_as::<_, OwnerPublic>(
        "SELECT id, username, fullname, status FROM tbl_users WHERE user_type = 'Owner' ORDER BY id ASC",
    )
    .fetch_all(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(rows))
}

// Admin-only: create owner
async fn admin_create_owner(
    state: web::Data<AppState>,
    req: HttpRequest,
    payload: web::Json<OwnerCreateRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_only_claims(&req, &state.jwt_secret)?;
    let data = payload.into_inner();

    // unique username
    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_users WHERE username = ?")
        .bind(&data.username)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if exists > 0 {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "username_exists"}))); 
    }

    let hashed = hash(&data.password, DEFAULT_COST).map_err(actix_web::error::ErrorInternalServerError)?;

    let result = sqlx::query(
        "INSERT INTO tbl_users (username, fullname, password, user_type, status, creationdate) VALUES (?, ?, ?, 'Owner', 'Active', NOW())",
    )
    .bind(&data.username)
    .bind(&data.fullname)
    .bind(&hashed)
    .execute(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    let id = result.last_insert_id();

    Ok(HttpResponse::Created().json(json!({"id": id, "username": data.username})))
}

// Admin-only: update owner
async fn admin_update_owner(
    state: web::Data<AppState>,
    req: HttpRequest,
    path: web::Path<(i32,)>,
    payload: web::Json<OwnerUpdateRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let owner_id = path.into_inner().0 as u32;
    let mut data = payload.into_inner();
    data.id = owner_id;

    // ensure owner exists and is of type 'Owner'
    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_users WHERE id = ? AND user_type = 'Owner'")
        .bind(data.id)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if exists == 0 {
        return Ok(HttpResponse::NotFound().json(json!({"error": "owner_not_found"}))); 
    }

    // update fields; handle optional password
    if let Some(pw) = data.password {
        let hashed = hash(&pw, DEFAULT_COST).map_err(actix_web::error::ErrorInternalServerError)?;
        sqlx::query("UPDATE tbl_users SET username = ?, fullname = ?, password = ?, status = ? WHERE id = ? AND user_type = 'Owner'")
            .bind(&data.username)
            .bind(&data.fullname)
            .bind(&hashed)
            .bind(data.status.unwrap_or_else(|| "Active".to_string()))
            .bind(data.id)
            .execute(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;
    } else {
        sqlx::query("UPDATE tbl_users SET username = ?, fullname = ?, status = ? WHERE id = ? AND user_type = 'Owner'")
            .bind(&data.username)
            .bind(&data.fullname)
            .bind(data.status.unwrap_or_else(|| "Active".to_string()))
            .bind(data.id)
            .execute(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;
    }

    Ok(HttpResponse::Ok().json(json!({"id": data.id, "username": data.username})))
}

// Admin-only: delete owner
async fn admin_delete_owner(
    state: web::Data<AppState>,
    req: HttpRequest,
    path: web::Path<(i32,)>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_only_claims(&req, &state.jwt_secret)?;
    let owner_id = path.into_inner().0;

    // check exists
    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_users WHERE id = ? AND user_type = 'Owner'")
        .bind(owner_id)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if exists == 0 {
        return Ok(HttpResponse::NotFound().json(json!({"error": "owner_not_found"}))); 
    }

    // remove owner mappings
    let _ = sqlx::query("DELETE FROM owner_gateways WHERE owner_id = ?")
        .bind(owner_id)
        .execute(&state.db)
        .await;

    sqlx::query("DELETE FROM tbl_users WHERE id = ? AND user_type = 'Owner'")
        .bind(owner_id)
        .execute(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(json!({"id": owner_id})))
}

// Admin-only: owner tops up a customer's wallet (records owner wallet transaction)
async fn admin_owner_topup_customer(
    state: web::Data<AppState>,
    req: HttpRequest,
    path: web::Path<(i32,)>,
    payload: web::Json<models::OwnerTopupRequest>,
) -> actix_web::Result<HttpResponse> {
    // allow either admin or owner; owners may only top up for their own owner_id
    let owner_id = path.into_inner().0;
    let claims = extract_user_claims(&req, &state.jwt_secret)?;
    if claims.role.to_lowercase() == "owner" {
        if claims.sub as i32 != owner_id {
            return Err(actix_web::error::ErrorUnauthorized("cannot_topup_other_owner_customers"));
        }
    } else if claims.role.to_lowercase() == "admin" {
        // admin allowed
    } else {
        return Err(actix_web::error::ErrorUnauthorized("admin_or_owner_only"));
    }
    let data = payload.into_inner();

    if data.amount <= BigDecimal::from(0) {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "invalid_amount"}))); 
    }

    // idempotency: if client supplied an idempotency_key and a matching transaction exists, return it
    if let Some(ref key) = data.idempotency_key {
        let existing: Option<(i64, i32, i32, bigdecimal::BigDecimal, Option<String>, chrono::NaiveDateTime)> = sqlx::query_as(
            "SELECT id, owner_id, customer_id, amount, note, created_at FROM owner_wallet_transactions WHERE owner_id = ? AND idempotency_key = ? LIMIT 1"
        )
        .bind(owner_id)
        .bind(key)
        .fetch_optional(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

        if let Some((id, owner_id, customer_id, amount, note, created_at)) = existing {
            return Ok(HttpResponse::Ok().json(json!({
                "id": id,
                "owner_id": owner_id,
                "customer_id": customer_id,
                "amount": amount.to_string(),
                "note": note.unwrap_or_default(),
                "created_at": created_at.to_string(),
                "idempotent": true
            })));
        }
    }

    let mut tx = state.db.begin().await.map_err(actix_web::error::ErrorInternalServerError)?;

    // ensure owner wallet exists
    sqlx::query("INSERT INTO owner_wallets (owner_id, balance) SELECT ?, 0.00 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM owner_wallets WHERE owner_id = ?)")
        .bind(owner_id)
        .bind(owner_id)
        .execute(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    // check owner balance
    let owner_bal: Option<BigDecimal> = sqlx::query_scalar("SELECT balance FROM owner_wallets WHERE owner_id = ?")
        .bind(owner_id)
        .fetch_optional(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    let owner_bal = owner_bal.unwrap_or_else(|| BigDecimal::from(0));
    if owner_bal < data.amount {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "insufficient_owner_balance"})));
    }

    // debit owner wallet
    sqlx::query("UPDATE owner_wallets SET balance = balance - ? WHERE owner_id = ?")
        .bind(data.amount.clone())
        .bind(owner_id)
        .execute(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    // credit customer balance
    sqlx::query("UPDATE tbl_customers SET balance = balance + ? WHERE id = ?")
        .bind(data.amount.clone())
        .bind(data.customer_id)
        .execute(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    // record owner wallet transaction
    sqlx::query("INSERT INTO owner_wallet_transactions (owner_id, customer_id, amount, note, idempotency_key) VALUES (?, ?, ?, ?, ?)")
        .bind(owner_id)
        .bind(data.customer_id)
        .bind(data.amount.clone())
        .bind(data.note.clone())
        .bind(data.idempotency_key.clone())
        .execute(&mut *tx)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    // optional: create tbl_transactions row
    sqlx::query("INSERT INTO tbl_transactions (invoice, username, user_id, plan_name, price, recharged_on, recharged_time, expiration, time, method, routers, type, note, admin_id) VALUES (?, ?, ?, ?, ?, CURDATE(), CURTIME(), CURDATE(), '00:00:00', ?, '', '', ?, 0)")
        .bind(format!("TOPUP-{}-{}", owner_id, data.customer_id))
        .bind("")
        .bind(data.customer_id)
        .bind("owner_topup")
        .bind(data.amount.to_string())
        .bind("owner_topup")
        .bind(data.note.unwrap_or_default())
        .execute(&mut *tx)
        .await
        .ok();

    // audit log entry in tbl_logs
    let desc = format!("Owner {} topped up customer {} amount {}", owner_id, data.customer_id, data.amount);
    sqlx::query("INSERT INTO tbl_logs (`date`, `type`, `description`, `userid`, `ip`) VALUES (NOW(), 'owner_topup', ?, ?, '')")
        .bind(desc)
        .bind(owner_id)
        .execute(&mut *tx)
        .await
        .ok();

    tx.commit().await.map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(json!({"owner_id": owner_id, "customer_id": data.customer_id, "amount": data.amount.to_string()})))
}

// Admin-only: list internet plans
async fn admin_list_internet_plans(
    state: web::Data<AppState>,
    req: HttpRequest,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;

    let rows = sqlx::query_as::<_, InternetPlan>(
        "SELECT id, name, category, price, currency, validity_unit, validity_value, download_mbps, upload_mbps, radius_groupname, status FROM tbl_internet_plans ORDER BY id ASC"
    )
    .fetch_all(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(rows))
}

// Admin-only: create a new internet plan
async fn admin_create_internet_plan(
    state: web::Data<AppState>,
    req: HttpRequest,
    payload: web::Json<InternetPlanCreateRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let data = payload.into_inner();

    // Validate required fields
    if data.name.trim().is_empty() || data.radius_groupname.trim().is_empty() {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "name and radius_groupname are required"})));
    }

    let currency = data.currency.unwrap_or_else(|| "MMK".to_string());
    let status = data.status.unwrap_or_else(|| "Active".to_string());

    let result = sqlx::query(
        r#"
        INSERT INTO tbl_internet_plans
            (name, category, price, currency, validity_unit, validity_value, download_mbps, upload_mbps, radius_groupname, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        "#
    )
    .bind(&data.name)
    .bind(&data.category)
    .bind(&data.price)
    .bind(&currency)
    .bind(&data.validity_unit)
    .bind(data.validity_value)
    .bind(data.download_mbps)
    .bind(data.upload_mbps)
    .bind(&data.radius_groupname)
    .bind(&status)
    .execute(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    let plan_id = result.last_insert_id();

    Ok(HttpResponse::Created().json(json!({
        "id": plan_id,
        "name": data.name,
        "radius_groupname": data.radius_groupname
    })))
}

// Admin-only: update an internet plan
async fn admin_update_internet_plan(
    state: web::Data<AppState>,
    req: HttpRequest,
    path: web::Path<(i32,)>,
    payload: web::Json<InternetPlanUpdateRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let plan_id = path.into_inner().0;
    let mut data = payload.into_inner();
    data.id = plan_id;

    // Check if plan exists
    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_internet_plans WHERE id = ?")
        .bind(data.id)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    if exists == 0 {
        return Ok(HttpResponse::NotFound().json(json!({"error": "plan_not_found"})));
    }

    sqlx::query(
        r#"
        UPDATE tbl_internet_plans
        SET name = ?, category = ?, price = ?, currency = ?, validity_unit = ?, validity_value = ?,
            download_mbps = ?, upload_mbps = ?, radius_groupname = ?, status = ?
        WHERE id = ?
        "#
    )
    .bind(&data.name)
    .bind(&data.category)
    .bind(&data.price)
    .bind(&data.currency)
    .bind(&data.validity_unit)
    .bind(data.validity_value)
    .bind(data.download_mbps)
    .bind(data.upload_mbps)
    .bind(&data.radius_groupname)
    .bind(&data.status)
    .bind(data.id)
    .execute(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(json!({
        "id": data.id,
        "name": data.name,
        "radius_groupname": data.radius_groupname
    })))
}

// Admin-only: compute owner income for a period (YYYY-MM)
async fn admin_compute_owner_income(
    state: web::Data<AppState>,
    req: HttpRequest,
    payload: web::Json<models::OwnerIncomeComputeRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let period = payload.into_inner().period; // expected YYYY-MM

    // parse period bounds
    let start = format!("{}-01 00:00:00", period);
    let dt = chrono::NaiveDateTime::parse_from_str(&start, "%Y-%m-%d %H:%M:%S")
        .map_err(actix_web::error::ErrorBadRequest)?;
    let year = dt.date().year();
    let month = dt.date().month();
    let next_month = if month == 12 { format!("{}-01-01 00:00:00", year + 1) } else { format!("{}-{}-01 00:00:00", year, month + 1) };

    // configuration: revenue rate per MB and tax rate from env
    let rate_per_mb: f64 = env::var("REVENUE_PER_MB")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(0.01); // default $0.01 per MB
    let tax_rate: f64 = env::var("OWNER_TAX_RATE")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(0.05); // default 5%

    // Aggregate usage and session time from radacct grouped by owner, customer, nas
    // include pppoe username so we can lookup customer plan billing
    let rows = sqlx::query(
        r#"
        SELECT r.username AS pppoe_username, n.owner_id AS owner_id, c.id AS customer_id, n.id AS nas_id,
               SUM(COALESCE(r.acctinputoctets,0) + COALESCE(r.acctoutputoctets,0)) AS usage_bytes,
               SUM(COALESCE(r.acctsessiontime,0)) AS session_seconds
        FROM radacct r
        JOIN nas n ON n.nasname = r.nasipaddress
        LEFT JOIN tbl_customers c ON c.pppoe_username = r.username
        WHERE r.acctstarttime >= ? AND r.acctstarttime < ?
        GROUP BY n.owner_id, c.id, n.id, r.username
        "#,
    )
    .bind(&start)
    .bind(&next_month)
    .fetch_all(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    let mut tx = state.db.begin().await.map_err(actix_web::error::ErrorInternalServerError)?;

    for row in rows {
        let owner_id: Option<i64> = row.try_get("owner_id").ok();
        if owner_id.is_none() { continue; }
        let owner_id = owner_id.unwrap();
        let customer_id: Option<i64> = row.try_get("customer_id").ok();
        let nas_id: Option<i64> = row.try_get("nas_id").ok();
        let usage_bytes: i64 = row.try_get("usage_bytes").unwrap_or(0);
        let session_seconds: i64 = row.try_get("session_seconds").unwrap_or(0);
        let pppoe_username: String = row.try_get("pppoe_username").unwrap_or_default();

        // determine billing for this customer (lookup via radusergroup -> tbl_internet_plans)
        let plan_row = sqlx::query(
            r#"SELECT tip.billing_mode AS billing_mode, tip.price_per_unit AS price_per_unit, tip.billing_unit AS billing_unit
               FROM radusergroup rug
               JOIN tbl_internet_plans tip ON tip.radius_groupname = rug.groupname
               WHERE rug.username = ? LIMIT 1"#
        )
        .bind(&pppoe_username)
        .fetch_optional(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

        // compute revenue based on plan billing mode
        #[allow(unused_assignments)]
        let mut revenue = 0.0_f64;
        if let Some(pr) = plan_row {
            let billing_mode: Option<String> = pr.try_get("billing_mode").ok();
            let price_per_unit: Option<BigDecimal> = pr.try_get("price_per_unit").ok();
            let _billing_unit: Option<String> = pr.try_get("billing_unit").ok();

            if let Some(ppu) = price_per_unit {
                let ppu_f = ppu.to_string().parse::<f64>().unwrap_or(0.0);
                if billing_mode.as_deref() == Some("time") {
                    // time-based billing: price per minute
                    let minutes = (session_seconds as f64) / 60.0;
                    revenue = minutes * ppu_f;
                } else {
                    // default to data-based: price per MB
                    let usage_mb = (usage_bytes as f64) / 1048576.0;
                    revenue = usage_mb * ppu_f;
                }
            } else {
                // price not set on plan; fallback to env defaults
                if billing_mode.as_deref() == Some("time") {
                    let rate_per_min: f64 = env::var("REVENUE_PER_MIN")
                        .ok()
                        .and_then(|s| s.parse().ok())
                        .unwrap_or(0.001);
                    let minutes = (session_seconds as f64) / 60.0;
                    revenue = minutes * rate_per_min;
                } else {
                    let usage_mb = (usage_bytes as f64) / 1048576.0;
                    revenue = usage_mb * rate_per_mb;
                }
            }
        } else {
            // no plan found: fallback to data-based pricing
            let usage_mb = (usage_bytes as f64) / 1048576.0;
            revenue = usage_mb * rate_per_mb;
        }

        let tax = revenue * tax_rate;

        // insert aggregated record (store revenue/tax as string decimal)
        sqlx::query("INSERT INTO owner_income (owner_id, customer_id, nas_id, period, usage_bytes, revenue, tax) VALUES (?, ?, ?, ?, ?, ?, ?)")
            .bind(owner_id)
            .bind(customer_id)
            .bind(nas_id)
            .bind(&period)
            .bind(usage_bytes)
            .bind(format!("{:.2}", revenue))
            .bind(format!("{:.2}", tax))
            .execute(&mut *tx)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;
    }

    tx.commit().await.map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(json!({"period": period, "status": "computed"})))
}

// Admin-only: query owner income for a given owner and period (or all)
async fn admin_get_owner_income(
    state: web::Data<AppState>,
    req: HttpRequest,
    query: web::Query<std::collections::HashMap<String, String>>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let owner_id = query.get("owner_id").and_then(|s| s.parse::<i32>().ok());
    let period = query.get("period");

    // Build parameterized query to prevent SQL injection
    let rows = match (period, owner_id) {
        (Some(p), Some(oid)) => {
            sqlx::query(
                "SELECT id, owner_id, customer_id, nas_id, period, usage_bytes, revenue, tax, created_at FROM owner_income WHERE period = ? AND owner_id = ? ORDER BY period DESC, owner_id ASC"
            )
            .bind(p)
            .bind(oid)
            .fetch_all(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?
        },
        (Some(p), None) => {
            sqlx::query(
                "SELECT id, owner_id, customer_id, nas_id, period, usage_bytes, revenue, tax, created_at FROM owner_income WHERE period = ? ORDER BY period DESC, owner_id ASC"
            )
            .bind(p)
            .fetch_all(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?
        },
        (None, Some(oid)) => {
            sqlx::query(
                "SELECT id, owner_id, customer_id, nas_id, period, usage_bytes, revenue, tax, created_at FROM owner_income WHERE owner_id = ? ORDER BY period DESC, owner_id ASC"
            )
            .bind(oid)
            .fetch_all(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?
        },
        (None, None) => {
            sqlx::query(
                "SELECT id, owner_id, customer_id, nas_id, period, usage_bytes, revenue, tax, created_at FROM owner_income ORDER BY period DESC, owner_id ASC"
            )
            .fetch_all(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?
        },
    };

    let mut out = Vec::new();
    for r in rows {
        let rec = json!({
            "id": r.try_get::<i64, _>("id").unwrap_or(0),
            "owner_id": r.try_get::<i32, _>("owner_id").unwrap_or(0),
            "customer_id": r.try_get::<Option<i32>, _>("customer_id").unwrap_or(None),
            "nas_id": r.try_get::<Option<i32>, _>("nas_id").unwrap_or(None),
            "period": r.try_get::<String, _>("period").unwrap_or_default(),
            "usage_bytes": r.try_get::<i64, _>("usage_bytes").unwrap_or(0),
            "revenue": r.try_get::<Option<String>, _>("revenue").unwrap_or(Some("0".to_string())).unwrap_or("0".to_string()),
            "tax": r.try_get::<Option<String>, _>("tax").unwrap_or(Some("0".to_string())).unwrap_or("0".to_string()),
            "created_at": r.try_get::<chrono::NaiveDateTime, _>("created_at").map(|dt| dt.to_string()).unwrap_or_default(),
        });
        out.push(rec);
    }

    Ok(HttpResponse::Ok().json(out))
}

// Admin-only: owner income history (monthly totals) for a specific owner
async fn admin_owner_income_history(
    state: web::Data<AppState>,
    req: HttpRequest,
    path: web::Path<(i32,)>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let owner_id = path.into_inner().0;

    let rows = sqlx::query(
        r#"SELECT period, SUM(revenue) as revenue_total, SUM(tax) as tax_total, SUM(usage_bytes) as usage_bytes_total
           FROM owner_income WHERE owner_id = ? GROUP BY period ORDER BY period DESC"#,
    )
    .bind(owner_id)
    .fetch_all(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    // map to JSON
    let mut out = Vec::new();
    for r in rows {
        let period: String = r.try_get("period").unwrap_or_default();
        let revenue_total: Option<BigDecimal> = r.try_get("revenue_total").ok();
        let tax_total: Option<BigDecimal> = r.try_get("tax_total").ok();
        let usage_bytes_total: Option<i64> = r.try_get("usage_bytes_total").ok();
        out.push(json!({
            "period": period,
            "revenue_total": revenue_total.map(|d| d.to_string()).unwrap_or_else(|| "0".to_string()),
            "tax_total": tax_total.map(|d| d.to_string()).unwrap_or_else(|| "0".to_string()),
            "usage_bytes_total": usage_bytes_total.unwrap_or(0),
        }));
    }

    Ok(HttpResponse::Ok().json(out))
}

// Admin-only: list operators
async fn admin_list_operators(
    state: web::Data<AppState>,
    req: HttpRequest,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;

    let rows = sqlx::query_as::<_, OwnerPublic>(
        "SELECT id, username, fullname, status FROM tbl_users WHERE user_type = 'Operator' ORDER BY id ASC",
    )
    .fetch_all(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(rows))
}

// Admin-only: create operator
async fn admin_create_operator(
    state: web::Data<AppState>,
    req: HttpRequest,
    payload: web::Json<OwnerCreateRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let data = payload.into_inner();

    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_users WHERE username = ?")
        .bind(&data.username)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if exists > 0 {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "username_exists"}))); 
    }

    let hashed = hash(&data.password, DEFAULT_COST).map_err(actix_web::error::ErrorInternalServerError)?;

    let result = sqlx::query(
        "INSERT INTO tbl_users (username, fullname, password, user_type, status, creationdate) VALUES (?, ?, ?, 'Operator', 'Active', NOW())",
    )
    .bind(&data.username)
    .bind(&data.fullname)
    .bind(&hashed)
    .execute(&state.db)
    .await
    .map_err(actix_web::error::ErrorInternalServerError)?;

    let id = result.last_insert_id();

    Ok(HttpResponse::Created().json(json!({"id": id, "username": data.username})))
}

// Admin-only: update operator
async fn admin_update_operator(
    state: web::Data<AppState>,
    req: HttpRequest,
    path: web::Path<(i32,)>,
    payload: web::Json<OwnerUpdateRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let operator_id = path.into_inner().0 as u32;
    let mut data = payload.into_inner();
    data.id = operator_id;

    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_users WHERE id = ? AND user_type = 'Operator'")
        .bind(data.id)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if exists == 0 {
        return Ok(HttpResponse::NotFound().json(json!({"error": "operator_not_found"}))); 
    }

    if let Some(pw) = data.password {
        let hashed = hash(&pw, DEFAULT_COST).map_err(actix_web::error::ErrorInternalServerError)?;
        sqlx::query("UPDATE tbl_users SET username = ?, fullname = ?, password = ?, status = ? WHERE id = ? AND user_type = 'Operator'")
            .bind(&data.username)
            .bind(&data.fullname)
            .bind(&hashed)
            .bind(data.status.unwrap_or_else(|| "Active".to_string()))
            .bind(data.id)
            .execute(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;
    } else {
        sqlx::query("UPDATE tbl_users SET username = ?, fullname = ?, status = ? WHERE id = ? AND user_type = 'Operator'")
            .bind(&data.username)
            .bind(&data.fullname)
            .bind(data.status.unwrap_or_else(|| "Active".to_string()))
            .bind(data.id)
            .execute(&state.db)
            .await
            .map_err(actix_web::error::ErrorInternalServerError)?;
    }

    Ok(HttpResponse::Ok().json(json!({"id": data.id, "username": data.username})))
}

// Admin-only: delete operator
async fn admin_delete_operator(
    state: web::Data<AppState>,
    req: HttpRequest,
    path: web::Path<(i32,)>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
    let operator_id = path.into_inner().0;

    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_users WHERE id = ? AND user_type = 'Operator'")
        .bind(operator_id)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if exists == 0 {
        return Ok(HttpResponse::NotFound().json(json!({"error": "operator_not_found"}))); 
    }

    sqlx::query("DELETE FROM tbl_users WHERE id = ? AND user_type = 'Operator'")
        .bind(operator_id)
        .execute(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Ok().json(json!({"id": operator_id})))
}

// Admin or SuperAdmin: create user of type Admin/Report/Owner/Operator
async fn admin_create_user(
    state: web::Data<AppState>,
    req: HttpRequest,
    payload: web::Json<models::UserCreateRequest>,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_only_claims(&req, &state.jwt_secret)?;
    let data = payload.into_inner();

    let allowed = ["admin", "report", "owner", "operator"];
    if !allowed.contains(&data.user_type.to_lowercase().as_str()) {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "invalid_user_type"}))); 
    }

    let exists: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tbl_users WHERE username = ?")
        .bind(&data.username)
        .fetch_one(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;
    if exists > 0 {
        return Ok(HttpResponse::BadRequest().json(json!({"error": "username_exists"}))); 
    }

    let hashed = hash(&data.password, DEFAULT_COST).map_err(actix_web::error::ErrorInternalServerError)?;

    let q = "INSERT INTO tbl_users (username, fullname, password, user_type, status, creationdate) VALUES (?, ?, ?, ?, 'Active', NOW())";
    sqlx::query(q)
        .bind(&data.username)
        .bind(&data.fullname)
        .bind(&hashed)
        .bind(&data.user_type)
        .execute(&state.db)
        .await
        .map_err(actix_web::error::ErrorInternalServerError)?;

    Ok(HttpResponse::Created().json(json!({"username": data.username, "user_type": data.user_type})))
}