#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-MenuBarDeclutter}"
FIXTURE_SCHEME="${FIXTURE_SCHEME:-MenuBarFixtureApp}"
DESTINATION="${DESTINATION:-platform=macOS}"
RESULT_BUNDLE_DIR="${RESULT_BUNDLE_DIR:-$ROOT_DIR/build/TestResults}"
RELEASE_APP_PATH="${RELEASE_APP_PATH:-$ROOT_DIR/build/Export/MenuBarDeclutter.app}"
XCODE_DERIVED_DATA_PATH="${XCODE_DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData/qa-dogfood}"
XCODE_ENABLE_DEBUG_DYLIB="${XCODE_ENABLE_DEBUG_DYLIB:-NO}"
XCTESTRUN_PATH="${XCTESTRUN_PATH:-}"
DOGFOOD_SECOND_BAR_AUDIT_ONLY="${DOGFOOD_SECOND_BAR_AUDIT_ONLY:-0}"
SECOND_BAR_DIAGNOSTICS_JSON="${SECOND_BAR_DIAGNOSTICS_JSON:-}"
SECOND_BAR_AUDIT_OUTPUT="${SECOND_BAR_AUDIT_OUTPUT:-$RESULT_BUNDLE_DIR/qa-second-bar-manual-gate-audit.log}"
SECOND_BAR_AUDIT_MATRIX_OUTPUT="${SECOND_BAR_AUDIT_MATRIX_OUTPUT:-}"
SECOND_BAR_AUDIT_MIN_VISIBLE_ITEMS="${SECOND_BAR_AUDIT_MIN_VISIBLE_ITEMS:-1}"
SECOND_BAR_AUDIT_MAX_FALLBACK_ICONS="${SECOND_BAR_AUDIT_MAX_FALLBACK_ICONS:-}"
SECOND_BAR_AUDIT_REQUIRE_NOTCH="${SECOND_BAR_AUDIT_REQUIRE_NOTCH:-0}"
SECOND_BAR_AUDIT_REQUIRE_FAILURE_ROW="${SECOND_BAR_AUDIT_REQUIRE_FAILURE_ROW:-0}"
SECOND_BAR_AUDIT_DATE="${SECOND_BAR_AUDIT_DATE:-}"
SECOND_BAR_AUDIT_APP_CATEGORY="${SECOND_BAR_AUDIT_APP_CATEGORY:-unknown}"
SECOND_BAR_AUDIT_DYNAMIC_ICON="${SECOND_BAR_AUDIT_DYNAMIC_ICON:-unknown}"
SECOND_BAR_AUDIT_RETRY_RESULT="${SECOND_BAR_AUDIT_RETRY_RESULT:-not-recorded}"

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
    echo "WARN: Found multiple .xctestrun files in $products_dir; selecting the latest MenuBarDeclutter match." >&2
  fi

  if [[ "${#preferred_matches[@]}" -gt 0 ]]; then
    printf '%s\n' "${preferred_matches[@]}" | sort | tail -n 1
  else
    printf '%s\n' "${matches[@]}" | sort | tail -n 1
  fi
}

prepare_phase15_xctestrun() {
  local log_file="$RESULT_BUNDLE_DIR/qa-dogfood-build-for-testing.log"
  mkdir -p "$RESULT_BUNDLE_DIR"

  if [[ -n "$XCTESTRUN_PATH" ]]; then
    if [[ ! -f "$XCTESTRUN_PATH" ]]; then
      echo "FAIL: Provided xctestrun path does not exist: $XCTESTRUN_PATH"
      return 1
    fi
    echo "INFO: Using provided dogfood xctestrun file: $XCTESTRUN_PATH"
    return 0
  fi

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
    CODE_SIGNING_REQUIRED=NO > "$log_file" 2>&1
  local rc="$?"
  set -e
  cat "$log_file"

  if [[ "$rc" -ne 0 ]]; then
    echo "FAIL: dogfood build-for-testing failed. Preserved log: $log_file"
    return "$rc"
  fi

  if ! XCTESTRUN_PATH="$(find_xctestrun_path)"; then
    echo "FAIL: dogfood build-for-testing succeeded but no xctestrun file was found. Preserved log: $log_file"
    return 1
  fi

  export XCTESTRUN_PATH
  echo "INFO: Using dogfood xctestrun file: $XCTESTRUN_PATH"
  rm -f "$log_file"
}

