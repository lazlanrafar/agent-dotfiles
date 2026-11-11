# Type System & Testing — Python Developer Reference

Sumber: [docs.python.org/3/library/typing.html](https://docs.python.org/3/library/typing.html), [typing.readthedocs.io](https://typing.readthedocs.io/), roadmap.sh/python

---

## Modern Type Syntax (Python 3.12+ / PEP 695)

Python 3.12 memperkenalkan sintaks deklarasi generic dan `type` alias bawaan tanpa perlu `TypeVar` manual:

```python
from collections.abc import Callable, Iterable, Sequence

# Type alias baru (PEP 695)
type Point = tuple[float, float]
type JsonDict = dict[str, object]

# Generic function
def first[T](items: Sequence[T]) -> T:
    return items[0]

# Generic class dengan bound
class Box[T: (int, float)]:
    def __init__(self, value: T) -> None:
        self.value = value
```

- Untuk argumen fungsi, gunakan tipe abstrak dari `collections.abc` (`Sequence`, `Mapping`, `Iterable`) dibanding tipe konkrit (`list`, `dict`) agar lebih fleksibel.
- Untuk return type, gunakan tipe konkrit (`list[str]`, `dict[str, int]`).

---

## Advanced Typing (`TypedDict`, `Literal`, `Annotated`, `Self`, `TypeIs`)

```python
from typing import Annotated, Literal, NotRequired, Self, TypedDict, TypeIs

# TypedDict untuk payload dictionary terstruktur
class UserPayload(TypedDict):
    id: int
    role: Literal["admin", "member"]
    bio: NotRequired[str]  # Python 3.11+

# Type narrowing dengan TypeIs (Python 3.13+ / typing_extensions)
def is_str_list(val: list[object]) -> TypeIs[list[str]]:
    return all(isinstance(x, str) for x in val)

# Builder pattern dengan Self (Python 3.11+)
class QueryBuilder:
    def where(self, cond: str) -> Self:
        return self
```

---

## Runtime Validation dengan Pydantic v2

Type hints standar Python tidak divalidasi saat runtime. Gunakan **Pydantic v2** di trust boundary (API input, file konfigurasi, environment variable, webhook).

```python
from pydantic import BaseModel, ConfigDict, Field

class CreateUserRequest(BaseModel):
    model_config = ConfigDict(frozen=True, extra="forbid")

    username: str = Field(min_length=3, max_length=32, pattern=r"^[a-z0-9_]+$")
    age: int = Field(ge=18, le=120)
```

---

## Pytest Architecture & Best Practices

### 1. Fixtures & Dependency Injection
Letakkan fixture bersama di `tests/conftest.py`. Gunakan `yield` untuk setup + teardown otomatis.

```python
from collections.abc import Iterator
import pytest

@pytest.fixture
def db_session() -> Iterator[Session]:
    session = create_test_session()
    try:
        yield session
    finally:
        session.rollback()
        session.close()
```

### 2. Parametrize & Exception Checking

```python
import pytest

@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("  hello ", "hello"),
        ("", ""),
    ],
)
def test_normalize(raw: str, expected: str) -> None:
    assert normalize(raw) == expected

def test_invalid_input_raises() -> None:
    with pytest.raises(ValueError, match=r"must be positive"):
        parse_amount(-5)
```

### 3. Mocking di Trust Boundary (`monkeypatch` & `unittest.mock`)
- Mock hanya I/O eksternal (waktu, env vars, HTTP call, third-party API).
- Jangan mock fungsi internal domain sendiri; uji perilakunya langsung.

```python
def test_env_override(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "production")
    assert get_env() == "production"
```
