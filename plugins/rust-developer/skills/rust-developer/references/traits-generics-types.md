# Traits, Generics & Type-Level Programming

Deep reference based on The Rust Book (Ch. 10, 18, 20).

## Generics & Monomorphization

```rust
fn largest<T: PartialOrd>(list: &[T]) -> &T { ... }
```

Rust monomorphizes generic code at compile time, generating specialized machine code for each concrete type with zero runtime vtable overhead.

## Traits & The Orphan Rule

```rust
pub trait Summary {
    fn summarize(&self) -> String;
    fn preview(&self) -> String {
        format!("{}...", &self.summarize()[..20])
    }
}
```

- **Orphan Rule (Coherence)**: you can implement a trait for a type only if either the trait OR the type is local to your crate.
- **Newtype Pattern**: wrap an external type in a single-field tuple struct (`struct Wrapper(Vec<String>);`) to implement external traits or enforce domain invariants.

## Static vs. Dynamic Dispatch

```rust
// Static dispatch (preferred default)
fn notify(item: &impl Summary) { ... }

// Dynamic dispatch (for heterogeneous collections or runtime-selected types)
fn notify_all(items: &[Box<dyn Summary>]) { ... }
```

## Associated Types vs. Generic Type Parameters

```rust
// Associated type: one logical implementation per Self type
trait Iterator {
    type Item;
    fn next(&mut self) -> Option<Self::Item>;
}

// Generic parameter: multiple implementations per Self type (e.g. From<u32>, From<&str>)
trait From<T> {
    fn from(value: T) -> Self;
}
```

## Closures & Capture Modes

Closures automatically implement one or more of:
- `FnOnce`: consumes captured variables by value (callable once).
- `FnMut`: mutates captured variables via `&mut`.
- `Fn`: borrows captured variables immutably via `&` (or captures nothing).

```rust
let name = String::from("Alice");
std::thread::spawn(move || println!("Hello, {name}"));

fn make_adder(x: i32) -> impl Fn(i32) -> i32 {
    move |y| x + y
}
```

## Iterators & Zero-Cost Adapters

```rust
let sum_of_squares: i32 = (1..=10)
    .filter(|x| x % 2 == 0)
    .map(|x| x * x)
    .sum();
```

Iterator adapters (`map`, `filter`, `flat_map`, `fold`) are lazy and compile down to tight loops without intermediate allocations.
