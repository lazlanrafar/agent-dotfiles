---
name: python-developer
description: >-
  Python development skill based on roadmap.sh/python and official docs.python.org/3.
  Enforces idiomatic Python 3.12+: type hints, structural pattern matching, dataclasses,
  async/await, robust error handling, modern packaging (uv/pyproject.toml), and testing
  with pytest. Use whenever creating, reviewing, refactoring, or debugging Python code.
---

# Python Developer Skill

Pedoman rekayasa Python berbasis kurikulum roadmap.sh/python + docs.python.org/3 (Tutorial, Library Reference, HOWTOs, Typing docs).

> **Lihat referensi mendalam di folder `references/`** — dimuat hanya saat dibutuhkan:
> - [Language Fundamentals](./references/language-fundamentals.md)
> - [OOP, Protocols & Functional](./references/oop-and-functional.md)
> - [Concurrency & Async](./references/concurrency-and-async.md)
> - [Type System & Testing](./references/type-system-and-testing.md)
> - [Modern Ecosystem](./references/modern-ecosystem.md)
> - [Data Analysis, Visualization & Pipelines](./references/data-analysis-and-pipelines.md)

---

## 1. Environment Setup

- Python versi aktif: **3.12+**. Gunakan `pyenv` untuk manajemen versi multi-Python.
- Package manager: **`uv`** (default, cepat, Rust-based). Fallback: `pip` + `venv`.
- Project dependency: **`pyproject.toml`** (PEP 517/518/621) — bukan `setup.py` atau `requirements.txt` naked.
- Virtual environment: selalu isolasi, jangan install global kecuali tool dev (uv, mypy, ruff).

```bash
# setup project baru
uv init myproject && cd myproject
uv add fastapi uvicorn         # dependency runtime
uv add --dev ruff mypy pytest  # dev tools
```

---

## 2. Idiomatic Python (Core Pillar)

- **Explicit beats implicit** (PEP 20). Jangan clever kecuali perlu.
- **Comprehensions** atas `map`/`filter` bare: `[x*2 for x in items if x > 0]`.
- **f-string** (3.12 `f"{val!r}"`, `f"{val:{width}.{prec}f}"`), bukan `%` atau `.format()`.
- **`pathlib.Path`** bukan `os.path` string concatenation.
- **Context manager (`with`)** wajib untuk resource: file, DB connection, lock, HTTP session.
- **`dataclasses`** atau **`attrs`** untuk data containers. `NamedTuple` untuk immutable value objects.
- **Structural Pattern Matching** (`match`/`case`, PEP 634) untuk dispatch kompleks — bukan `if/elif` chain panjang.

```python
# dataclass + match
from dataclasses import dataclass

@dataclass
class Point:
    x: float
    y: float

def describe(p: Point) -> str:
    match p:
        case Point(x=0, y=0): return "origin"
        case Point(x=0, y=y): return f"y-axis at {y}"
        case Point(x=x, y=0): return f"x-axis at {x}"
        case _: return f"({p.x}, {p.y})"
```

---

## 3. Type Safety (Mandatory)

- **Semua kode produksi wajib type-annotated** — argumen, return type, class attributes.
- Gunakan `from __future__ import annotations` di file yang butuh forward reference.
- `Optional[X]` → `X | None` (Python 3.10+). `Union[X, Y]` → `X | Y`.
- **`TypeVar`, `Generic[T]`** untuk fungsi/class polimorfik.
- **Protocols** (`typing.Protocol`) untuk structural subtyping — hindari ABC jika protocol cukup.
- Jalankan **`mypy --strict`** di CI. Nol error, nol `type: ignore` tanpa komentar alasan.
- **Pydantic v2** untuk validation data eksternal (API request/response, env config).

```python
from typing import Protocol

class Drawable(Protocol):
    def draw(self) -> None: ...

def render(item: Drawable) -> None:
    item.draw()  # works for ANY class with draw(), no inheritance needed
```

**Referensi mendalam**: [type-system-and-testing.md](./references/type-system-and-testing.md)

---

## 4. Error Handling

- **Haram `except Exception: pass`** — selalu log atau re-raise dengan konteks.
- Tangkap exception **spesifik**, bukan `Exception` bare kecuali top-level handler.
- Gunakan **`contextlib.suppress()`** hanya untuk error yang memang expected dan boleh diabaikan.
- Custom exception: turunkan dari domain base class, bukan langsung `Exception`.
- **`ExceptionGroup`** (Python 3.11+) untuk propagasi multi-error dari async task group.

```python
class AppError(Exception): ...
class NotFoundError(AppError): ...
class ValidationError(AppError): ...

def get_user(uid: int) -> User:
    user = db.find(uid)
    if user is None:
        raise NotFoundError(f"user {uid} not found")
    return user
```

---

