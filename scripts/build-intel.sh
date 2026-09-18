#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

command -v node >/dev/null || { echo "Node.js is required"; exit 1; }
command -v npm >/dev/null || { echo "npm is required"; exit 1; }
command -v cargo >/dev/null || { echo "Rust/Cargo is required"; exit 1; }

rustup target add x86_64-apple-darwin
npm install
npm run build:intel

echo
echo "Build complete. Look under src-tauri/target/x86_64-apple-darwin/release/bundle/"
