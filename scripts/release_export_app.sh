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
DRY_RUN="${DRY_RUN:-1}"
DEVELOPER_ID_EXPORT="${DEVELOPER_ID_EXPORT:-0}"

mkdir -p "$EXPORT_DIR" "$LOG_DIR"

cd "$ROOT_DIR"

echo "MenuBarDeclutter release export"
echo "Archive: $ARCHIVE_PATH"
echo "Export directory: $EXPORT_DIR"
echo "App path: $APP_PATH"
echo "Log: $LOG_FILE"
echo "Dry run: $DRY_RUN"
echo "Developer ID export opt-in: $DEVELOPER_ID_EXPORT"
echo

if [[ ! -d "$ARCHIVE_PATH" ]]; then
  echo "FAIL: archive path is missing: $ARCHIVE_PATH" >&2
  exit 1
fi

rm -rf "$APP_PATH"
SOURCE_APP="$ARCHIVE_PATH/Products/Applications/$APP_NAME"

if [[ "$DRY_RUN" == "1" ]]; then
  if [[ ! -d "$SOURCE_APP" ]]; then
    echo "FAIL: archived app is missing: $SOURCE_APP" >&2
    exit 1
  fi
  echo "INFO: dry-run export copies the archived app directly and does not require Developer ID credentials."
  echo "+ ditto \"$SOURCE_APP\" \"$APP_PATH\""
  ditto "$SOURCE_APP" "$APP_PATH" 2>&1 | tee "$LOG_FILE"
elif [[ "$DEVELOPER_ID_EXPORT" != "1" ]]; then
  echo "FAIL: Developer ID export is out of the current project scope and must be explicitly opted into." >&2
  echo "Use the default dry-run export, or set DEVELOPER_ID_EXPORT=1 only after Developer ID distribution is requested." >&2
  exit 2
elif [[ -f "$EXPORT_OPTIONS_PLIST" ]]; then
  echo "+ xcodebuild -exportArchive -archivePath \"$ARCHIVE_PATH\" -exportPath \"$EXPORT_DIR\" -exportOptionsPlist \"$EXPORT_OPTIONS_PLIST\""
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    2>&1 | tee "$LOG_FILE"
else
  echo "FAIL: Developer ID export options plist is missing: $EXPORT_OPTIONS_PLIST" >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "FAIL: exported app was not created at $APP_PATH" >&2
  exit 1
fi

echo "PASS: exported app created at $APP_PATH"
