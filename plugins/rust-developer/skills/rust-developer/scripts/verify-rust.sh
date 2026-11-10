#!/usr/bin/env bash
# verify-rust.sh: minimal quality check for Rust projects
set -euo pipefail

echo "==> 1. Checking format..."
cargo fmt -- --check

echo "==> 2. Checking compilation..."
cargo check

echo "==> 3. Running Clippy..."
cargo clippy --all-targets --all-features -- -D warnings

echo "==> 4. Running tests..."
cargo test

echo "==> All Rust quality checks passed."