run_phase15_tests_once() {
  local log_file="$1"
  local test_pid
  local rc
  local timeout_seconds
  local deadline

  timeout_seconds="${TEST_TIMEOUT_SECONDS:-180}"
  deadline=$((SECONDS + timeout_seconds))
  rm -f "$log_file"

  set +e
  xcodebuild test-without-building -xctestrun "$XCTESTRUN_PATH" -destination "$DESTINATION" \
    -only-testing:MenuBarDeclutterTests/DogfoodStoreTests \
    -only-testing:MenuBarDeclutterTests/QAScriptsTests \
    -only-testing:MenuBarDeclutterTests/AppSupportPathsTests \
    -only-testing:MenuBarDeclutterTests/SettingsStoreTests \
    -only-testing:MenuBarDeclutterTests/DiagnosticsExportTests \
    -only-testing:MenuBarDeclutterTests/HealthReportTests \
    -only-testing:MenuBarDeclutterTests/StatusBarMenuBuilderTests \
    -only-testing:MenuBarDeclutterTests/CrowdedRevealDecisionEngineTests \
    -only-testing:MenuBarDeclutterTests/LayoutSettingsDefaultsTests \
    -only-testing:MenuBarDeclutterTests/Phase14ProductDietTests \
    -only-testing:MenuBarDeclutterTests/SettingsExportImportTests \
    -only-testing:MenuBarDeclutterTests/RecoveryServiceTests > "$log_file" 2>&1 &
  test_pid=$!

  while kill -0 "$test_pid" >/dev/null 2>&1; do
    if [[ -s "$log_file" ]] && grep -Eq '(\*\* TEST SUCCEEDED \*\*|Test run with .* passed)' "$log_file"; then
      sleep 2
      if kill -0 "$test_pid" >/dev/null 2>&1; then
        terminate_pid_with_deadline "$test_pid"
      fi
      grep -v '^\*\* BUILD INTERRUPTED \*\*$' "$log_file"
      echo "INFO: xcodebuild cleaned up after Phase 15 dogfood tests reported pass."
      rm -f "$log_file"
      set -e
      return 0
    fi

    if [[ -s "$log_file" ]] && is_xcode_runner_bootstrap_failure "$log_file"; then
      terminate_pid_with_deadline "$test_pid"
      cat "$log_file"
      echo "ERROR: Phase 15 dogfood test runner failed before tests attached. Preserved log: $log_file"
      set -e
      return 125
    fi

    if [[ -s "$log_file" ]] && grep -Eq '(\*\* TEST FAILED \*\*|Test run with .* failed)' "$log_file"; then
      sleep 2
      if kill -0 "$test_pid" >/dev/null 2>&1; then
        terminate_pid_with_deadline "$test_pid"
      else
        wait "$test_pid" >/dev/null 2>&1
      fi
      cat "$log_file"
      echo "ERROR: Phase 15 dogfood tests failed. Preserved log: $log_file"
      set -e
      return 1
    fi

    if (( SECONDS >= deadline )); then
      terminate_pid_with_deadline "$test_pid"
      cat "$log_file"
      if xcode_tests_have_started "$log_file"; then
        echo "ERROR: Phase 15 dogfood tests timed out after tests started. Preserved log: $log_file"
        set -e
        return 126
      fi
      echo "ERROR: Phase 15 dogfood tests timed out before tests attached after ${timeout_seconds}s. Preserved log: $log_file"
      set -e
      return 124
    fi

    sleep 1
  done

  wait "$test_pid"
  rc=$?
  cat "$log_file"
  set -e
  return "$rc"
}

