#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_DIR="$ROOT_DIR/QuanSweep.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$ROOT_DIR/logo/AppIcon.iconset"
ICNS_PATH="$ROOT_DIR/logo/AppIcon.icns"
SOURCE_ICON="$ROOT_DIR/logo/quansweep.png"

echo "Building QuanSweep release..."
cd "$ROOT_DIR"
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/QuanSweep" "$MACOS_DIR/QuanSweep"
cp "$SCRIPT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"

# SPM may produce a resources bundle next to the executable; copy it if present.
for resource in "$BUILD_DIR"/QuanSweep*.resources; do
    if [[ -d "$resource" ]]; then
        cp -R "$resource" "$RESOURCES_DIR/$(basename "$resource")"
    fi
done

echo "Building AppIcon.icns..."
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

sips -z 16 16     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16.png"       >/dev/null
sips -z 32 32     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png"   >/dev/null
sips -z 32 32     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32.png"       >/dev/null
sips -z 64 64     "$SOURCE_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png"   >/dev/null
sips -z 128 128   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128.png"     >/dev/null
sips -z 256 256   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png"  >/dev/null
sips -z 256 256   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256.png"     >/dev/null
sips -z 512 512   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png"  >/dev/null
sips -z 512 512   "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512.png"     >/dev/null
sips -z 1024 1024 "$SOURCE_ICON" --out "$ICONSET_DIR/icon_512x512@2x.png"  >/dev/null

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"
rm -rf "$ICONSET_DIR"

cp "$ICNS_PATH" "$RESOURCES_DIR/AppIcon.icns"

chmod +x "$MACOS_DIR/QuanSweep"

echo "Done: $APP_DIR"
echo ""
echo "To run:      open '$APP_DIR'"
echo "To install:  cp -R '$APP_DIR' /Applications/"
