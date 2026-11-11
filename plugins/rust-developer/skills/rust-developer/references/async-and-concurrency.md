# Concurrency, Async & Parallelism

Deep reference based on The Rust Book (Ch. 16 Fearless Concurrency & Ch. 17 Async/Await).

## Fearless Concurrency (`Send` & `Sync`)

- **`Send`**: safe to transfer ownership across thread boundaries (almost all types except `Rc<T>` and raw pointers).
- **`Sync`**: safe to share immutable references (`&T`) across threads simultaneously (`T: Sync` iff `&T: Send`; excludes `Cell<T>` and `RefCell<T>`).

### Message Passing (`mpsc`)

```rust
use std::sync::mpsc;
use std::thread;

let (tx, rx) = mpsc::channel();
thread::spawn(move || {
    tx.send(String::from("work item")).unwrap();
});

for msg in rx {
    println!("received: {msg}");
}
```

### Shared State (`Arc<Mutex<T>>`)

```rust
use std::sync::{Arc, Mutex};
use std::thread;

let counter = Arc::new(Mutex::new(0));
let handles: Vec<_> = (0..4)
    .map(|_| {
        let counter = Arc::clone(&counter);
        thread::spawn(move || {
            *counter.lock().unwrap() += 1;
        })
    })
    .collect();

for h in handles {
    h.join().unwrap();
}
```

- **Deadlock Prevention**: acquire locks in a consistent order, keep critical sections minimal, and never hold a synchronous `MutexGuard` across an `.await` suspension point.

## Async / Await with Tokio

`async fn` returns a lazy `Future` state machine driven by an executor (`tokio`).

```rust
use tokio::time::{sleep, Duration};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let (a, b) = tokio::try_join!(fetch_a(), fetch_b())?;
    Ok(())
}

async fn fetch_a() -> anyhow::Result<String> {
    sleep(Duration::from_millis(50)).await;
    Ok(String::from("a"))
}
```

### Never Block the Async Executor

```rust
// WRONG: blocks the Tokio worker thread
async fn bad() {
    std::thread::sleep(Duration::from_secs(1));
}

// RIGHT: offload blocking I/O or CPU work to the blocking pool
async fn good() -> anyhow::Result<u64> {
    let res = tokio::task::spawn_blocking(|| heavy_cpu_work()).await?;
    Ok(res)
}
```

## Atomic Operations

Use `std::sync::atomic` (`AtomicBool`, `AtomicUsize`, `AtomicU64`) for lock-free counters and flags:
- `Ordering::Relaxed`: independent counters where relative ordering of other memory accesses does not matter.
- `Ordering::Acquire` / `Ordering::Release`: synchronize state publication between producer and consumer threads.
- `Ordering::SeqCst`: globally consistent ordering across all threads.
