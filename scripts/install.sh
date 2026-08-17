#!/usr/bin/env bash
set -euo pipefail

REPO="quanvio/quansweep"
INSTALL_DIR="/Applications"
APP_PATH="${INSTALL_DIR}/QuanSweep.app"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "QuanSweep is built for macOS only." >&2
    exit 1
fi

echo "==> Looking up the latest QuanSweep release..."
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
RELEASE_JSON=$(curl -fsSL "${API_URL}")
DOWNLOAD_URL=$(echo "${RELEASE_JSON}" | grep '"browser_download_url":' | grep 'QuanSweep-.*\.zip' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
LATEST_TAG=$(echo "${RELEASE_JSON}" | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')

if [[ -z "${DOWNLOAD_URL}" ]]; then
    echo "Could not find a release download. Please install manually from https://github.com/${REPO}/releases" >&2
    exit 1
fi

echo "==> Latest release: ${LATEST_TAG}"
echo "==> Downloading QuanSweep..."
curl -fsSL --progress-bar -o "${TMP_DIR}/QuanSweep.zip" "${DOWNLOAD_URL}"

echo "==> Preparing ${INSTALL_DIR}..."
if pgrep -xq "QuanSweep"; then
    echo "==> QuanSweep is currently running. Quitting it before updating..."
    osascript -e 'quit app "QuanSweep"' 2>/dev/null || true
    sleep 1
fi

if [[ -d "${APP_PATH}" ]]; then
    rm -rf "${APP_PATH}"
fi

echo "==> Installing to ${INSTALL_DIR}..."
unzip -q -o "${TMP_DIR}/QuanSweep.zip" -d "${INSTALL_DIR}"

if [[ ! -d "${APP_PATH}" ]]; then
    echo "Installation failed: QuanSweep.app was not extracted." >&2
    exit 1
fi

echo "==> Removing macOS quarantine flag..."
xattr -cr "${APP_PATH}" 2>/dev/null || true

echo "==> QuanSweep installed at ${APP_PATH}"
INSTALLED_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "unknown")
echo "==> Installed version: ${INSTALLED_VERSION}"

echo ""
echo "Because QuanSweep is distributed directly rather than through the Mac App Store,"
echo "macOS may ask you to approve the first launch:"
echo "  1. Right-click ${APP_PATH} → Open."
echo "  2. If a warning appears, approve it in System Settings → Privacy & Security."
echo ""
echo "QuanSweep needs Full Disk Access to scan caches and residues:"
echo "  System Settings → Privacy & Security → Full Disk Access → add QuanSweep"
echo ""

read -rp "Open QuanSweep now? [Y/n]: " answer
if [[ "${answer:-Y}" =~ ^[Yy]$ ]]; then
    open "${APP_PATH}"
fi
