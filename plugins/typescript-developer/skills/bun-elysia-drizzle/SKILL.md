---
name: bun-elysia-drizzle
description: >-
  TypeScript backend & monorepo skill for Bun, Turborepo, ElysiaJS (Eden Treaty), Drizzle ORM,
  Zod/TypeBox, and Biome. Enforces strict module layering (*.dto.ts, *.model.ts, *.service.ts,
  *.controller.ts, *.repository.ts), CUID2 string IDs, multi-tenant soft deletes, response envelopes,
  and isolated Bun test execution. Use when building or reviewing Bun/Elysia/Drizzle/Turborepo services.
---

# Bun, ElysiaJS & Drizzle Monorepo Skill

Engineering guidelines for TypeScript monorepos running on **Bun + Turborepo + ElysiaJS + Drizzle ORM**.

---

## 1. Non-Negotiable Tooling & Workspace Rules

1. **Always Bun**: Use `bun install`, `bun add`, `bun run`, `bunx`, `bun test`. Never use `npm`, `yarn`, `pnpm`, or commit their lockfiles.
2. **Zero `any` Types**: Enforce strict TypeScript (`strict: true`, Biome `noExplicitAny = "error"`). Use generics, discriminated unions, `unknown` with type narrowing, or TypeBox/Zod inference.
3. **Strict Monorepo Dependency Direction**:
   - `apps/*` import from shared `@workspace/*` or `@repo/*` packages.
   - **Packages never import from `apps/*`**.
   - **Database Isolation**: `@repo/database` (Drizzle + Postgres) is imported **only** by backend repositories inside `apps/api`. Frontend apps (`apps/app`, `apps/pos`) never import `@repo/database` or connect to the DB directly; they call `apps/api` via the typed **Eden Treaty** client (`@repo/api-client`).
4. **Validated Environment Access**: Never read `process.env` ad-hoc across modules; import validated constants from `@repo/constants` (`Env.DATABASE_URL`, `Env.JWT_SECRET`) that fail fast at boot if required secrets are missing.

---

## 2. ElysiaJS Module Architecture (`apps/api`)

Every feature module under `src/modules/<module>/` uses explicit file suffixes (`{module}.{layer}.ts`) with **no barrel `index.ts`** inside modules:

| File | Pattern | Responsibility |
|------|---------|----------------|
| `{module}.dto.ts` | Plain TypeScript interfaces | Pure types for service/repository signatures; zero runtime or Elysia imports |
| `{module}.model.ts` | `new Elysia({ name: "{module}.model" }).model({...})` | Runtime TypeBox schemas named `"{module}.{action}.{slot}"` (`body`, `query`, `params`) |
| `{module}.repository.ts` | `abstract class` with `static` methods | **Only layer allowed to import `@repo/database`**. Enforces `organization_id` and `isNull(deletedAt)` |
| `{module}.service.ts` | `abstract class` with `static` methods | Business rules, transactions, audit logs, and realtime events. **Never receives Elysia `Context`** |
| `{module}.controller.ts` | `new Elysia({ name, prefix })` | Composes auth plugin + model plugin, extracts validated inputs, calls `Service`, returns `respond()` envelope |

```typescript
// auth.model.ts
import { Elysia, t } from "elysia";

export const authModel = new Elysia({ name: "auth.model" }).model({
  "auth.login.body": t.Object({
    email: t.String({ format: "email" }),
    password: t.String({ minLength: 8 }),
  }),
});

// auth.controller.ts
import { Elysia } from "elysia";
import { authModel } from "./auth.model";
import { AuthService } from "./auth.service";
import { respond } from "../../lib/response";

export const authController = new Elysia({
  name: "controller.auth",
  prefix: "/auth",
})
  .use(authModel)
  .post(
    "/login",
    async ({ body, set }) => {
      const result = await AuthService.login(body);
      set.status = 200;
      return respond.ok({ data: result });
    },
    { body: "auth.login.body" },
  );
```

- **Named Plugins for Deduplication**: Always pass `{ name: "plugin.<name>" }` to `new Elysia(...)` so Elysia deduplicates plugins across the router tree.
- **Route Guards over Inline Checks**: Enforce auth via `onBeforeHandle` guards (`requireAuth`, `requireAdmin`, `requireRole("admin")`) + `assertPermission(auth, key)` rather than scattering manual `if (!auth)` checks inside handlers.
- **Uniform Envelope**: Every controller returns the standard `respond()` envelope (`{ status, message, meta, data }`) and throws typed domain errors (`ErrorCode` / `fail.conflict(...)`) rather than inline raw strings.

---

## 3. Drizzle ORM & Data Integrity Rules

1. **String CUID2 Primary/Foreign Keys**: Use `@paralleldrive/cuid2` (`text` PKs) everywhere. Never call `Number(id)` or `parseInt(id)` on entity IDs, and never sort by CUID2 alone (sort by `createdAt, id`).
2. **Multi-Tenant & Soft-Delete by Default**:
   - Every read query must filter by `eq(table.organizationId, orgId)` and `isNull(table.deletedAt)`.
   - Never execute hard `db.delete(...)` on workspace/tenant tables; set `deletedAt: new Date()`.
3. **Relative Ledger/Balance Updates**:
   - Never compute points, wallet balances, or stock from an earlier `SELECT` and write an absolute value back.
   - Perform relative atomic updates (`sql\`${table.balance} - ${cost}\``) with `gte(table.balance, cost)` in the `WHERE` clause inside a single `db.transaction()`.

---

## 4. Testing in Bun Workspaces

- **Process-Isolated Test Files**: Because `mock.module()` in Bun applies process-wide, run unit/integration test suites that use module mocks in isolated per-file Bun processes (`scripts/test-isolated.ts`) or scope `bun test <exact-file.test.ts>`.
- Always run `bun run lint` and `bun run typecheck` across all workspaces before pushing.
