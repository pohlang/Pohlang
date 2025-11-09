#!/bin/bash
# PohLang Installation Script for Linux/macOS
# Usage: curl -sSL https://raw.githubusercontent.com/AlhaqGH/PohLang/main/install/install.sh | bash

set -euo pipefail

REPO="AlhaqGH/PohLang"
DEFAULT_VERSION="v0.6.7"
BIN_NAME="pohlang"

log() {
    printf '%s\n' "$1"
}

require_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log "Error: required tool '$1' not found on PATH."
        exit 1
    fi
}

require_tool curl
require_tool tar
require_tool install

VERSION="${POHLANG_VERSION:-}"
if [[ -z "$VERSION" ]]; then
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"[:space:]]*\)".*/\1/p' \
        | head -n 1 || true)
    if [[ -z "$VERSION" ]]; then
        log "Warn: could not determine the latest release automatically; using ${DEFAULT_VERSION}."
        VERSION="$DEFAULT_VERSION"
    fi
fi

VERSION=${VERSION#refs/tags/}
[[ "$VERSION" != v* ]] && VERSION="v${VERSION#v}"

uname_s=$(uname -s)
uname_m=$(uname -m)
case "$uname_s" in
    Linux*)  OS="linux" ;;
    Darwin*) OS="macos" ;;
    *)
        log "Error: unsupported operating system '$uname_s'."
        exit 1
        ;;
esac

case "$uname_m" in
    x86_64|amd64) ARCH="x64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *)
        log "Error: unsupported architecture '$uname_m'."
        exit 1
        ;;
esac

case "${OS}-${ARCH}" in
    linux-x64) PLATFORM="linux-x64" ;;
    macos-x64) PLATFORM="macos-x64" ;;
    macos-arm64) PLATFORM="macos-arm64" ;;
    *)
        log "Error: no prebuilt PohLang binary for ${OS}-${ARCH}."
        exit 1
        ;;
esac

ASSET="${BIN_NAME}-${VERSION}-${PLATFORM}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET}"

TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t pohlang)
cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT INT TERM

log "Downloading ${ASSET} (${VERSION}) for ${OS}-${ARCH}..."
curl -fL -o "${TMP_DIR}/${ASSET}" "${DOWNLOAD_URL}"

log "Extracting archive..."
tar -xzf "${TMP_DIR}/${ASSET}" -C "${TMP_DIR}"

BIN_PATH="${TMP_DIR}/${BIN_NAME}"
chmod +x "${BIN_PATH}"

INSTALL_DIR="${POHLANG_INSTALL_DIR:-/usr/local/bin}"
if [[ ! -d "${INSTALL_DIR}" ]]; then
    if mkdir -p "${INSTALL_DIR}" 2>/dev/null; then
        :
    elif command -v sudo >/dev/null 2>&1; then
        log "Creating ${INSTALL_DIR} (requires elevated permissions)..."
        sudo mkdir -p "${INSTALL_DIR}"
    else
        log "Error: unable to create ${INSTALL_DIR}."
        exit 1
    fi
fi

TARGET="${INSTALL_DIR}/${BIN_NAME}"
if [[ -w "${INSTALL_DIR}" ]]; then
    install -m 755 "${BIN_PATH}" "${TARGET}"
else
    if command -v sudo >/dev/null 2>&1; then
        log "Installing to ${TARGET} (requires elevated permissions)..."
        sudo install -m 755 "${BIN_PATH}" "${TARGET}"
    else
        log "Error: write access to ${INSTALL_DIR} required (sudo not available)."
        exit 1
    fi
fi

log "Installed PohLang to ${TARGET}."

if command -v "${BIN_NAME}" >/dev/null 2>&1; then
    "${BIN_NAME}" --version || true
else
    log "Note: ${INSTALL_DIR} may not be on your PATH. Add it manually to use '${BIN_NAME}'."
fi

log "Installation complete."
log "Next steps:"
log "  - Run '${BIN_NAME} --version' to verify the installation."
log "  - Visit https://github.com/${REPO} for documentation and examples."
