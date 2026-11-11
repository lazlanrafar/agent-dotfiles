# Macros, Pattern Matching & Testing

Deep reference based on The Rust Book (Ch. 18 Patterns, Ch. 20 Macros) and Rust 2024 practices.

## 1. Declarative Macros (`macro_rules!`)

Match against syntax token trees to eliminate repetitive boilerplate:

```rust
#[macro_export]
macro_rules! string_vec {
    ( $( $x:expr ),* $(,)? ) => {
        {
            let mut v = Vec::new();
            $( v.push(String::from($x)); )*
            v
        }
    };
}
```

Common fragment specifiers: `expr` (expression), `ident` (identifier), `ty` (type), `pat` (pattern), `path`, `block`, `tt` (single token tree).

## 2. Procedural Macros

Compiled in a dedicated crate with `proc-macro = true` using `syn`, `quote`, and `proc-macro2`:
- **Custom Derive (`#[proc_macro_derive(MyTrait)]`)**: auto-generate trait implementations for structs/enums.
- **Attribute Macros (`#[proc_macro_attribute]`)**: wrap or transform functions/items (e.g., `#[tokio::main]`, `#[tracing::instrument]`).
- **Function-like Macros (`#[proc_macro]`)**: custom compile-time validation (e.g., `sqlx::query!`).

## 3. Advanced Pattern Matching

```rust
// Match guards & @ bindings
match msg {
    Message::Move { x: x @ 0..=10, y } if y >= 0 => println!("valid x={x}, y={y}"),
    Message::Quit => return,
    _ => {}
}

// let-else (Rust 1.65+): early return when a refutable pattern fails
let Some(user_id) = raw_id.strip_prefix("usr_") else {
    return Err(AppError::InvalidId);
};
```

## 4. Structured Error Handling (`thiserror` & `anyhow`)

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum StorageError {
    #[error("database error")]
    Database(#[from] sqlx::Error),
    #[error("{resource} {id} not found")]
    NotFound { resource: &'static str, id: u64 },
}
```

## 5. Testing Patterns

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_valid_id() -> Result<(), Box<dyn std::error::Error>> {
        let v: i32 = "42".parse()?;
        assert_eq!(v, 42);
        Ok(())
    }

    #[tokio::test]
    async fn fetches_record() {
        let res = async_op().await;
        assert!(res.is_ok());
    }
}
```
