use actix_web::{HttpRequest, Error};
use bcrypt::verify;
use sha1::Sha1;
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};

/// Verify password with support for bcrypt, legacy SHA1, or plaintext
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

/// Extract JWT claims from Authorization header
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
