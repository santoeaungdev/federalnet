//! Authentication utilities for FederalNet API
//!
//! This module provides reusable authentication and authorization functions including:
//! - Password verification with support for bcrypt, legacy SHA1, and plaintext
//! - JWT token extraction and validation from HTTP requests
//! - Password hashing with bcrypt

use actix_web::{HttpRequest, Error};
use bcrypt::{verify, hash, DEFAULT_COST};
use sha1::Sha1;
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};

/// Hashes a plaintext password using bcrypt.
///
/// # Arguments
///
/// * `plaintext` - The plaintext password to hash
///
/// # Returns
///
/// Returns the bcrypt hash string on success, or an error if hashing fails.
///
/// # Examples
///
/// ```ignore
/// let hashed = hash_password("mypassword")?;
/// ```
pub fn hash_password(plaintext: &str) -> Result<String, Error> {
    hash(plaintext, DEFAULT_COST)
        .map_err(actix_web::error::ErrorInternalServerError)
}

/// Verifies a password against a stored hash.
///
/// Supports multiple password storage formats for backward compatibility:
/// - bcrypt hashes (recommended, starts with "$2")
/// - SHA1 hashes (legacy, 40 character hex string)
/// - plaintext passwords (legacy fallback)
///
/// # Arguments
///
/// * `plaintext` - The plaintext password to verify
/// * `stored_hash` - The stored password hash or plaintext
///
/// # Returns
///
/// Returns `Ok(true)` if the password matches, `Ok(false)` if it doesn't,
/// or an error if bcrypt verification fails.
///
/// # Examples
///
/// ```ignore
/// let is_valid = verify_password("mypassword", "$2b$12$...")?;
/// ```
pub fn verify_password(plaintext: &str, stored_hash: &str) -> Result<bool, Error> {
    let ok = if stored_hash.starts_with("$2") {
        // bcrypt hash
        verify(plaintext, stored_hash)
            .map_err(actix_web::error::ErrorInternalServerError)?
    } else if stored_hash.len() == 40 {
        // legacy SHA1 hex
        let bytes = Sha1::from(plaintext).digest().bytes();
        let hex = hex::encode(bytes);
        hex == stored_hash
    } else {
        // fallback plaintext compare
        stored_hash == plaintext
    };
    Ok(ok)
}

/// Extracts and validates JWT claims from the Authorization header.
///
/// This generic function can extract any type of JWT claims that implements
/// `serde::de::DeserializeOwned`.
///
/// # Arguments
///
/// * `req` - The HTTP request containing the Authorization header
/// * `secret` - The JWT secret key used for token validation
///
/// # Returns
///
/// Returns the decoded JWT claims on success, or an error if:
/// - The Authorization header is missing or invalid
/// - The token is not in Bearer format
/// - The JWT signature is invalid or the token is expired
///
/// # Examples
///
/// ```ignore
/// let claims: CustomerClaims = extract_claims(&req, &jwt_secret)?;
/// ```
pub fn extract_claims<T>(req: &HttpRequest, secret: &str) -> Result<T, Error>
where
    T: serde::de::DeserializeOwned,
{
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

    let data = decode::<T>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::new(Algorithm::HS256),
    )
    .map_err(|_| actix_web::error::ErrorUnauthorized("invalid_token"))?;

    Ok(data.claims)
}
