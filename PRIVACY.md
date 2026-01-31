# Privacy

Englearn runs locally on your Mac. It only sends text to the model provider you choose (Gemini or DeepSeek) when you press **Generate** or **Test Connection**.

## What is stored locally

- Your **API key** is stored in macOS app preferences (`UserDefaults`) as **plain text**.
- Your generated content can be stored in a local SQLite database for **History**.

## What is sent to providers

- Your input text
- Your glossary text (if any)
- App-selected settings (domains, jargon level, style)

## What is NOT sent

- Your API key is only used for request authorization and is not logged by the app.

## Delete your data

- Clear API key: Settings → **Clear Key**
- Clear history: delete the `history.sqlite` file in your `~/Library/Application Support/Englearn/` directory

