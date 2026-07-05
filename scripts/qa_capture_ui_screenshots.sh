#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date -u +"%Y-%m-%d_%H%M%S")"
SCHEME="${SCHEME:-MenuBarDeclutter}"
DESTINATION="${DESTINATION:-platform=macOS}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData/screenshot-qa}"
XCODE_ENABLE_DEBUG_DYLIB="${XCODE_ENABLE_DEBUG_DYLIB:-NO}"
APPEARANCE="${APPEARANCE:-system}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/docs/testing/screenshot-qa/$STAMP}"
APP_PATH="${APP_PATH:-}"
APP_EXECUTABLE_NAME="${APP_EXECUTABLE_NAME:-MenuBarDeclutter}"
OWNER_NAME="${OWNER_NAME:-MenuBarDeclutter}"
CAPTURE_WAIT_SECONDS="${CAPTURE_WAIT_SECONDS:-20}"
CAPTURE_SETTLE_SECONDS="${CAPTURE_SETTLE_SECONDS:-2}"
CAPTURE_ATTEMPTS="${CAPTURE_ATTEMPTS:-2}"
WINDOW_MIN_WIDTH="${WINDOW_MIN_WIDTH:-120}"
WINDOW_MIN_HEIGHT="${WINDOW_MIN_HEIGHT:-80}"
BUILD_APP=0
INCLUDE_DEEP_SETTINGS=1
INCLUDE_PANELS=1
KEEP_RUNNING_APP=0
STRICT_OPTIONAL=0
UI_TESTING_APPEARANCE_ARGS=()
UI_TESTING_ARG_PREFIX="--ui-testing"

ORIGINAL_COMMAND="$(printf '%q ' "$0" "$@")"

usage() {
  cat <<'USAGE'
Usage:
  scripts/qa_capture_ui_screenshots.sh [options]

Options:
  --build                 Build the Debug app before capture.
  --app-path PATH         Use an existing MenuBarDeclutter.app bundle.
  --output-dir PATH       Write run artifacts to PATH.
  --focused-only          Capture focused Settings pages and onboarding, plus panels unless --settings-only is set.
  --settings-only         Skip floating Find Icon / Second Bar / Groups panels.
  --keep-running-app      Do not terminate an already-running MenuBarDeclutter before capture.
  --strict-optional       Treat optional floating panel capture failures as failures.
  -h, --help              Show this help.

Environment overrides:
  SCHEME, DESTINATION, CONFIGURATION, DERIVED_DATA_PATH, APP_PATH, OUTPUT_DIR,
  XCODE_ENABLE_DEBUG_DYLIB, APPEARANCE=system|light|dark,
  CAPTURE_WAIT_SECONDS, CAPTURE_SETTLE_SECONDS, CAPTURE_ATTEMPTS,
  WINDOW_MIN_WIDTH, WINDOW_MIN_HEIGHT
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build)
      BUILD_APP=1
      shift
      ;;
    --app-path)
      APP_PATH="${2:-}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    --focused-only)
      INCLUDE_DEEP_SETTINGS=0
      shift
      ;;
    --settings-only)
      INCLUDE_PANELS=0
      shift
      ;;
    --keep-running-app)
      KEEP_RUNNING_APP=1
      shift
      ;;
    --strict-optional)
      STRICT_OPTIONAL=1
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

case "$APPEARANCE" in
  system|"")
    APPEARANCE="system"
    ;;
  light)
    UI_TESTING_APPEARANCE_ARGS=(--ui-testing-appearance-light)
    UI_TESTING_ARG_PREFIX="$UI_TESTING_ARG_PREFIX --ui-testing-appearance-light"
    ;;
  dark)
    UI_TESTING_APPEARANCE_ARGS=(--ui-testing-appearance-dark)
    UI_TESTING_ARG_PREFIX="$UI_TESTING_ARG_PREFIX --ui-testing-appearance-dark"
    ;;
  *)
    echo "Unknown APPEARANCE: $APPEARANCE (expected system, light, or dark)" >&2
    exit 2
    ;;
esac

cd "$ROOT_DIR"

SCREENSHOT_DIR="$OUTPUT_DIR/screenshots"
LOG_DIR="$OUTPUT_DIR/logs"
MANIFEST_PATH="$OUTPUT_DIR/manifest.tsv"
SUMMARY_PATH="$OUTPUT_DIR/README.md"
WINDOW_HELPER_SOURCE="$ROOT_DIR/scripts/qa_window_id.swift"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/menubardeclutter-screenshot-qa.XXXXXX")"
WINDOW_HELPER_BIN="$TEMP_DIR/qa-window-id"
RUNNING_PID=""
OVERALL_RC=0

