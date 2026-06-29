#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:-${1:-$ROOT_DIR/build/Export/MenuBarDeclutter.app}}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/build/Logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/gatekeeper-validation.log}"
FAILED=0

mkdir -p "$LOG_DIR"
: > "$LOG_FILE"

check() {
  local label="$1"
  shift
  echo "+ $*" | tee -a "$LOG_FILE"
  if "$@" 2>&1 | tee -a "$LOG_FILE"; then
    echo "PASS: $label" | tee -a "$LOG_FILE"
  else
    echo "FAIL: $label" | tee -a "$LOG_FILE"
    FAILED=1
  fi
  echo | tee -a "$LOG_FILE"
}

cd "$ROOT_DIR"

echo "MenuBarDeclutter Gatekeeper validation" | tee -a "$LOG_FILE"
echo "App: $APP_PATH" | tee -a "$LOG_FILE"
echo | tee -a "$LOG_FILE"

if [[ ! -d "$APP_PATH" ]]; then
  echo "FAIL: app path is missing: $APP_PATH" | tee -a "$LOG_FILE"
  exit 1
fi

check "codesign strict verification" codesign --verify --deep --strict --verbose=4 "$APP_PATH"
check "spctl execute assessment" spctl --assess --type execute --verbose=4 "$APP_PATH"
check "stapler validation" xcrun stapler validate "$APP_PATH"

if [[ "$FAILED" -ne 0 ]]; then
  echo "Gatekeeper validation failed. If notarization was only dry-run, spctl/stapler failures are expected and must be recorded." | tee -a "$LOG_FILE"
  exit 1
fi

echo "Gatekeeper validation passed." | tee -a "$LOG_FILE"
