#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${APP_PATH:-/Applications/MenuBarDeclutter.app}"
BUNDLE_ID="${BUNDLE_ID:-Yongjun-Zhang.MenuBarDeclutter}"
PREFS_PATH="${PREFS_PATH:-$HOME/Library/Preferences/$BUNDLE_ID.plist}"
OPEN_SETTINGS=0
PREPARE_LOCAL_GATES=0
RESTART_APP=0

usage() {
  cat <<'USAGE'
Usage:
  scripts/qa_second_bar_permission_preflight.sh [options]

Options:
  --app-path PATH      Installed app to inspect. Default: /Applications/MenuBarDeclutter.app
  --bundle-id ID       Bundle identifier. Default: Yongjun-Zhang.MenuBarDeclutter
  --prefs PATH         Preferences plist to inspect.
  --open-settings      Open settings panes for any missing Accessibility or
                       Screen Recording permissions.
  --restart-app        Quit and reopen the installed app before checking the
                       app-observed permission state.
  --prepare-local-gates
                       Turn on local Optional Pro, Accessibility Discovery,
                       Accurate Icons, Second Bar, and compact-strip primary
                       click opt-in for hands-on dogfood, then restart the app.
                       This does not request or grant macOS privacy permissions.
  -h, --help           Show this help.

Reads local installed-app and preference evidence for Pro Second Bar readiness.
By default it does not change app settings or macOS privacy settings. Screen
Recording readiness uses the app's last public ScreenCapture preflight result,
so quit and reopen the app after changing macOS privacy settings.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-path)
      APP_PATH="${2:-}"
      shift 2
      ;;
    --bundle-id)
      BUNDLE_ID="${2:-}"
      shift 2
      ;;
    --prefs)
      PREFS_PATH="${2:-}"
      shift 2
      ;;
    --open-settings)
      OPEN_SETTINGS=1
      shift
      ;;
    --restart-app)
      RESTART_APP=1
      shift
      ;;
    --prepare-local-gates)
      PREPARE_LOCAL_GATES=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

failures=0

pass() {
  echo "PASS: $1"
}

warn() {
  echo "WARN: $1"
}

fail() {
  echo "FAIL: $1"
  failures=$((failures + 1))
}

action() {
  echo "ACTION: $1"
}

read_info_plist() {
  local key="$1"
  /usr/libexec/PlistBuddy -c "Print :$key" "$APP_PATH/Contents/Info.plist" 2>/dev/null || true
}

read_pref() {
  local key="$1"
  if [[ ! -f "$PREFS_PATH" ]]; then
    echo "<missing>"
    return 0
  fi
  /usr/bin/plutil -extract "$key" raw -o - "$PREFS_PATH" 2>/dev/null || echo "<missing>"
}

ensure_prefs_file() {
  mkdir -p "$(dirname "$PREFS_PATH")"
  if [[ ! -f "$PREFS_PATH" ]]; then
    /usr/bin/plutil -create binary1 "$PREFS_PATH"
  fi
}

write_bool_pref() {
  local key="$1"
  local value="$2"

  if /usr/bin/plutil -extract "$key" raw -o - "$PREFS_PATH" >/dev/null 2>&1; then
    /usr/bin/plutil -replace "$key" -bool "$value" "$PREFS_PATH"
  else
    /usr/bin/plutil -insert "$key" -bool "$value" "$PREFS_PATH"
  fi
}

prepare_local_gates() {
  if [[ ! -d "$APP_PATH" ]]; then
    echo "Cannot prepare local gates because app is missing at $APP_PATH" >&2
    exit 1
  fi

  echo "Preparing local Pro Second Bar dogfood gates."
  echo "This updates app preferences only; it does not request or grant macOS privacy permissions."

  if pgrep -x MenuBarDeclutter >/dev/null 2>&1; then
    osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
    sleep 2
  fi

  ensure_prefs_file
  write_bool_pref proModeEnabled true
  write_bool_pref accessibilityDiscoveryEnabled true
  write_bool_pref renderedIconCaptureEnabled true
  write_bool_pref secondBarEnabled true
  write_bool_pref secondBarPrimaryClickEnabled true

  killall cfprefsd >/dev/null 2>&1 || true
  open "$APP_PATH"
  sleep 5
  echo
}

