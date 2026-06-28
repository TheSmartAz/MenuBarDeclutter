#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:-}"
FAILED=0

fail() {
  echo "FAIL: $*"
  FAILED=1
}

pass() {
  echo "PASS: $*"
}

check_absent() {
  local description="$1"
  local pattern="$2"
  shift 2
  if rg -n "$pattern" "$@" >/tmp/menubardeclutter-privacy-match.txt 2>/dev/null; then
    fail "$description"
    sed -n '1,12p' /tmp/menubardeclutter-privacy-match.txt
  else
    pass "$description"
  fi
}

cd "$ROOT_DIR"

echo "MenuBarDeclutter privacy boundary verification"
echo "Root: $ROOT_DIR"
echo "This script inspects project/source files and, when APP_PATH is set, the built app bundle."
echo "It does not upload anything and does not inspect screen contents."
echo

check_absent "No network entitlements are declared" "com\\.apple\\.security\\.network\\.(client|server)" MenuBar-Manager.xcodeproj Config MenuBar-Manager
check_absent "No ScreenCaptureKit imports are present in app code" "import[[:space:]]+ScreenCaptureKit|ScreenCaptureKit" MenuBar-Manager Config
check_absent "No Screen Recording usage string is registered" "NSScreenCaptureUsageDescription|Screen Recording" Config MenuBar-Manager.xcodeproj
check_absent "No Apple Events usage string is registered" "NSAppleEventsUsageDescription" Config MenuBar-Manager.xcodeproj
check_absent "No Input Monitoring usage string is registered" "NSInputMonitoringUsageDescription|Input Monitoring" Config MenuBar-Manager.xcodeproj

if rg -n "AXIsProcessTrusted|AXUIElement|AccessibilityPermissionService|AXMenuBarScanner" MenuBar-Manager >/tmp/menubardeclutter-ax-match.txt 2>/dev/null; then
  pass "Accessibility references are present for opt-in Pro discovery"
else
  fail "Expected Accessibility references were not found"
fi

if plutil -extract CFBundleURLTypes xml1 -o - Config/MenuBarDeclutter-Info.plist | rg -q "menubardeclutter"; then
  pass "Local menubardeclutter:// URL scheme is registered"
else
  fail "menubardeclutter:// URL scheme is missing"
fi

if rg -n "Application Support|MenuBarDeclutter|AppSupportPaths" MenuBar-Manager/Core MenuBar-Manager/Profiles >/tmp/menubardeclutter-appsupport-match.txt 2>/dev/null; then
  pass "App Support paths are local MenuBarDeclutter paths"
else
  fail "Could not confirm local App Support path usage"
fi

if rg -n "excludes|Excluded by design|live search text|selected item identity|screenshots|screen contents" MenuBar-Manager/Core/DiagnosticsExporter.swift >/tmp/menubardeclutter-export-match.txt 2>/dev/null; then
  pass "Diagnostics exporter documents privacy exclusions"
else
  fail "Diagnostics exporter privacy exclusions were not found"
fi

if [[ -n "$APP_PATH" ]]; then
  if [[ ! -d "$APP_PATH" ]]; then
    fail "APP_PATH does not exist: $APP_PATH"
  else
    INFO_PLIST="$APP_PATH/Contents/Info.plist"
    if [[ -f "$INFO_PLIST" ]]; then
      if /usr/libexec/PlistBuddy -c "Print :LSUIElement" "$INFO_PLIST" 2>/dev/null | rg -q "true|1|YES"; then
        pass "Built app has LSUIElement enabled"
      else
        fail "Built app does not have LSUIElement enabled"
      fi
      if /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" "$INFO_PLIST" 2>/dev/null | rg -q "^menubardeclutter$"; then
        pass "Built app URL scheme is menubardeclutter"
      else
        fail "Built app URL scheme is missing or different"
      fi
    else
      fail "Built app Info.plist is missing"
    fi

    if codesign -d --entitlements :- "$APP_PATH" >/tmp/menubardeclutter-entitlements.plist 2>/dev/null; then
      if rg -q "com\\.apple\\.security\\.network\\.(client|server)" /tmp/menubardeclutter-entitlements.plist; then
        fail "Built app has network entitlements"
      else
        pass "Built app has no network entitlements"
      fi
    else
      echo "WARN: Could not read built app entitlements; codesign may be ad-hoc or unavailable."
    fi
  fi
else
  echo "INFO: APP_PATH not set; built-app checks skipped."
fi

echo
if [[ "$FAILED" -ne 0 ]]; then
  echo "Privacy boundary verification failed."
  exit 1
fi

echo "Privacy boundary verification passed."
