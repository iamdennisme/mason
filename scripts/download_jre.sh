#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-resources/jre}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin) PLATFORM="mac" ;;
  Linux) PLATFORM="linux" ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac

case "$ARCH" in
  x86_64) API_ARCH="x64" ;;
  arm64|aarch64) API_ARCH="aarch64" ;;
  *)
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

JRE_URL="https://api.adoptium.net/v3/binary/latest/17/ga/${PLATFORM}/${API_ARCH}/jre/hotspot/normal/eclipse?project=jdk"
ARCHIVE="${TMP_DIR}/jre.tar.gz"

echo "Downloading JRE from: ${JRE_URL}"
curl -L --fail --retry 3 -o "${ARCHIVE}" "${JRE_URL}"
tar -xzf "${ARCHIVE}" -C "${TMP_DIR}"

if [[ "${PLATFORM}" == "mac" ]]; then
  JRE_ROOT="$(find "${TMP_DIR}" -type d -path "*/Contents/Home" | head -n 1)"
else
  JRE_ROOT="$(find "${TMP_DIR}" -type f -path "*/bin/java" | head -n 1 | xargs -I{} dirname "{}" | xargs -I{} dirname "{}")"
fi

if [[ -z "${JRE_ROOT}" || ! -d "${JRE_ROOT}" ]]; then
  echo "Failed to locate extracted JRE root" >&2
  exit 1
fi

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"
cp -R "${JRE_ROOT}/." "${OUT_DIR}/"

echo "Embedded JRE ready at: ${OUT_DIR}"
ls -la "${OUT_DIR}/bin" | sed -n '1,6p'
