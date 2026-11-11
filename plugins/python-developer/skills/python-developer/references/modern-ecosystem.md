# Modern Ecosystem — Python Developer Reference

Sumber: [docs.python.org/3/library/](https://docs.python.org/3/library/), [packaging.python.org](https://packaging.python.org/), roadmap.sh/python

---

## Standar Pemilihan Library (2025/2026)

Utamakan stdlib terlebih dahulu. Jika butuh paket eksternal, gunakan standar de-facto modern:

| Kebutuhan | Stdlib (Utamakan) | Ekosistem Modern (Jika butuh lebih) | Hindari / Legacy |
|-----------|-------------------|-------------------------------------|------------------|
| **Package & Env** | `venv` | **`uv`** | `pipenv`, `setup.py`, `easy_install` |
| **Linter & Formatter** | — | **`ruff`** | `flake8`, `black` + `isort` terpisah, `yapf` |
| **Type Checker** | — | **`mypy`** / **`pyright`** | Tanpa type check |
| **Testing** | `unittest` | **`pytest`** + `hypothesis` | `nose` |
| **Path & File** | **`pathlib`**, `shutil`, `tempfile` | — | `os.path` string manipulasi |
| **Konfigurasi TOML** | **`tomllib`** (3.11+ read-only) | `tomli-w` (write) | `toml` lama |
| **Data Validation** | `dataclasses` | **`pydantic` v2**, `msgspec` | `marshmallow` (untuk project baru) |
| **HTTP Client** | `urllib.request` | **`httpx`** (sync + async) | `urllib2`, `requests` di dalam kode async |
| **Web API / Server** | `wsgiref` | **`FastAPI`** / **`Litestar`** (API), **`Django`** (Full-stack) | `Flask` untuk async API murni |
| **Database / ORM** | **`sqlite3`** | **`SQLAlchemy 2.0`** (async), `psycopg` v3, `alembic` | `SQLAlchemy 1.x` query style (`session.query()`) |
| **CLI** | **`argparse`** | **`typer`** / `click` / `rich` | `optparse` |
| **Data & Numerik** | `statistics`, `decimal` | **`polars`**, `numpy`, `duckdb` | Loop Python murni pada jutaan baris |

---

## Project Layout (`src/` layout & `pyproject.toml`)

Gunakan `src/` layout agar test selalu menguji paket ter-install, bukan folder lokal secara tidak sengaja:

```
myproject/
├── pyproject.toml
├── README.md
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── py.typed        # Marker PEP 561 agar mypy membaca type hints paket ini
│       └── main.py
└── tests/
    ├── conftest.py
    └── test_main.py
```

Contoh `pyproject.toml` lengkap:

```toml
[project]
name = "myproject"
version = "0.1.0"
description = "Production Python service"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115.0",
    "pydantic>=2.10.0",
    "pydantic-settings>=2.6.0",
    "httpx>=0.28.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.0",
    "pytest-asyncio>=0.24.0",
    "pytest-cov>=6.0.0",
    "mypy>=1.13.0",
    "ruff>=0.8.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "UP", "I", "B", "SIM", "PTH", "RUF"]

[tool.mypy]
python_version = "3.12"
strict = true
```

---

## Observability & Structured Logging

- Jangan pakai `print()` di kode produksi. Gunakan modul `logging` atau `structlog`.
- Gunakan lazy formatting di `logging` (`logger.info("user %s logged in", user_id)`) atau extra dict agar tidak membebani string formatting saat level log tidak aktif.

```python
import logging

logger = logging.getLogger(__name__)

def process_order(order_id: str) -> None:
    logger.info("processing order", extra={"order_id": order_id})
```

---

## Security & Cryptography (`secrets`, SQL Injection, Subprocess)

1. **Token & Randomness**: Jangan pernah gunakan modul `random` untuk token keamanan, OTP, atau password. Wajib gunakan **`secrets`**:
   ```python
   import secrets
   token = secrets.token_urlsafe(32)
   is_valid = secrets.compare_digest(a, b)  # anti timing-attack
   ```
2. **Subprocess**: Selalu panggil `subprocess.run(["cmd", arg1], check=True)` dengan list argumen, **jangan pernah `shell=True`** dengan input user.
3. **Deserialisasi**: Jangan pernah `pickle.loads()` atau `yaml.load()` (pakai `yaml.safe_load()`) pada data dari user/network.
4. **SQL**: Selalu gunakan parameterized query (`cursor.execute("SELECT * FROM t WHERE id = ?", (uid,))`), jangan pernah f-string ke dalam SQL.
