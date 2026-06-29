#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP_PATH=""
KEYCHAIN_PROFILE="${NOTARYTOOL_KEYCHAIN_PROFILE:-}"
APPLE_ID="${NOTARYTOOL_APPLE_ID:-${APPLE_ID:-}}"
TEAM_ID="${NOTARYTOOL_TEAM_ID:-${TEAM_ID:-}}"
APP_PASSWORD="${NOTARYTOOL_PASSWORD:-${APP_SPECIFIC_PASSWORD:-}}"
WAIT_FLAG="--wait"
DRY_RUN=0
LOG_DIR="${LOG_DIR:-$ROOT_DIR/build/Logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/notarization-submit.log}"
VERSION="${VERSION:-}"

version_from_config() {
  awk '/^MARKETING_VERSION[[:space:]]*=/{ print $3; exit }' "$ROOT_DIR/Config/Shared.xcconfig"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --keychain-profile)
      KEYCHAIN_PROFILE="${2:-}"
      shift 2
      ;;
    --apple-id)
      APPLE_ID="${2:-}"
      shift 2
      ;;
    --team-id)
      TEAM_ID="${2:-}"
      shift 2
      ;;
    --password)
      APP_PASSWORD="${2:-}"
      shift 2
      ;;
    --wait)
      WAIT_FLAG="--wait"
      shift
      ;;
    --no-wait)
      WAIT_FLAG=""
      shift
      ;;
    -h|--help)
      cat <<EOF
Usage: scripts/release_notarize.sh [--dry-run] [--keychain-profile NAME] ZIP

Credentials:
  Preferred: --keychain-profile NAME or NOTARYTOOL_KEYCHAIN_PROFILE=NAME
  Fallback: NOTARYTOOL_APPLE_ID/APPLE_ID, NOTARYTOOL_TEAM_ID/TEAM_ID,
            NOTARYTOOL_PASSWORD/APP_SPECIFIC_PASSWORD

No credentials are stored by this script.
EOF
      exit 0
      ;;
    *)
      if [[ -z "$ZIP_PATH" ]]; then
        ZIP_PATH="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        exit 2
      fi
      ;;
  esac
done

VERSION="${VERSION:-$(version_from_config)}"
ZIP_PATH="${ZIP_PATH:-$ROOT_DIR/build/Dist/MenuBarDeclutter-v$VERSION.zip}"
mkdir -p "$LOG_DIR"

cd "$ROOT_DIR"

echo "MenuBarDeclutter notarization submit"
echo "Zip: $ZIP_PATH"
echo "Log: $LOG_FILE"
echo

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "FAIL: packaged zip is missing: $ZIP_PATH" >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  {
    echo "DRY-RUN: notarization submission skipped by --dry-run."
    echo "Would submit: $ZIP_PATH"
  } | tee "$LOG_FILE"
  exit 0
fi

if [[ -n "$KEYCHAIN_PROFILE" ]]; then
  echo "+ xcrun notarytool submit \"$ZIP_PATH\" --keychain-profile \"$KEYCHAIN_PROFILE\" $WAIT_FLAG"
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$KEYCHAIN_PROFILE" ${WAIT_FLAG:+$WAIT_FLAG} 2>&1 | tee "$LOG_FILE"
elif [[ -n "$APPLE_ID" && -n "$TEAM_ID" && -n "$APP_PASSWORD" ]]; then
  echo "+ xcrun notarytool submit \"$ZIP_PATH\" --apple-id \"$APPLE_ID\" --team-id \"$TEAM_ID\" --password REDACTED $WAIT_FLAG"
  xcrun notarytool submit "$ZIP_PATH" --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_PASSWORD" ${WAIT_FLAG:+$WAIT_FLAG} 2>&1 | tee "$LOG_FILE"
else
  {
    echo "FAIL: notarization credentials are missing."
    echo "Missing one of:"
    echo "- NOTARYTOOL_KEYCHAIN_PROFILE / --keychain-profile"
    echo "- NOTARYTOOL_APPLE_ID or APPLE_ID"
    echo "- NOTARYTOOL_TEAM_ID or TEAM_ID"
    echo "- NOTARYTOOL_PASSWORD or APP_SPECIFIC_PASSWORD"
    echo "Would submit: $ZIP_PATH"
  } | tee "$LOG_FILE"
  exit 1
fi

echo "PASS: notarytool submit completed. Review $LOG_FILE for final status."
