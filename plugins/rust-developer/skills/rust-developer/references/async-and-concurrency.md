# Concurrency, Async & Parallelism

Berdasarkan The Rust Book Ch.16 (Fearless Concurrency) & Ch.17 (Async/Await).

## Fearless Concurrency

Ownership & type system menjamin: jika kode compile, tidak ada data race.

### Threads

```rust
use std::thread;
use std::time::Duration;

let handle = thread::spawn(|| {
    // closure di-move: owns all captured values
    for i in 1..10 { println!("thread: {}", i); }
});

handle.join().unwrap(); // tunggu thread selesai
```

**`move` closure wajib** jika closure dibawa ke thread lain agar ownership jelas.

### Message Passing (mpsc Channel)

```rust
use std::sync::mpsc;

let (tx, rx) = mpsc::channel();

let tx_clone = tx.clone(); // boleh banyak sender
thread::spawn(move || {
    tx.send(String::from("hello")).unwrap();
});

for msg in rx { // rx adalah iterator: drain sampai semua sender di-drop
    println!("Got: {}", msg);
}
```

**Prinsip Go**: "Do not communicate by sharing memory; share memory by communicating."

### Shared State: Arc + Mutex

```rust
use std::sync::{Arc, Mutex};
use std::thread;

let counter = Arc::new(Mutex::new(0));

let handles: Vec<_> = (0..10).map(|_| {
    let counter = Arc::clone(&counter);
    thread::spawn(move || {
        let mut num = counter.lock().unwrap();
        *num += 1;
    })
}).collect();

for h in handles { h.join().unwrap(); }
println!("Result: {}", *counter.lock().unwrap()); // 10
```

**Hindari deadlock**:
- Acquire lock dalam urutan yang konsisten.
- Jangan hold lock saat memanggil fungsi eksternal yang bisa block.
- Pertimbangkan `try_lock()` untuk non-blocking attempt.

### Send & Sync Traits

- `Send`: tipe aman untuk berpindah ke thread lain. Hampir semua tipe adalah `Send`. `Rc<T>` bukan.
- `Sync`: tipe aman untuk direferensikan dari banyak thread. `T: Sync` jika `&T: Send`. `Cell<T>`, `RefCell<T>` bukan.
- `Arc<T>` adalah `Send + Sync` jika `T: Send + Sync`.

## Async / Await

### Konsep Dasar

- **Concurrency** (async): satu thread, banyak tasks, cooperative multitasking.
- **Parallelism** (threads): beberapa thread, benar-benar bersamaan.
- **I/O-bound** → gunakan async. **CPU-bound** → gunakan thread / `rayon`.

### Futures & Runtime

`async fn` mengembalikan `Future` — struktur data yang merepresentasikan komputasi yang belum selesai. Future adalah *lazy*: tidak jalan sampai di-`.await` atau di-poll runtime.

```rust
use tokio::time::{sleep, Duration};

#[tokio::main]  // macro setup Tokio runtime
async fn main() {
    let result = fetch_data().await;
    println!("{}", result);
}

async fn fetch_data() -> String {
    sleep(Duration::from_millis(100)).await;
    String::from("data")
}
```

### Concurrency dengan Async

```rust
use tokio::task;

// Jalankan banyak future secara concurrent (bukan sequential)
let (res1, res2) = tokio::join!(fetch_a(), fetch_b());

// Jalankan sebagai task terpisah (seperti thread tapi lightweight)
let handle = task::spawn(async { fetch_data().await });
let result = handle.await.unwrap();
```

### Jangan Blokir Async Thread

```rust
// SALAH: blokir runtime async dengan operasi sync berat
async fn bad() {
    std::thread::sleep(Duration::from_secs(1));  // blokir seluruh thread!
}

// BENAR: gunakan spawn_blocking untuk kode sync/CPU-bound
async fn good() {
    tokio::task::spawn_blocking(|| {
        heavy_cpu_computation()
    }).await.unwrap();
}
```

### Streams (Async Iterator)

```rust
use tokio_stream::StreamExt;

let mut stream = tokio_stream::iter(vec![1, 2, 3]);
while let Some(val) = stream.next().await {
    println!("{}", val);
}
```

### Error Handling di Async

```rust
// ? operator bekerja sama di async fn
async fn read_file(path: &str) -> Result<String, io::Error> {
    let content = tokio::fs::read_to_string(path).await?;
    Ok(content)
}
```

## Atomic Operations

Untuk counter sederhana tanpa Mutex overhead:

```rust
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

let counter = Arc::new(AtomicUsize::new(0));
counter.fetch_add(1, Ordering::Relaxed);  // non-blocking increment

// Memory Ordering:
// Relaxed  : tidak ada guarantee urutan operasi lain
// Acquire  : operasi setelah ini tidak bisa diangkat sebelumnya (read barrier)
// Release  : operasi sebelum ini tidak bisa diturunkan setelahnya (write barrier)
// SeqCst   : total sequential consistency (paling aman, paling lambat)
```

**Aturan praktis**: `Relaxed` untuk counter independen. `Acquire`/`Release` untuk komunikasi antar-thread. `SeqCst` jika ragu.