cleanup() {
  if [[ -n "$RUNNING_PID" ]]; then
    terminate_pid "$RUNNING_PID" 3
  fi
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

required_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "FAIL: required tool not found: $tool" >&2
    exit 1
  fi
}

print_command() {
  printf "+"
  printf " %q" "$@"
  printf "\n"
}

terminate_pid() {
  local pid="$1"
  local grace_seconds="${2:-3}"
  local deadline=$((SECONDS + grace_seconds))
  local stat

  kill "$pid" >/dev/null 2>&1 || true
  while kill -0 "$pid" >/dev/null 2>&1; do
    stat="$(ps -p "$pid" -o stat= 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ -z "$stat" || "$stat" == Z* ]]; then
      break
    fi
    if (( SECONDS >= deadline )); then
      kill -KILL "$pid" >/dev/null 2>&1 || true
      break
    fi
    sleep 1
  done

  wait "$pid" >/dev/null 2>&1 || true
}

clear_intentional_termination_marker() {
  local marker_paths=(
    "$HOME/Library/Application Support/MenuBarDeclutter/running.marker"
    "$HOME/Library/Containers/Yongjun-Zhang.MenuBarDeclutter/Data/Library/Application Support/MenuBarDeclutter/running.marker"
  )

  local marker
  for marker in "${marker_paths[@]}"; do
    rm -f "$marker"
  done
}

terminate_running_app() {
  if [[ "$KEEP_RUNNING_APP" -eq 1 ]]; then
    echo "INFO: --keep-running-app set; leaving existing MenuBarDeclutter processes alone."
    return
  fi

  if pgrep -x "$APP_EXECUTABLE_NAME" >/dev/null 2>&1; then
    echo "INFO: Terminating existing $APP_EXECUTABLE_NAME processes to avoid capturing the wrong window."
    pkill -x "$APP_EXECUTABLE_NAME" 2>/dev/null || true
    sleep 1
    clear_intentional_termination_marker
  fi
}

build_app() {
  local command=(
    xcodebuild
    -scheme "$SCHEME"
    -destination "$DESTINATION"
    -configuration "$CONFIGURATION"
    -derivedDataPath "$DERIVED_DATA_PATH"
    build
    "ENABLE_DEBUG_DYLIB=$XCODE_ENABLE_DEBUG_DYLIB"
  )

  print_command "${command[@]}"
  "${command[@]}"

  APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/MenuBarDeclutter.app"
}

