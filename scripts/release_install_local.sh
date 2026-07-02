#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH=""
DESTINATION="${DESTINATION:-/Applications/MenuBarDeclutter.app}"
CLEAR_QUARANTINE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --destination)
      DESTINATION="${2:-}"
      shift 2
      ;;
    --clear-quarantine)
      CLEAR_QUARANTINE=1
      shift
      ;;
    -h|--help)
      cat <<EOF
Usage: scripts/release_install_local.sh [APP_PATH] [--destination PATH] [--clear-quarantine]

Defaults:
  APP_PATH: build/Export/MenuBarDeclutter.app
  destination: /Applications/MenuBarDeclutter.app
EOF
      exit 0
      ;;
    *)
      if [[ -z "$APP_PATH" ]]; then
        APP_PATH="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        exit 2
      fi
      ;;
  esac
done

APP_PATH="${APP_PATH:-$ROOT_DIR/build/Export/MenuBarDeclutter.app}"

cd "$ROOT_DIR"

clear_intentional_termination_marker() {
  local marker_paths=(
    "$HOME/Library/Application Support/MenuBarDeclutter/running.marker"
    "$HOME/Library/Containers/Yongjun-Zhang.MenuBarDeclutter/Data/Library/Application Support/MenuBarDeclutter/running.marker"
  )

  local marker
  for marker in "${marker_paths[@]}"; do
    if [[ -f "$marker" ]]; then
      rm -f "$marker"
      echo "INFO: Cleared script-controlled termination marker: $marker"
    fi
  done
}

echo "MenuBarDeclutter local install"
echo "Source: $APP_PATH"
echo "Destination: $DESTINATION"
echo

if [[ ! -d "$APP_PATH" ]]; then
  echo "FAIL: app path is missing: $APP_PATH" >&2
  exit 1
fi

echo "+ pkill -x MenuBarDeclutter || true"
pkill -x MenuBarDeclutter 2>/dev/null || true
sleep 1
clear_intentional_termination_marker

echo "+ rm -rf \"$DESTINATION\""
if ! rm -rf "$DESTINATION" 2>/tmp/menubardeclutter-install-rm.err; then
  echo "FAIL: could not remove existing app at $DESTINATION" >&2
  cat /tmp/menubardeclutter-install-rm.err >&2
  echo "Try installing to a user-writable destination with --destination, or copy manually in Finder." >&2
  exit 1
fi

echo "+ ditto \"$APP_PATH\" \"$DESTINATION\""
if ! ditto "$APP_PATH" "$DESTINATION" 2>/tmp/menubardeclutter-install-copy.err; then
  echo "FAIL: could not copy app to $DESTINATION" >&2
  cat /tmp/menubardeclutter-install-copy.err >&2
  echo "If /Applications requires approval, copy the app manually in Finder or rerun with --destination ~/Applications/MenuBarDeclutter.app." >&2
  exit 1
fi

if [[ "$CLEAR_QUARANTINE" -eq 1 ]]; then
  echo "+ xattr -dr com.apple.quarantine \"$DESTINATION\""
  xattr -dr com.apple.quarantine "$DESTINATION" 2>/dev/null || true
else
  echo "INFO: quarantine left intact. Pass --clear-quarantine only for local dry-run testing."
fi

echo "+ open \"$DESTINATION\""
open "$DESTINATION"

echo "PASS: installed app bundle path: $DESTINATION"
