mod models;

use actix_cors::Cors;
use actix_web::{middleware::Logger, web, App, HttpRequest, HttpResponse, HttpServer};
use chrono::{Duration, Utc};
use bcrypt::{hash, verify, DEFAULT_COST};
use sha1::Sha1;
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use models::{Customer, CustomerClaims, CustomerLoginRequest, CustomerLoginResponse, CustomerPublic, CustomerRegisterRequest,
AdminUser, AdminLoginRequest, AdminLoginResponse, AdminPublic, AdminClaims, AssignPlanRequest, AdminCustomerListItem, NrcRow};
use serde::Deserialize;
use sqlx::{mysql::MySqlPoolOptions, MySqlPool};
use std::env;
use serde_json::json;

#[derive(Clone)]
struct AppState {
    db: MySqlPool,
    jwt_secret: String,
}

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

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let jwt_secret = env::var("JWT_SECRET").expect("JWT_SECRET must be set");
    let enable_seed = env::var("ENABLE_SEED_ENDPOINTS")
        .map(|v| matches!(v.as_str(), "1" | "true" | "TRUE" | "yes" | "YES"))
        .unwrap_or(false);

    let pool = MySqlPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
        .expect("DB connect failed");

    let state = AppState {
        db: pool,
        jwt_secret,
    };

    HttpServer::new(move || {
        let mut scoped = web::scope("/api")
            .route("/health", web::get().to(health))
            .route("/admin/login", web::post().to(admin_login))
            .route("/customer/login", web::post().to(customer_login))
            .route("/customers/me", web::get().to(customers_me))
            .route("/customer/register", web::post().to(customer_register))
            .route("/admin/nrcs", web::get().to(admin_list_nrcs))
            .route("/admin/customer/register", web::post().to(admin_customer_register))
            .route("/admin/assign_plan", web::post().to(admin_assign_plan))
            .route("/admin/customers", web::get().to(admin_list_customers));

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
        .bind(("0.0.0.0", 8080))?
        .run()
        .await
}


async fn admin_login(
    state: web::Data<AppState>,
    payload: web::Json<AdminLoginRequest>,
) -> actix_web::Result<HttpResponse> {
    let login = payload.into_inner();

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
    .map_err(actix_web::error::ErrorInternalServerError)?;

    let admin = match admin {
        Some(a) => a,
        None => {
            return Ok(HttpResponse::Unauthorized().json(json!({"error": "invalid_credentials"})));
        }
    };

    if admin.status != "Active" {
        return Ok(HttpResponse::Unauthorized().json(json!({"error": "inactive_admin"})));
    }

    // verify admin password with support for bcrypt, legacy SHA1, or plaintext
    let stored = admin.password.clone();
    let ok = if stored.starts_with("$2") {
        verify(&login.password, &stored).map_err(actix_web::error::ErrorInternalServerError)?
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
        return Ok(HttpResponse::Unauthorized().json(json!({"error": "invalid_credentials"})));
    }

    let expiration = Utc::now() + Duration::minutes(60);
    let claims = AdminClaims {
        sub: admin.id,
        role: "admin".to_string(),
        exp: expiration.timestamp(),
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(state.jwt_secret.as_bytes()),
    )
    .map_err(actix_web::error::ErrorInternalServerError)?;

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
        .map_err(actix_web::error::ErrorInternalServerError)?;

    let customer = match customer {
        Some(c) => c,
        None => {
            return Ok(
                HttpResponse::Unauthorized().json(json!({"error": "invalid_credentials"}))
            );
        }
    };

    if customer.status != "Active" {
        return Ok(
            HttpResponse::Unauthorized().json(json!({"error": "inactive_customer"}))
        );
    }

    // verify customer password with bcrypt, legacy SHA1, or plaintext
    let stored = customer.password.clone();
    let ok = if stored.starts_with("$2") {
        verify(&login.password, &stored).map_err(actix_web::error::ErrorInternalServerError)?
    } else if stored.len() == 40 {
        let bytes = Sha1::from(login.password.as_str()).digest().bytes();
        let hex = hex::encode(bytes);
        hex == stored
    } else {
        stored == login.password
    };

    if !ok {
        return Ok(
            HttpResponse::Unauthorized().json(json!({"error": "invalid_credentials"}))
        );
    }

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

    Ok(data.claims)
}

// Admin-only: fetch NRC township codes from `nrcs` table for dropdowns.
async fn admin_list_nrcs(
    state: web::Data<AppState>,
    req: HttpRequest,
) -> actix_web::Result<HttpResponse> {
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;

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
    // require admin token
    let admin_claims = extract_admin_claims(&req, &state.jwt_secret)?;

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
    .bind(admin_claims.sub as i64)
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

    // Optionally add group mapping for plan/router_tag
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
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;
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
    let _admin = extract_admin_claims(&req, &state.jwt_secret)?;

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