# Obvious Intel Wrapper for macOS

Built by **m.j. zilla**  
subscribe for more tools and insights [mecxist.substack.com](https://mecxist.substack.com/)

## Disclaimer

This is an **unofficial compatibility wrapper** and is provided for **educational and testing purposes**.
It is not affiliated with or endorsed by Obvious.

## What This Project Does

Obvious currently distributes its desktop app for Apple Silicon Macs (`arm64`).

This project builds an **Intel-compatible (`x86_64`) macOS wrapper** that loads the Obvious web application inside a native Tauri desktop window and recreates the desktop commands the web app expects where possible.

This does **not** convert the original Apple Silicon Obvious executable into an Intel executable. It creates a separate Intel-compatible desktop wrapper.

### What should work

The wrapper is intended to support the main Obvious experience, including:

- signing in
- opening the Obvious app
- projects and agents
- files and workbooks
- links that need to open in your browser
- basic desktop app commands used by the web interface

### Known limitation

**Meeting capture / desktop recording is not expected to work on Intel Macs right now.**

Obvious uses functionality associated with the Recall.ai Desktop Recording SDK, whose macOS desktop recording support is Apple Silicon-only. The Intel wrapper reports this capability as unavailable rather than pretending it is supported.

The rest of Obvious can still be tested independently of that feature.

## Files

The important files are:

- `scripts/build-intel.sh` - builds the Intel version of the app
- `scripts/inspect-official.sh` - optional tool for inspecting an official Obvious Apple Silicon DMG
- `src-tauri/` - Tauri desktop wrapper
- `README.md` - this guide

## Requirements

You need:

- an **Intel Mac**
- macOS
- an internet connection
- Apple's Command Line Tools
- Rust / Cargo
- Node.js + npm

If you already use development tools on your Mac, you may already have most of these installed.

### Check whether the required tools are installed

Open **Terminal** and copy/paste:

```bash
xcode-select -p
rustc --version
cargo --version
node --version
npm --version
```

If each command prints a path or version number, you are ready to build.

## Quick Start

You do **not** need to understand Rust, Tauri, or the Obvious source code to try this.

### 1) Download this repository

Download the repository from GitHub and unzip it if necessary.

For example, you may end up with a folder like:

```text
~/Downloads/obvious-intel-wrapper/
```

### 2) Open Terminal

On your Mac:

1. Open **Spotlight** with `Command + Space`
2. Type `Terminal`
3. Press **Return**

### 3) Go to the wrapper folder

If the folder is in Downloads, copy/paste:

```bash
cd ~/Downloads/obvious-intel-wrapper
```

If you put the folder somewhere else, the easiest method is:

1. Type `cd ` into Terminal, including the space after `cd`
2. Drag the `obvious-intel-wrapper` folder from Finder into the Terminal window
3. Press **Return**

### 4) Make the build script executable

Copy/paste:

```bash
chmod +x ./scripts/build-intel.sh ./scripts/inspect-official.sh
```

You only need to do this once.

### 5) Build the Intel version

Copy/paste:

```bash
./scripts/build-intel.sh
```

The script builds the app for:

```text
x86_64-apple-darwin
```

When the build finishes successfully, look for:

```text
Obvious Intel.app
```

inside the Tauri build output directory.

A typical Tauri build places the app under a path similar to:

```text
src-tauri/target/x86_64-apple-darwin/release/bundle/macos/
```

### 6) Open Obvious Intel

Double-click:

```text
Obvious Intel.app
```

Because this is an unofficial locally built app, macOS may block it the first time.

If that happens:

1. Find `Obvious Intel.app` in Finder
2. Right-click it
3. Choose **Open**
4. Choose **Open** again if macOS asks for confirmation

You should only need to do this once.

## Optional: Inspect the Official Obvious App

You do **not** need the official Apple Silicon DMG just to build the wrapper.

The inspection script is included for development and compatibility testing. If you have an official Obvious DMG, you can inspect it with:

```bash
./scripts/inspect-official.sh /path/to/Obvious_0.34.1_aarch64.dmg
```

For example, if the DMG is in Downloads:

```bash
./scripts/inspect-official.sh ~/Downloads/Obvious_0.34.1_aarch64.dmg
```

The script creates:

```text
obvious-official-report.txt
```

This report helps identify changes in future Obvious releases that may need to be added to the Intel wrapper.

## First Things to Test

After the app opens, try:

1. Sign in to your Obvious account
2. Open an existing project
3. Create or open an agent
4. Open files or workbooks
5. Test links that should open in your normal browser
6. Use the app normally and note anything that fails

If the web interface calls a desktop command the wrapper does not yet implement, that command can be added to the Tauri compatibility layer.

## Troubleshooting

### `Permission denied`

Run:

```bash
chmod +x ./scripts/build-intel.sh ./scripts/inspect-official.sh
```

Then try again:

```bash
./scripts/build-intel.sh
```

### `cargo: command not found` or `rustc: command not found`

Rust is not installed or is not available in your Terminal environment.

Install Rust, close and reopen Terminal, then run the build again.

### `node: command not found` or `npm: command not found`

Install Node.js, close and reopen Terminal, then run the build again.

### Apple Command Line Tools are missing

Run:

```bash
xcode-select --install
```

Complete Apple's installer, then run the build again.

### Intel target is missing

Run:

```bash
rustup target add x86_64-apple-darwin
```

Then run:

```bash
./scripts/build-intel.sh
```

### The app builds but macOS will not open it

Right-click `Obvious Intel.app` in Finder and choose **Open** instead of double-clicking it.

If macOS still blocks the locally built app, check **System Settings → Privacy & Security** for an option to allow it to open.

### Obvious opens but a feature does nothing

That may mean the web app is calling a Tauri desktop command that the Intel wrapper does not implement yet.

If possible, record:

- what you clicked
- what you expected to happen
- any error shown in the app
- any error shown in Terminal or Web Inspector

That information can be used to add the missing compatibility command.

### Meeting recording does not work

This is currently expected on Intel Macs. The desktop recording dependency used for this capability does not currently provide the Intel macOS support needed by this wrapper.

### Build fails partway through

Scroll to the last error shown in Terminal. The final error is usually the most useful part.

If you are opening an issue, include that error along with:

```bash
uname -m
sw_vers
rustc --version
node --version
```

## For Developers

The wrapper is a **Tauri 2** application built for:

```text
x86_64-apple-darwin
```

It loads the Obvious web application and includes an initial compatibility layer for desktop commands such as configuration, onboarding state, external links, logging, capability checks, and selected Obvious desktop UI commands.

The recommended compatibility workflow is:

```bash
./scripts/inspect-official.sh /path/to/Obvious_0.34.1_aarch64.dmg
./scripts/build-intel.sh
```

Then launch `Obvious Intel.app`, enable Web Inspector/devtools if needed, and test the normal product flows. Missing Tauri invocations can be implemented as they are discovered.

## Why This Exists

Obvious currently targets Apple Silicon Macs. This project explores whether the parts of the product that are not inherently Apple Silicon-specific can remain usable on Intel hardware through a compatibility wrapper.

It is intended to extend access to otherwise capable Intel Macs without bypassing Obvious authentication, subscriptions, or account controls.

---

Still stuck? Message me on Substack: [mecxist.substack.com](https://mecxist.substack.com/)
