---
name: rust-developer
description: >-
  Rust development skill based on roadmap.sh Rust fundamentals. Enforces idiomatic Rust: ownership, borrowing, lifetimes, zero-cost abstractions, robust error handling without unwrap, safe concurrency, and Cargo toolchain standards. Use whenever creating, reviewing, refactoring, or debugging Rust code.
---

# Rust Developer Skill

Pedoman rekayasa Rust berbasis kurikulum fundamental roadmap.sh.

## 1. Memory Safety & Ownership (Pillar Utama)

- **Ownership & Move**:
  - Tiap nilai punya tepat satu variabel pemilik.
  - Saat owner keluar dari scope, nilai di-drop otomatis (RAII).
  - Tipe non-`Copy` otomatis pindah kepemilikan (*move*). Jangan gunakan `.clone()` sembarangan hanya untuk menenangkan compiler; pahami alur data dan gunakan borrowing.
- **Borrowing Rules**:
  - Boleh banyak referensi baca (*immutable borrow*: `&T`) **ATAU** tepat satu referensi tulis (*mutable borrow*: `&mut T`), tidak boleh keduanya bersamaan dalam scope hidup yang sama.
  - Cegah pointer dangling dan data race saat kompilasi.
- **Slices**:
  - Utamakan slice sebagai argumen fungsi: gunakan `&str` bukan `&String`, `&[T]` bukan `&Vec<T>`.
- **Lifetimes (`'a`)**:
  - Percayakan pada *lifetime elision rules* untuk fungsi umum.
  - Tulis anotasi eksplisit hanya saat compiler butuh disambiguasi hubungan antar-referensi pada struct atau signature fungsi.

## 2. Idiomatic Error Handling

- **Larangan `unwrap()` / `expect()`**:
  - Haram di kode produksi. Hanya boleh di unit test atau prototipe sekali pakai yang diverifikasi.
  - Gunakan `Option<T>` untuk ketiadaan nilai yang valid, dan `Result<T, E>` untuk operasi yang bisa gagal.
  - Propagasikan error memakai operator `?`.
- **Standar Crate Error**:
  - **Library / Core Domain**: Gunakan `thiserror` untuk membuat enum error bertipe kuat dan terstruktur.
  - **Application / Binary / CLI**: Gunakan `anyhow` (atau `color-eyre`) untuk penanganan error tingkat atas dengan context (`with_context`).

## 3. Types, Traits & Abstraksi

- **Data Modeling**:
  - Gunakan `enum` dengan data (algebraic data types) untuk state machine dan representasi domain yang mustahil salah (*make illegal states unrepresentable*).
  - Gunakan `match` komprehensif atau `if let` untuk destructuring.
- **Zero-Cost Abstractions**:
  - Pilih static dispatch (generics `T: Trait` atau `impl Trait`) secara default untuk performa dan inlining kompilator.
  - Gunakan dynamic dispatch (`Box<dyn Trait>` / `&dyn Trait`) hanya jika koleksi heterogen memang dibutuhkan.
- **Functional Iterators**:
  - Utamakan rantai iterator (`map`, `filter`, `fold`) daripada loop `for` berbasis indeks manual untuk optimasi bounds-check.

## 4. Concurrency & Asynchronous Programming

- **Fearless Concurrency**:
  - Kirim data antar-thread via message passing (`std::sync::mpsc` atau `crossbeam-channel`).
  - Untuk shared mutable state antar-thread: bungkus dengan `Arc<Mutex<T>>` atau `Arc<RwLock<T>>`.
  - Pastikan tipe mengimplementasikan `Send` dan `Sync` dengan benar.
- **Async Runtime**:
  - Standar ekosistem: `tokio` (multi-threaded runtime).
  - Jangan memblokir thread async dengan I/O sinkron atau komputasi CPU intensif; gunakan `tokio::task::spawn_blocking`.

## 5. Ekosistem Crate Terstandar

| Kategori | Crate Pilihan |
| :--- | :--- |
| **CLI** | `clap` (derive feature) |
| **Serialization** | `serde`, `serde_json` |
| **Async Runtime** | `tokio` |
| **HTTP Client / Web** | `reqwest` / `axum` |
| **Database** | `sqlx` (compile-time verified queries) |
| **Error Handling** | `thiserror` (lib), `anyhow` (bin) |
| **Logging / Tracing** | `tracing`, `tracing-subscriber` |

## 6. Verification & Quality Gate

Setiap perubahan kode Rust wajib lolos verifikasi berikut:

```bash
# Jalankan script verifikasi
./skills/rust-developer/scripts/verify-rust.sh

# Atau perintah individual:
cargo fmt -- --check
cargo check
cargo clippy --all-targets --all-features -- -D warnings
cargo test
```
