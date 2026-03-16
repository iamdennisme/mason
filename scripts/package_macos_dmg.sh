#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT_DIR}"

SKIP_BUILD=0
SKIP_JRE_DOWNLOAD=0
VERSION_OVERRIDE=""

usage() {
  cat <<'EOF'
Usage: ./scripts/package_macos_dmg.sh [options]

Options:
  --version <version>     Override version used in DMG filename and Info.plist
  --skip-build            Skip `cargo build --release`
  --skip-jre-download     Reuse existing resources/jre (do not download)
  -h, --help              Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION_OVERRIDE="${2:-}"
      if [[ -z "${VERSION_OVERRIDE}" ]]; then
        echo "Missing value for --version" >&2
        exit 1
      fi
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --skip-jre-download)
      SKIP_JRE_DOWNLOAD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script only supports macOS." >&2
  exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
  echo "Missing required command: hdiutil" >&2
  exit 1
fi

if [[ -n "${VERSION_OVERRIDE}" ]]; then
  VERSION="${VERSION_OVERRIDE}"
else
  VERSION="$(awk -F'"' '/^version =/{print $2; exit}' Cargo.toml)"
fi

if [[ -z "${VERSION}" ]]; then
  echo "Failed to resolve app version." >&2
  exit 1
fi

if [[ ! -f "resources/walle/walle-cli-all.jar" ]]; then
  echo "Missing resources/walle/walle-cli-all.jar" >&2
  exit 1
fi

if [[ "${SKIP_JRE_DOWNLOAD}" -eq 0 ]]; then
  "${ROOT_DIR}/scripts/download_jre.sh" "resources/jre"
fi

if [[ ! -x "resources/jre/bin/java" ]]; then
  echo "Missing embedded JRE executable at resources/jre/bin/java" >&2
  echo "Try rerun without --skip-jre-download." >&2
  exit 1
fi

if [[ "${SKIP_BUILD}" -eq 0 ]]; then
  cargo build --release
fi

if [[ ! -x "target/release/mason" ]]; then
  echo "Missing target/release/mason. Build failed or binary not found." >&2
  exit 1
fi

APP_DIR="dist/Mason.app"
DMG_PATH="dist/Mason-${VERSION}-macos.dmg"
SHA_PATH="${DMG_PATH}.sha256"
INSTALL_GUIDE="dist/MACOS_INSTALL.md"

rm -rf "${APP_DIR}" "${DMG_PATH}" "${SHA_PATH}" "${INSTALL_GUIDE}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources/walle"

cp "target/release/mason" "${APP_DIR}/Contents/MacOS/mason"
chmod +x "${APP_DIR}/Contents/MacOS/mason"
cp "resources/walle/walle-cli-all.jar" "${APP_DIR}/Contents/Resources/walle/walle-cli-all.jar"
cp -R "resources/jre" "${APP_DIR}/Contents/Resources/jre"
cp "resources/icons/mason.icns" "${APP_DIR}/Contents/Resources/mason.icns"

cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>mason</string>
  <key>CFBundleIdentifier</key>
  <string>com.taicheng.mason</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Mason</string>
  <key>CFBundleIconFile</key>
  <string>mason.icns</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
</dict>
</plist>
PLIST

hdiutil create -volname "Mason" -srcfolder "${APP_DIR}" -ov -format UDZO "${DMG_PATH}"
shasum -a 256 "${DMG_PATH}" > "${SHA_PATH}"

cat > "${INSTALL_GUIDE}" <<'GUIDE'
# Mason macOS Installation (Apple Silicon)

This macOS package is not notarized (no Apple Developer account yet).
If Gatekeeper blocks launch on first run, do this:

1. Drag `Mason.app` to `Applications`.
2. In `Applications`, right-click `Mason.app` and click `Open`.
3. In the warning dialog, click `Open` again.

Optional terminal fallback:

```bash
xattr -dr com.apple.quarantine /Applications/Mason.app
```

Notes:
- Supported architecture: Apple Silicon (arm64) only.
- Embedded JRE is bundled inside the app.
GUIDE

echo "Packaged:"
echo "  ${DMG_PATH}"
echo "  ${SHA_PATH}"
echo "  ${INSTALL_GUIDE}"
