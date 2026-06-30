#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-${APP_PATH:-/Applications/MenuBarDeclutter.app}}"
EXPECTED_BUNDLE_ID="${EXPECTED_BUNDLE_ID:-Yongjun-Zhang.MenuBarDeclutter}"
EXPECTED_MARKETING_VERSION="${EXPECTED_MARKETING_VERSION:-0.1.1}"
EXPECTED_BUILD_VERSION="${EXPECTED_BUILD_VERSION:-2}"
EXPECTED_CATEGORY="${EXPECTED_CATEGORY:-public.app-category.utilities}"
REQUIRE_NOTARIZED=0
FAILED=0

if [[ "${2:-}" == "--require-notarized" || "${REQUIRE_NOTARIZED_ENV:-0}" == "1" ]]; then
  REQUIRE_NOTARIZED=1
fi

fail() {
  echo "FAIL: $*"
  FAILED=1
}

pass() {
  echo "PASS: $*"
}

warn() {
  echo "WARN: $*"
}

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST" 2>/dev/null || true
}

echo "MenuBarDeclutter installed-app verification"
echo "App: $APP_PATH"
echo

if [[ -d "$APP_PATH" ]]; then
  pass "App exists"
else
  fail "App does not exist"
fi

INFO_PLIST="$APP_PATH/Contents/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
  pass "Info.plist exists"

  BUNDLE_ID="$(plist_value CFBundleIdentifier)"
  [[ "$BUNDLE_ID" == "$EXPECTED_BUNDLE_ID" ]] && pass "Bundle identifier is $EXPECTED_BUNDLE_ID" || fail "Bundle identifier is $BUNDLE_ID"

  MARKETING_VERSION="$(plist_value CFBundleShortVersionString)"
  [[ "$MARKETING_VERSION" == "$EXPECTED_MARKETING_VERSION" ]] && pass "Marketing version is $EXPECTED_MARKETING_VERSION" || fail "Marketing version is $MARKETING_VERSION"

  BUILD_VERSION="$(plist_value CFBundleVersion)"
  [[ "$BUILD_VERSION" == "$EXPECTED_BUILD_VERSION" ]] && pass "Build version is $EXPECTED_BUILD_VERSION" || fail "Build version is $BUILD_VERSION"

  CATEGORY="$(plist_value LSApplicationCategoryType)"
  [[ "$CATEGORY" == "$EXPECTED_CATEGORY" ]] && pass "App category is $EXPECTED_CATEGORY" || fail "App category is $CATEGORY"

  if plist_value LSUIElement | rg -q "true|1|YES"; then
    pass "LSUIElement is enabled"
  else
    fail "LSUIElement is not enabled"
  fi

  if /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" "$INFO_PLIST" 2>/dev/null | rg -q "^menubardeclutter$"; then
    pass "URL scheme is menubardeclutter"
  else
    fail "URL scheme is missing or different"
  fi

  for key in NSScreenCaptureUsageDescription NSAppleEventsUsageDescription NSInputMonitoringUsageDescription; do
    if /usr/libexec/PlistBuddy -c "Print :$key" "$INFO_PLIST" >/dev/null 2>&1; then
      fail "$key is present"
    else
      pass "$key is absent"
    fi
  done
else
  fail "Info.plist is missing"
fi

if [[ -d "$APP_PATH" ]]; then
  if codesign --verify --strict --verbose=2 "$APP_PATH"; then
    pass "codesign verification passed"
  else
    fail "codesign verification failed"
  fi

  if codesign -d --entitlements :- "$APP_PATH" >/tmp/menubardeclutter-installed-entitlements.plist 2>/dev/null; then
    pass "Entitlements are readable"
    if rg -q "com\\.apple\\.security\\.app-sandbox" /tmp/menubardeclutter-installed-entitlements.plist; then
      pass "Sandbox entitlement present"
    else
      fail "Sandbox entitlement missing"
    fi
    if rg -q "com\\.apple\\.security\\.network\\.(client|server)" /tmp/menubardeclutter-installed-entitlements.plist; then
      fail "Network entitlement present"
    else
      pass "No network entitlements present"
    fi
  else
    warn "Could not read entitlements; unsigned/ad-hoc builds may omit them."
  fi

  if codesign -dvv "$APP_PATH" >/tmp/menubardeclutter-installed-codesign-detail.txt 2>&1 &&
     rg -q "Runtime Version|flags=.*runtime" /tmp/menubardeclutter-installed-codesign-detail.txt; then
    pass "Hardened runtime metadata is present"
  else
    fail "Hardened runtime metadata was not confirmed"
  fi

  EXECUTABLE_NAME="$(plist_value CFBundleExecutable)"
  EXECUTABLE="$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"
  if [[ -f "$EXECUTABLE" ]]; then
    if otool -L "$EXECUTABLE" | rg -q "ScreenCaptureKit"; then
      fail "Executable links ScreenCaptureKit"
    else
      pass "Executable does not link ScreenCaptureKit"
    fi
  else
    fail "Executable is missing"
  fi

  if spctl --assess --type execute --verbose=4 "$APP_PATH"; then
    pass "spctl assessment passed"
  elif [[ "$REQUIRE_NOTARIZED" -eq 1 ]]; then
    fail "spctl assessment failed"
  else
    warn "spctl assessment failed; expected for non-notarized dry-run artifacts."
  fi

  if xcrun stapler validate "$APP_PATH"; then
    pass "Stapler validation passed"
  elif [[ "$REQUIRE_NOTARIZED" -eq 1 ]]; then
    fail "Stapler validation failed"
  else
    warn "Stapler validation failed; expected until notarization has succeeded."
  fi
fi

echo
if [[ "$FAILED" -ne 0 ]]; then
  echo "Installed-app verification failed."
  exit 1
fi

echo "Installed-app verification passed."
