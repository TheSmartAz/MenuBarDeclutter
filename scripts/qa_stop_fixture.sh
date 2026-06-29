#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-MenuBarFixtureApp}"

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
  sleep 1
fi

if pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  pkill -x "$APP_NAME"
fi

echo "MenuBarFixtureApp stopped if it was running."
