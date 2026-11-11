# Agent Dotfiles & Customizations

Portable repository for AI agent customizations (skills, rules, plugins, and MCP configuration templates) for seamless multi-device migration.

## Structure & Skill Taxonomy

```text
agent-dotfiles/
├── install.sh                    # Symlinks plugins into ~/.gemini/config/plugins/
├── .gitignore                    # Excludes local secrets and tokens
├── mcp/
│   └── mcp_config.template.json  # Sanitized MCP server configuration template
└── plugins/
    ├── rust-developer/
    │   └── skills/
    │       └── rust-developer/       # Rust 2024, ownership, lifetimes, Axum, SQLx, Tokio, WASM
    ├── python-developer/
    │   └── skills/
    │       ├── python-developer/     # Python 3.12+, uv, PEP 723/735, ty/mypy, FastAPI, Anthropic AI
    │       └── python-data-analysis/ # Vectorized NumPy, Polars/DuckDB, EDA, Plotly/Streamlit, Airflow
    ├── golang-developer/
    │   └── skills/
    │       └── golang-developer/     # Go 1.24+/1.27, chi/v5, pgx/v5, sqlc, goose, RLS Tx, apperr, MCP
    ├── typescript-developer/
    │   └── skills/
    │       ├── typescript-developer/ # Bun, Turborepo, ElysiaJS (Eden), Drizzle ORM, TypeBox/Zod
    │       ├── frontend-developer/   # Next.js 15 (React 19), Svelte 5 Runes/SvelteKit, URL state, UI craft
    │       ├── module-structure/     # Colocated modules/{module}/{module}.{controller|service|repository|model|dto}
    │       └── atomic-design/        # components/{atoms,molecules,organisms}, {module}-{name}, zero restyling
    ├── flutter-developer/
    │   └── skills/
    │       └── flutter-developer/    # Flutter 3.x MVVM + Repository + Riverpod + freezed + flutter_ui
    ├── backend-engineer/
    │   └── skills/
    │       ├── backend-architecture/ # Clean Architecture, Modular Monolith, Caching, Kafka/RabbitMQ, RED
    │       ├── api-security/         # REST/gRPC/GraphQL/SSE, RFC 7807, Cursor Pagination, JWT/Argon2id, BOLA
    │       ├── database-sql/         # PostgreSQL, forced RLS initPlan, pgvector HNSW, CUID2, atomic ledgers
    │       └── cs-algorithms/        # Big-O complexity, Hash/Heap/Deque/Trie/B-Tree, Graphs, Cache Locality
    ├── growth-marketing/
    │   └── skills/
    │       ├── seo-geo/              # Technical SEO, JSON-LD Entity Schema, Core Web Vitals, llms.txt, GEO/AEO Citability
    │       └── product-marketing/    # Conversion Copywriting (anti-AI-slop), Landing Page CRO, Pricing, Programmatic SEO
    ├── product-planning/
    │   └── skills/
    │       ├── prd-discovery/        # Interactive Socratic interview (7 checkpoints), never assumes, outputs PRD / FEAT_*.md
    │       └── feature-planning/     # File-by-file vertical-slice implementation plan (DB -> Repo -> Service -> Controller -> UI)
    ├── caveman/                      # Ultra-concise communication & execution workflows
    └── ponytail/                     # Lazy senior developer mode (YAGNI / stdlib-first)
```

## Setup on a New Machine

1. Clone this repository:
   ```bash
   git clone https://github.com/lazlanrafar/agent-dotfiles.git ~/agent-dotfiles
   cd ~/agent-dotfiles
   ```
2. Run the installer:
   ```bash
   ./install.sh
   ```
3. Populate your MCP credentials in `~/.gemini/config/mcp_config.json` (Boekti token, Exa API key, etc.).

## Division of Responsibility with Boekti (Online Memory)

- **Git Repository (`agent-dotfiles`)**: Stores static execution rules, engineering skills, verification scripts, and toolchain configurations shared identically across machines.
- **Boekti (`boekti.lazlanrafar.com`)**: Stores dynamic project memory, Architecture Decision Records (ADRs), sprint/backlog items, and project documentation accessed via the Boekti MCP server.
