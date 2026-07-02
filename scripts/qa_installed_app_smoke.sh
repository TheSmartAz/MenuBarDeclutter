#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:-/Applications/MenuBarDeclutter.app}"
BUNDLE_ID="${BUNDLE_ID:-Yongjun-Zhang.MenuBarDeclutter}"
RUN_URL_SMOKE=1
RUN_PRIVACY=1
RUN_NETWORK=1
RUN_SAFE_MODE_FLAG=1
APP_LAUNCH_TIMEOUT_SECONDS="${APP_LAUNCH_TIMEOUT_SECONDS:-45}"

usage() {
  cat <<EOF
Usage: scripts/qa_installed_app_smoke.sh [--app-path PATH] [--skip-url] [--skip-privacy] [--skip-network] [--skip-safe-mode-flag]

Runs local installed-app smoke checks only:
- launches the installed app if needed,
- verifies menubardeclutter:// safe commands reuse the installed process,
- runs installed-app privacy verification,
- runs the local no-network socket probe,
- verifies the one-shot Safe Mode next-launch flag is consumed by the installed app.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-path)
      APP_PATH="${2:-}"
      shift 2
      ;;
    --skip-url)
      RUN_URL_SMOKE=0
      shift
      ;;
    --skip-privacy)
      RUN_PRIVACY=0
      shift
      ;;
    --skip-network)
      RUN_NETWORK=0
      shift
      ;;
    --skip-safe-mode-flag)
      RUN_SAFE_MODE_FLAG=0
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

cd "$ROOT_DIR"

clear_intentional_termination_marker() {
  local marker_paths=(
    "$HOME/Library/Application Support/MenuBarDeclutter/running.marker"
    "$HOME/Library/Containers/Yongjun-Zhang.MenuBarDeclutter/Data/Library/Application Support/MenuBarDeclutter/running.marker"
  )

  local marker
  for marker in "${marker_paths[@]}"; do
    if [[ -f "$marker" ]]; then
      rm -f "$marker"
      echo "INFO: Cleared script-controlled termination marker: $marker"
    fi
  done
}

standard_safe_mode_flag_path="$HOME/Library/Application Support/MenuBarDeclutter/safe-mode-next-launch.flag"
container_safe_mode_flag_path="$HOME/Library/Containers/$BUNDLE_ID/Data/Library/Application Support/MenuBarDeclutter/safe-mode-next-launch.flag"

all_safe_mode_flag_paths=(
  "$standard_safe_mode_flag_path"
  "$container_safe_mode_flag_path"
)

clear_safe_mode_flags() {
  local flag
  for flag in "${all_safe_mode_flag_paths[@]}"; do
    rm -f "$flag"
  done
}

app_uses_sandbox() {
  local entitlements
  entitlements="$(codesign -d --entitlements :- "$APP_PATH" 2>/dev/null)" || return 2

  local sandbox_value
  sandbox_value="$(printf '%s\n' "$entitlements" | /usr/bin/plutil -extract com.apple.security.app-sandbox raw -o - - 2>/dev/null || true)"
  if [[ "$sandbox_value" == "true" || "$sandbox_value" == "1" ]]; then
    return 0
  fi

  if printf '%s\n' "$entitlements" | grep -A1 '<key>com.apple.security.app-sandbox</key>' | grep -q '<true/>'; then
    return 0
  fi

  return 1
}

expected_safe_mode_flag_path() {
  app_uses_sandbox
  local sandbox_status=$?

  case "$sandbox_status" in
    0)
      printf '%s\n' "$container_safe_mode_flag_path"
      ;;
    1)
      printf '%s\n' "$standard_safe_mode_flag_path"
      ;;
    *)
      echo "FAIL: unable to read app entitlements for Safe Mode flag path selection." >&2
      return 1
      ;;
  esac
}

terminate_installed_app() {
  if candidate_installed_pids >/dev/null 2>&1; then
    echo "INFO: Terminating MenuBarDeclutter for installed-app smoke relaunch."
    pkill -x MenuBarDeclutter 2>/dev/null || true
    pkill -f "$APP_PATH/Contents/MacOS/MenuBarDeclutter" 2>/dev/null || true
    sleep 1
    clear_intentional_termination_marker
  fi
}

candidate_installed_pids() {
  {
    pgrep -x MenuBarDeclutter 2>/dev/null || true
    pgrep -f "$APP_PATH/Contents/MacOS/MenuBarDeclutter" 2>/dev/null || true
  } | sort -u
}

