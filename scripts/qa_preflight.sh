#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-MenuBarDeclutter}"

cd "$ROOT_DIR"

echo "MenuBarDeclutter Alpha RC preflight"
echo "This script runs local validation only. It does not upload artifacts."
echo

echo "== System =="
sw_vers
echo "Architecture: $(uname -m)"
echo

echo "== Xcode =="
xcodebuild -version
echo

echo "== Git =="
git rev-parse --short HEAD
echo

echo "== Schemes =="
xcodebuild -list
echo

echo "== Tests =="
RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-$ROOT_DIR/build/TestResults/qa-preflight.xcresult}"
rm -rf "$RESULT_BUNDLE_PATH"
xcodebuild test \
  -scheme "$SCHEME" \
  -destination "platform=macOS" \
  -enableCodeCoverage NO \
  -resultBundlePath "$RESULT_BUNDLE_PATH"
echo

echo "== Privacy Boundary =="
"$ROOT_DIR/scripts/verify_privacy_boundary.sh"

echo
echo "Preflight complete."
