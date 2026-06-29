#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE_PATH="${ARCHIVE_PATH:-${1:-$ROOT_DIR/build/Archives/MenuBarDeclutter.xcarchive}}"
EXPORT_DIR="${EXPORT_DIR:-$ROOT_DIR/build/Export}"
APP_NAME="${APP_NAME:-MenuBarDeclutter.app}"
APP_PATH="${APP_PATH:-$EXPORT_DIR/$APP_NAME}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/build/Logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/release-export.log}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-$ROOT_DIR/Config/ExportOptions.plist}"

mkdir -p "$EXPORT_DIR" "$LOG_DIR"

cd "$ROOT_DIR"

echo "MenuBarDeclutter release export"
echo "Archive: $ARCHIVE_PATH"
echo "Export directory: $EXPORT_DIR"
echo "App path: $APP_PATH"
echo "Log: $LOG_FILE"
echo

if [[ ! -d "$ARCHIVE_PATH" ]]; then
  echo "FAIL: archive path is missing: $ARCHIVE_PATH" >&2
  exit 1
fi

rm -rf "$APP_PATH"

if [[ -f "$EXPORT_OPTIONS_PLIST" ]]; then
  echo "+ xcodebuild -exportArchive -archivePath \"$ARCHIVE_PATH\" -exportPath \"$EXPORT_DIR\" -exportOptionsPlist \"$EXPORT_OPTIONS_PLIST\""
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    2>&1 | tee "$LOG_FILE"
else
  SOURCE_APP="$ARCHIVE_PATH/Products/Applications/$APP_NAME"
  if [[ ! -d "$SOURCE_APP" ]]; then
    echo "FAIL: archived app is missing: $SOURCE_APP" >&2
    exit 1
  fi
  echo "INFO: Config/ExportOptions.plist not found; copying archived app from Products/Applications."
  echo "INFO: This project has no installer/export customization yet, so direct archive extraction is deterministic."
  echo "+ ditto \"$SOURCE_APP\" \"$APP_PATH\""
  ditto "$SOURCE_APP" "$APP_PATH" 2>&1 | tee "$LOG_FILE"
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "FAIL: exported app was not created at $APP_PATH" >&2
  exit 1
fi

echo "PASS: exported app created at $APP_PATH"
