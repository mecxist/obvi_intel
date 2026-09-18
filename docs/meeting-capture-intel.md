# Intel Meeting Capture Add-on

This folder contains an experimental **x86_64 macOS meeting-capture helper** for Obvious Intel.

It is **not** a rebuild of Recall.ai's Desktop Recording SDK and it does not use or modify Recall.ai's private native binary. Recall.ai currently supports macOS only on Apple Silicon for the Desktop Recording SDK.

Instead, this add-on uses Apple's native macOS APIs to restore the basic local-capture layer that Intel users otherwise lose:

- ScreenCaptureKit for window/display video
- ScreenCaptureKit for system audio
- AVFoundation for microphone audio
- JSON output so the Tauri wrapper can invoke the helper as a sidecar

## Current output

A recording session writes:

- `meeting.mov` - captured window/display video plus system audio
- `microphone.caf` - the local microphone track when enabled

The two audio sources are intentionally kept separate in this first version. That avoids pretending we have reproduced Recall.ai's full media pipeline before it has been tested on real Intel hardware.

## What this does not reproduce

The add-on does not currently reproduce Recall.ai's:

- proprietary Desktop SDK upload protocol
- participant identity enrichment
- speaker labels
- automatic meeting-provider detection
- Recall-hosted realtime transcription
- Recall SDK upload-token lifecycle

Those remain separate compatibility work.

## Requirements

- Intel Mac
- macOS 13 or newer
- Xcode Command Line Tools with `swiftc`
- Screen Recording permission
- Microphone permission if microphone capture is enabled

## Build only the helper

```bash
chmod +x ./scripts/build-meeting-addon.sh
./scripts/build-meeting-addon.sh
```

The output is:

```text
addons/meeting-capture-intel/bin/obvious-intel-meeting-capture
```

## Build Obvious Intel with the add-on packaged inside

```bash
chmod +x ./scripts/build-intel-with-meeting-addon.sh
./scripts/build-intel-with-meeting-addon.sh
```

That keeps the normal Obvious Intel build path unchanged and creates an opt-in build containing the helper.

## Manual helper test

Check capability and permissions:

```bash
./addons/meeting-capture-intel/bin/obvious-intel-meeting-capture status
```

Ask macOS for the required permissions:

```bash
./addons/meeting-capture-intel/bin/obvious-intel-meeting-capture request-permissions
```

List capturable windows and displays:

```bash
./addons/meeting-capture-intel/bin/obvious-intel-meeting-capture list-sources
```

Start a recording with a source id returned above:

```bash
./addons/meeting-capture-intel/bin/obvious-intel-meeting-capture record \
  --source-id "window:1234" \
  --output-dir "$HOME/Desktop/obvious-intel-test" \
  --capture-microphone true
```

Press `Control-C` to finalize the recording.

## Integration strategy

The Tauri wrapper exposes a separate set of `meeting_addon_*` commands for this helper. The existing Obvious-facing `meeting_window_status` remains conservative: it reports the upstream Recall.ai path as unsupported while also reporting whether the optional local Intel add-on is present.

That separation is intentional. It prevents the wrapper from telling Obvious that the full Recall.ai Desktop SDK is available when only the local capture layer has been restored.

## Upstream references

Recall.ai documents that its Desktop Recording SDK supports macOS on Apple Silicon only. Recall.ai also publishes examples showing how native macOS capture can be implemented using ScreenCaptureKit and AVFoundation. This add-on is an independent implementation using those Apple frameworks; it does not copy or redistribute Recall.ai's private Desktop SDK binary.
