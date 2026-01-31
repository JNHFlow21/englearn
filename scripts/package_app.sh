#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="Thought2English"
BIN_NAME="englearn"
BUNDLE_ID="com.englearn.app"
VERSION="${APP_VERSION:-0.1.0}"

echo "Building (release)…"
swift build -c release

BIN_PATH="$ROOT_DIR/.build/release/$BIN_NAME"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "Binary not found: $BIN_PATH" >&2
  exit 1
fi

OUT_DIR="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$OUT_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$OUT_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/$BIN_NAME"
chmod +x "$MACOS_DIR/$BIN_NAME"

# Optional icon hook:
# - put a final icon at Assets/AppIcon.icns (recommended), or
# - generate one from a 1024px source via scripts/build_icon.sh
ICON_FILE=""
if [[ -f "$ROOT_DIR/Assets/AppIcon.icns" ]]; then
  cp "$ROOT_DIR/Assets/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
  ICON_FILE="AppIcon"
fi

ICON_PLIST_ENTRY=""
if [[ -n "$ICON_FILE" ]]; then
  ICON_PLIST_ENTRY="  <key>CFBundleIconFile</key>\n  <string>$ICON_FILE</string>"
fi

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$BIN_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
$(printf "%b\n" "$ICON_PLIST_ENTRY")
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

echo "App bundle created: $OUT_DIR"
echo "Run: open \"$OUT_DIR\""
