# Obvious Intel Wrapper for macOS (Unofficial)

Built by **m.j. zilla**  
subscribe for more tools and insights [mecxist.substack.com](https://mecxist.substack.com/)

## Disclaimer

This is an **unofficial compatibility wrapper** provided for **educational and testing purposes**.
It is not affiliated with or endorsed by Obvious. Use at your own risk.

## What This Project Does

Obvious currently distributes its desktop app for Apple Silicon Macs.

This project lets you build a version called **Obvious Intel** that can run on an Intel Mac.

It does **not** modify or convert the original Obvious app. Instead, it creates a separate Intel-compatible desktop app that loads Obvious and recreates supported desktop features where possible.

### What should work

The wrapper is intended to support the main Obvious experience, including:

- signing in
- opening the Obvious app
- projects and agents
- files and workbooks
- links that need to open in your browser
- supported desktop features used by the Obvious web interface

### Meeting capture on Intel

Recall.ai's official Desktop Recording SDK does not support Intel Macs, so the default Obvious Intel build continues to report the upstream meeting-capture capability as unavailable.

This repository now also contains an **optional experimental Intel meeting-capture add-on**. It is an independent x86_64 native capture helper built with Apple's ScreenCaptureKit and AVFoundation APIs. It can capture a selected meeting window or display, system audio, and microphone audio locally.

It is not a port or replacement distribution of Recall.ai's private native SDK, and it does not currently reproduce Recall.ai's meeting detection, participant metadata, hosted transcription, or upload-token pipeline.

The normal Obvious Intel build remains unchanged unless you explicitly choose the add-on build.

---

# Quick Start

You do **not** need to know how to code to try this.

You will use the **Terminal** app on your Mac, but you can copy and paste the commands below exactly as shown.

## Before you start

You need:

- an **Intel Mac**
- macOS
- an internet connection
- this project downloaded to your Mac

The builder also uses a few free developer tools. If one of them is missing, the build may stop and tell you what is missing. See **Setup Help** farther down this page.

## 1. Download this project

Download the repository from GitHub.

If it downloads as a ZIP file, double-click the ZIP to open it.

You should now have a folder for this project somewhere on your Mac, usually in **Downloads**.

## 2. Open Terminal

1. Press **Command + Space** on your keyboard.
2. Type **Terminal**.
3. Press **Return**.

A Terminal window will open.

## 3. Tell Terminal where you downloaded this project

The easiest way is to use Finder instead of typing the folder location yourself.

1. In Terminal, type:

```bash
cd 
```

Make sure there is a space after `cd`.

2. Open Finder and locate the project folder you downloaded.
3. Drag that folder directly into the Terminal window.
4. Press **Return**.

Terminal is now working inside the correct folder.

> If your folder is named `obvious-intel-wrapper` and is in Downloads, you can also paste this instead:
>
> ```bash
> cd ~/Downloads/obvious-intel-wrapper
> ```

## 4. Allow the included builder to run

macOS may prevent a newly downloaded command file from running until you give it permission.

Copy and paste this into Terminal, then press **Return**:

```bash
chmod +x ./scripts/build-intel.sh ./scripts/inspect-official.sh ./scripts/build-meeting-addon.sh ./scripts/build-intel-with-meeting-addon.sh ./scripts/meeting-addon-control.sh
```

**Nothing may appear to happen after you press Return. That is normal.**

You only need to do this once for this downloaded copy of the project.

## 5. Build Obvious Intel

Copy and paste this into Terminal, then press **Return**:

```bash
./scripts/build-intel.sh
```

Terminal will begin showing lines of text while it builds the app. That is normal.

Keep the Terminal window open until the command finishes and you can type into Terminal again.

If the build succeeds, it creates:

```text
Obvious Intel.app
```

## 6. Find the finished app

The finished app is normally placed inside the project's build folder.

To open that folder without searching for it yourself, copy and paste this into Terminal:

```bash
open src-tauri/target/x86_64-apple-darwin/release/bundle/macos/
```

A Finder window should open showing:

```text
Obvious Intel.app
```

## 7. Open Obvious Intel

Double-click **Obvious Intel.app**.

Because this is an unofficial app you built locally, macOS may block it the first time.

If macOS says the app cannot be opened:

1. Find **Obvious Intel.app** in Finder.
2. Right-click it, or hold **Control** and click it.
3. Choose **Open**.
4. Choose **Open** again if macOS asks for confirmation.

You should only need to do this once.

## 8. Sign in and try Obvious

Once the app opens, sign in with your normal Obvious account.

Good first things to test are:

1. Open an existing project.
2. Create or open an agent.
3. Open files or workbooks.
4. Click links that should open in your normal browser.
5. Use Obvious normally and note anything that does not work.

The official Recall.ai meeting-recording path remains unavailable on Intel. If you want to test the experimental local Intel capture add-on, see **Optional Intel Meeting Capture Add-on** below.

---

# Optional Intel Meeting Capture Add-on

This is optional. The normal build above does not include it.

The add-on requires **macOS 13 or newer** and Apple's command-line developer tools.

To build Obvious Intel with the native x86_64 capture helper packaged inside it:

```bash
./scripts/build-intel-with-meeting-addon.sh
```

That produces the normal app bundle plus:

```text
ObviousIntelWithMeetingCapture.dmg
```

The helper is deliberately controlled locally rather than granting the hosted Obvious web page unrestricted screen/microphone capture commands.

Check the add-on:

```bash
./scripts/meeting-addon-control.sh status
```

Request Screen Recording and Microphone permissions:

```bash
./scripts/meeting-addon-control.sh permissions
```

List capturable windows/displays:

```bash
./scripts/meeting-addon-control.sh sources
```

Start a local recording using a source id returned above:

```bash
./scripts/meeting-addon-control.sh record "window:1234" "$HOME/Desktop/obvious-recording" true
```

Press **Control-C** to stop and finalize the recording.

For architecture, limitations, and developer details, see:

```text
docs/meeting-capture-intel.md
```

---

# Setup Help

If the build works, you can ignore this section.

Use this section only if Terminal tells you that something is missing.

## Check the tools the builder needs

Copy and paste these commands into Terminal one at a time:

```bash
xcode-select -p
rustc --version
cargo --version
node --version
npm --version
```

If a command shows a version number or file location, that tool is installed.

If Terminal says **command not found**, use the matching instructions below.

### If Apple Command Line Tools are missing

Paste:

```bash
xcode-select --install
```

Follow the installation window that appears. When installation is complete, close and reopen Terminal and try the build again.

### If Terminal says `rustc: command not found` or `cargo: command not found`

Rust is missing from your Mac.

Install Rust, then close and reopen Terminal before trying the build again.

### If Terminal says `node: command not found` or `npm: command not found`

Node.js is missing from your Mac.

Install Node.js, then close and reopen Terminal before trying the build again.

### If Terminal says the Intel Rust target is missing

Paste:

```bash
rustup target add x86_64-apple-darwin
```

Then start the build again:

```bash
./scripts/build-intel.sh
```

---

# Troubleshooting

## Terminal says `Permission denied`

This usually means Step 4 was skipped.

Paste:

```bash
chmod +x ./scripts/build-intel.sh ./scripts/inspect-official.sh
```

Then try the build again:

```bash
./scripts/build-intel.sh
```

## Terminal says `No such file or directory`

Terminal is probably not inside the project folder.

Go back to **Step 3** and drag the project folder into Terminal after typing `cd `.

Then try the command again.

## The build finished, but I cannot find Obvious Intel

Paste:

```bash
open src-tauri/target/x86_64-apple-darwin/release/bundle/macos/
```

That should open the folder containing **Obvious Intel.app**.

## macOS will not open the app

Right-click **Obvious Intel.app** in Finder and choose **Open** instead of double-clicking it.

If macOS still blocks it, open:

**System Settings → Privacy & Security**

Look for a message about **Obvious Intel** and choose the option that allows it to open.

## Obvious opens, but a feature does nothing

That may be a feature the Intel wrapper does not support yet.

If you report the problem, include:

- what you clicked
- what you expected to happen
- what happened instead
- any error message you saw

## The Obvious meeting button still says recording is unavailable

That is expected. The official Recall.ai Desktop Recording SDK does not support Intel Macs, and this wrapper does not impersonate that SDK.

If you built the optional Intel add-on, use the local add-on controls described above while the direct Obvious/Recall integration is still being mapped.

## The build stops with an error

Look at the final few lines shown in Terminal. The last error is usually the most useful one.

If you need help, copy the error message before closing Terminal.

Still stuck? Message me on Substack: [mecxist.substack.com](https://mecxist.substack.com/)

---

# Optional: Inspect the Official Obvious App

**Most users do not need this section.**

You do not need the official Apple Silicon DMG to build Obvious Intel.

This tool is included for developers who want to compare the wrapper with a current official Obvious release.

If you have an official Obvious DMG, run:

```bash
./scripts/inspect-official.sh /path/to/Obvious_0.34.1_aarch64.dmg
```

For example, if the DMG is in Downloads:

```bash
./scripts/inspect-official.sh ~/Downloads/Obvious_0.34.1_aarch64.dmg
```

The tool creates:

```text
obvious-official-report.txt
```

This can help identify changes in future Obvious releases that may need to be added to the Intel wrapper.

---

# For Developers

The wrapper is a **Tauri 2** application built for:

```text
x86_64-apple-darwin
```

It loads the Obvious web application and includes an initial compatibility layer for desktop commands such as configuration, onboarding state, external links, logging, capability checks, and selected Obvious desktop UI commands.

A development compatibility workflow is:

```bash
./scripts/inspect-official.sh /path/to/Obvious_0.34.1_aarch64.dmg
./scripts/build-intel.sh
```

To include the optional Intel meeting-capture helper:

```bash
./scripts/build-intel-with-meeting-addon.sh
```

The wrapper continues to expose the upstream Recall capability as unsupported, while `get_config` and `meeting_window_status` report whether the independent Intel add-on is packaged. This keeps capability reporting accurate while the remaining Obvious-to-capture integration is developed.

Then launch **Obvious Intel.app**, enable Web Inspector/devtools if needed, and test normal product flows. Missing Tauri invocations can be implemented as they are discovered.

## Why This Exists

Obvious currently targets Apple Silicon Macs. This project explores whether the parts of the product that are not inherently Apple Silicon-specific can remain usable on Intel hardware through a compatibility wrapper.

It is intended to extend access to otherwise capable Intel Macs without bypassing Obvious authentication, subscriptions, or account controls.
