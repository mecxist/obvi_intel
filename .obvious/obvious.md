# obvi_intel — obvious.md

## Repository

- **Repo:** mecxist/obvi_intel
- **Default branch:** main
- **Status:** Obvious Intel Builder — source and scripts that produce **Obvious Intel.app**, an Intel-compatible Tauri wrapper for Obvious.

## What this file is

Top-level agent guidance for working in this repository.

## Terminology

- **Obvious Intel Builder** = this repository, its source, and its build scripts
- **Obvious Intel.app** = the generated Intel-compatible desktop wrapper
- **wrapper** = the generated app, not this repository
- **builder** = what a user downloads from GitHub

Do not rename internal package identifiers such as `obvious-intel-wrapper` or `ai.obvious.intel.compat` unless a change is clearly necessary.

## Stack

- Tauri 2 desktop shell in `src-tauri/`
- Node/`@tauri-apps/cli` for the Intel (`x86_64-apple-darwin`) build
- Optional Tacet companion via `scripts/setup-tacet.sh` and `scripts/run-tacet.sh`

## Commands

```bash
chmod +x ./scripts/build-intel.sh ./scripts/inspect-official.sh ./scripts/setup-tacet.sh ./scripts/run-tacet.sh
./scripts/build-intel.sh
```

The built app is normally at:

```text
src-tauri/target/x86_64-apple-darwin/release/bundle/macos/Obvious Intel.app
```

## Meeting capture

Recall.ai does not provide an Intel Mac build. Tacet is the open-source companion on `main` for meeting capture and recap. The wrapper still reports the official Recall capability as unavailable.

## Snapshot

- `snapshotId: null`
