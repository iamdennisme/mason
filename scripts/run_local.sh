#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT_DIR}"

cargo build --release

if [[ "$(uname -s)" == "Darwin" ]]; then
  RUNTIME_RES_DIR="target/Resources"
else
  RUNTIME_RES_DIR="target/release/resources"
fi

"${ROOT_DIR}/scripts/download_jre.sh" "${RUNTIME_RES_DIR}/jre"

mkdir -p "${RUNTIME_RES_DIR}/walle"
cp resources/walle/walle-cli-all.jar "${RUNTIME_RES_DIR}/walle/walle-cli-all.jar"

exec "${ROOT_DIR}/target/release/mason"
