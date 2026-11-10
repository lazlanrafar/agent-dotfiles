# Macros & Metaprogramming

Berdasarkan The Rust Book Ch.20 (Macros) dan praktik ekosistem Rust 2024.

## Dua Jenis Makro Utama

### 1. Declarative Macros (`macro_rules!`)

Pencocokkan pola atas struktur kode, bukan nilai. Dipakai untuk menghindari duplikasi boilerplate.

```rust
// Contoh: vec! macro standar
#[macro_export]
macro_rules! my_vec {
    // Pattern: ekspresi yang dipisah koma, nol atau lebih
    ( $( $x:expr ),* ) => {
        {
            let mut v = Vec::new();
            $( v.push($x); )*
            v
        }
    };
}

let v = my_vec![1, 2, 3];
```

**Fragment specifiers** yang sering dipakai:
- `expr`: ekspresi
- `ident`: identifier/nama
- `ty`: tipe
- `tt`: token tree (paling fleksibel)
- `path`: path seperti `std::io`
- `block`: blok kode `{ ... }`

**Kapan pakai**: Duplikasi pola yang tidak bisa diatasi generics, DSL kecil, variadic argument.

### 2. Procedural Macros

Fungsi Rust yang terima dan kembalikan `TokenStream`. Harus diletakkan di crate terpisah dengan `proc-macro = true`.

**Dependensi standar**:
```toml
[dependencies]
syn = { version = "2", features = ["full"] }
quote = "1"
proc-macro2 = "1"
```

#### a. Custom Derive

```rust
// Crate proc-macro
use proc_macro::TokenStream;
use quote::quote;
use syn;

#[proc_macro_derive(HelloMacro)]
pub fn hello_macro_derive(input: TokenStream) -> TokenStream {
    let ast = syn::parse(input).unwrap();
    let name = &ast.ident;
    quote! {
        impl HelloMacro for #name {
            fn hello_macro() {
                println!("Hello, Macro! My name is {}!", stringify!(#name));
            }
        }
    }.into()
}

// Pemakaian
#[derive(HelloMacro)]
struct Pancakes;
```

#### b. Attribute Macros

```rust
// #[route(GET, "/")]
#[proc_macro_attribute]
pub fn route(attr: TokenStream, item: TokenStream) -> TokenStream { ... }
```

#### c. Function-like Macros

```rust
// sql!(SELECT * FROM users WHERE id = {user_id})
#[proc_macro]
pub fn sql(input: TokenStream) -> TokenStream { ... }
```

## Pattern Matching Lanjutan (Ch.18)

Pattern matching tidak hanya untuk `match` — dipakai di `let`, `if let`, `while let`, function parameter, dan destructuring.

```rust
// Ranges dalam pattern
match x {
    1..=5 => println!("one through five"),
    _ => println!("something else"),
}

// Guard dalam match
let pair = (2, -2);
match pair {
    (x, y) if x == y => println!("equal"),
    (x, y) if x + y == 0 => println!("sum is zero"),
    _ => println!("other"),
}

// @ binding: test + bind sekaligus
match msg {
    Message::Move { x: x @ 0..=10, y } => println!("x in range: {}", x),
    _ => {}
}

// Destructuring struct, enum, tuple, nested
let Point { x, y } = p;
let (a, b, c) = tuple;
let &ref_val = &5;  // ref pattern

// Irrefutable vs Refutable: if let untuk refutable patterns
if let Some(value) = optional_value {
    println!("{}", value);
}

// while let
while let Some(top) = stack.pop() {
    println!("{}", top);
}
```

## Error Handling Lanjutan

```rust
// thiserror: library error types yang terstruktur
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),

    #[error("not found: {resource} with id {id}")]
    NotFound { resource: &'static str, id: u64 },

    #[error("parse error")]
    Parse(#[from] std::num::ParseIntError),
}

// anyhow: application-level error handling dengan context
use anyhow::{Context, Result};

fn load_config(path: &str) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read config from {}", path))?;
    let config: Config = toml::from_str(&content)
        .context("failed to parse config as TOML")?;
    Ok(config)
}
```

## Testing

```rust
// Unit test dalam modul yang sama
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_addition() {
        assert_eq!(2 + 2, 4);
    }

    #[test]
    #[should_panic(expected = "overflow")]
    fn test_panic() {
        panic!("overflow");
    }

    #[test]
    fn test_result() -> Result<(), String> {
        // Gunakan ? operator dalam test
        let v = "2".parse::<i32>().map_err(|e| e.to_string())?;
        assert_eq!(v, 2);
        Ok(())
    }
}

// Integration test: file di tests/ direktori
// Hanya akses public API
// tests/integration_test.rs
use my_crate::public_function;

#[test]
fn it_works() {
    assert_eq!(public_function(), expected);
}

// Async test dengan tokio
#[tokio::test]
async fn test_async() {
    let result = async_function().await;
    assert!(result.is_ok());
}
```
