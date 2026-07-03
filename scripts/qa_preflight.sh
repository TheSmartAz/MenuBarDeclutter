#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-MenuBarDeclutter}"
DESTINATION="${DESTINATION:-platform=macOS}"
RESULT_BUNDLE_DIR="${RESULT_BUNDLE_DIR:-$ROOT_DIR/build/TestResults}"
XCODE_DERIVED_DATA_PATH="${XCODE_DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData/qa-preflight}"
XCODE_ENABLE_DEBUG_DYLIB="${XCODE_ENABLE_DEBUG_DYLIB:-NO}"
XCTESTRUN_PATH="${XCTESTRUN_PATH:-}"

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

terminate_running_app_for_tests() {
  if [[ "${KEEP_RUNNING_APP_FOR_TESTS:-0}" == "1" ]]; then
    echo "INFO: KEEP_RUNNING_APP_FOR_TESTS=1; leaving running MenuBarDeclutter process alone."
    return
  fi

  if pgrep -x MenuBarDeclutter >/dev/null 2>&1; then
    echo "INFO: Terminating running MenuBarDeclutter before Xcode tests to avoid automation launch conflicts."
    pkill -x MenuBarDeclutter 2>/dev/null || true
    sleep 1
    clear_intentional_termination_marker
  fi
}

