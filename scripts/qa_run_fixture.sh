#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-MenuBarFixtureApp}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/build/DerivedData/MenuBarFixtureApp}"

cd "$ROOT_DIR"

xcodebuild build -scheme "$SCHEME" -destination "platform=macOS" -derivedDataPath "$DERIVED_DATA"

APP_PATH="$DERIVED_DATA/Build/Products/Debug/MenuBarFixtureApp.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Fixture app not found at $APP_PATH"
  exit 1
fi

open -n "$APP_PATH"

echo "MenuBarFixtureApp launched."
echo "Use Command-drag on fixture menu bar items to test placement and moving behavior."
echo "Use scripts/qa_stop_fixture.sh to stop it."
