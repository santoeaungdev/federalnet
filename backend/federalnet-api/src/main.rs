mod models;

use actix_cors::Cors;
use actix_web::{middleware::Logger, web, App, HttpRequest, HttpResponse, HttpServer};
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use models::{Customer, CustomerClaims, CustomerLoginRequest, CustomerLoginResponse, CustomerPublic};
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
        App::new()
            .wrap(Logger::default())
            .wrap(Cors::permissive())
            .app_data(web::Data::new(state.clone()))
            .service(
                web::scope("/api")
                    .route("/health", web::get().to(health))
                    .route("/customer/login", web::post().to(customer_login))
                    .route("/customers/me", web::get().to(customers_me)),
            )
    })
        .bind(("0.0.0.0", 8080))?
        .run()
        .await
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

    // TEMP: compare plain text; later use bcrypt::verify with password_hash
    if customer.password != login.password {
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
