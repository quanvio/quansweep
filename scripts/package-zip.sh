#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"
scripts/build-app.sh

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" scripts/Info.plist)
ZIP_NAME="QuanSweep-${VERSION}.zip"

rm -f "$ZIP_NAME"
ditto -c -k --keepParent "$ROOT_DIR/QuanSweep.app" "$ZIP_NAME"

echo ""
echo "Distribution package: $ZIP_NAME"
