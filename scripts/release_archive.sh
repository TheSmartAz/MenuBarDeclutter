#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-MenuBarDeclutter}"
CONFIGURATION="${CONFIGURATION:-Release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/Archives/MenuBarDeclutter.xcarchive}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/build/Logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/release-archive.log}"
AD_HOC_SIGNING_OVERRIDES="${AD_HOC_SIGNING_OVERRIDES:-1}"

mkdir -p "$(dirname "$ARCHIVE_PATH")" "$LOG_DIR"

cd "$ROOT_DIR"

echo "MenuBarDeclutter release archive"
echo "Scheme: $SCHEME"
echo "Configuration: $CONFIGURATION"
echo "Archive path: $ARCHIVE_PATH"
echo "Log: $LOG_FILE"
if [[ "$AD_HOC_SIGNING_OVERRIDES" == "1" ]]; then
  echo "Signing: CI-style ad-hoc/no-account overrides"
else
  echo "Signing: project defaults"
fi
echo

command=(
  xcodebuild archive
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "generic/platform=macOS"
  -archivePath "$ARCHIVE_PATH"
)
if [[ "$AD_HOC_SIGNING_OVERRIDES" == "1" ]]; then
  command+=(CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO)
fi

printf "+"
printf " %q" "${command[@]}"
printf "\n"
set +e
"${command[@]}" > "$LOG_FILE" 2>&1
archive_rc="$?"
set -e

if [[ "$archive_rc" -ne 0 ]]; then
  echo "FAIL: archive command failed. Showing the last 120 log lines from $LOG_FILE" >&2
  tail -120 "$LOG_FILE" >&2
  exit "$archive_rc"
fi

if rg -q "warning:" "$LOG_FILE"; then
  echo "WARN: archive completed with warnings. First warning lines from $LOG_FILE:"
  rg -n "warning:" "$LOG_FILE" | head -20
fi

if [[ ! -d "$ARCHIVE_PATH" ]]; then
  echo "FAIL: archive was not created at $ARCHIVE_PATH" >&2
  exit 1
fi

echo "PASS: archive created at $ARCHIVE_PATH"
