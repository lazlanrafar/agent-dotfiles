---
name: api-and-security
description: >-
  API Design and API Security skill based on roadmap.sh/api-design and roadmap.sh/api-security-best-practices.
  Enforces REST/gRPC/GraphQL/SSE design standards, RFC 7807 Problem Details, cursor pagination,
  idempotency keys, rate limiting, AuthN/AuthZ (JWT, OAuth2, RBAC/ReBAC), and OWASP API security.
  Use when designing, building, or auditing HTTP/gRPC/GraphQL APIs and authentication flows.
---

# API Design & Security Skill

Pedoman perancangan API dan pengamanan aplikasi berbasis kurikulum `roadmap.sh/api-design` dan `roadmap.sh/api-security-best-practices`.

---

## 1. Memilih Paradigma API

| Paradigma | Kasus Penggunaan Terbaik | Kontrak / Skema |
|-----------|--------------------------|-----------------|
| **REST (JSON)** | Public API, CRUD resource-oriented, caching HTTP standar | OpenAPI 3.1 |
| **gRPC (Protobuf)** | Komunikasi internal antar-microservice latensi rendah, streaming dua arah | `.proto` (Protocol Buffers) |
| **GraphQL** | Klien beragam (mobile/web) dengan kebutuhan agregasi field fleksibel | GraphQL SDL (wajib batasi query depth & selesaikan N+1 dengan DataLoader) |
| **SSE / WebSockets** | Notifikasi real-time satu arah (SSE — lebih ramah HTTP/proxy) atau dua arah penuh (WebSockets) | Event schema |

---

## 2. Standar Desain RESTful API

1. **URI & Semantik HTTP**:
   - Gunakan kata benda jamak kebab-case: `/v1/orders/{order_id}/items`.
   - `GET` & `HEAD` (safe, idempotent), `PUT` & `DELETE` (idempotent), `POST` (create/action — buat idempotent dengan header `Idempotency-Key`), `PATCH` (partial update).
2. **Status Code Presisi**:
   - `200 OK`, `201 Created` (sertakan header `Location`), `202 Accepted` (async job), `204 No Content`.
   - `400 Bad Request` (sintaks salah), `401 Unauthorized` (belum autentikasi), `403 Forbidden` (tidak punya hak akses), `404 Not Found`, `409 Conflict` (state/duplikat), `422 Unprocessable Content` (gagal validasi domain), `429 Too Many Requests` (sertakan header `Retry-After`).
3. **Standar Error Response (RFC 9457 / RFC 7807 Problem Details)**:
   Jangan mengembalikan format error yang berbeda-beda. Gunakan struktur konsisten:
   ```json
   {
     "type": "https://example.com/probs/out-of-credit",
     "title": "Insufficient balance",
     "status": 422,
     "detail": "Current balance is 30, but item costs 50.",
     "instance": "/v1/orders/ord_123",
     "request_id": "req_01J9XYZ"
   }
   ```
4. **Pagination**:
   - Gunakan **Cursor-based pagination** (`?cursor=eyJpZCI6MTAwfQ&limit=25`) untuk tabel besar atau feed real-time agar bebas dari *offset drift* dan lambatnya `OFFSET 100000`.
   - Selalu batasi `max_limit` (misal maksimal 100 item per request).

---

## 3. Authentication (AuthN) & Authorization (AuthZ)

- **Password Storage**: Hanya gunakan **Argon2id** (pilihan utama) atau `bcrypt` / `scrypt`. Haram menggunakan SHA-256/MD5 polos.
- **Session vs JWT**:
  - Aplikasi web first-party: utamakan **Server-side Session** dengan cookie `HttpOnly; Secure; SameSite=Lax` (mudah di-revoke seketika).
  - API / Mobile / Stateless: gunakan **Short-lived Access Token (JWT, 5–15 menit)** + **Rotating Refresh Token** yang dapat di-revoke di DB.
  - **JWT Hardening**: Validasi algoritma secara eksplisit (tolak `alg: none`), verifikasi `iss`, `aud`, `exp`, dan jangan pernah simpan data sensitif di payload JWT.
- **Authorization (BOLA / IDOR Prevention)**:
  - **Risiko #1 OWASP API Security adalah Broken Object Level Authorization (BOLA/IDOR)**.
  - Setiap query baca/ubah/hapus resource berdasarkan ID dari user **wajib menyertakan filter kepemilikan/tenant** di level query (`WHERE id = $1 AND org_id = $2`).

---

## 4. Hardening & Perlindungan Input/Output

1. **Strict Schema Validation**: Tolak field tak dikenal (`extra="forbid"` / `additionalProperties: false`) untuk mencegah *Mass Assignment*. Batasi ukuran body request (misal maks 1–5 MB).
2. **Rate Limiting & Throttling**: Pasang Token Bucket / Sliding Window per IP dan per API Key/User ID, terutama pada endpoint login, OTP, dan pencarian berat.
3. **CORS & Security Headers**:
   - Jangan pernah menggunakan `Access-Control-Allow-Origin: *` bersamaan dengan `Access-Control-Allow-Credentials: true`.
   - Pasang header `Strict-Transport-Security` (HSTS), `X-Content-Type-Options: nosniff`, dan `Content-Security-Policy`.
4. **Zero Sensitive Data in Logs/Errors**: Jangan pernah menampilkan stack trace internal ke klien atau mencatat `Authorization` header, token, password, atau nomor kartu di log.
