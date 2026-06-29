#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:-${1:-$ROOT_DIR/build/Export/MenuBarDeclutter.app}}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/build/Logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/notarization-staple.log}"

mkdir -p "$LOG_DIR"

cd "$ROOT_DIR"

echo "MenuBarDeclutter notarization staple"
echo "App: $APP_PATH"
echo "Log: $LOG_FILE"
echo

if [[ ! -d "$APP_PATH" ]]; then
  echo "FAIL: app path is missing: $APP_PATH" >&2
  exit 1
fi

echo "+ xcrun stapler staple \"$APP_PATH\""
xcrun stapler staple "$APP_PATH" 2>&1 | tee "$LOG_FILE"

echo "+ xcrun stapler validate \"$APP_PATH\""
xcrun stapler validate "$APP_PATH" 2>&1 | tee -a "$LOG_FILE"

echo "PASS: staple validation completed."
