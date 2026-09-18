# Tacet companion integration

Obvious Intel uses Tacet as the recommended meeting recording and recap companion on Intel Macs.

Tacet is an independent open-source project maintained at:

https://github.com/Tacetapp/tacet

It is licensed under the MIT License.

## Why Tacet

Tacet already provides the parts that would otherwise need to be rebuilt inside this repository:

- Intel Mac support
- ScreenCaptureKit-based system audio capture
- microphone capture through AVAudioEngine
- periodic screen frames
- 16 kHz PCM output suitable for speech recognition
- faster-whisper on Intel Macs
- speaker identification and diarization
- local meeting storage
- summaries and follow-up analysis

Its native CaptureHelper exposes a documented stdin/stdout protocol:

- 0x01: system audio, float32 PCM, 16 kHz mono
- 0x02: JPEG screen frame
- 0x03: JSON status
- 0x04: microphone audio, float32 PCM, 16 kHz mono

Commands are newline-delimited JSON sent over stdin.

## Installation

From the Obvious Intel repository:

```bash
chmod +x ./scripts/setup-tacet.sh ./scripts/run-tacet.sh
./scripts/setup-tacet.sh
```

By default Tacet is cloned to:

```text
~/.local/share/obvious-intel/tacet
```

Then run Tacet's own setup once:

```bash
cd ~/.local/share/obvious-intel/tacet
./setup.sh
```

Tacet's setup chooses `faster-whisper` automatically on Intel Macs.

## Launch

```bash
./scripts/run-tacet.sh
```

## Integration boundary

The current integration intentionally treats Tacet as a companion process rather than copying its source into Obvious Intel.

That gives us several advantages:

1. Tacet can continue receiving upstream fixes.
2. Intel recording bugs can be contributed back to Tacet rather than maintained twice.
3. Obvious Intel stays focused on Obvious compatibility.
4. The hosted Obvious web app is not granted arbitrary direct control of local screen and microphone capture.
5. Tacet's MIT licensing and attribution remain clear.

The next integration step, if needed, is a narrow adapter between Obvious Intel and Tacet's CaptureHelper protocol rather than a new recorder implementation.

## Recall.ai compatibility

This does not make Tacet a drop-in binary replacement for Recall.ai's Desktop Recording SDK.

Obvious currently expects Recall-specific desktop behavior. The wrapper therefore continues to report the official Recall recording capability as unavailable on Intel while identifying Tacet as the recommended companion meeting engine.
