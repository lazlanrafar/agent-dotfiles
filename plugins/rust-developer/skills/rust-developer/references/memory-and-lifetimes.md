# Memory Management, Lifetimes & Smart Pointers

Deep reference based on The Rust Book (Ch. 4, 10, 15) and the Rustonomicon.

## Stack vs. Heap

- **Stack**: fixed size known at compile time, LIFO allocation, cache-friendly and fast.
- **Heap**: dynamic size or lifetime beyond a single call frame, managed via smart pointers (`Box<T>`, `Vec<T>`, `String`).
- **Rule**: keep fixed-size values on the stack unless indirection, recursive types, or large ownership transfers require heap allocation.

## Ownership Rules

1. Every value in Rust has a single owner.
2. There can only be one owner at a time.
3. When the owner goes out of scope, the value is automatically dropped (`Drop` trait / RAII).

## Move Semantics vs. `Copy`

- Types implementing `Copy` (scalars, `bool`, `char`, shared references `&T`, tuples/arrays of `Copy` types) are duplicated via bitwise copy on assignment.
- Non-`Copy` types (`String`, `Vec<T>`, `Box<T>`, custom structs) **move** ownership on assignment — the previous binding becomes invalidated at compile time.
- `.clone()` performs an explicit deep copy; call it only when independent ownership is intentionally needed.

## Borrowing & References

```rust
fn read(s: &str) { /* shared, immutable borrow */ }
fn modify(s: &mut String) { /* exclusive, mutable borrow */ }
```

- Either any number of shared references (`&T`) OR exactly one mutable reference (`&mut T`) may be active at the same time.
- **Non-Lexical Lifetimes (NLL)**: a borrow ends at the last point the reference is used, not at the end of the enclosing lexical block.

## Lifetime Annotations

```rust
// Elided: compiler infers lifetimes automatically
fn first_word(s: &str) -> &str { ... }

// Explicit: output lifetime is tied to the shorter of x and y
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// Struct holding a reference requires an explicit lifetime parameter
struct Excerpt<'a> {
    part: &'a str,
}
```

**Three Lifetime Elision Rules**:
1. Each elided reference parameter gets its own distinct lifetime parameter.
2. If there is exactly one input lifetime parameter, that lifetime is assigned to all elided output lifetimes.
3. If one of the parameters is `&self` or `&mut self`, the lifetime of `self` is assigned to all elided output lifetimes.

**Variance** (Rustonomicon):
- `&'a T` is *covariant* over both `'a` and `T` (`'long: 'short` allows passing `&'long T` where `&'short T` is expected).
- `&'a mut T` is *covariant* over `'a` but *invariant* over `T` to prevent type-unsound mutation.

## Smart Pointers & Reference Cycles

| Type | Use Case | Thread-Safe? |
|:-----|:---------|:-------------|
| `Box<T>` | Single-owner heap allocation | Yes |
| `Rc<T>` | Reference-counted shared ownership | **No** |
| `Arc<T>` | Atomic reference-counted shared ownership | **Yes** |
| `Cell<T>` | Zero-overhead interior mutability for `Copy` types | No |
| `RefCell<T>` | Single-threaded dynamic borrow checking | No |
| `Mutex<T>` / `RwLock<T>` | Synchronized multi-threaded interior mutability | **Yes** |
| `Cow<'a, B>` | Clone-on-write abstraction over borrowed or owned data | Yes (if `B: Sync`) |

### Breaking Reference Cycles with `Weak<T>`

Combining `Rc<RefCell<T>>` (or `Arc<Mutex<T>>`) in cyclic graphs leaks memory because strong counts never reach zero. Use `Weak<T>` for parent or observer back-references:

```rust
use std::cell::RefCell;
use std::rc::{Rc, Weak};

struct Node {
    children: Vec<Rc<RefCell<Node>>>,
    parent: Option<Weak<RefCell<Node>>>, // Weak prevents reference cycles
}
```
