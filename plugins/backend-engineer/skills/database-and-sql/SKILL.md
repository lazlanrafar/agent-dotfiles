---
name: database-and-sql
description: >-
  Database Engineering, SQL Optimization, and Backend Performance skill based on roadmap.sh/sql,
  roadmap.sh/backend, and roadmap.sh/backend-performance-best-practices.
  Enforces relational modeling, ACID isolation levels, B-Tree/GIN/composite indexing, N+1 prevention,
  EXPLAIN ANALYZE profiling, connection pooling, and zero-downtime migrations.
  Use when writing SQL queries, designing database schemas, using ORMs, or tuning DB performance.
---

# Database & SQL Engineering Skill

Database schema design, SQL authoring, and performance optimization guidelines based on `roadmap.sh/sql`, `roadmap.sh/backend`, and `roadmap.sh/backend-performance-best-practices`.

---

## 1. Schema Design & Data Integrity

1. **Database as the Final Fortress of Integrity**:
   - Never rely solely on application-layer validation. Enforce constraints in the database: `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `UNIQUE`, and `CHECK`.
2. **Precision Data Types (PostgreSQL Standard)**:
   - Money / Financial amounts: **`NUMERIC(p, s)`** or integer minor units (cents). **Never use `FLOAT`/`REAL` for money**.
   - Timestamps: Always store UTC using **`TIMESTAMPTZ`** (`timestamp with time zone`).
   - Primary Keys: Use `BIGINT GENERATED ALWAYS AS IDENTITY` or **UUIDv7** (time-ordered UUIDs prevent B-Tree page fragmentation caused by random UUIDv4).
   - Semi-structured data: Use `JSONB` for dynamic attributes, while keeping frequently joined or constrained fields as first-class relational columns.

---

## 2. Indexing Strategy (`roadmap.sh/sql` & `backend-performance`)

- **Index Selection**:
  - **B-Tree** (default): Equality (`=`) and range predicates (`<, <=, >, >=, BETWEEN, ORDER BY`).
  - **Composite Index `(a, b, c)`**: Column order follows the *Leftmost Prefix Rule*. Place equality (`=`) columns first and range/sort columns last.
  - **Covering Index (`INCLUDE`)**: Attach non-filtered payload columns to achieve **Index-Only Scans** without heap fetches.
  - **Partial Index (`WHERE ...`)**: Index only hot subsets, e.g., `CREATE INDEX ON orders (created_at) WHERE status = 'pending'`.
  - **GIN Index**: Use for `JSONB` containment (`@>`), array membership, and Full-Text Search (`tsvector`).
- **Write Amplification Awareness**: Every additional index slows down `INSERT`/`UPDATE`/`DELETE` and consumes buffer pool memory. Drop unused indexes.

---

## 3. Query Optimization & Anti-Patterns

1. **Eliminate N+1 Queries**:
   - Never execute database queries inside an application loop.
   - Use `JOIN`, batch queries (`WHERE id = ANY($1)`), or explicit ORM eager loading (`selectinload` / `joinedload`).
2. **Avoid `SELECT *` in Production Code**: Fetch only required columns to reduce network I/O, memory allocation, and enable Index-Only Scans.
3. **Write Sargable Queries (Search Argument Able)**:
   - Never wrap indexed columns in functions on the left side of a `WHERE` clause:
   - Bad: `WHERE DATE(created_at) = '2026-11-11'` (disables B-Tree index, forces Seq Scan).
   - Good: `WHERE created_at >= '2026-11-11 00:00:00Z' AND created_at < '2026-11-12 00:00:00Z'` (or create a functional index).
4. **Profile with `EXPLAIN (ANALYZE, BUFFERS)`**:
   - Inspect *actual rows* vs. *estimated rows*, unintended *Seq Scans* on large tables, and *Buffers: shared hit vs. read*.

---

## 4. Transactions, Concurrency & Migrations

- **ACID & Concurrency Control**:
  - Keep transactions **short and fast**. **Never make external HTTP calls inside an open database transaction!**
  - Prevent *lost updates* on balances/inventory via atomic updates (`UPDATE accounts SET balance = balance - $1 WHERE id = $2 AND balance >= $1`), pessimistic row locks (`SELECT ... FOR UPDATE`), or optimistic concurrency control (`version` column).
- **Connection Pooling**: Always route connections through a pooler (PgBouncer / SQLAlchemy pool) sized appropriately for DB CPU/memory limits.
- **Zero-Downtime Migrations (Expand and Contract)**:
  - In PostgreSQL, build indexes with `CREATE INDEX CONCURRENTLY` to avoid locking table writes.
  - Never rename or drop active columns in a single deployment; follow *Expand (add column) -> Dual-write & Backfill -> Switch reads -> Contract (drop old column)*.
