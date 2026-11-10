# Traits, Generics & Type-Level Programming

Berdasarkan The Rust Book Ch.10, Ch.18, Ch.20 (Advanced Traits & Types).

## Generics & Monomorphization

```rust
// Generic function: compiler generate konkret tiap tipe yang dipakai
fn largest<T: PartialOrd>(list: &[T]) -> &T { ... }
```

Monomorphization = zero runtime overhead. Tidak ada boxing, tidak ada virtual dispatch.

## Trait: Interface Rust

```rust
pub trait Summary {
    fn summarize(&self) -> String;
    fn preview(&self) -> String {  // Default implementation
        format!("{}...", &self.summarize()[..20])
    }
}
```

**Orphan Rule**: boleh impl trait untuk tipe hanya jika trait ATAU tipe didefinisikan dalam crate-mu. Mencegah konflik antar-library.

## Dispatch: Static vs Dynamic

```rust
// Static dispatch: compiler tahu tipe konkret saat compile — preferred
fn notify(item: &impl Summary) { ... }
fn notify<T: Summary>(item: &T) { ... }  // equivalent

// Dynamic dispatch: pakai saat koleksi heterogen atau return type tidak diketahui
fn returns_summarizable() -> Box<dyn Summary> { ... }
fn notify(items: &[Box<dyn Summary>]) { ... }
```

`dyn Trait` selalu berada di balik pointer (`Box`, `&`, `Arc`) karena Sized tidak diketahui.

## Trait Bounds & Where Clause

```rust
// Inline — OK untuk 1-2 bound
fn print<T: Display + Clone>(item: T) { ... }

// Where clause — lebih readable untuk multiple bound
fn some_function<T, U>(t: &T, u: &U) -> String
where
    T: Display + Clone,
    U: Clone + Debug,
{ ... }
```

## Associated Types vs Generic Parameters

```rust
// Associated type: satu implementasi per tipe — lebih ergonomis di site pemakaian
trait Iterator {
    type Item;
    fn next(&mut self) -> Option<Self::Item>;
}

// Generic param: boleh banyak impl untuk tipe yang sama
trait From<T> {
    fn from(value: T) -> Self;
}
```

Gunakan **Associated Type** jika hubungan "satu-ke-satu". Gunakan **Generic Param** jika tipe bisa impl trait untuk banyak parameter.

## Advanced Traits

### Newtype Pattern

Bungkus tipe external untuk impl trait (memotong Orphan Rule):

```rust
struct Wrapper(Vec<String>);
impl fmt::Display for Wrapper { ... }  // Vec<String> dari stdlib, Display dari stdlib
```

### Supertraits

```rust
trait OutlinePrint: fmt::Display {  // Implementor WAJIB impl Display dulu
    fn outline_print(&self) {
        let s = self.to_string();  // boleh pakai Display method
        println!("*{}*", s);
    }
}
```

### Fully Qualified Syntax

Saat banyak trait punya method dengan nama sama:

```rust
<Type as Trait>::method(&value);
// Contoh:
<Dog as Animal>::baby_name();
```

## Type Aliases

```rust
type Thunk = Box<dyn Fn() -> String + Send>;  // Alias untuk tipe panjang
type Result<T> = std::result::Result<T, io::Error>;  // Alias dengan default error
```

## Never Type `!`

```rust
// Fungsi yang tidak pernah return (diverging function)
fn server_loop() -> ! {
    loop { handle_connection(); }
}

// panic!, loop, continue, return punya tipe !
let guess: u32 = match guess.trim().parse() {
    Ok(num) => num,
    Err(_) => continue,  // ! dapat dicoerce ke tipe apapun
};
```

## Closures

Closures capture environment. Tiga trait closure:
- `FnOnce`: consume captured values (dipanggil sekali).
- `FnMut`: mutably borrow captured values.
- `Fn`: immutably borrow (atau tidak capture apapun).

```rust
// move closure: take ownership dari captured values (berguna untuk thread)
let name = String::from("Alice");
thread::spawn(move || println!("Hello, {}", name));

// Return closure dari function
fn make_adder(x: i32) -> impl Fn(i32) -> i32 {
    move |y| x + y
}
```

## Iterators & Lazy Evaluation

```rust
// Iterator adapters: lazy, zero-cost abstraction
let result: Vec<i32> = (1..=10)
    .filter(|x| x % 2 == 0)
    .map(|x| x * x)
    .collect();

// Custom Iterator
struct Counter { count: u32 }
impl Iterator for Counter {
    type Item = u32;
    fn next(&mut self) -> Option<u32> {
        if self.count < 5 { self.count += 1; Some(self.count) }
        else { None }
    }
}
```

**Aturan agen**: Gunakan iterator chains atas manual `for` loop dengan index kecuali perlu akses index explisit.
