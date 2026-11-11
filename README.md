# Agent Dotfiles & Customizations

Portable repository for AI agent customizations (skills, rules, plugins, and MCP configuration templates) for seamless multi-device migration.

## Structure

```text
agent-dotfiles/
├── install.sh                    # Symlinks plugins into ~/.gemini/config/plugins/
├── .gitignore                    # Excludes local secrets and tokens
├── mcp/
│   └── mcp_config.template.json  # Sanitized MCP server configuration template
└── plugins/
    ├── rust-developer/           # Idiomatic Rust 2024 skill (roadmap.sh/rust + rust-lang.org/learn)
    ├── python-developer/         # Python 3.12+ & Data Analysis skills (roadmap.sh/python, python-data-analysis, docs.python.org/3)
    ├── backend-engineer/         # Engineering fundamentals (Architecture, System Design, API & Security, SQL & DB, CS & Algorithms)
    ├── caveman/                  # Ultra-concise communication & execution workflows
    └── ponytail/                 # Lazy senior developer mode (YAGNI / stdlib-first)
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
