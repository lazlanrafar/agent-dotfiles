---
name: rust-developer
description: >-
  Rust development skill based on roadmap.sh Rust fundamentals and official rust-lang.org/learn documentation.
  Enforces idiomatic Rust 2024: ownership, borrowing, lifetimes, zero-cost abstractions, robust error
  handling without unwrap, safe concurrency, async/await, macros, and modern ecosystem standards.
  Use whenever creating, reviewing, refactoring, or debugging Rust code.
---

# Rust Developer Skill

Engineering guidelines based on `roadmap.sh/rust` and `rust-lang.org/learn` (The Book, Rust by Example, Rustonomicon, Cargo Book).

> **On-demand deep references in `references/`**:
> - [Memory, Lifetimes & Smart Pointers](./references/memory-and-lifetimes.md)
> - [Traits, Generics & Type-Level Programming](./references/traits-generics-types.md)
> - [Concurrency, Async & Parallelism](./references/async-and-concurrency.md)
> - [Macros & Metaprogramming](./references/macros-and-metaprogramming.md)
> - [Cargo, Workspaces & Modern Ecosystem](./references/modern-ecosystem.md)

---

## 1. Memory Safety & Ownership (Core Pillar)

- **Three Ownership Laws**: one owner per value, one owner at a time, deterministic `Drop` on scope exit (RAII).
- **Borrowing Rules**: any number of shared `&T` references XOR exactly one exclusive `&mut T` reference.
- **Accept Slices Over Owned Containers**: take `&str` instead of `&String`, and `&[T]` instead of `&Vec<T>` in function parameters.
- **Avoid Unjustified `.clone()`**: borrow where possible; clone only when independent ownership semantics are required.
- **Non-Lexical Lifetimes (NLL)**: borrows end at the last usage point, not necessarily the end of the lexical block.

**Deep reference**: [memory-and-lifetimes.md](./references/memory-and-lifetimes.md)

---

## 2. Idiomatic Error Handling

- **Never use `.unwrap()` or `.expect()` in production code**. Reserve them for unit tests or provably infallible static initialization.
- Use **`Option<T>`** for optional values and **`Result<T, E>`** for fallible operations.
- Propagate errors with the `?` operator.
- **Libraries / Domain crates**: use `thiserror` to define strongly typed error enums.
- **Applications / Binaries**: use `anyhow` with `.context()` / `.with_context()`.

```rust
#[derive(thiserror::Error, Debug)]
pub enum AppError {
    #[error("not found: {0}")]
    NotFound(String),
    #[error("database error")]
    Db(#[from] sqlx::Error),
}

fn load() -> anyhow::Result<Config> {
    let s = std::fs::read_to_string("config.toml")
        .context("missing config.toml")?;
    Ok(toml::from_str(&s)?)
}
```

---

## 3. Types, Traits & Abstractions

- **Default to Static Dispatch** (`impl Trait` / generics): monomorphized, zero-cost, inlinable.
- **Use Dynamic Dispatch** (`Box<dyn Trait>` / `&dyn Trait`) only for heterogeneous collections or runtime polymorphism.
- **Make Illegal States Unrepresentable**: model domain state machines with algebraic data types (`enum`) and newtypes (`struct UserId(u64)`).
- **Prefer Iterator Chains** over manual indexed `for` loops.

**Deep reference**: [traits-generics-types.md](./references/traits-generics-types.md)

---

## 4. Smart Pointers & Interior Mutability

| Type | Purpose | Thread-Safe? |
|:-----|:--------|:-------------|
| `Box<T>` | Heap allocation, single owner | Yes |
| `Rc<T>` | Reference-counted shared ownership | **No** (single-thread) |
| `Arc<T>` | Atomically reference-counted shared ownership | **Yes** |
| `Cell<T>` | Interior mutability for `Copy` types | No |
| `RefCell<T>` | Interior mutability with runtime borrow checks | No |
| `Cow<'a, B>` | Clone-on-write (borrowed or owned) | Yes (if `B: Sync`) |
| `Weak<T>` | Non-owning reference to break reference cycles | Matches `Rc`/`Arc` |

---

## 5. Concurrency & Async

- Prefer **message passing** (`std::sync::mpsc`, `tokio::sync::mpsc`, `crossbeam`) over shared mutable state.
- For shared mutable state, keep lock scopes tight with `Arc<Mutex<T>>` or `Arc<RwLock<T>>`. Never hold a `std::sync::MutexGuard` across an `.await` point.
- **Async runtime**: use `tokio`. Never block async worker threads with synchronous I/O or heavy CPU loops — offload via `tokio::task::spawn_blocking` or `rayon`.

```rust
let result = tokio::task::spawn_blocking(|| heavy_computation()).await?;
```

**Deep reference**: [async-and-concurrency.md](./references/async-and-concurrency.md)

---

## 6. Macros & Metaprogramming

- **`macro_rules!`**: declarative token pattern matching for eliminating repetitive boilerplate or variadic helpers.
- **Procedural macros** (`#[derive]`, attribute, function-like): isolate in a dedicated `proc-macro = true` crate using `syn`, `quote`, and `proc-macro2`.

**Deep reference**: [macros-and-metaprogramming.md](./references/macros-and-metaprogramming.md)

---

## 7. Testing

- **Unit tests**: co-located in `#[cfg(test)] mod tests` within the same file.
- **Integration tests**: standalone files in `tests/` exercising only the public API.
- **Doc tests**: executable examples inside `///` doc comments verified by `cargo test`.

---

## 8. Cargo & Workspaces

- Use **Cargo Workspaces** (`resolver = "3"`, `[workspace.dependencies]`) for multi-crate repositories.
- Audit dependencies with `cargo audit` and keep feature flags minimal.

**Deep reference**: [modern-ecosystem.md](./references/modern-ecosystem.md)

---

## 9. Approved Ecosystem Crates

| Category | Standard Crate |
|:---------|:---------------|
| CLI | `clap` (derive) |
| Serialization | `serde`, `serde_json` |
| Async Runtime | `tokio` |
| HTTP Client | `reqwest` |
| Web Framework | `axum` |
| Database | `sqlx` (compile-time checked SQL) |
| Errors (lib / app) | `thiserror` / `anyhow` |
| Observability | `tracing`, `tracing-subscriber` |
| Benchmarking | `criterion` |

---

## 10. Mandatory Quality Gates

Every Rust change must pass [`scripts/verify-rust.sh`](./scripts/verify-rust.sh):

```bash
cargo fmt -- --check
cargo check
cargo clippy --all-targets --all-features -- -D warnings
cargo test
```