## 5. Functions & Decorators

- **Pure functions** where possible — no side effects, predictable output.
- `*args`, `**kwargs` hanya jika benar-benar variadic. Explicit signature lebih baik.
- **`functools.cache` / `functools.lru_cache`** untuk memoization — bukan manual dict.
- Decorator order: paling luar dieksekusi terakhir. `@wraps(func)` wajib di decorator custom.
- **`functools.partial`** untuk currying sederhana; `operator` module untuk fungsi operator.

```python
import functools

def retry(times: int = 3):
    def decorator(fn):
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            for attempt in range(times):
                try:
                    return fn(*args, **kwargs)
                except Exception:
                    if attempt == times - 1:
                        raise
        return wrapper
    return decorator
```

---

## 6. Data Structures & Algorithms

- **`collections`**: `defaultdict`, `Counter`, `deque`, `OrderedDict`, `ChainMap` — stdlib first.
- **`heapq`** untuk priority queue, **`bisect`** untuk binary search pada sorted list.
- **Generator expressions** untuk lazy sequence — hemat memori pada data besar.
- **`itertools`**: `chain`, `islice`, `groupby`, `product`, `combinations`, `permutations`.
- Dict guaranteed ordered (Python 3.7+). `frozenset` untuk hashable set.

```python
from collections import Counter
from itertools import groupby

words = ["cat", "bat", "cat", "rat", "bat", "cat"]
freq = Counter(words)       # Counter({'cat': 3, 'bat': 2, 'rat': 1})
top2 = freq.most_common(2)  # [('cat', 3), ('bat', 2)]
```

---

## 7. Async & Concurrency

- **`asyncio`** untuk I/O-bound concurrency (HTTP, DB, file). Jangan block event loop.
- **`async def` + `await`** — hindari `asyncio.run()` bersarang; satu event loop per program.
- **`asyncio.TaskGroup`** (Python 3.11+) untuk structured concurrency — bukan `gather()` bare.
- CPU-bound: **`multiprocessing`** atau `concurrent.futures.ProcessPoolExecutor`.
- Thread-safe shared state: **`asyncio.Lock`**, `threading.Lock`, `queue.Queue`.
- Hindari mixing sync dan async naif — gunakan `asyncio.to_thread()` untuk call sync blocking.

```python
import asyncio
import httpx

async def fetch_all(urls: list[str]) -> list[str]:
    async with httpx.AsyncClient() as client:
        async with asyncio.TaskGroup() as tg:
            tasks = [tg.create_task(client.get(url)) for url in urls]
    return [t.result().text for t in tasks]
```

**Referensi mendalam**: [concurrency-and-async.md](./references/concurrency-and-async.md)

---

## 8. Testing

- **`pytest`** — bukan `unittest` (kecuali legacy). Pakai fixtures, parametrize, marks.
- Naming: `test_<what>_<condition>_<expected>`. Satu assertion per test jika memungkinkan.
- **`pytest-cov`** untuk coverage — target ≥ 80% line coverage pada produksi code.
- Mock: **`unittest.mock.patch`** / `pytest-mock`. Mock hanya di boundary (HTTP, DB, OS).
- **Property-based testing**: `hypothesis` untuk invariant dan edge case otomatis.
- Organisasi: `tests/unit/`, `tests/integration/`, `tests/e2e/`.

```python
import pytest
from myapp.math import divide

def test_divide_by_zero_raises():
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

@pytest.mark.parametrize("a,b,expected", [(10, 2, 5), (9, 3, 3)])
def test_divide(a, b, expected):
    assert divide(a, b) == expected
```

**Referensi mendalam**: [type-system-and-testing.md](./references/type-system-and-testing.md)

---

## 9. Modules, Packages & Import

- Satu module = satu responsibility. Hindari circular import.
- **`__init__.py`** minimal — jangan import semua; expose hanya public API.
- **`__all__`** di module untuk kontrol `from module import *`.
- **Relative import** di dalam package: `from .utils import helper`. Absolute di script entry.
- **`importlib`** untuk dynamic import; **`importlib.resources`** untuk bundled data files.
- Hindari `sys.path` manipulation — gunakan proper package install atau editable install (`uv pip install -e .`).

---

## 10. Code Quality Gates

Jalankan sebelum commit / di CI:

```bash
ruff format --check .      # format check (Black-compatible)
ruff check .               # linting (replaces flake8, isort, pyupgrade)
mypy . --strict            # type checking
pytest --cov=src --cov-report=term-missing
```

Tool config di `pyproject.toml`:

```toml
[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "UP", "I", "N", "ANN", "S", "B", "C4", "PTH"]

[tool.mypy]
python_version = "3.12"
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-ra -q"
```

**Script lengkap**: [`scripts/verify-python.sh`](./scripts/verify-python.sh)
