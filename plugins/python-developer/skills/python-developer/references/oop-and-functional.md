# OOP, Protocols & Functional Programming — Python Developer Reference

Sumber: [docs.python.org/3/reference/datamodel.html](https://docs.python.org/3/reference/datamodel.html), [docs.python.org/3/library/dataclasses.html](https://docs.python.org/3/library/dataclasses.html), [docs.python.org/3/library/functools.html](https://docs.python.org/3/library/functools.html), roadmap.sh/python

---

## Dataclasses & Value Objects

```python
from dataclasses import dataclass, field

# Immutable value object dengan slots (hemat memori, akses cepat)
@dataclass(frozen=True, slots=True, kw_only=True)
class Money:
    amount: int
    currency: str = "IDR"
    tags: list[str] = field(default_factory=list, compare=False)

    def __post_init__(self) -> None:
        if self.amount < 0:
            raise ValueError("amount cannot be negative")
```

- Gunakan `@dataclass(slots=True)` secara default di Python 3.10+ kecuali butuh dynamic attribute atau multiple inheritance kompleks.
- Gunakan `field(default_factory=...)` untuk mutable default.
- Untuk simple tuple dengan nama field tanpa metode mutasi: `typing.NamedTuple`.

---

## Python Data Model (Dunder Methods)

Implementasikan dunder method hanya jika selaras dengan semantik objek:

| Kategori | Dunder Methods | Kegunaan |
|----------|----------------|----------|
| Representasi | `__repr__`, `__str__`, `__format__` | Debugging (`!r`) vs display (`!s`) |
| Perbandingan | `__eq__`, `__lt__` (+ `@functools.total_ordering`) | Equality & sorting |
| Hashing | `__hash__` | Wajib jika dipakai sebagai key `dict` / anggota `set` (hanya untuk objek immutable) |
| Container | `__len__`, `__getitem__`, `__iter__`, `__contains__` | Sequence / mapping behavior |
| Context | `__enter__`, `__exit__`, `__aenter__`, `__aexit__` | `with` / `async with` |
| Callable | `__call__` | Stateful function object |

```python
import functools

@functools.total_ordering
class Version:
    def __init__(self, major: int, minor: int) -> None:
        self.major = major
        self.minor = minor

    def __repr__(self) -> str:
        return f"Version({self.major}, {self.minor})"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Version):
            return NotImplemented
        return (self.major, self.minor) == (other.major, other.minor)

    def __lt__(self, other: object) -> bool:
        if not isinstance(other, Version):
            return NotImplemented
        return (self.major, self.minor) < (other.major, other.minor)
```

---

## Structural Subtyping (Protocols) vs ABC

- **Utamakan Composition & `typing.Protocol`** dibanding inheritance hierarki dalam.
- Pakai **`abc.ABC` + `@abstractmethod`** hanya jika ingin berbagi implementasi konkrit atau memaksa validasi saat class definition.
- Pakai **`@runtime_checkable`** pada `Protocol` hanya jika benar-benar butuh `isinstance()` saat runtime.

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class Closer(Protocol):
    def close(self) -> None: ...

def cleanup(resource: Closer) -> None:
    resource.close()
```

---

## Properties, Descriptors & Class Methods

```python
class Account:
    def __init__(self, balance: int) -> None:
        self._balance = balance

    @property
    def balance(self) -> int:
        return self._balance

    @classmethod
    def empty(cls) -> "Account":
        return cls(0)

    @staticmethod
    def is_valid_amount(val: int) -> bool:
        return val >= 0
```

- Gunakan `@functools.cached_property` untuk komputasi properti mahal pada objek yang datanya tidak berubah.

---

## Functional Tools (`functools`, `itertools`, `operator`)

```python
import functools
import itertools
import operator

# Single-dispatch generic function (pengganti bersih visitor pattern)
@functools.singledispatch
def serialize(val: object) -> str:
    raise TypeError(f"Unsupported type: {type(val)}")

@serialize.register
def _(val: int) -> str:
    return str(val)

@serialize.register
def _(val: list) -> str:
    return ",".join(map(serialize, val))

# Memoization
@functools.cache
def fib(n: int) -> int:
    return n if n < 2 else fib(n - 1) + fib(n - 2)

# Itertools recipes
batches = itertools.batched(range(10), 3)  # Python 3.12+: (0,1,2), (3,4,5)...
```