restart_app_for_fresh_status() {
  if [[ ! -d "$APP_PATH" ]]; then
    echo "Cannot restart app because it is missing at $APP_PATH" >&2
    exit 1
  fi

  echo "Restarting MenuBarDeclutter to refresh app-observed permission state."

  if pgrep -x MenuBarDeclutter >/dev/null 2>&1; then
    osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
    sleep 2
  fi

  killall cfprefsd >/dev/null 2>&1 || true
  open "$APP_PATH"
  sleep 5
  echo
}

if [[ "$PREPARE_LOCAL_GATES" -eq 1 ]]; then
  prepare_local_gates
elif [[ "$RESTART_APP" -eq 1 ]]; then
  restart_app_for_fresh_status
fi

echo "Pro Second Bar permission preflight"
echo "App: $APP_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo "Preferences: $PREFS_PATH"
echo

if [[ -d "$APP_PATH" ]]; then
  pass "Installed app exists"
else
  fail "Installed app missing at $APP_PATH"
fi

if [[ -f "$APP_PATH/Contents/Info.plist" ]]; then
  actual_bundle_id="$(read_info_plist CFBundleIdentifier)"
  if [[ "$actual_bundle_id" == "$BUNDLE_ID" ]]; then
    pass "Bundle identifier is $actual_bundle_id"
  else
    fail "Bundle identifier expected $BUNDLE_ID, got ${actual_bundle_id:-<missing>}"
  fi

  if [[ -n "$(read_info_plist NSScreenCaptureUsageDescription)" ]]; then
    pass "NSScreenCaptureUsageDescription is present"
  else
    fail "NSScreenCaptureUsageDescription is missing"
  fi

  if [[ -n "$(read_info_plist NSAppleEventsUsageDescription)" ]]; then
    fail "NSAppleEventsUsageDescription should be absent"
  else
    pass "NSAppleEventsUsageDescription is absent"
  fi

  if [[ -n "$(read_info_plist NSInputMonitoringUsageDescription)" ]]; then
    fail "NSInputMonitoringUsageDescription should be absent"
  else
    pass "NSInputMonitoringUsageDescription is absent"
  fi
fi

if [[ -x "$APP_PATH/Contents/MacOS/MenuBarDeclutter" ]]; then
  if otool -L "$APP_PATH/Contents/MacOS/MenuBarDeclutter" | grep -q ScreenCaptureKit; then
    pass "Executable links ScreenCaptureKit for Accurate Icons"
  else
    fail "Executable does not link ScreenCaptureKit"
  fi

  codesign_output="$(codesign -dv --verbose=4 "$APP_PATH" 2>&1 || true)"
  cdhash="$(printf '%s\n' "$codesign_output" | awk -F= '/^CDHash=/{print $2; exit}')"
  if [[ -n "$cdhash" ]]; then
    pass "Installed app CDHash $cdhash"
  else
    warn "Unable to read installed app CDHash"
  fi
fi

running_pids="$(pgrep -x MenuBarDeclutter 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//' || true)"
if [[ -n "$running_pids" ]]; then
  pass "MenuBarDeclutter is running: $running_pids"
else
  fail "MenuBarDeclutter is not running"
fi

echo
echo "== Preference gates =="

pro_mode="$(read_pref proModeEnabled)"
discovery="$(read_pref accessibilityDiscoveryEnabled)"
accessibility_status="$(read_pref lastAccessibilityPermissionStatus)"
screen_capture_status="$(read_pref lastScreenCapturePermissionStatus)"
accurate_icons="$(read_pref renderedIconCaptureEnabled)"
second_bar="$(read_pref secondBarEnabled)"
primary_click="$(read_pref secondBarPrimaryClickEnabled)"

