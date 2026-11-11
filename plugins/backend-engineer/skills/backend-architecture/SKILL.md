---
name: backend-architecture
description: >-
  Backend Architecture, System Design, and Software Design skill based on roadmap.sh/backend,
  roadmap.sh/system-design, and roadmap.sh/software-design-architecture.
  Enforces Clean Architecture, Modular Monolith first, 12-Factor App, CAP/Consistency patterns,
  multi-layer caching (Cache-Aside, Write-Through), message brokers (Kafka/RabbitMQ), backpressure,
  and observability. Use when designing systems, services, or refactoring backend architecture.
---

# Backend Architecture & System Design Skill

Pedoman arsitektur perangkat lunak dan sistem terdistribusi berbasis kurikulum `roadmap.sh/backend`, `roadmap.sh/system-design`, dan `roadmap.sh/software-design-architecture`.

---

## 1. Software Design & Clean Architecture

1. **Modular Monolith First**: Jangan memecah sistem ke microservices sebelum batas domain stabil dan skala organisasi/beban benar-benar menuntut deployment independen.
2. **Dependency Rule (Boundary Isolation)**:
   - Core domain & business logic **bebas dari dependensi framework, ORM, HTTP, atau transport**.
   - Arah dependensi selalu mengarah ke dalam: `Delivery (HTTP/gRPC/CLI) -> Application/Use-Case -> Domain <- Infrastructure (DB/Cache/Queue)`.
3. **Prinsip Desain Inti**:
   - **Composition over Inheritance**: Rangkai perilaku kecil via interface/protocol/trait, hindari hierarki class dalam.
   - **Command-Query Separation (CQS)**: Pisahkan fungsi yang mengubah state (command) dari fungsi yang hanya membaca data (query).
   - **Avoid Anemic & Leaky Models**: Validasi invariant domain di dalam entitas/value object, bukan tersebar di controller.

---

## 2. Caching Strategies (`roadmap.sh/system-design`)

Pilih strategi cache secara eksplisit sesuai profil baca/tulis:

| Strategi | Alur | Kapan Dipakai | Risiko & Mitigasi |
|----------|------|---------------|-------------------|
| **Cache-Aside** | App cek cache -> miss -> baca DB -> isi cache | Beban baca berat, umum (Redis/Memcached) | Cache stampede -> mitigasi dengan singleflight/mutex lock & jitter TTL |
| **Write-Through** | App tulis ke cache & DB secara sinkron | Butuh cache selalu segar setelah write | Latensi write naik |
| **Write-Behind** | App tulis ke cache -> antrean async tulis ke DB | Counter/analitik frekuensi tulis sangat tinggi | Risiko kehilangan data jika node cache mati sebelum flush |
| **HTTP / CDN Cache** | `Cache-Control`, `ETag`, `Last-Modified` | Aset statis & respons GET publik | Gunakan immutable hash URL atau `stale-while-revalidate` |

- **Aturan Wajib**: Setiap key di Redis/Memcached **wajib memiliki TTL** (plus random jitter 5–10% agar tidak kedaluwarsa serentak) dan kebijakan `maxmemory-policy` yang jelas (`allkeys-lru` / `volatile-lfu`).

---

## 3. Asynchronous Messaging & Event-Driven Patterns

- **Kapan Pakai Message Broker**:
  - **RabbitMQ / SQS**: Task queue, job background, routing berbasis pesan, retry + Dead Letter Queue (DLQ).
  - **Kafka / Redpanda / NATS JetStream**: Event streaming throughput tinggi, log append-only yang bisa di-replay oleh banyak consumer group.
- **Transactional Outbox Pattern**: Jangan pernah melakukan `db.commit()` lalu `broker.publish()` secara terpisah tanpa pengaman (dual-write bug). Simpan event di tabel `outbox` dalam transaksi DB yang sama, lalu relay ke broker.
- **Idempotent Consumer**: Broker menjamin *at-least-once delivery*. Setiap consumer **wajib idempotent** (simpan `message_id` / `idempotency_key` yang sudah diproses atau gunakan `ON CONFLICT DO NOTHING`).
- **Backpressure & Graceful Shutdown**: Batasi concurrency worker (`prefetch_count` / semaphore), pasang Dead Letter Queue (DLQ) setelah N kali retry dengan exponential backoff + jitter, dan selesaikan in-flight job saat menerima `SIGTERM`.

---

## 4. Scalability, High Availability & Observability

1. **Stateless Application Tier (12-Factor App)**: Simpan session/state di Redis atau DB, bukan di memori lokal proses, agar horizontal scaling di belakang Load Balancer (L4/L7) berjalan mulus.
2. **Timeouts & Circuit Breaker**: Setiap panggilan jaringan keluar (HTTP, DB, RPC) **wajib memiliki timeout eksplisit**. Jangan pernah gunakan default infinite timeout.
3. **Three Pillars of Observability**:
   - **Structured Logs**: Format JSON di produksi dengan `trace_id`, `request_id`, `user_id`, dan durasi.
   - **Metrics (RED Method)**: **R**ate (req/s), **E**rrors (error/s), **D**uration (p50, p95, p99 histogram).
   - **Health Checks**: Pisahkan `/healthz/live` (proses hidup) dan `/healthz/ready` (siap menerima trafik, koneksi DB/cache sehat).
