#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if ! command -v mkdocs >/dev/null 2>&1; then
  echo "[ERROR] mkdocs is not installed or not in PATH" >&2
  exit 1
fi

cd "${REPO_ROOT}"
mkdocs serve --config-file docs/mkdocs.yml --dev-addr 0.0.0.0:8000 "$@"