find_existing_app() {
  local candidate
  local candidates=(
    "$ROOT_DIR/build/DerivedData/Build/Products/Debug/MenuBarDeclutter.app"
    "$ROOT_DIR/build/DerivedData/screenshot-qa/Build/Products/Debug/MenuBarDeclutter.app"
    "$ROOT_DIR/build/DerivedData/Build/Products/Release/MenuBarDeclutter.app"
    "$ROOT_DIR/build/MenuBarDeclutter.app"
    "$ROOT_DIR/build/Export/MenuBarDeclutter.app"
    "/Applications/MenuBarDeclutter.app"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  if [[ -d "$ROOT_DIR/build" ]]; then
    find "$ROOT_DIR/build" -path '*/MenuBarDeclutter.app' -type d -prune -print 2>/dev/null |
      sort |
      tail -n 1
  fi
}

resolve_app_path() {
  if [[ "$BUILD_APP" -eq 1 ]]; then
    build_app
  elif [[ -z "$APP_PATH" ]]; then
    APP_PATH="$(find_existing_app)"
  fi

  if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
    echo "FAIL: MenuBarDeclutter.app not found. Pass --app-path PATH or use --build." >&2
    exit 1
  fi

  if [[ ! -x "$APP_PATH/Contents/MacOS/$APP_EXECUTABLE_NAME" ]]; then
    echo "FAIL: app executable is missing or not executable: $APP_PATH/Contents/MacOS/$APP_EXECUTABLE_NAME" >&2
    exit 1
  fi
}

compile_window_helper() {
  if [[ ! -f "$WINDOW_HELPER_SOURCE" ]]; then
    echo "FAIL: window helper not found: $WINDOW_HELPER_SOURCE" >&2
    exit 1
  fi

  print_command xcrun swiftc "$WINDOW_HELPER_SOURCE" -o "$WINDOW_HELPER_BIN"
  xcrun swiftc "$WINDOW_HELPER_SOURCE" -o "$WINDOW_HELPER_BIN"
}

window_info_for_current_surface() {
  local title_contains="${1:-}"
  local owner_pid="${2:-}"
  local command=(
    "$WINDOW_HELPER_BIN"
    --owner "$OWNER_NAME" \
    --min-width "$WINDOW_MIN_WIDTH" \
    --min-height "$WINDOW_MIN_HEIGHT" \
    --wait "$CAPTURE_WAIT_SECONDS"
  )

  if [[ -n "$title_contains" ]]; then
    command+=(--title-contains "$title_contains")
  fi

  if [[ -n "$owner_pid" ]]; then
    command+=(--pid "$owner_pid")
  fi

  "${command[@]}"
}

write_manifest_header() {
  printf 'status\tslug\tlabel\tkind\twindow_id\tx\ty\twidth\theight\tlayer\ttitle\tpath\targs\n' > "$MANIFEST_PATH"
}

append_manifest() {
  local status="$1"
  local slug="$2"
  local label="$3"
  local kind="$4"
  local window_id="$5"
  local x="$6"
  local y="$7"
  local width="$8"
  local height="$9"
  local layer="${10}"
  local title="${11}"
  local path="${12}"
  local args="${13}"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$status" "$slug" "$label" "$kind" "$window_id" "$x" "$y" "$width" "$height" "$layer" "$title" "$path" "$args" >> "$MANIFEST_PATH"
}

launch_surface() {
  local slug="$1"
  local log_file="$LOG_DIR/$slug.log"
  shift

  local executable="$APP_PATH/Contents/MacOS/$APP_EXECUTABLE_NAME"
  local command=("$executable" --ui-testing "${UI_TESTING_APPEARANCE_ARGS[@]}" "$@")

  print_command "${command[@]}"
  "${command[@]}" > "$log_file" 2>&1 &
  RUNNING_PID="$!"
}

capture_surface() {
  local kind="$1"
  local slug="$2"
  local label="$3"
  local required="$4"
  local args_string="$5"
  local title_contains="${6:-}"
  local screenshot_path="$SCREENSHOT_DIR/$slug.png"
  local args=()
  local window_info
  local window_id x y width height layer title
  local helper_rc=1
  local attempt=1
  local window_log

  read -r -a args <<< "$args_string"

  echo
  echo "== $label =="
  while (( attempt <= CAPTURE_ATTEMPTS )); do
    RUNNING_PID=""
    launch_surface "$slug" "${args[@]}"

    sleep "$CAPTURE_SETTLE_SECONDS"

    window_log="$LOG_DIR/$slug-window.log"
    if (( attempt > 1 )); then
      window_log="$LOG_DIR/$slug-window-attempt-$attempt.log"
    fi

    set +e
    window_info="$(window_info_for_current_surface "$title_contains" "$RUNNING_PID" 2>"$window_log")"
    helper_rc="$?"
    set -e

    if [[ "$helper_rc" -eq 0 ]]; then
      if (( attempt > 1 )); then
        echo "INFO: captured $label after retry attempt $attempt."
      fi
      break
    fi

    echo "WARN: no capturable window found for $label on attempt $attempt. See $window_log"
    terminate_pid "$RUNNING_PID" 3
    RUNNING_PID=""
    clear_intentional_termination_marker

    if (( attempt < CAPTURE_ATTEMPTS )); then
      sleep 1
    fi
    attempt=$((attempt + 1))
  done

  if [[ "$helper_rc" -ne 0 ]]; then
    echo "WARN: no capturable window found for $label after $CAPTURE_ATTEMPTS attempt(s)."
    append_manifest "skipped" "$slug" "$label" "$kind" "" "" "" "" "" "" "" "" "$UI_TESTING_ARG_PREFIX $args_string"
    if [[ "$required" == "required" || "$STRICT_OPTIONAL" -eq 1 ]]; then
      OVERALL_RC=1
    fi
    return
  fi

  IFS=$'\t' read -r window_id x y width height layer title <<< "$window_info"

  print_command screencapture -x -l "$window_id" "$screenshot_path"
  if screencapture -x -l "$window_id" "$screenshot_path"; then
    if [[ -s "$screenshot_path" ]]; then
      echo "PASS: captured $label -> $screenshot_path"
      append_manifest "captured" "$slug" "$label" "$kind" "$window_id" "$x" "$y" "$width" "$height" "$layer" "$title" "screenshots/$slug.png" "$UI_TESTING_ARG_PREFIX $args_string"
    else
      echo "WARN: screencapture wrote an empty file for $label." >&2
      append_manifest "failed" "$slug" "$label" "$kind" "$window_id" "$x" "$y" "$width" "$height" "$layer" "$title" "screenshots/$slug.png" "$UI_TESTING_ARG_PREFIX $args_string"
      OVERALL_RC=1
    fi
  else
    echo "WARN: screencapture failed for $label." >&2
    append_manifest "failed" "$slug" "$label" "$kind" "$window_id" "$x" "$y" "$width" "$height" "$layer" "$title" "screenshots/$slug.png" "$UI_TESTING_ARG_PREFIX $args_string"
    if [[ "$required" == "required" || "$STRICT_OPTIONAL" -eq 1 ]]; then
      OVERALL_RC=1
    fi
  fi

  terminate_pid "$RUNNING_PID" 3
  RUNNING_PID=""
  clear_intentional_termination_marker
}

write_summary() {
  local captured_count skipped_count failed_count
  captured_count="$(awk -F '\t' 'NR > 1 && $1 == "captured" { count += 1 } END { print count + 0 }' "$MANIFEST_PATH")"
  skipped_count="$(awk -F '\t' 'NR > 1 && $1 == "skipped" { count += 1 } END { print count + 0 }' "$MANIFEST_PATH")"
  failed_count="$(awk -F '\t' 'NR > 1 && $1 == "failed" { count += 1 } END { print count + 0 }' "$MANIFEST_PATH")"

  {
    echo "# MenuBarDeclutter Screenshot QA"
    echo
    echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo
    echo "Command:"
    echo
    echo "\`\`\`sh"
    echo "$ORIGINAL_COMMAND"
    echo "\`\`\`"
    echo
    echo "App bundle: \`$APP_PATH\`"
    echo "Scheme: \`$SCHEME\`"
    echo "Destination: \`$DESTINATION\`"
    echo "Configuration: \`$CONFIGURATION\`"
    echo "Appearance: \`$APPEARANCE\`"
    echo
    echo "Results:"
    echo
    echo "- Captured: $captured_count"
    echo "- Skipped: $skipped_count"
    echo "- Failed: $failed_count"
    echo
    echo "Artifacts:"
    echo
    echo "- Screenshots: \`screenshots/*.png\`"
    echo "- Per-surface app logs: \`logs/*.log\`"
    echo "- Window finder logs: \`logs/*-window.log\`"
    echo "- Manifest: \`manifest.tsv\`"
    echo
    echo "Notes:"
    echo
    echo "- The app is launched with \`--ui-testing\` so screenshots use isolated defaults and temporary app-support data."
    echo "- This runner uses public CoreGraphics window metadata plus the system \`screencapture\` tool. It does not use private APIs, Accessibility automation, network access, or XCTest UI automation."
    echo "- macOS may require Screen Recording permission for the terminal or Codex runner that executes \`screencapture\`; do not grant Screen Recording to MenuBarDeclutter for Basic Mode QA."
    echo "- Status menu visual capture is not automated by this harness; keep using source-covered StatusBarMenuBuilder tests plus manual QA for status menu behavior."
    echo "- XCTest attachment export remains useful after successful UI tests, but XCTest automation can time out while enabling automation mode on macOS automation sessions."
  } > "$SUMMARY_PATH"
}

focused_settings_surfaces=(
  "settings|01-general|General|required|--ui-testing-show-general"
  "settings|02-hide-reveal|Hide & Reveal|required|--ui-testing-show-hide-reveal"
  "settings|03-arrange|Arrange|required|--ui-testing-show-arrange --ui-testing-seed-menu-bar-items"
  "settings|04-find-rescue|Find & Rescue|required|--ui-testing-show-find-rescue --ui-testing-seed-menu-bar-items"
  "settings|05-workspaces|Workspaces|required|--ui-testing-show-workspaces"
  "settings|06-privacy|Privacy|required|--ui-testing-show-privacy"
  "settings|07-recovery|Recovery|required|--ui-testing-show-recovery"
  "settings|08-advanced|Advanced|required|--ui-testing-show-advanced"
)

deep_settings_surfaces=(
  "settings|09-diagnostics|Diagnostics|required|--ui-testing-show-diagnostics"
  "settings|10-behavior-legacy|Behavior|required|--ui-testing-show-behavior"
  "settings|11-layout-legacy|Layout|required|--ui-testing-show-layout"
  "settings|12-menu-bar-items-hidden|Menu Bar Items|required|--ui-testing-show-menu-bar-items --ui-testing-seed-menu-bar-items"
  "settings|13-search-settings-hidden|Search Settings|required|--ui-testing-show-search-settings"
  "settings|14-second-bar-settings-hidden|Second Bar Settings|required|--ui-testing-show-second-bar-settings"
  "settings|15-groups-hidden|Groups|required|--ui-testing-show-groups --ui-testing-seed-groups --ui-testing-seed-menu-bar-items"
  "settings|16-hotkeys-hidden|Hotkeys|required|--ui-testing-show-hotkeys"
  "settings|17-profiles-hidden|Profiles|required|--ui-testing-show-profiles --ui-testing-seed-profiles --ui-testing-seed-menu-bar-items"
  "settings|18-automation-hidden|Automation|required|--ui-testing-show-automation --ui-testing-seed-profiles"
  "settings|19-private-access-hidden|Private Access|required|--ui-testing-show-private-access"
  "settings|20-import-export-hidden|Import / Export|required|--ui-testing-show-import-export"
)

floating_panel_surfaces=(
  "panel|21-floating-find-icon|Floating Find Icon|optional|--ui-testing-show-search|Find Icon"
  "panel|22-floating-second-bar|Floating Second Bar|optional|--ui-testing-show-second-bar|Second Bar"
  "panel|23-floating-group-panel|Floating Group Panel|optional|--ui-testing-show-group-panel|Pinned Tools"
  "panel|26-floating-find-icon-typed|Floating Find Icon - Typed|optional|--ui-testing-show-search --ui-testing-pro-discovery-enabled --ui-testing-accessibility-granted --ui-testing-seed-menu-bar-items --ui-testing-find-icon-query=Fant|Find Icon"
  "panel|27-floating-find-icon-no-results|Floating Find Icon - No Results|optional|--ui-testing-show-search --ui-testing-pro-discovery-enabled --ui-testing-accessibility-granted --ui-testing-seed-menu-bar-items --ui-testing-find-icon-query=NoSuchIcon|Find Icon"
  "panel|28-floating-second-bar-typed|Floating Second Bar - Typed|optional|--ui-testing-show-second-bar --ui-testing-pro-discovery-enabled --ui-testing-accessibility-granted --ui-testing-seed-menu-bar-items --ui-testing-second-bar-query=Drop|Second Bar"
  "panel|29-floating-second-bar-no-results|Floating Second Bar - No Results|optional|--ui-testing-show-second-bar --ui-testing-pro-discovery-enabled --ui-testing-accessibility-granted --ui-testing-seed-menu-bar-items --ui-testing-second-bar-query=NoSuchIcon|Second Bar"
  "panel|30-floating-group-panel-typed|Floating Group Panel - Typed|optional|--ui-testing-show-group-panel --ui-testing-group-panel-query=Drop|Pinned Tools"
  "panel|31-floating-group-panel-no-results|Floating Group Panel - No Results|optional|--ui-testing-show-group-panel --ui-testing-group-panel-query=NoSuchIcon|Pinned Tools"
)

onboarding_surfaces=(
  "onboarding|24-onboarding-welcome|Onboarding Welcome|required|--ui-testing-show-onboarding|Setup"
  "onboarding|25-onboarding-privacy|Onboarding Privacy|required|--ui-testing-show-onboarding-privacy|Setup"
)

mkdir -p "$SCREENSHOT_DIR" "$LOG_DIR"
write_manifest_header

required_tool xcodebuild
required_tool xcrun
required_tool screencapture
required_tool awk

resolve_app_path
compile_window_helper
terminate_running_app

echo "MenuBarDeclutter screenshot QA"
echo "App: $APP_PATH"
echo "Output: $OUTPUT_DIR"
echo

for entry in "${focused_settings_surfaces[@]}"; do
  IFS='|' read -r kind slug label required args_string title_contains <<< "$entry"
  capture_surface "$kind" "$slug" "$label" "$required" "$args_string" "$title_contains"
done

if [[ "$INCLUDE_DEEP_SETTINGS" -eq 1 ]]; then
  for entry in "${deep_settings_surfaces[@]}"; do
    IFS='|' read -r kind slug label required args_string title_contains <<< "$entry"
    capture_surface "$kind" "$slug" "$label" "$required" "$args_string" "$title_contains"
  done
fi

if [[ "$INCLUDE_PANELS" -eq 1 ]]; then
  for entry in "${floating_panel_surfaces[@]}"; do
    IFS='|' read -r kind slug label required args_string title_contains <<< "$entry"
    capture_surface "$kind" "$slug" "$label" "$required" "$args_string" "$title_contains"
  done
fi

for entry in "${onboarding_surfaces[@]}"; do
  IFS='|' read -r kind slug label required args_string title_contains <<< "$entry"
  capture_surface "$kind" "$slug" "$label" "$required" "$args_string" "$title_contains"
done

write_summary

echo
echo "Screenshot QA artifacts written to:"
echo "$OUTPUT_DIR"

exit "$OVERALL_RC"