terminate_pid_with_deadline() {
  local pid="$1"
  local grace_seconds="${2:-5}"
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

is_xcode_runner_bootstrap_failure() {
  local log_file="$1"

  grep -Eiq "IDELaunchServicesLauncher|Failed to send resume|operation never finished bootstrapping|Timed out while enabling automation mode|failed to initialize for UI testing|test runner failed to initialize for UI testing" "$log_file" \
    || (grep -Eiq "Early unexpected exit" "$log_file" && grep -Eiq "before establishing connection|never finished bootstrapping" "$log_file")
}

xcode_tests_have_started() {
  local log_file="$1"

  [[ -s "$log_file" ]] && grep -Eiq 'Test Suite .+ started|Test Case .+ started|Test run started|Suite ".+" started|Test [[:alnum:]_]+\([^)]*\) started' "$log_file"
}

run_xcode_lane() {
  local result_bundle_path="$1"
  shift
  local max_attempts="${XCODE_TEST_ATTEMPTS:-3}"
  local timeout_seconds="${XCODE_TEST_TIMEOUT_SECONDS:-600}"
  local attempt
  local rc
  local log_file
  local lane_name
  local test_pid
  local deadline
  local timed_out
  local bootstrap_failed

  lane_name="$(basename "$result_bundle_path" .xcresult)"
  mkdir -p "$RESULT_BUNDLE_DIR"

  local args=("$@")

  if [[ "${WRITE_RESULT_BUNDLES:-0}" == "1" ]]; then
    args+=(-resultBundlePath "$result_bundle_path")
  fi

  for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
    log_file="$RESULT_BUNDLE_DIR/${lane_name}-attempt-${attempt}.log"
    rm -f "$log_file"
    if [[ "${WRITE_RESULT_BUNDLES:-0}" == "1" ]]; then
      rm -rf "$result_bundle_path"
    fi

    set +e
    xcodebuild "${args[@]}" > "$log_file" 2>&1 &
    test_pid=$!
    deadline=$((SECONDS + timeout_seconds))
    timed_out=0
    bootstrap_failed=0

    while kill -0 "$test_pid" >/dev/null 2>&1; do
      if (( SECONDS >= deadline )); then
        timed_out=1
        terminate_pid_with_deadline "$test_pid"
        break
      fi
      if [[ -s "$log_file" ]] && is_xcode_runner_bootstrap_failure "$log_file"; then
        bootstrap_failed=1
        terminate_pid_with_deadline "$test_pid"
        break
      fi
      sleep 1
    done

    if [[ "$bootstrap_failed" -eq 1 ]]; then
      rc=125
    elif [[ "$timed_out" -eq 0 ]]; then
      wait "$test_pid"
      rc="$?"
    else
      rc=124
    fi
    set -e
    cat "$log_file"

    if [[ "$rc" -eq 0 ]]; then
      rm -f "$log_file"
      return 0
    fi

    if [[ "$timed_out" -eq 1 ]]; then
      if xcode_tests_have_started "$log_file"; then
        echo "FAIL: Xcode test lane timed out after tests started. Preserved log: $log_file"
        return "$rc"
      fi
      if [[ "$attempt" -lt "$max_attempts" ]]; then
        echo "WARN: Xcode test lane timed out after ${timeout_seconds}s; retrying attempt $((attempt + 1)) of $max_attempts."
        terminate_running_app_for_tests
        sleep 3
        continue
      fi
      echo "BLOCKED-INFRA: Xcode test lane timed out after ${timeout_seconds}s. Preserved log: $log_file"
    elif [[ "$rc" -eq 125 ]] || is_xcode_runner_bootstrap_failure "$log_file"; then
      if [[ "$attempt" -lt "$max_attempts" ]]; then
        echo "WARN: Xcode test runner launch failed before tests completed; retrying attempt $((attempt + 1)) of $max_attempts."
        terminate_running_app_for_tests
        sleep 3
        continue
      fi
      echo "BLOCKED-INFRA: Xcode test runner failed before tests attached. Preserved log: $log_file"
    else
      echo "FAIL: Xcode test lane failed. Preserved log: $log_file"
    fi

    return "$rc"
  done

  return 1
}

run_xcode_tests_without_building() {
  local result_bundle_path="$1"
  shift

  if [[ -z "$XCTESTRUN_PATH" ]]; then
    echo "FAIL: xctestrun path was not set before test-without-building."
    return 1
  fi

  local args=(
    test-without-building
    -xctestrun "$XCTESTRUN_PATH"
    -destination "$DESTINATION"
    "$@"
  )

  run_xcode_lane "$result_bundle_path" "${args[@]}"
}

find_xctestrun_path() {
  local products_dir="$XCODE_DERIVED_DATA_PATH/Build/Products"
  local matches=()
  local preferred_matches=()
  local path

  if [[ ! -d "$products_dir" ]]; then
    echo "FAIL: Build products directory does not exist: $products_dir" >&2
    return 1
  fi

  while IFS= read -r -d '' path; do
    matches+=("$path")
    if [[ "$(basename "$path")" == *MenuBarDeclutter* ]]; then
      preferred_matches+=("$path")
    fi
  done < <(find "$products_dir" -maxdepth 1 -type f -name '*.xctestrun' -print0)

  if [[ "${#matches[@]}" -eq 0 ]]; then
    echo "FAIL: No .xctestrun file found in $products_dir" >&2
    return 1
  fi

  if [[ "${#matches[@]}" -gt 1 ]]; then
    echo "WARN: Found multiple .xctestrun files in $products_dir; selecting the newest MenuBarDeclutter match." >&2
  fi

  if [[ "${#preferred_matches[@]}" -gt 0 ]]; then
    ls -t "${preferred_matches[@]}" 2>/dev/null | head -n 1
  else
    ls -t "${matches[@]}" 2>/dev/null | head -n 1
  fi
}

run_build_for_testing() {
  local log_file="$RESULT_BUNDLE_DIR/qa-preflight-build-for-testing.log"
  mkdir -p "$RESULT_BUNDLE_DIR"
  rm -rf "$XCODE_DERIVED_DATA_PATH"
  rm -f "$log_file"

  set +e
  xcodebuild build-for-testing \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -derivedDataPath "$XCODE_DERIVED_DATA_PATH" \
    -enableCodeCoverage NO \
    "ENABLE_DEBUG_DYLIB=$XCODE_ENABLE_DEBUG_DYLIB" \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO 2>&1 | tee "$log_file"
  local rc="${PIPESTATUS[0]}"
  set -e

  if [[ "$rc" -eq 0 ]]; then
    if ! XCTESTRUN_PATH="$(find_xctestrun_path)"; then
      echo "FAIL: build-for-testing succeeded but no xctestrun file was found. Preserved log: $log_file"
      return 1
    fi
    echo "INFO: Using xctestrun file: $XCTESTRUN_PATH"
    rm -f "$log_file"
    return 0
  fi

  echo "FAIL: build-for-testing failed. Preserved log: $log_file"
  return "$rc"
}

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
terminate_running_app_for_tests
UNIT_RESULT_BUNDLE_PATH="${UNIT_RESULT_BUNDLE_PATH:-$RESULT_BUNDLE_DIR/qa-preflight-unit.xcresult}"
UI_RESULT_BUNDLE_PATH="${UI_RESULT_BUNDLE_PATH:-$RESULT_BUNDLE_DIR/qa-preflight-ui.xcresult}"
overall_rc=0
if [[ "${WRITE_RESULT_BUNDLES:-0}" == "1" ]]; then
  mkdir -p "$RESULT_BUNDLE_DIR"
else
  echo "INFO: Result bundles disabled by default to avoid Xcode 26.3 launch-services instability; set WRITE_RESULT_BUNDLES=1 to write them."
fi

echo "-- Build for testing --"
if ! run_build_for_testing; then
  overall_rc=1
fi
echo

echo "-- Unit tests --"
if ! run_xcode_tests_without_building "$UNIT_RESULT_BUNDLE_PATH" -only-testing:MenuBarDeclutterTests; then
  overall_rc=1
fi
echo

echo "-- UI tests --"
terminate_running_app_for_tests
if ! run_xcode_tests_without_building "$UI_RESULT_BUNDLE_PATH" -only-testing:MenuBarDeclutterUITests; then
  overall_rc=1
fi
echo

echo "== Privacy Boundary =="
if ! "$ROOT_DIR/scripts/verify_privacy_boundary.sh"; then
  overall_rc=1
fi

echo
if [[ "$overall_rc" -ne 0 ]]; then
  echo "Preflight completed with failures. Review preserved logs in $RESULT_BUNDLE_DIR."
  exit "$overall_rc"
fi

echo "Preflight complete."
