# Cargo, Workspace & Ekosistem Modern

Berdasarkan The Cargo Book, Rust By Example, dan praktik Rust 2024 Edition.

## Cargo Essentials

```toml
# Cargo.toml: Rust 2024 Edition
[package]
name = "my-app"
version = "0.1.0"
edition = "2024"

[dependencies]
# Versi exact (untuk app binary)
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
anyhow = "1"

[dev-dependencies]
# Hanya di build test/bench
tokio = { version = "1", features = ["test-util"] }

[features]
default = ["postgres"]
postgres = ["sqlx/postgres"]
sqlite = ["sqlx/sqlite"]
```

### Cargo Workspace (Monorepo)

```toml
# Cargo.toml (root)
[workspace]
members = ["crates/*"]
resolver = "3"

[workspace.dependencies]  # Shared versions
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }

# Crates anggota inherit dengan workspace = true
# crates/my-lib/Cargo.toml
[dependencies]
tokio = { workspace = true }
```

**Gunakan workspace** jika project punya multiple crates yang saling terhubung (lib + binary + proc-macro).

### Release Profiles

```toml
[profile.release]
opt-level = 3        # Maksimum optimasi
lto = true           # Link Time Optimization
codegen-units = 1    # Satu unit: lebih lambat compile, lebih cepat runtime
strip = true         # Strip debug symbols dari binary

[profile.dev]
opt-level = 0        # Kompilasi cepat
debug = true
```

### Cargo Commands Penting

```bash
cargo check              # Cepat: cek error tanpa generate binary
cargo build --release    # Build optimized
cargo test -- --nocapture              # Test dengan stdout
cargo test specific_test               # Jalankan test tertentu
cargo bench                            # Benchmark
cargo doc --open                       # Buka dokumentasi
cargo update                           # Update Cargo.lock
cargo tree                             # Dependency tree
cargo audit                            # Cek CVE di dependencies
```

## Serde: Serialization / Deserialization

```rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]   // snake_case <-> camelCase otomatis
struct User {
    #[serde(rename = "user_id")]     // Override field tertentu
    id: u64,
    username: String,
    #[serde(skip_serializing_if = "Option::is_none")]  // Skip null
    email: Option<String>,
    #[serde(default)]               // Gunakan Default jika field tidak ada
    active: bool,
}

// JSON
let json_str = serde_json::to_string(&user)?;
let user: User = serde_json::from_str(&json_str)?;

// Untagged enum: representasi polimorfik
#[derive(Serialize, Deserialize)]
#[serde(untagged)]
enum Response {
    Success { data: String },
    Error { code: u32, message: String },
}
```

## SQLx: Database dengan Compile-time Verification

```rust
use sqlx::PgPool;

// Compile-time query check (butuh DATABASE_URL saat compile)
let users = sqlx::query!(
    "SELECT id, name, email FROM users WHERE active = $1",
    true
)
.fetch_all(&pool)
.await?;

// Dengan struct mapping
#[derive(sqlx::FromRow)]
struct User { id: i64, name: String, email: String }

let users: Vec<User> = sqlx::query_as!(
    User,
    "SELECT id, name, email FROM users WHERE active = $1",
    true
)
.fetch_all(&pool)
.await?;

// Transaction
let mut tx = pool.begin().await?;
sqlx::query!("INSERT INTO users (name) VALUES ($1)", name)
    .execute(&mut *tx).await?;
tx.commit().await?;
```

## Axum: Web Framework

```rust
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};

#[derive(Clone)]
struct AppState { db: PgPool }

#[tokio::main]
async fn main() {
    let state = AppState { db: PgPool::connect(&db_url).await.unwrap() };

    let app = Router::new()
        .route("/users", get(list_users).post(create_user))
        .route("/users/:id", get(get_user).delete(delete_user))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

// Handler: return impl IntoResponse
async fn get_user(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<User>, StatusCode> {
    let user = fetch_user(&state.db, id).await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    Ok(Json(user))
}
```

## Clap: CLI

```rust
use clap::{Args, Parser, Subcommand};

#[derive(Parser)]
#[command(name = "mytool", version, about)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Run the server
    Serve(ServeArgs),
    /// Process a file
    Process { #[arg(short, long)] input: String },
}

#[derive(Args)]
struct ServeArgs {
    #[arg(short, long, default_value = "3000")]
    port: u16,
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Commands::Serve(args) => start_server(args.port),
        Commands::Process { input } => process_file(input),
    }
}
```

## Tracing: Structured Logging

```rust
use tracing::{info, warn, error, instrument};
use tracing_subscriber::EnvFilter;

// Setup di main
tracing_subscriber::fmt()
    .with_env_filter(EnvFilter::from_default_env())  // RUST_LOG=info
    .init();

// Instrument function: otomatis log enter/exit + span
#[instrument(skip(db), fields(user_id = %id))]
async fn fetch_user(db: &PgPool, id: i64) -> Result<User, Error> {
    info!("fetching user");
    let user = sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
        .fetch_one(db).await?;
    info!(email = %user.email, "user found");
    Ok(user)
}
```

## rustdoc: Dokumentasi

```rust
/// Hitung luas lingkaran.
///
/// # Examples
///
/// ```
/// use my_crate::circle_area;
/// let area = circle_area(5.0);
/// assert!((area - 78.54).abs() < 0.01);
/// ```
///
/// # Panics
///
/// Panic jika `radius` negatif.
pub fn circle_area(radius: f64) -> f64 {
    assert!(radius >= 0.0, "radius cannot be negative");
    std::f64::consts::PI * radius * radius
}
```

Doc tests (```` ```rust ```` dalam komentar) dijalankan oleh `cargo test` otomatis.
