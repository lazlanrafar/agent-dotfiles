---
name: modern-frontend
description: >-
  Modern Frontend Engineering skill for Next.js 15+ (App Router, React 19) and Svelte 5 (Runes, SvelteKit, Astro)
  with Tailwind CSS v4 and shadcn/ui. Distills Vercel React best practices, Emil Kowalski design engineering,
  Atomic Design (atoms/molecules/organisms), URL-driven table/filter state, and zero call-site restyling.
  Use when building, refactoring, or reviewing web UI components, pages, data tables, or forms.
---

# Modern Frontend & Design Engineering Skill

Frontend architecture and UI polish guidelines for **Next.js 15+ (React 19)** and **Svelte 5 (Runes / SvelteKit / Astro)** using **Tailwind CSS v4** and **shadcn/ui**, integrating rules from `vercel-react-best-practices`, `emil-design-eng`, and `taste-skill`.

---

## 1. Atomic Design & Component Ownership

1. **Read `DESIGN.md` First**: Before adding or modifying UI in an app, check its `DESIGN.md` (or `/design-system` specimen page) for design tokens, typography scale, radii, and component rules.
2. **Strict Atomic Hierarchy (`components/{atoms,molecules,organisms}`)**:
   - **`atoms/`**: All `shadcn/ui` or `shadcn-svelte` primitives (`Button`, `Input`, `Dialog`, `Badge`).
   - **`molecules/`**: Domain-agnostic or single-purpose composite controls (`DataTable`, `SearchFilterBar`, `SelectUser`, `SelectCategory` comboboxes).
   - **`organisms/{module}/`**: Feature-specific sections prefixed with the module name (`order/order-data-table.tsx`, `item/item-board.svelte` — never generic names like `header.tsx` inside a module folder).
3. **Zero Call-Site Restyling (Non-Negotiable)**:
   - A component owns how it looks. Call sites pass domain data, a documented `variant`/`size`, and at most layout placement classes (`w-full`, `col-span-2`, `flex-1`).
   - **Never override colors, border radii, shadows, borders, typography, or internal padding at the call site**. If a visual style needs adjustment, update the shared component and its design-system specimen once.
4. **Custom Pickers Over Native `<select>` for Dynamic Data**:
   - Whenever options come from the database, workspace, or API (users, categories, outlets, currencies), use a reusable searchable combobox molecule (`<SelectCategory creatable />`), never a raw `<select>`.

---

## 2. URL as Single Source of Truth for View State

- **Every list filter, search query, sort column/direction, pagination cursor/page, date range, and active tab must live in the URL query string** (via `nuqs` in Next.js or `url-state.ts` in SvelteKit).
- Holding filter/tab/sort state only in local `useState` / `$state` breaks page refresh, back/forward navigation, and link sharing.
- **Standard List Screen Shape**:
  - One header row: filter/search bar on the left, primary table actions on the right.
  - Shared `DataTable` molecule configured by a dedicated columns definition file.
  - Two distinct empty states with clear copy: **"None created yet"** (empty resource) vs. **"No items match your filters"** (with a one-click "Reset filters" action).

---

## 3. Next.js 15+ & React 19 Best Practices (`vercel-react-best-practices`)

1. **Server Components & BFF Data Access**:
   - Frontend apps never query the database directly. All mutations and authenticated calls go through thin Server Actions (`actions/{feature}.actions.ts`) wrapping the typed API client (`@repo/api-client`).
   - Fetch independent resources in parallel inside Server Components (`Promise.all(...)`) and stream slow secondary sections with `<Suspense>`.
2. **Composition Over Boolean Prop Proliferation**:
   - Do not add 8 boolean flags (`isCompact`, `withHeader`, `showFooter`, `isEditing`) to a single component. Expose compound components (`Card.Header`, `Card.Body`, `Card.Footer`) or explicit variant unions.
3. **React 19 Idioms**:
   - Pass `ref` as a standard prop without `forwardRef`.
   - Avoid unnecessary `useEffect` for derived state — compute derived values during render or memoize expensive pure calculations.

---

## 4. Svelte 5 Runes & SvelteKit Best Practices

- Use **Svelte 5 Runes** exclusively: `$state()`, `$derived()`, `$derived.by()`, `$props()`, and `$bindable()`. Do not use legacy Svelte 4 `export let`, `$:`, or `<slot>` (use `{#snippet ...}` and `{@render ...}`).
- Keep `$effect()` only for DOM/browser synchronization or analytics side effects — never use `$effect()` to synchronize derived state variables.
- **Strict BFF Boundary**: The browser never talks directly to internal backend/AI microservices; SvelteKit server routes (`+page.server.ts`, `+server.ts`, `src/lib/server/`) own cookies, encryption, and service hops.

---

## 5. Design Engineering & UI Craft (`emil-design-eng` & `taste-skill`)

- **Anti-Slop Layout & Typography**: Use tabular numerals (`tabular-nums`) on all financial amounts, counters, timestamps, and table columns so digits align vertically and never jitter during updates.
- **Interactive Polish**:
  - Every async action button must display a pending indicator and disable duplicate submissions without shifting layout width.
  - Maintain keyboard navigability (`Escape` closes overlays, focus trap inside modals, visible `:focus-visible` rings) and verify with `@axe-core/playwright`.
  - Keep first-load JS budgets tight (<300 kB gzip per route); lazy-load heavy editors, charts, or canvas engines.
