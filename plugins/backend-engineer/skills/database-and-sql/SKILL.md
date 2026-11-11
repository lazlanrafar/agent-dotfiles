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

Pedoman perancangan skema database, penulisan query SQL, dan optimasi performa berbasis kurikulum `roadmap.sh/sql`, `roadmap.sh/backend`, dan `roadmap.sh/backend-performance-best-practices`.

---

## 1. Schema Design & Data Integrity

1. **Database sebagai Benteng Terakhir Integritas Data**:
   - Jangan hanya mengandalkan validasi di kode aplikasi. Wajib pasang constraint di level DB: `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `UNIQUE`, dan `CHECK`.
2. **Pemilihan Tipe Data Presisi (PostgreSQL Standard)**:
   - Uang / Finansial: **`NUMERIC(p, s)`** atau integer satuan terkecil (sen/rupiah). **Haram menggunakan `FLOAT`/`REAL` untuk uang**.
   - Waktu: Selalu simpan dalam UTC menggunakan **`TIMESTAMPTZ`** (`timestamp with time zone`).
   - ID / Primary Key: `BIGINT GENERATED ALWAYS AS IDENTITY` atau **UUIDv7** (time-ordered UUID — menghindari fragmentasi B-Tree index dibanding UUIDv4 acak).
   - Semi-terstruktur: Gunakan `JSONB` hanya untuk atribut dinamis; kolom yang sering di-JOIN atau menjadi constraint utama tetap harus menjadi kolom relasional.

---

## 2. Indexing Strategy (`roadmap.sh/sql` & `backend-performance`)

- **Kapan & Jenis Index yang Dipakai**:
  - **B-Tree** (default): Equality (`=`) dan range query (`<, <=, >, >=, BETWEEN, ORDER BY`).
  - **Composite Index `(a, b, c)`**: Urutan kolom sangat menentukan (*Leftmost Prefix Rule*). Letakkan kolom equality (`=`) di depan dan kolom range/sort di belakang.
  - **Covering Index (`INCLUDE`)**: Sertakan kolom tambahan agar tercapai **Index-Only Scan** tanpa menyentuh heap tabel.
  - **Partial Index (`WHERE ...`)**: Indeks hanya baris aktif, misal `CREATE INDEX ON orders (created_at) WHERE status = 'pending'`.
  - **GIN Index**: Untuk pencarian di dalam `JSONB`, array, atau Full-Text Search (`tsvector`).
- **Waspada Write Amplification**: Setiap index tambahan memperlambat `INSERT`/`UPDATE`/`DELETE` dan memakan RAM buffer pool. Hapus index yang tidak terpakai.

---

## 3. Query Optimization & Anti-Patterns

1. **Berantas N+1 Query Problem**:
   - Haram melakukan query database di dalam loop aplikasi.
   - Gunakan `JOIN`, `WHERE id = ANY($1)`, atau eager loading ORM (`selectinload` / `joinedload` di SQLAlchemy).
2. **Hindari `SELECT *` di Kode Produksi**: Ambil hanya kolom yang dibutuhkan untuk menghemat I/O jaringan, memori, dan membuka peluang Index-Only Scan.
3. **Sargable Queries (Search Argument Able)**:
   - Jangan membungkus kolom ber-index dengan fungsi di klausa `WHERE`:
   - Buruk: `WHERE DATE(created_at) = '2026-11-11'` (mematikan B-Tree index, memicu Seq Scan).
   - Baik: `WHERE created_at >= '2026-11-11 00:00:00Z' AND created_at < '2026-11-12 00:00:00Z'` (atau buat functional index).
4. **Profiling dengan `EXPLAIN (ANALYZE, BUFFERS)`**:
   - Periksa *actual rows* vs *estimated rows*, *Seq Scan* pada tabel besar, dan *Buffers: shared hit vs read*.

---

## 4. Transactions, Concurrency & Migrations

- **ACID & Concurrency Control**:
  - Jaga transaksi tetap **pendek dan cepat**. **Jangan pernah melakukan HTTP call ke pihak ketiga di tengah transaksi database yang sedang terbuka!**
  - Untuk mencegah *lost update* pada saldo/stok: gunakan atomic update (`UPDATE accounts SET balance = balance - $1 WHERE id = $2 AND balance >= $1`), pessimistic lock (`SELECT ... FOR UPDATE`), atau optimistic concurrency control (kolom `version`).
- **Connection Pooling**: Selalu gunakan connection pooler (PgBouncer / SQLAlchemy pool) dan batasi ukuran pool agar tidak menghabiskan koneksi DB.
- **Zero-Downtime Migrations (Expand and Contract)**:
  - Di PostgreSQL, gunakan `CREATE INDEX CONCURRENTLY` agar tidak mengunci penulisan tabel.
  - Jangan me-rename atau menghapus kolom langsung dalam satu rilis jika aplikasi masih berjalan; lakukan pola *Expand (tambah kolom baru) -> Dual-write & Backfill -> Switch read -> Contract (hapus kolom lama)*.
