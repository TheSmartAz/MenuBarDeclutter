#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${APP_PATH:-${1:-build/MenuBarDeclutter.app}}"
FAILED=0

fail() {
  echo "FAIL: $*"
  FAILED=1
}

pass() {
  echo "PASS: $*"
}

echo "MenuBarDeclutter release artifact verification"
echo "App: $APP_PATH"
echo "This script verifies a local app bundle only and does not upload anything."
echo

if [[ ! -d "$APP_PATH" ]]; then
  fail "App bundle does not exist"
else
  pass "App bundle exists"
fi

INFO_PLIST="$APP_PATH/Contents/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
  pass "Info.plist exists"

  if /usr/libexec/PlistBuddy -c "Print :LSUIElement" "$INFO_PLIST" 2>/dev/null | rg -q "true|1|YES"; then
    pass "LSUIElement is enabled"
  else
    fail "LSUIElement is not enabled"
  fi

  if /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" "$INFO_PLIST" 2>/dev/null | rg -q "^menubardeclutter$"; then
    pass "URL scheme is menubardeclutter"
  else
    fail "URL scheme is missing or different"
  fi
else
  fail "Info.plist is missing"
fi

if [[ -d "$APP_PATH" ]]; then
  if codesign --verify --strict --verbose=2 "$APP_PATH"; then
    pass "codesign verification passed"
  else
    fail "codesign verification failed"
  fi

  if codesign -d --entitlements :- "$APP_PATH" >/tmp/menubardeclutter-release-entitlements.plist 2>/dev/null; then
    pass "Entitlements readable"
    if rg -q "com\\.apple\\.security\\.network\\.(client|server)" /tmp/menubardeclutter-release-entitlements.plist; then
      fail "Network entitlement present"
    else
      pass "No network entitlements present"
    fi
  else
    echo "WARN: Entitlements could not be read; ad-hoc or unsigned local builds may omit them."
  fi

  if codesign -dvv "$APP_PATH" 2>&1 | rg -q "Runtime Version"; then
    pass "Hardened runtime metadata is present or tool reports runtime metadata"
  else
    echo "WARN: Hardened runtime was not confirmed. Developer ID release builds should enable it."
  fi

  EXECUTABLE="$APP_PATH/Contents/MacOS/$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$INFO_PLIST" 2>/dev/null || true)"
  if [[ -f "$EXECUTABLE" ]]; then
    if otool -L "$EXECUTABLE" | rg -q "ScreenCaptureKit"; then
      fail "Executable links ScreenCaptureKit"
    else
      pass "Executable does not link ScreenCaptureKit"
    fi
  else
    fail "Executable could not be found"
  fi
fi

echo
if [[ "$FAILED" -ne 0 ]]; then
  echo "Release artifact verification failed."
  exit 1
fi

echo "Release artifact verification passed."
