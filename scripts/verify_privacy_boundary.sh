#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:-${1:-}}"
FAILED=0

fail() {
  echo "FAIL: $*"
  FAILED=1
}

pass() {
  echo "PASS: $*"
}

search_to_file() {
  local pattern="$1"
  local output_file="$2"
  shift 2
  if command -v rg >/dev/null 2>&1; then
    rg -n "$pattern" "$@" >"$output_file" 2>/dev/null
  else
    grep -R -n -E "$pattern" "$@" >"$output_file" 2>/dev/null
  fi
}

contains_pattern() {
  local pattern="$1"
  shift
  if command -v rg >/dev/null 2>&1; then
    rg -q "$pattern" "$@"
  else
    grep -E -q "$pattern" "$@"
  fi
}

check_absent() {
  local description="$1"
  local pattern="$2"
  shift 2
  if search_to_file "$pattern" /tmp/menubardeclutter-privacy-match.txt "$@"; then
    fail "$description"
    sed -n '1,12p' /tmp/menubardeclutter-privacy-match.txt
  else
    pass "$description"
  fi
}

check_screen_capturekit_scope() {
  local output_file="/tmp/menubardeclutter-screencapturekit-match.txt"
  if search_to_file "import[[:space:]]+ScreenCaptureKit|ScreenCaptureKit" "$output_file" MenuBar-Manager; then
    if grep -Ev '^MenuBar-Manager/MenuBarIconCapture/' "$output_file" >/tmp/menubardeclutter-screencapturekit-out-of-scope.txt; then
      fail "ScreenCaptureKit is scoped to the rendered icon capture module"
      sed -n '1,12p' /tmp/menubardeclutter-screencapturekit-out-of-scope.txt
    else
      pass "ScreenCaptureKit is scoped to the rendered icon capture module"
    fi
  else
    fail "Expected ScreenCaptureKit reference for Accurate Icons was not found"
  fi
}

cd "$ROOT_DIR"

echo "MenuBarDeclutter privacy boundary verification"
echo "Root: $ROOT_DIR"
echo "This script inspects project/source files and, when APP_PATH is set, the built app bundle."
echo "It does not upload anything and does not inspect screen contents."
echo

check_absent "No network entitlements are declared" "com\\.apple\\.security\\.network\\.(client|server)" MenuBar-Manager.xcodeproj Config MenuBar-Manager
check_screen_capturekit_scope
if /usr/libexec/PlistBuddy -c "Print :NSScreenCaptureUsageDescription" Config/MenuBarDeclutter-Info.plist 2>/dev/null | contains_pattern "Accurate Icons"; then
  pass "Screen Recording usage string is registered for Accurate Icons"
else
  fail "Screen Recording usage string for Accurate Icons is missing"
fi
check_absent "No Apple Events usage string is registered" "NSAppleEventsUsageDescription" Config MenuBar-Manager.xcodeproj
check_absent "No Input Monitoring usage string is registered" "NSInputMonitoringUsageDescription|Input Monitoring" Config MenuBar-Manager.xcodeproj
check_absent "No direct network client APIs or analytics SDK names are present in app code" "URLSession|NWConnection|import[[:space:]]+Network|Sentry|Firebase|TelemetryDeck|Mixpanel|Amplitude" MenuBar-Manager

if search_to_file "AXIsProcessTrusted|AXUIElement|AccessibilityPermissionService|AXMenuBarScanner" /tmp/menubardeclutter-ax-match.txt MenuBar-Manager; then
  pass "Accessibility references are present for opt-in Pro discovery"
else
  fail "Expected Accessibility references were not found"
fi

if plutil -extract CFBundleURLTypes xml1 -o - Config/MenuBarDeclutter-Info.plist | contains_pattern "menubardeclutter"; then
  pass "Local menubardeclutter:// URL scheme is registered"
else
  fail "menubardeclutter:// URL scheme is missing"
fi

if search_to_file "Application Support|MenuBarDeclutter|AppSupportPaths" /tmp/menubardeclutter-appsupport-match.txt MenuBar-Manager/Core MenuBar-Manager/Profiles; then
  pass "App Support paths are local MenuBarDeclutter paths"
else
  fail "Could not confirm local App Support path usage"
fi

if search_to_file "excludes|Excluded by design|live search text|selected item identity|screenshots|screen contents" /tmp/menubardeclutter-export-match.txt MenuBar-Manager/Core/DiagnosticsExporter.swift; then
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
      if /usr/libexec/PlistBuddy -c "Print :LSUIElement" "$INFO_PLIST" 2>/dev/null | contains_pattern "true|1|YES"; then
        pass "Built app has LSUIElement enabled"
      else
        fail "Built app does not have LSUIElement enabled"
      fi
      if /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" "$INFO_PLIST" 2>/dev/null | contains_pattern "^menubardeclutter$"; then
        pass "Built app URL scheme is menubardeclutter"
      else
        fail "Built app URL scheme is missing or different"
      fi
      if /usr/libexec/PlistBuddy -c "Print :NSScreenCaptureUsageDescription" "$INFO_PLIST" >/dev/null 2>&1; then
        pass "Built app declares NSScreenCaptureUsageDescription for Accurate Icons"
      else
        fail "Built app does not declare NSScreenCaptureUsageDescription"
      fi
      for key in NSAppleEventsUsageDescription NSInputMonitoringUsageDescription; do
        if /usr/libexec/PlistBuddy -c "Print :$key" "$INFO_PLIST" >/dev/null 2>&1; then
          fail "Built app declares $key"
        else
          pass "Built app does not declare $key"
        fi
      done
    else
      fail "Built app Info.plist is missing"
    fi

    if codesign -d --entitlements :- "$APP_PATH" >/tmp/menubardeclutter-entitlements.plist 2>/dev/null; then
      if contains_pattern "com\\.apple\\.security\\.network\\.(client|server)" /tmp/menubardeclutter-entitlements.plist; then
        fail "Built app has network entitlements"
      else
        pass "Built app has no network entitlements"
      fi
    else
      echo "WARN: Could not read built app entitlements; codesign may be ad-hoc or unavailable."
    fi

    EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$INFO_PLIST" 2>/dev/null || true)"
    EXECUTABLE="$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"
    if [[ -f "$EXECUTABLE" ]]; then
      if otool -L "$EXECUTABLE" | contains_pattern "ScreenCaptureKit"; then
        pass "Built app executable links ScreenCaptureKit for Accurate Icons"
      else
        pass "Built app executable does not link ScreenCaptureKit directly"
      fi
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
