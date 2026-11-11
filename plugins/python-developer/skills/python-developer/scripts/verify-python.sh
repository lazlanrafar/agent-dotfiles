#!/usr/bin/env bash
# verify-python.sh — quality gate untuk Python project
# Jalankan dari root project. Exit non-zero jika ada yang gagal.
set -euo pipefail

echo "=== Python Quality Gate ==="

# 1. Format check (ruff, Black-compatible)
echo "[1/4] ruff format --check"
ruff format --check .

# 2. Linting (ruff: replaces flake8, isort, pyupgrade, etc.)
echo "[2/4] ruff check"
ruff check .

# 3. Type checking
echo "[3/4] mypy --strict"
mypy . --strict

# 4. Tests dengan coverage
echo "[4/4] pytest --cov"
pytest --cov=src --cov-report=term-missing --tb=short

echo ""
echo "✓ All checks passed"