run_phase15_tests() {
  local max_attempts="${XCODE_TEST_ATTEMPTS:-3}"
  local attempt
  local log_file
  local rc
  mkdir -p "$RESULT_BUNDLE_DIR"

  for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
    log_file="$RESULT_BUNDLE_DIR/qa-dogfood-phase15-attempt-${attempt}.log"

    set +e
    run_phase15_tests_once "$log_file"
    rc="$?"
    set -e

    if [[ "$rc" -eq 0 ]]; then
      return 0
    fi

    if [[ "$rc" -eq 124 ]]; then
      if [[ "$attempt" -lt "$max_attempts" ]]; then
        echo "WARN: Xcode dogfood test lane timed out; retrying attempt $((attempt + 1)) of $max_attempts."
        terminate_running_app_for_tests
        sleep 3
        continue
      fi
      echo "BLOCKED-INFRA: Xcode dogfood test lane timed out. Preserved log: $log_file"
    elif [[ "$rc" -eq 125 ]] || is_xcode_runner_bootstrap_failure "$log_file"; then
      if [[ "$attempt" -lt "$max_attempts" ]]; then
        echo "WARN: Xcode dogfood test runner launch failed before tests completed; retrying attempt $((attempt + 1)) of $max_attempts."
        terminate_running_app_for_tests
        sleep 3
        continue
      fi
      echo "BLOCKED-INFRA: Xcode dogfood test runner failed before tests attached. Preserved log: $log_file"
    elif [[ "$rc" -eq 126 ]]; then
      echo "FAIL: Phase 15 dogfood tests timed out after tests started. Preserved log: $log_file"
    else
      echo "FAIL: Phase 15 dogfood tests failed. Preserved log: $log_file"
    fi

    return "$rc"
  done

  return 1
}

run_release_artifact_verification() {
  local max_attempts="${DOGFOOD_ARTIFACT_VERIFY_ATTEMPTS:-2}"
  local attempt
  local rc

  for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
    set +e
    APP_PATH="$RELEASE_APP_PATH" "$ROOT_DIR/scripts/verify_release_artifact.sh"
    rc="$?"
    set -e

    if [[ "$rc" -eq 0 ]]; then
      return 0
    fi

    if [[ "$rc" -eq 137 && "$attempt" -lt "$max_attempts" ]]; then
      echo "WARN: Release artifact verification was killed by the OS; retrying attempt $((attempt + 1)) of $max_attempts."
      sleep 2
      continue
    fi

    return "$rc"
  done

  return 1
}

run_second_bar_manual_gate_audit() {
  if [[ -z "$SECOND_BAR_DIAGNOSTICS_JSON" ]]; then
    echo "INFO: SECOND_BAR_DIAGNOSTICS_JSON not set; Second Bar manual gate audit skipped."
    return 0
  fi

  if [[ ! -f "$SECOND_BAR_DIAGNOSTICS_JSON" ]]; then
    echo "FAIL: SECOND_BAR_DIAGNOSTICS_JSON does not exist: $SECOND_BAR_DIAGNOSTICS_JSON"
    return 1
  fi

  mkdir -p "$(dirname "$SECOND_BAR_AUDIT_OUTPUT")"
  local args=(
    --min-visible-items "$SECOND_BAR_AUDIT_MIN_VISIBLE_ITEMS"
  )

  if [[ -n "$SECOND_BAR_AUDIT_MAX_FALLBACK_ICONS" ]]; then
    args+=(--max-fallback-icons "$SECOND_BAR_AUDIT_MAX_FALLBACK_ICONS")
  fi
  if [[ "$SECOND_BAR_AUDIT_REQUIRE_NOTCH" == "1" ]]; then
    args+=(--require-notch-avoidance)
  fi
  if [[ "$SECOND_BAR_AUDIT_REQUIRE_FAILURE_ROW" == "1" ]]; then
    args+=(--require-failure-row)
  fi
  if [[ -n "$SECOND_BAR_AUDIT_MATRIX_OUTPUT" ]]; then
    args+=(
      --matrix-output "$SECOND_BAR_AUDIT_MATRIX_OUTPUT"
      --date "$SECOND_BAR_AUDIT_DATE"
      --app-category "$SECOND_BAR_AUDIT_APP_CATEGORY"
      --dynamic-icon "$SECOND_BAR_AUDIT_DYNAMIC_ICON"
      --retry-result "$SECOND_BAR_AUDIT_RETRY_RESULT"
    )
  fi
  args+=("$SECOND_BAR_DIAGNOSTICS_JSON")

  echo "INFO: Running Second Bar manual gate audit for $SECOND_BAR_DIAGNOSTICS_JSON"
  "$ROOT_DIR/scripts/qa_second_bar_manual_gate_audit.sh" "${args[@]}" | tee "$SECOND_BAR_AUDIT_OUTPUT"
}

