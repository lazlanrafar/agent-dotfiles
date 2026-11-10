---
name: rust-developer
description: >-
  Rust development skill based on roadmap.sh Rust fundamentals and official rust-lang.org/learn documentation.
  Enforces idiomatic Rust 2024: ownership, borrowing, lifetimes, zero-cost abstractions, robust error
  handling without unwrap, safe concurrency, async/await, macros, and modern ecosystem standards.
  Use whenever creating, reviewing, refactoring, or debugging Rust code.
---

# Rust Developer Skill

Pedoman rekayasa Rust berbasis kurikulum roadmap.sh + rust-lang.org/learn (The Book, Rust by Example, Rustonomicon).

> **Lihat referensi mendalam di folder `references/`** — dimuat hanya saat dibutuhkan:
> - [Memory, Lifetimes & Smart Pointers](./references/memory-and-lifetimes.md)
> - [Traits, Generics & Type-Level Programming](./references/traits-generics-types.md)
> - [Concurrency, Async & Parallelism](./references/async-and-concurrency.md)
> - [Macros & Metaprogramming](./references/macros-and-metaprogramming.md)
> - [Cargo, Workspace & Ekosistem Modern](./references/modern-ecosystem.md)

---

## 1. Memory Safety & Ownership (Core Pillar)

- **3 Hukum Ownership**: satu pemilik, satu waktu, drop otomatis saat keluar scope (RAII).
- **Borrowing**: banyak `&T` (read) XOR satu `&mut T` (write) — tidak boleh bersamaan.
- **Slice over owning**: argumen fungsi pakai `&str` bukan `&String`, `&[T]` bukan `&Vec<T>`.
- **No clone tanpa alasan**: pahami alur data dan gunakan borrowing. Clone hanya jika semantik independen memang diperlukan.
- **Non-Lexical Lifetimes**: borrow checker Rust 2018+ mengakhiri borrow saat last-use, bukan end-of-block.

**Referensi mendalam**: [memory-and-lifetimes.md](./references/memory-and-lifetimes.md)

---

## 2. Idiomatic Error Handling

- **Haram `unwrap()` / `expect()`** di kode produksi. Hanya boleh di unit test atau prototipe one-off.
- **`Option<T>`** untuk nilai yang mungkin tidak ada. **`Result<T, E>`** untuk operasi yang bisa gagal.
- Propagasikan error dengan operator `?`.
- **Library / core domain**: pakai `thiserror` — enum error bertipe kuat.
- **Application / binary**: pakai `anyhow` — error kontekstual dengan `.context()`.

```rust
// thiserror
#[derive(thiserror::Error, Debug)]
pub enum AppError {
    #[error("not found: {0}")]
    NotFound(String),
    #[error("database error")]
    Db(#[from] sqlx::Error),
}

// anyhow
fn load() -> anyhow::Result<Config> {
    let s = std::fs::read_to_string("config.toml")
        .context("missing config.toml")?;
    Ok(toml::from_str(&s)?)
}
```

---

## 3. Types, Traits & Abstraksi

- **Static dispatch default** (`impl Trait` / generics): zero-cost, compiler inline.
- **Dynamic dispatch** (`Box<dyn Trait>`) hanya untuk koleksi heterogen atau return type dinamis.
- **Enum sebagai ADT**: modelkan state machine dengan `enum` agar illegal states impossible.
- **Iterator chains** atas `for` loop manual dengan index.
- **Newtype pattern**: bungkus tipe eksternal untuk impl trait (atasi Orphan Rule).

**Referensi mendalam**: [traits-generics-types.md](./references/traits-generics-types.md)

---

## 4. Smart Pointers & Interior Mutability

| Tipe | Kegunaan | Thread Safe? |
|:-----|:---------|:-------------|
| `Box<T>` | Alokasi heap, single owner | Ya |
| `Rc<T>` | Multiple ownership, single-thread | **Tidak** |
| `Arc<T>` | Multiple ownership, multi-thread | **Ya** |
| `Cell<T>` | Interior mutability untuk `Copy` | Tidak |
| `RefCell<T>` | Interior mutability, runtime check | Tidak |
| `Cow<'a, B>` | Clone-on-write adaptif | - |
| `Weak<T>` | Non-owning ref, cegah cycle | - |

Gunakan `Weak<T>` untuk referensi balik (parent-child, observer) guna mencegah memory leak.

---

## 5. Concurrency & Async

- **Message passing** (`mpsc::channel`, `crossbeam`) over shared mutable state.
- **Shared state**: `Arc<Mutex<T>>` atau `Arc<RwLock<T>>` — satu lock, satu resource.
- **Async runtime**: `tokio` (standar ekosistem). Jangan blokir async thread dengan sync I/O.
- **I/O-bound → async**, **CPU-bound → `spawn_blocking` atau thread / `rayon`**.
- Pastikan tipe yang di-share antar-thread implement `Send + Sync`.

```rust
// CPU-bound di dalam async context
let result = tokio::task::spawn_blocking(|| heavy_computation()).await?;
```

**Referensi mendalam**: [async-and-concurrency.md](./references/async-and-concurrency.md)

---

## 6. Macros & Metaprogramming

- **`macro_rules!`**: pattern matching atas token, untuk DSL kecil dan variadic args.
- **Procedural macros**: butuh crate terpisah (`proc-macro = true`), gunakan `syn` + `quote`.
  - `#[derive(...)]`: generate trait impl otomatis.
  - Attribute macro: transformasi fungsi/struct.
  - Function-like: parsing kustom.

**Referensi mendalam**: [macros-and-metaprogramming.md](./references/macros-and-metaprogramming.md)

---

## 7. Testing

```bash
cargo test                              # Semua test
cargo test -- --nocapture              # Tampilkan stdout
cargo test integration                 # Filter nama test
#[tokio::test]                         # Async test
```

- Unit test: dalam modul `#[cfg(test)]` di file yang sama.
- Integration test: file di `tests/` — hanya akses public API.
- Doc test: contoh kode dalam `///` komentar — dijalankan `cargo test`.

---

## 8. Cargo & Workspace

```bash
cargo check                            # Cepat: validasi tanpa build
cargo clippy --all-targets -- -D warnings
cargo fmt -- --check
cargo doc --open
cargo audit                            # Cek CVE
```

Gunakan **Cargo Workspace** untuk monorepo (multiple crates). Gunakan `workspace.dependencies` untuk share versi.

**Referensi mendalam**: [modern-ecosystem.md](./references/modern-ecosystem.md)

---

## 9. Crate Standar yang Disetujui

| Kategori | Crate |
|:---------|:------|
| CLI | `clap` (derive feature) |
| Serialization | `serde`, `serde_json` |
| Async Runtime | `tokio` |
| HTTP Client | `reqwest` |
| Web Framework | `axum` |
| Database | `sqlx` (compile-time query check) |
| Error (lib) | `thiserror` |
| Error (app) | `anyhow` |
| Logging | `tracing`, `tracing-subscriber` |
| Benchmark | `criterion` |

---

## 10. Quality Gate Wajib

Setiap perubahan kode Rust wajib lolos:

```bash
./skills/rust-developer/scripts/verify-rust.sh
# Atau individual:
cargo fmt -- --check
cargo check
cargo clippy --all-targets --all-features -- -D warnings
cargo test
```
