#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ICON_DIR="$ROOT_DIR/resources/icons"
MASTER_SVG="$ICON_DIR/mason-master.svg"
MASTER_PNG="$ICON_DIR/mason-master-1024.png"
APP_PNG="$ICON_DIR/mason.png"
APP_ICO="$ICON_DIR/mason.ico"
APP_ICNS="$ICON_DIR/mason.icns"
ICONSET_DIR="$ICON_DIR/AppIcon.iconset"

if ! command -v magick >/dev/null 2>&1; then
  echo "magick not found" >&2
  exit 1
fi

if ! command -v iconutil >/dev/null 2>&1; then
  echo "iconutil not found (required on macOS to build .icns)" >&2
  exit 1
fi

if ! command -v sips >/dev/null 2>&1; then
  echo "sips not found" >&2
  exit 1
fi

if [[ ! -f "$MASTER_SVG" ]]; then
  echo "Missing source SVG: $MASTER_SVG" >&2
  exit 1
fi

mkdir -p "$ICON_DIR"

magick -background none "$MASTER_SVG" -resize 1024x1024 "$MASTER_PNG"
magick "$MASTER_PNG" -resize 512x512 "$APP_PNG"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

sips -z 16 16 "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASTER_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$MASTER_PNG" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "$APP_ICNS"

magick "$MASTER_PNG" -define icon:auto-resize=256,128,64,48,32,24,16 "$APP_ICO"

rm -rf "$ICONSET_DIR"

echo "Generated icons:"
ls -lh "$MASTER_PNG" "$APP_PNG" "$APP_ICNS" "$APP_ICO"
