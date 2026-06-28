#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${DEST:-$ROOT_DIR/build/qa-artifacts}"
STAMP="$(date -u +"%Y-%m-%d_%H%M%S")"
OUT_DIR="$DEST/$STAMP"

cd "$ROOT_DIR"
mkdir -p "$OUT_DIR"

echo "Collecting local QA artifacts into $OUT_DIR"
echo "This script does not collect screenshots or screen contents and does not upload anything."

{
  echo "MenuBarDeclutter QA Artifact Manifest"
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "Git: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
  echo "App version/build:"
  /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Config/MenuBarDeclutter-Info.plist 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" Config/MenuBarDeclutter-Info.plist 2>/dev/null || true
} > "$OUT_DIR/manifest.txt"

if [[ -d "$ROOT_DIR/build/reports" ]]; then
  mkdir -p "$OUT_DIR/test-logs"
  cp -R "$ROOT_DIR/build/reports/." "$OUT_DIR/test-logs/" || true
fi

APP_SUPPORT="$HOME/Library/Application Support/MenuBarDeclutter"
if [[ -d "$APP_SUPPORT/Diagnostics" ]]; then
  mkdir -p "$OUT_DIR/diagnostics"
  find "$APP_SUPPORT/Diagnostics" -maxdepth 1 -type f \( -name '*.txt' -o -name '*.json' \) -print0 |
    xargs -0 -I {} cp {} "$OUT_DIR/diagnostics/" || true
fi

if [[ -f "$ROOT_DIR/docs/testing/alpha-rc-qa-run-template.md" ]]; then
  cp "$ROOT_DIR/docs/testing/alpha-rc-qa-run-template.md" "$OUT_DIR/alpha-rc-qa-run.md"
fi

echo "Artifacts collected."
echo "$OUT_DIR"
