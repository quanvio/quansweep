#!/usr/bin/env bash
set -euo pipefail

REPO="quanvio/quansweep"
INSTALL_DIR="/Applications"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "QuanSweep is built for macOS only." >&2
    exit 1
fi

echo "==> Looking up the latest QuanSweep release..."
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
DOWNLOAD_URL=$(curl -fsSL "${API_URL}" | grep '"browser_download_url":' | grep 'QuanSweep-.*\.zip' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')

if [[ -z "${DOWNLOAD_URL}" ]]; then
    echo "Could not find a release download. Please install manually from https://github.com/${REPO}/releases" >&2
    exit 1
fi

echo "==> Downloading QuanSweep..."
curl -fsSL --progress-bar -o "${TMP_DIR}/QuanSweep.zip" "${DOWNLOAD_URL}"

echo "==> Installing to ${INSTALL_DIR}..."
unzip -q -o "${TMP_DIR}/QuanSweep.zip" -d "${INSTALL_DIR}"

if [[ ! -d "${INSTALL_DIR}/QuanSweep.app" ]]; then
    echo "Installation failed: QuanSweep.app was not extracted." >&2
    exit 1
fi

echo "==> QuanSweep installed at ${INSTALL_DIR}/QuanSweep.app"
echo ""
echo "Because QuanSweep is distributed directly rather than through the Mac App Store,"
echo "macOS may ask you to approve the first launch:"
echo "  1. Right-click ${INSTALL_DIR}/QuanSweep.app → Open."
echo "  2. If a warning appears, approve it in System Settings → Privacy & Security."
echo "  3. QuanSweep needs Full Disk Access to scan caches and residues."
echo "     Go to System Settings → Privacy & Security → Full Disk Access → add QuanSweep."
echo ""

read -rp "Open QuanSweep now? [Y/n]: " answer
if [[ "${answer:-Y}" =~ ^[Yy]$ ]]; then
    open "${INSTALL_DIR}/QuanSweep.app"
fi