if [[ "$DOGFOOD_SECOND_BAR_AUDIT_ONLY" == "1" ]]; then
  echo "MenuBarDeclutter dogfood preflight"
  echo "Second Bar audit-only mode. No builds, app launches, screenshots, uploads, or screen contents are collected."
  echo
  echo "== Second Bar Manual Gate Audit =="
  run_second_bar_manual_gate_audit
  exit "$?"
fi

echo "MenuBarDeclutter dogfood preflight"
echo "Local validation only. No screenshots, uploads, or screen contents are collected."
echo

echo "== System =="
sw_vers
echo "Architecture: $(uname -m)"
echo

echo "== Git =="
git rev-parse --short HEAD || true
echo

echo "== Schemes =="
xcodebuild -list
echo

echo "== Main App Build =="
xcodebuild build -scheme "$SCHEME" -destination "$DESTINATION"
echo

echo "== Fixture Build =="
xcodebuild build -scheme "$FIXTURE_SCHEME" -destination "$DESTINATION"
echo

overall_rc=0
phase15_tests_passed=0
phase15_tests_ran=0
phase15_tests_blocked_by_infra=0

echo "== Phase 15 Focused Tests =="
terminate_running_app_for_tests
if ! prepare_phase15_xctestrun; then
  overall_rc=1
else
  phase15_tests_ran=1
  if run_phase15_tests; then
    phase15_tests_passed=1
  else
    phase15_tests_rc="$?"
    overall_rc=1
    if [[ "$phase15_tests_rc" -eq 124 || "$phase15_tests_rc" -eq 125 ]]; then
      phase15_tests_blocked_by_infra=1
    fi
  fi
fi
echo

echo "== Privacy Boundary =="
if ! "$ROOT_DIR/scripts/verify_privacy_boundary.sh"; then
  overall_rc=1
fi
echo

echo "== Second Bar Manual Gate Audit =="
if ! run_second_bar_manual_gate_audit; then
  overall_rc=1
fi
echo

echo "== Release Artifact =="
if [[ -d "$RELEASE_APP_PATH" ]]; then
  if [[ "$phase15_tests_passed" -eq 1 || "${DOGFOOD_VERIFY_RELEASE_AFTER_TEST_FAILURE:-0}" == "1" || ( "$phase15_tests_ran" -eq 1 && "$phase15_tests_blocked_by_infra" -eq 0 ) ]]; then
    if ! run_release_artifact_verification; then
      overall_rc=1
    fi
  else
    echo "INFO: Phase 15 focused tests did not attach or were blocked by runner infrastructure; skipping release artifact verification in dogfood preflight."
    echo "INFO: Run 'bash scripts/verify_release_artifact.sh $RELEASE_APP_PATH' separately to validate the artifact without Xcode runner noise."
  fi
elif [[ "${DOGFOOD_REQUIRE_RELEASE_APP:-0}" == "1" ]]; then
  echo "FAIL: $RELEASE_APP_PATH not present."
  overall_rc=1
else
  echo "INFO: $RELEASE_APP_PATH not present; release artifact verification skipped."
fi
echo

echo "== Fixture =="
if pgrep -x MenuBarFixtureApp >/dev/null 2>&1; then
  echo "MenuBarFixtureApp is running."
else
  echo "MenuBarFixtureApp is not running."
fi
echo

echo "Dogfood docs: $ROOT_DIR/docs/testing/dogfood"
if [[ "$overall_rc" -ne 0 ]]; then
  echo "Dogfood preflight completed with failures. Review preserved logs in $RESULT_BUNDLE_DIR."
  exit "$overall_rc"
fi

echo "Preflight complete."
