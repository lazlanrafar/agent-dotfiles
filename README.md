# Agent Customizations & Sync

Repositori portabel untuk menyimpan kustomisasi AI agent (skills, rules, plugins, MCP config template) agar mudah migrasi antar-device.

## Struktur

```text
agent-customizations/
├── install.sh                  # Script symlink plugin ke ~/.gemini/config/plugins/
├── .gitignore                  # Filter token/secret lokal
├── mcp/
│   └── mcp_config.template.json # Template konfigurasi MCP server (tanpa secret)
└── plugins/
    ├── rust-developer/         # Skill & pedoman Rust (roadmap.sh/rust + rust-lang.org/learn)
    ├── python-developer/       # Skill Python 3.12+ & Data Analysis (roadmap.sh/python, python-data-analysis, docs.python.org/3)
    ├── backend-engineer/       # Fundamental Engineering (Backend, System Design, API & Security, SQL & DB, CS & Algorithms)
    ├── caveman/                # Mode komunikasi terkompresi
    └── ponytail/               # Mode lazy senior dev (YAGNI/stdlib)
```

## Setup di Device Baru

1. Clone repo ini:
   ```bash
   git clone <repo-url> ~/agent-customizations
   cd ~/agent-customizations
   ```
2. Jalankan instalasi:
   ```bash
   ./install.sh
   ```
3. Konfigurasi kredensial MCP di `~/.gemini/config/mcp_config.json` (isi token Boekti / Exa dll).

## Pembagian Peran dengan Boekti (Online Memory)

- **Git Repo**: Menyimpan instruksi eksekusi, kode skill, skrip pengujian, dan konfigurasi toolchain yang harus identik di tiap mesin.
- **Boekti (`boekti.lazlanrafar.com`)**: Menyimpan memori dinamis, catatan keputusan arsitektur (ADR), backlog/sprint items, dan dokumentasi proyek yang diakses via Boekti MCP server.