matching_installed_pids() {
  local pid
  candidate_installed_pids | while read -r pid; do
    local command
    command="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    if [[ "$command" == "$APP_PATH/Contents/MacOS/MenuBarDeclutter"* ]]; then
      echo "$pid"
    fi
  done
}

wait_for_installed_pid() {
  local deadline=$((SECONDS + APP_LAUNCH_TIMEOUT_SECONDS))
  local pids

  while (( SECONDS < deadline )); do
    pids="$(matching_installed_pids | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
    if [[ -n "$pids" ]]; then
      echo "$pids"
      return 0
    fi
    sleep 1
  done

  return 1
}

single_installed_pid() {
  local pids
  pids="$(matching_installed_pids | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  local count=0
  local pid
  for pid in $pids; do
    count=$((count + 1))
  done

  if [[ "$count" -eq 1 ]]; then
    echo "$pids"
    return 0
  fi

  echo "FAIL: expected one installed MenuBarDeclutter process, found $count: ${pids:-none}" >&2
  return 1
}

echo "MenuBarDeclutter installed-app smoke"
echo "App: $APP_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo

if [[ ! -d "$APP_PATH" ]]; then
  echo "FAIL: installed app not found at $APP_PATH" >&2
  exit 1
fi

echo "+ open \"$APP_PATH\""
open "$APP_PATH"

if ! wait_for_installed_pid >/tmp/menubardeclutter-installed-smoke-pids.txt; then
  echo "FAIL: installed MenuBarDeclutter process did not launch within ${APP_LAUNCH_TIMEOUT_SECONDS}s." >&2
  exit 1
fi

BASE_PID="$(single_installed_pid)"
echo "PASS: installed app is running as PID $BASE_PID"

if [[ "$RUN_URL_SMOKE" -eq 1 ]]; then
  echo
  echo "== URL Scheme Smoke =="
  for command in expand collapse reveal-all; do
    url="menubardeclutter://$command"
    echo "+ open -b \"$BUNDLE_ID\" \"$url\""
    open -b "$BUNDLE_ID" "$url"
    sleep 1
    CURRENT_PID="$(single_installed_pid)"
    if [[ "$CURRENT_PID" == "$BASE_PID" ]]; then
      echo "PASS: $url reused installed PID $CURRENT_PID"
    else
      echo "FAIL: $url changed installed PID from $BASE_PID to $CURRENT_PID" >&2
      exit 1
    fi
  done
fi

if [[ "$RUN_PRIVACY" -eq 1 ]]; then
  echo
  echo "== Installed Privacy Boundary =="
  APP_PATH="$APP_PATH" bash scripts/verify_privacy_boundary.sh
fi

if [[ "$RUN_NETWORK" -eq 1 ]]; then
  echo
  echo "== Installed Network Probe =="
  bash scripts/qa_network_watch.sh --installed
fi

if [[ "$RUN_SAFE_MODE_FLAG" -eq 1 ]]; then
  echo
  echo "== One-Shot Safe Mode Flag Smoke =="
  terminate_installed_app
  clear_safe_mode_flags

  expected_flag="$(expected_safe_mode_flag_path)"
  echo "INFO: Writing expected one-shot Safe Mode flag path: $expected_flag"
  mkdir -p "$(dirname "$expected_flag")"
  printf 'safe-mode\n' > "$expected_flag"

  echo "+ open \"$APP_PATH\""
  open "$APP_PATH"

  if ! wait_for_installed_pid >/tmp/menubardeclutter-installed-smoke-pids.txt; then
    echo "FAIL: installed MenuBarDeclutter process did not launch within ${APP_LAUNCH_TIMEOUT_SECONDS}s for Safe Mode flag smoke." >&2
    clear_safe_mode_flags
    exit 1
  fi

  sleep 2

  if [[ -f "$expected_flag" ]]; then
    clear_safe_mode_flags
    echo "FAIL: installed app did not consume the expected one-shot Safe Mode flag path: $expected_flag" >&2
    exit 1
  fi

  clear_safe_mode_flags
  echo "PASS: installed app consumed the expected one-shot Safe Mode flag on launch."

  terminate_installed_app
  echo "+ open \"$APP_PATH\""
  open "$APP_PATH"
  if ! wait_for_installed_pid >/tmp/menubardeclutter-installed-smoke-pids.txt; then
    echo "FAIL: installed MenuBarDeclutter process did not relaunch within ${APP_LAUNCH_TIMEOUT_SECONDS}s after Safe Mode flag smoke." >&2
    exit 1
  fi
  BASE_PID="$(single_installed_pid)"
  echo "PASS: installed app relaunched normally as PID $BASE_PID"
fi

clear_intentional_termination_marker

echo
echo "PASS: installed-app smoke completed."
