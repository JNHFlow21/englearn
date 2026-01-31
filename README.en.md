# Thought2English

[中文](README.md)

A small macOS helper that turns your daily notes (Chinese or English) into two English outputs:

- **Spoken Script**: more conversational, closer to “how you’d actually say it” (Crypto Twitter / industry-native tone)
- **Formal Writing**: more professional and workplace-friendly

Supports **Gemini** and **DeepSeek** using your own API keys (stored locally in `UserDefaults` in plain text).

## Screenshots

(TBD)

## Run (dev)

```bash
swift run
```

## Build a `.app` bundle (no Xcode)

```bash
./scripts/package_app.sh
open dist/Thought2English.app
```

## Install via Homebrew (recommended)

```bash
brew tap jnhflow21/thought2english
brew install --cask thought2english
```

Upgrade:

```bash
brew upgrade --cask thought2english
```

## Configuration

Configure in **Settings**:

- Provider (Gemini / DeepSeek)
- Model
- Base URL
- API Key

Recommended defaults:

- DeepSeek: Base URL `https://api.deepseek.com`, model `deepseek-chat`
- Gemini: Base URL `https://generativelanguage.googleapis.com`, model `gemini-3-flash-preview`

## Icon (optional)

Provide a 1024×1024 PNG (centered with generous padding, strong contrast for both light/dark backgrounds).

```bash
# 1) Put your PNG at Assets/AppIcon-1024.png
# 2) Generate Assets/AppIcon.icns
./scripts/build_icon.sh

# 3) Re-package
./scripts/package_app.sh
```

## Privacy

See `PRIVACY.md`.
