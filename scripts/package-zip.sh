#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"
scripts/build-app.sh

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" scripts/Info.plist)
ZIP_NAME="QuanSweep-${VERSION}.zip"

CLEAN_DIR="$(mktemp -d)"
trap 'rm -rf "$CLEAN_DIR"' EXIT

echo "==> Creating clean distribution copy..."
cp -R "$ROOT_DIR/QuanSweep.app" "$CLEAN_DIR/QuanSweep.app"
# Strip macOS extended attributes (provenance, quarantine, etc.) so downloaded
# bundles don't trigger "app is damaged" warnings from resource-fork entries.
xattr -cr "$CLEAN_DIR/QuanSweep.app"
find "$CLEAN_DIR/QuanSweep.app" -name '.DS_Store' -delete
find "$CLEAN_DIR/QuanSweep.app" -name '._*' -delete

rm -f "$ZIP_NAME"
# Use zip -X to exclude extended attributes / resource forks from the archive.
# This prevents the "app is damaged" warning some users see on first launch.
cd "$CLEAN_DIR"
zip -r -X "$ROOT_DIR/$ZIP_NAME" QuanSweep.app >/dev/null
cd "$ROOT_DIR"

echo ""
echo "Distribution package: $ZIP_NAME"
