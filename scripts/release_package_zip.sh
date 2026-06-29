#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:-${1:-$ROOT_DIR/build/Export/MenuBarDeclutter.app}}"
ZIP_PATH="${ZIP_PATH:-$ROOT_DIR/build/Dist/MenuBarDeclutter-alpha.zip}"
VERSION="${VERSION:-0.1.0}"
VERSIONED_ZIP_PATH="${VERSIONED_ZIP_PATH:-$ROOT_DIR/build/Dist/MenuBarDeclutter-v$VERSION.zip}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/build/Logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/release-package.log}"

mkdir -p "$(dirname "$ZIP_PATH")" "$LOG_DIR"

cd "$ROOT_DIR"

echo "MenuBarDeclutter release package"
echo "App: $APP_PATH"
echo "Zip: $ZIP_PATH"
echo "Versioned zip: $VERSIONED_ZIP_PATH"
echo "Log: $LOG_FILE"
echo

if [[ ! -d "$APP_PATH" ]]; then
  echo "FAIL: app path is missing: $APP_PATH" >&2
  exit 1
fi

rm -f "$ZIP_PATH"
echo "+ ditto -c -k --keepParent \"$APP_PATH\" \"$ZIP_PATH\""
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH" 2>&1 | tee "$LOG_FILE"

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "FAIL: zip was not created at $ZIP_PATH" >&2
  exit 1
fi

if [[ "$VERSIONED_ZIP_PATH" != "$ZIP_PATH" ]]; then
  echo "+ cp \"$ZIP_PATH\" \"$VERSIONED_ZIP_PATH\""
  cp "$ZIP_PATH" "$VERSIONED_ZIP_PATH"
fi

echo "PASS: package created at $ZIP_PATH"
if [[ -f "$VERSIONED_ZIP_PATH" ]]; then
  echo "PASS: versioned package available at $VERSIONED_ZIP_PATH"
fi
