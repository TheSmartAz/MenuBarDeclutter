#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${APP_PATH:-}"
EXPECTED_MARKETING_VERSION="${EXPECTED_MARKETING_VERSION:-0.1.1}"
EXPECTED_BUILD_VERSION="${EXPECTED_BUILD_VERSION:-2}"
EXPECTED_BUNDLE_ID="${EXPECTED_BUNDLE_ID:-Yongjun-Zhang.MenuBarDeclutter}"
EXPECTED_CATEGORY="${EXPECTED_CATEGORY:-public.app-category.utilities}"
REQUIRE_NOTARIZED=0
FAILED=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --expected-version)
      EXPECTED_MARKETING_VERSION="${2:-}"
      shift 2
      ;;
    --expected-build)
      EXPECTED_BUILD_VERSION="${2:-}"
      shift 2
      ;;
    --require-notarized)
      REQUIRE_NOTARIZED=1
      shift
      ;;
    -h|--help)
      cat <<EOF
Usage: scripts/verify_release_artifact.sh [APP_PATH] [--expected-version VERSION] [--expected-build BUILD] [--require-notarized]
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

APP_PATH="${APP_PATH:-build/MenuBarDeclutter.app}"

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

  BUNDLE_ID="$(plist_value CFBundleIdentifier)"
  if [[ "$BUNDLE_ID" == "$EXPECTED_BUNDLE_ID" ]]; then
    pass "Bundle identifier is $EXPECTED_BUNDLE_ID"
  else
    fail "Bundle identifier is $BUNDLE_ID; expected $EXPECTED_BUNDLE_ID"
  fi

  if plist_value LSUIElement | rg -q "true|1|YES"; then
    pass "LSUIElement is enabled"
  else
    fail "LSUIElement is not enabled"
  fi

  if [[ "$(plist_value LSApplicationCategoryType)" == "$EXPECTED_CATEGORY" ]]; then
    pass "App category is $EXPECTED_CATEGORY"
  else
    fail "App category is $(plist_value LSApplicationCategoryType); expected $EXPECTED_CATEGORY"
  fi

  if /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" "$INFO_PLIST" 2>/dev/null | rg -q "^menubardeclutter$"; then
    pass "URL scheme is menubardeclutter"
  else
    fail "URL scheme is missing or different"
  fi

  MARKETING_VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || true)"
  if [[ "$MARKETING_VERSION" == "$EXPECTED_MARKETING_VERSION" ]]; then
    pass "Marketing version is $EXPECTED_MARKETING_VERSION"
  else
    fail "Marketing version is $MARKETING_VERSION; expected $EXPECTED_MARKETING_VERSION"
  fi

  BUILD_VERSION="$(plist_value CFBundleVersion)"
  if [[ "$BUILD_VERSION" == "$EXPECTED_BUILD_VERSION" ]]; then
    pass "Build version is $EXPECTED_BUILD_VERSION"
  else
    fail "Build version is $BUILD_VERSION; expected $EXPECTED_BUILD_VERSION"
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

  if codesign -d --entitlements :- "$APP_PATH" >/tmp/menubardeclutter-release-entitlements.plist 2>/dev/null; then
    pass "Entitlements readable"
    if rg -q "com\\.apple\\.security\\.app-sandbox" /tmp/menubardeclutter-release-entitlements.plist; then
      pass "Sandbox entitlement present"
    else
      fail "Sandbox entitlement missing"
    fi
    if rg -q "com\\.apple\\.security\\.network\\.(client|server)" /tmp/menubardeclutter-release-entitlements.plist; then
      fail "Network entitlement present"
    else
      pass "No network entitlements present"
    fi
  else
    warn "Entitlements could not be read; ad-hoc or unsigned local builds may omit them."
  fi

  if codesign -dvv "$APP_PATH" >/tmp/menubardeclutter-release-codesign-detail.txt 2>&1 &&
     rg -q "Runtime Version|flags=.*runtime" /tmp/menubardeclutter-release-codesign-detail.txt; then
    pass "Hardened runtime metadata is present"
  else
    fail "Hardened runtime metadata was not confirmed"
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
  echo "Release artifact verification failed."
  exit 1
fi

echo "Release artifact verification passed."
