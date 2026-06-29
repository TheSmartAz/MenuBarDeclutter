#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-MenuBarDeclutter}"
CONFIGURATION="${CONFIGURATION:-Release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/Archives/MenuBarDeclutter.xcarchive}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/build/Logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/release-archive.log}"

mkdir -p "$(dirname "$ARCHIVE_PATH")" "$LOG_DIR"

cd "$ROOT_DIR"

echo "MenuBarDeclutter release archive"
echo "Scheme: $SCHEME"
echo "Configuration: $CONFIGURATION"
echo "Archive path: $ARCHIVE_PATH"
echo "Log: $LOG_FILE"
echo

echo "+ xcodebuild archive -scheme \"$SCHEME\" -configuration \"$CONFIGURATION\" -destination \"generic/platform=macOS\" -archivePath \"$ARCHIVE_PATH\""
xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  2>&1 | tee "$LOG_FILE"

if [[ ! -d "$ARCHIVE_PATH" ]]; then
  echo "FAIL: archive was not created at $ARCHIVE_PATH" >&2
  exit 1
fi

echo "PASS: archive created at $ARCHIVE_PATH"
