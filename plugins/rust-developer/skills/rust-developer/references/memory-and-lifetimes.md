# Memory Management, Lifetimes & Smart Pointers

Referensi mendalam berdasarkan The Rust Book Ch.4, 10, 15 dan Rustonomicon.

## Stack vs Heap

- Stack: ukuran tetap saat compile-time, LIFO, sangat cepat.
- Heap: ukuran dinamis, butuh pointer, `Box<T>` sebagai penghubung.
- **Aturan agen**: jika data bisa stack (ukuran tetap), jangan paksakan ke heap.

## Ownership Rules (3 Hukum Inti)

1. Tiap nilai punya tepat satu pemilik.
2. Hanya boleh ada satu pemilik di satu waktu.
3. Pemilik keluar scope → nilai di-`drop` otomatis (RAII, seperti destructor C++).

## Move Semantics vs Copy

- Tipe yang implement `Copy` (integers, `bool`, `char`, tuples kecil): otomatis di-copy saat assign.
- Tipe non-`Copy` (`String`, `Vec<T>`, custom struct): **move** saat assign — pemilik lama tidak valid lagi.
- `clone()` adalah deep copy eksplisit: pakai hanya jika memang dibutuhkan semantik independen.

## Borrowing & References

```rust
// Shared borrow: banyak reader, immutable
fn read(s: &str) { ... }

// Mutable borrow: satu writer, exclusive
fn modify(s: &mut String) { ... }
```

**Aturan ketat borrow checker**:
- Boleh banyak `&T` aktif secara bersamaan, ATAU
- Tepat satu `&mut T` aktif — tidak boleh ada `&T` lain bersamaan.

**Non-Lexical Lifetimes (NLL)**: Rust 2018+ mengakhiri borrow saat referensi terakhir dipakai, bukan saat keluar scope blok. Efektif: borrow checker lebih fleksibel.

## Lifetime Annotations

```rust
// Elision: compiler tahu lifetime tanpa anotasi
fn first_word(s: &str) -> &str { ... }

// Perlu anotasi: compiler tidak bisa menyimpulkan mana yang hidup lebih lama
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// Struct menyimpan reference: wajib anotasi
struct Excerpt<'a> {
    part: &'a str,
}
```

**3 Lifetime Elision Rules**:
1. Tiap parameter `&` dapat lifetime parameter sendiri.
2. Jika tepat satu input lifetime, output pakai lifetime yang sama.
3. Jika ada `&self` / `&mut self`, output pakai lifetime `self`.

**Variance** (Rustonomicon):
- `&'a T` adalah *covariant* atas `'a` dan `T`: `'long <: 'short` → `&'long T` dapat dipakai di tempat `&'short T`.
- `&'a mut T` adalah *invariant* atas `T`: tidak boleh substitusi subtipe untuk mencegah data race.

## Smart Pointers

| Tipe | Kegunaan | Thread Safe? |
|:-----|:---------|:-------------|
| `Box<T>` | Alokasi heap, owned, tidak ada overhead runtime | Ya (data di-move, bukan shared) |
| `Rc<T>` | Multiple ownership, reference counted | **Tidak** (single-thread only) |
| `Arc<T>` | Multiple ownership, atomic reference counted | **Ya** |
| `Cell<T>` | Interior mutability untuk `Copy` types | Tidak |
| `RefCell<T>` | Interior mutability, runtime borrow check | Tidak |
| `Mutex<T>` | Mutual exclusion, interior mutability | **Ya** |
| `RwLock<T>` | Multi-reader / single-writer | **Ya** |
| `Cow<'a, B>` | Clone-on-write: borrowed atau owned adaptif | - |

**Deref Coercion**: `Box<T>`, `Rc<T>`, `Arc<T>` impl `Deref` → otomatis dereference saat diperlukan.
**Drop trait**: saat keluar scope, Rust panggil `drop` secara otomatis — jangan panggil manual kecuali via `std::mem::drop(val)`.

### Hindari Reference Cycle

`Rc<RefCell<T>>` bisa buat siklus memori yang tidak ter-drop. Gunakan `Weak<T>` untuk referensi balik (parent-child tree, observer pattern):

```rust
use std::rc::{Rc, Weak};
use std::cell::RefCell;

struct Node {
    children: Vec<Rc<RefCell<Node>>>,
    parent: Option<Weak<RefCell<Node>>>,  // Weak, bukan Rc!
}
```
