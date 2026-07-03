#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:-${1:-$ROOT_DIR/build/Export/MenuBarDeclutter.app}}"
version_from_config() {
  awk '/^MARKETING_VERSION[[:space:]]*=/{ print $3; exit }' "$ROOT_DIR/Config/Shared.xcconfig"
}

VERSION="${VERSION:-$(version_from_config)}"
if [[ -z "$VERSION" ]]; then
  echo "FAIL: could not derive MARKETING_VERSION from Config/Shared.xcconfig" >&2
  exit 1
fi

if [[ "$VERSION" == "0.2" || "$VERSION" == "0.2.0" || "$VERSION" == v0.2* ]]; then
  echo "FAIL: v0.1.x release tooling must not package a v0.2 artifact." >&2
  exit 1
fi

DRY_RUN="${DRY_RUN:-1}"
if [[ "$DRY_RUN" != "0" && "$DRY_RUN" != "1" ]]; then
  echo "FAIL: DRY_RUN must be 0 or 1." >&2
  exit 1
fi

if [[ -z "${ZIP_PATH:-}" ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    ZIP_PATH="$ROOT_DIR/build/Dist/MenuBarDeclutter-v$VERSION-alpha.zip"
  else
    ZIP_PATH="$ROOT_DIR/build/Dist/MenuBarDeclutter-v$VERSION.zip"
  fi
fi
VERSIONED_ZIP_PATH="${VERSIONED_ZIP_PATH:-}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/build/Logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/release-package.log}"

mkdir -p "$(dirname "$ZIP_PATH")" "$LOG_DIR"

cd "$ROOT_DIR"

echo "MenuBarDeclutter release package"
echo "App: $APP_PATH"
echo "Dry run: $DRY_RUN"
echo "Zip: $ZIP_PATH"
if [[ -n "$VERSIONED_ZIP_PATH" ]]; then
  echo "Additional zip copy: $VERSIONED_ZIP_PATH"
else
  echo "Additional zip copy: none"
fi
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

if [[ -n "$VERSIONED_ZIP_PATH" && "$VERSIONED_ZIP_PATH" != "$ZIP_PATH" ]]; then
  echo "+ cp \"$ZIP_PATH\" \"$VERSIONED_ZIP_PATH\""
  cp "$ZIP_PATH" "$VERSIONED_ZIP_PATH"
fi

echo "PASS: package created at $ZIP_PATH"
if [[ -n "$VERSIONED_ZIP_PATH" && -f "$VERSIONED_ZIP_PATH" ]]; then
  echo "PASS: versioned package available at $VERSIONED_ZIP_PATH"
fi
