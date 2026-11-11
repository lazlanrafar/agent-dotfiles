---
name: prd-discovery
description: >-
  Interactive Product Requirements Document (PRD) and feature specification skill.
  Enforces a strict "Ask, Never Assume" gate before any new feature or behavior change:
  inspects existing codebase context first, actively interviews the user on ambiguous scope,
  flows, permissions, edge cases, and trade-offs, and produces a rigorous PRD or FEAT_*.md spec.
  Use whenever the user proposes a new feature, product idea, workflow change, or PRD.
---

# PRD Discovery & Interactive Alignment Skill

Prevents vague scope and silent assumptions by enforcing **structured codebase reconnaissance + active Socratic interviewing** before drafting a PRD or writing any feature code.

---

## 1. The Iron Law: Never Assume, Always Ask

When a user asks to build a new feature, modify a workflow, or draft a specification:
1. **STOP before writing production code or locking in unverified design choices.**
2. **Never silently invent** business rules, permission scopes, pricing/point formulas, state transitions, UI placement, or error behaviors that the user did not specify.
3. If anything non-trivial can be interpreted in more than one way, **surface the options with their trade-offs and ask the user to decide**.

---

## 2. Phase 1: Look Before You Ask (Codebase Reconnaissance)

Before asking the user a single question, inspect the repository so you never ask what the codebase already answers:
- Read `CLAUDE.md` / `AGENTS.md`, `docs/prd.md`, `docs/architecture.md` (and its Decision Log `Dxx`), and related `docs/FEAT_*.md` or wiki pages via MCP.
- Check existing database tables (`packages/database` / `migrations`), API modules (`modules/{module}/`), and UI components (`components/{atoms,molecules,organisms}`) connected to the request.
- Identify how adjacent features handle tenancy (`organization_id` / `workspace_id`), permissions, soft deletes, IDs (CUID2), and audit logging.

---

## 3. Phase 2: Active Discovery Interview (The 7 Ambiguity Checkpoints)

In your response:
1. **Echo the Shape (<= 100 words)**: State what is understood so far and what existing codebase structures it touches.
2. **Ask 3–5 High-Impact Questions at a Time** (use the structured `ask_question` tool when available, placing the `(Recommended)` option first with a 1-line rationale). Audit the request across these **7 Ambiguity Checkpoints**:

| # | Checkpoint | Questions to Resolve |
|---|------------|----------------------|
| **1** | **Scope & Non-Goals** | What is the smallest complete v1? Which adjacent features are explicitly **OUT of scope (Non-Goals)** for this iteration? |
| **2** | **Actors, Tenancy & RBAC** | Which actor (`owner`, `admin`, `staff`, `member`, `guest`) triggers this? What permission key guards it? Is it scoped per `organization_id`, `workspace_id`, or `outlet_id`? |
| **3** | **End-to-End User Flow & UI Surface** | Where does the user start (route, list header button, modal, sheet, drawer)? What happens step-by-step on success? Where does the user land afterward? |
| **4** | **Data Model & State Invariants** | What new tables/columns/statuses are needed? What are the valid state transitions? How are money/points/quantities represented (never floats; relative atomic updates)? |
| **5** | **Edge Cases & Failure Modes** | What happens on duplicate clicks/webhooks (idempotency), concurrent edits, partial failures, expired items, or rollback/cancellation? What are the two empty states (*"none yet"* vs. *"none matching filters"*)? |
| **6** | **Security, Audit & Side Effects** | Does this mutation write an audit/activity row, send an email/push notification, or enqueue a background job inside the same transaction? Does it require step-up verification? |
| **7** | **Architectural Trade-Offs** | When multiple implementation paths exist (e.g., new table vs. extending an existing rule table; sync vs. background job), present 2–3 concrete options with pros/cons and ask the user to pick. |

*Continue the interview in short rounds until all 7 checkpoints are unambiguous, then ask for confirmation to generate the formal PRD / Feature Spec.*

---

## 4. Phase 3: Standardized PRD / Feature Spec Template

Once all decisions are locked in with the user, write the specification to the repository's standard location (`docs/prd.md`, `docs/FEAT_<NAME>.md`, `docs/features/<name>/README.md`, or the project's Boekti wiki page):

```markdown
# FEAT: <Feature Name>

> Status: Draft | Approved (<YYYY-MM-DD>) · Decision refs: D<xx> · Related: [<Related Doc>](./<related>.md)

## 1. Problem & Context
Why this feature exists, what pain or gap it solves, and how the system currently behaves without it.

## 2. Goals & Non-Goals
### Goals
- **G1.** <Concrete, measurable outcome>
- **G2.** <Concrete, measurable outcome>

### Explicit Non-Goals (Out of Scope for v1)
- <Feature or edge case deliberately excluded so scope never creeps>

## 3. Actors & Permissions
| Actor / Role | Permission Key | Tenant Scope | Allowed Actions |
|--------------|----------------|--------------|-----------------|
| Admin | `<module>.manage` | `organization_id` | Create, update, archive |
| Member | `authenticated` | Own record only | View, submit |

## 4. End-to-End User Flows
### Flow A: <Primary Happy Path>
1. **Trigger**: User navigates to `/path` and clicks `<Action>`.
2. **Input & Validation**: Fields required, client + server validation rules.
3. **System Mutation**: Transaction steps, relative balance/state changes, audit log, notifications.
4. **Outcome**: UI feedback (toast/redirect) and updated URL/table state.

### Flow B: <Edge Cases, Rollbacks & Error Paths>
- Duplicate submission / idempotency behavior.
- Insufficient balance / conflict / permission denied (`ErrorCode`).
- Empty states (*"None created yet"* vs. *"No items match your filters"*).

## 5. Requirements Matrix
| ID | Requirement | Acceptance Criteria (Testable Proof) |
|----|-------------|--------------------------------------|
| `<MOD>-1` | <Requirement statement> | <Exact condition that proves it works> |
| `<MOD>-2` | <Requirement statement> | <Exact condition that proves it works> |

## 6. Data Model (`@repo/database` / SQL)
- **Tables & Columns**: Exact table names, column types (`text` CUID2 PKs, `numeric` for money, `timestamptz`, `deleted_at`).
- **Constraints & Indexes**: Unique constraints, partial indexes (`WHERE deleted_at IS NULL`), RLS policies.

## 7. API Contract
| Method | Path | Guard / Permission | Request (`body`/`query`) | Response Envelope & Error Codes |
|--------|------|--------------------|--------------------------|---------------------------------|
| `POST` | `/v1/<resource>` | `requireAuth` + `<perm>` | `<module>.create.body` | `201` `{ data, meta }` · `409` `CONFLICT` |

## 8. UI Surfaces & Atomic Components
- **Routes & URL State**: Query parameters for filters, search, sort, and tabs.
- **Components**: `atoms/*`, `molecules/select-*`, `organisms/<module>/<module>-*`, `views/<module>/<module>-*-view`.

## 9. Decision Log & Open Questions
- **D<xx>**: <Decision made during discovery and why alternatives were rejected>.
```

After writing the PRD/Spec, hand off to the [`feature-planning`](../feature-planning/SKILL.md) skill to generate the step-by-step implementation plan.
