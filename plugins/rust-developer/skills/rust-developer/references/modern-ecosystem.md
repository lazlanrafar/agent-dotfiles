# Cargo, Workspaces & Modern Ecosystem

Deep reference based on The Cargo Book, Rust by Example, and Rust 2024 Edition standards.

## Cargo & Workspace Configuration

```toml
# Root Cargo.toml for a multi-crate workspace
[workspace]
members = ["crates/*"]
resolver = "3"

[workspace.package]
edition = "2024"
rust-version = "1.85"

[workspace.dependencies]
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
anyhow = "1"
thiserror = "2"
tracing = "0.1"

[profile.release]
opt-level = 3
lto = "thin"
codegen-units = 1
strip = true
```

## Serde: Type-Safe Serialization

```rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct User {
    #[serde(rename = "user_id")]
    pub id: u64,
    pub username: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    #[serde(default)]
    pub active: bool,
}
```

## SQLx: Compile-Time Checked SQL

```rust
use sqlx::PgPool;

#[derive(sqlx::FromRow)]
pub struct UserRow {
    pub id: i64,
    pub name: String,
    pub email: String,
}

pub async fn active_users(pool: &PgPool) -> Result<Vec<UserRow>, sqlx::Error> {
    sqlx::query_as!(
        UserRow,
        "SELECT id, name, email FROM users WHERE active = $1",
        true
    )
    .fetch_all(pool)
    .await
}
```

## Axum: Ergonomic Web Services

```rust
use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::get,
    Json, Router,
};

#[derive(Clone)]
struct AppState {
    db: PgPool,
}

async fn get_user(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<UserRow>, StatusCode> {
    let user = sqlx::query_as!(UserRow, "SELECT id, name, email FROM users WHERE id = $1", id)
        .fetch_optional(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    Ok(Json(user))
}
```

## Tracing: Structured Telemetry

```rust
use tracing::{info, instrument};

#[instrument(skip(db), fields(user_id = %id))]
pub async fn fetch_user(db: &PgPool, id: i64) -> Result<UserRow, sqlx::Error> {
    info!("fetching user record");
    sqlx::query_as!(UserRow, "SELECT id, name, email FROM users WHERE id = $1", id)
        .fetch_one(db)
        .await
}
```
