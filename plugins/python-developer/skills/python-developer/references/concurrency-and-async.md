# Concurrency & Async — Python Developer Reference

Sumber: [docs.python.org/3/library/asyncio.html](https://docs.python.org/3/library/asyncio.html), [docs.python.org/3/library/concurrent.futures.html](https://docs.python.org/3/library/concurrent.futures.html), roadmap.sh/python

---

## Memilih Model Concurrency (GIL vs I/O vs CPU)

| Beban Kerja | Pilihan Utama | Alasan |
|-------------|---------------|--------|
| **I/O-bound tinggi** (ribuan koneksi HTTP/DB/WS) | `asyncio` | Satu thread, overhead konteks sangat ringan, tanpa race condition OS thread |
| **I/O-bound menengah / library sync** | `ThreadPoolExecutor` / `asyncio.to_thread` | Melepas GIL saat syscall I/O, mudah dipakai dengan library blocking |
| **CPU-bound** (komputasi angka, parsing berat) | `ProcessPoolExecutor` / `multiprocessing` | Bypass GIL dengan proses terpisah (atau Python 3.13+ free-threaded / `concurrent.interpreters`) |

---

## Structured Concurrency (`asyncio.TaskGroup`)

Di Python 3.11+, gunakan `asyncio.TaskGroup` dibanding `asyncio.gather()`. Jika satu task gagal, task lain otomatis di-cancel dengan aman dan error dikumpulkan dalam `ExceptionGroup`.

```python
import asyncio

async def fetch_item(item_id: int) -> dict[str, int]:
    await asyncio.sleep(0.1)
    if item_id < 0:
        raise ValueError("negative id")
    return {"id": item_id}

async def process_batch(ids: list[int]) -> list[dict[str, int]]:
    tasks: list[asyncio.Task[dict[str, int]]] = []
    try:
        async with asyncio.TaskGroup() as tg:
            for i in ids:
                tasks.append(tg.create_task(fetch_item(i)))
    except* ValueError as eg:
        for err in eg.exceptions:
            print(f"Validation error: {err}")
        raise
    return [t.result() for t in tasks]
```

---

## Timeouts & Cancellation

Gunakan `asyncio.timeout()` (Python 3.11+) sebagai context manager:

```python
import asyncio

async def fetch_with_deadline() -> str:
    try:
        async with asyncio.timeout(2.5):
            return await slow_network_call()
    except TimeoutError:
        return "fallback"
```

- **Jangan menelan `asyncio.CancelledError`!** Jika menangkap `BaseException` atau `CancelledError` untuk cleanup, wajib `raise` kembali agar cancellation tidak macet.

---

## Sinkronisasi & Pembatasan Beban (`Semaphore`, `Queue`, `ContextVar`)

```python
import asyncio
from contextvars import ContextVar

request_id_var: ContextVar[str] = ContextVar("request_id", default="unknown")

async def bounded_worker(sem: asyncio.Semaphore, url: str) -> None:
    async with sem:  # Batasi maksimal N request paralel
        await call_url(url)

async def producer_consumer() -> None:
    queue: asyncio.Queue[int | None] = asyncio.Queue(maxsize=100)

    async def producer() -> None:
        for i in range(10):
            await queue.put(i)
        await queue.put(None)  # poison pill

    async def consumer() -> None:
        while (item := await queue.get()) is not None:
            queue.task_done()
```

---

## Menjembatani Sync dan Async

- **Jangan panggil fungsi blocking (`time.sleep`, `requests.get`, CPU berat) langsung di dalam `async def`** karena akan membekukan seluruh event loop.
- Bungkus I/O blocking dengan `await asyncio.to_thread(blocking_fn, arg1)`.
- Bungkus komputasi CPU berat dengan `loop.run_in_executor(process_pool, cpu_fn, arg1)`.

```python
import asyncio
from concurrent.futures import ProcessPoolExecutor

def heavy_cpu(n: int) -> int:
    return sum(i * i for i in range(n))

async def main() -> None:
    loop = asyncio.get_running_loop()
    with ProcessPoolExecutor() as pool:
        result = await loop.run_in_executor(pool, heavy_cpu, 10_000_000)
```