if [[ "$pro_mode" == "1" || "$pro_mode" == "true" ]]; then
  pass "Optional Pro is enabled"
else
  fail "Optional Pro is not enabled"
fi

if [[ "$discovery" == "1" || "$discovery" == "true" ]]; then
  pass "Accessibility Discovery is enabled"
else
  fail "Accessibility Discovery is not enabled"
fi

if [[ "$accessibility_status" == "granted" ]]; then
  pass "Last app-observed Accessibility status is granted"
else
  fail "Last app-observed Accessibility status is ${accessibility_status:-<missing>}"
fi

if [[ "$screen_capture_status" == "granted" ]]; then
  pass "Last app-observed Screen Recording status is granted"
else
  fail "Last app-observed Screen Recording status is ${screen_capture_status:-<missing>}"
fi

if [[ "$accurate_icons" == "1" || "$accurate_icons" == "true" ]]; then
  pass "Accurate Icons is enabled"
else
  fail "Accurate Icons is not enabled"
fi

if [[ "$second_bar" == "1" || "$second_bar" == "true" ]]; then
  pass "Second Bar is enabled"
else
  fail "Second Bar is not enabled"
fi

if [[ "$primary_click" == "1" || "$primary_click" == "true" ]]; then
  pass "Primary-click compact strip opt-in is enabled"
else
  fail "Primary-click compact strip opt-in is not enabled"
fi

echo
echo "== Manual TCC checks =="
missing_tcc=0
opened_privacy_panes=0

if [[ "$accessibility_status" != "granted" ]]; then
  missing_tcc=1
  action "Confirm MenuBarDeclutter is On in Privacy & Security -> Accessibility."
  if [[ "$OPEN_SETTINGS" -eq 1 ]]; then
    open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'
    opened_privacy_panes=1
  fi
fi

if [[ "$screen_capture_status" != "granted" ]]; then
  missing_tcc=1
  action "Confirm MenuBarDeclutter is On in Privacy & Security -> Screen & System Audio Recording."
  action "If Screen Recording does not list MenuBarDeclutter, use Add and select $APP_PATH, then quit and reopen the app."
  if [[ "$OPEN_SETTINGS" -eq 1 ]]; then
    open 'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture'
    opened_privacy_panes=1
  fi
fi

if [[ "$missing_tcc" -eq 1 ]]; then
  warn "After changing macOS privacy settings, quit and reopen MenuBarDeclutter before rerunning this script."
else
  pass "No manual TCC checks remain"
fi

if [[ "$OPEN_SETTINGS" -eq 1 && "$opened_privacy_panes" -eq 1 ]]; then
  pass "Opened missing macOS privacy pane(s) for manual review"
elif [[ "$OPEN_SETTINGS" -eq 1 ]]; then
  pass "No missing macOS privacy panes to open"
fi

echo
if [[ "$failures" -eq 0 ]]; then
  echo "Second Bar permission preflight passed."
  echo
  echo "Next hands-on sign-off steps:"
  echo "  1. Open the compact strip, warm up icons, and exercise at least one real third-party item."
  echo "  2. Export diagnostics JSON from Settings -> Diagnostics."
  echo "  3. Run:"
  echo "     SECOND_BAR_DIAGNOSTICS_JSON=/path/to/diagnostics.json \\"
  echo "     SECOND_BAR_AUDIT_MATRIX_OUTPUT=docs/testing/pro-second-bar-direct-activation-matrix.generated.md \\"
  echo "     DOGFOOD_SECOND_BAR_AUDIT_ONLY=1 scripts/qa_dogfood_preflight.sh"
  echo "  4. Review accepted generated matrix rows, copy them into docs/testing/pro-second-bar-direct-activation-matrix.md, then run scripts/qa_second_bar_signoff_audit.sh."
  exit 0
fi

echo "Second Bar permission preflight failed with $failures issue(s)."
exit 1
