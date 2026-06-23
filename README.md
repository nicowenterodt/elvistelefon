# Elvistelefon

*A little less conversation, a little more transcription, please.* A macOS menu bar app that turns your voice into text — transcribed **on-device** with Whisper (no API key, no cloud) — and can rewrite it in the unmistakable style of Elvis Presley, the backwards wisdom of Yoda, or the existential dread of Marvin the Paranoid Android. All shook up and ready to roll.

## Features

- **Menu bar app** — lives in the macOS menu bar, no Dock icon, hunk-a hunk-a hidden away
- **Push-to-talk or toggle** — hold a shortcut to record, or press once to start/stop
- **On-device Whisper transcription** — runs locally via [WhisperKit](https://github.com/argmaxinc/WhisperKit) (CoreML, Apple Silicon); works fully offline, no API key required. Defaults to the `large-v3` model for best accuracy
- **Optional OpenAI cloud transcription** — switch the engine to the OpenAI Whisper API in Settings if you prefer
- **Tonality modes** — optionally rewrite transcriptions in character (uses the OpenAI Chat API, so a key is needed *only* for these):
  - **Normal** — raw transcription, no transformation
  - **Elvis Talk** — the King's swagger and Southern charm
  - **Yoda Talk** — inverted speech patterns, hmm
  - **Marvin Talk** — depressed paranoid android from The Hitchhiker's Guide
- **Language-aware** — tonality transformations preserve the detected language
- **Clipboard integration** — transcribed text is automatically copied to clipboard
- **Customizable shortcut** — set any global keyboard shortcut (default: `Cmd+Shift+R`)
- **Toast notifications** — floating overlay shows recording status, results, and milestone messages

## Requirements

- macOS 13 (Ventura) or later, Apple Silicon
- **No API key needed** for transcription (runs on-device). An [OpenAI API key](https://platform.openai.com/api-keys) is optional — only for the Tonality transforms or the cloud transcription engine
- First on-device run downloads the Whisper model once (~1 GB for `large-v3`) into `~/Library/Application Support/Elvistelefon/models`

## Installation

### Download DMG (pre-built)

Grab the latest DMG and get straight to business:

> **[Download Elvistelefon v1.0.0](https://github.com/nicowenterodt/elvistelefon/releases/download/v1.0.0/Elvistelefon-1.0.0.dmg)**

Or browse all releases on the [Releases page](https://github.com/nicowenterodt/elvistelefon/releases). Open the DMG and drag Elvistelefon to your Applications folder.

> **Note — the app is not notarized**, so macOS Gatekeeper will block it on first launch. To open it, do one of the following:
>
> - **Right-click** the app → **Open** → click **Open** in the dialog, or
> - Run in Terminal:
>   ```
>   xattr -cr /Applications/Elvistelefon.app
>   ```
>   then open the app normally.

### Homebrew

A Homebrew Cask template is included in `Casks/elvistelefon.rb`. To use it, set up a personal tap:

1. Create a GitHub repo named `homebrew-elvistelefon`
2. Copy `Casks/elvistelefon.rb` into the repo
3. Replace `USER` with your GitHub username
4. Build the DMG and generate the checksum:
   ```
   make dmg
   shasum -a 256 build/Elvistelefon-1.0.0.dmg
   ```
5. Replace `CHECKSUM` in the formula with the output
6. Create a GitHub release tagged `v1.0.0` and attach the DMG

Then install with:

```
brew install <your-username>/elvistelefon/elvistelefon
```

### Build from source

Requires Swift 5.9+ and Xcode Command Line Tools.

```bash
cd Elvistelefon

# Build the release binary
make build

# Build the .app bundle
make bundle

# Build and run
make run

# Build a DMG for distribution
make dmg

# Clean build artifacts
make clean
```

## Configuration

On first launch, open **Settings** from the menu bar icon:

1. **Transcription** — pick the On-device engine (default) and a model size, then click Download to fetch it once. Or switch to the OpenAI API engine
2. **API Key** *(optional)* — paste your OpenAI API key and click Save; only needed for Tonality transforms or the cloud engine
3. **Recording Mode** — choose Push to Talk (hold to record) or Toggle (press to start/stop)
4. **Tonality Mode** — choose Normal, Elvis Talk, Yoda Talk, or Marvin Talk
5. **Keyboard Shortcut** — click the recorder field and press your desired shortcut

## How it works

1. Press the keyboard shortcut — the King is listening
2. Audio is captured from the microphone and saved as a temporary file
3. The audio is transcribed **on-device** by WhisperKit (or sent to the OpenAI Whisper API if the cloud engine is selected)
4. If a tonality mode is active, the transcription is sent to the OpenAI Chat Completions API for transformation (requires a key)
5. The result is copied to the clipboard and shown in a toast notification — thank you, thank you very much

### Architecture

| File | Purpose |
|------|---------|
| `WhisperTranscribeApp.swift` | App entry point, menu bar setup |
| `AppViewModel.swift` | Core state machine and recording logic |
| `AudioRecorder.swift` | Microphone capture via AVFoundation |
| `TranscriptionProvider.swift` | Protocol abstracting local vs OpenAI transcription backends |
| `LocalWhisperService.swift` | On-device transcription via WhisperKit (model download/load) |
| `WhisperService.swift` | OpenAI Whisper API client (cloud engine) |
| `ChatCompletionService.swift` | OpenAI Chat Completions API client (tonality transforms) |
| `TonalityMode.swift` | Voice transformation modes and prompts |
| `KeychainService.swift` | API key storage |
| `MenuBarView.swift` | Menu bar dropdown UI |
| `SettingsView.swift` | Settings window UI |
| `ToastWindow.swift` | Floating toast notification overlay |

## Security

The OpenAI API key is stored locally at `~/Library/Application Support/Elvistelefon/api-key` with:

- File permissions `0600` (owner read/write only)
- Directory permissions `0700` (owner only)

(macOS data protection / `.completeFileProtection` is not used: it requires the `com.apple.developer.default-data-protection` entitlement, which ad-hoc-signed Cask builds don't have. The owner-only `0600`/`0700` permissions already restrict access to the user.)

The key is entered via a `SecureField` (masked input) and cleared from memory after saving. No keys, tokens, or credentials are hardcoded in the source.

## License

MIT — take care of business, but share the love.
