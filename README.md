# Englearn

Menu bar helper to turn your daily notes (Chinese or English) into:
- **Spoken Script** (natural, can read aloud)
- **Formal Writing** (more professional)

Supports **Gemini** and **DeepSeek** via your own API keys (stored in app preferences as plain text).

Recommended defaults:
- DeepSeek: Base URL `https://api.deepseek.com`, model `deepseek-chat`
- Gemini: Base URL `https://generativelanguage.googleapis.com`, model `gemini-3-flash-preview` (or any `/v1beta/models/...` model)

## Run (dev)

```bash
swift run
```

## Build a `.app` bundle (no Xcode)

```bash
./scripts/package_app.sh
open dist/Englearn.app
```

## Privacy

See `PRIVACY.md`.
