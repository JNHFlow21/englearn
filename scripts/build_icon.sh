#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SRC_PNG="${1:-$ROOT_DIR/Assets/AppIcon-1024.png}"
OUT_ICNS="$ROOT_DIR/Assets/AppIcon.icns"

if [[ ! -f "$SRC_PNG" ]]; then
  echo "Missing source PNG: $SRC_PNG" >&2
  echo "Provide a 1024x1024 PNG at: Assets/AppIcon-1024.png" >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/Assets"

ICONSET_DIR="$ROOT_DIR/.build/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

function make_png() {
  local size="$1"
  local name="$2"
  /usr/bin/sips -Z "$size" "$SRC_PNG" --out "$ICONSET_DIR/$name" >/dev/null
}

make_png 16 icon_16x16.png
make_png 32 icon_16x16@2x.png
make_png 32 icon_32x32.png
make_png 64 icon_32x32@2x.png
make_png 128 icon_128x128.png
make_png 256 icon_128x128@2x.png
make_png 256 icon_256x256.png
make_png 512 icon_256x256@2x.png
make_png 512 icon_512x512.png
make_png 1024 icon_512x512@2x.png

/usr/bin/iconutil -c icns "$ICONSET_DIR" -o "$OUT_ICNS"
echo "Wrote: $OUT_ICNS"

