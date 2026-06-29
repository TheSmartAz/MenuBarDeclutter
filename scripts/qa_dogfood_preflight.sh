#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-MenuBarDeclutter}"
FIXTURE_SCHEME="${FIXTURE_SCHEME:-MenuBarFixtureApp}"
DESTINATION="${DESTINATION:-platform=macOS}"

cd "$ROOT_DIR"

run_phase92_tests() {
  local log_file
  local test_pid
  local rc
  local timeout_seconds
  local deadline

  log_file="${TMPDIR:-/tmp}/menubardeclutter-phase92-tests.$$.log"
  timeout_seconds="${TEST_TIMEOUT_SECONDS:-180}"
  deadline=$((SECONDS + timeout_seconds))

  set +e
  xcodebuild test -scheme "$SCHEME" -destination "$DESTINATION" \
    -only-testing:MenuBarDeclutterTests/DogfoodStoreTests \
    -only-testing:MenuBarDeclutterTests/QAScriptsTests \
    -only-testing:MenuBarDeclutterTests/AppSupportPathsTests \
    -only-testing:MenuBarDeclutterTests/SettingsStoreTests \
    -only-testing:MenuBarDeclutterTests/DiagnosticsExportTests \
    -only-testing:MenuBarDeclutterTests/HealthReportTests > "$log_file" 2>&1 &
  test_pid=$!

  while kill -0 "$test_pid" >/dev/null 2>&1; do
    if grep -Eq '(\*\* TEST FAILED \*\*|Test run with .* failed)' "$log_file"; then
      wait "$test_pid"
      rc=$?
      cat "$log_file"
      rm -f "$log_file"
      set -e
      return "${rc:-1}"
    fi

    if grep -Eq '(\*\* TEST SUCCEEDED \*\*|Test run with .* passed)' "$log_file"; then
      sleep 2
      if kill -0 "$test_pid" >/dev/null 2>&1; then
        kill "$test_pid" >/dev/null 2>&1
        wait "$test_pid" >/dev/null 2>&1
      fi
      grep -v '^\*\* BUILD INTERRUPTED \*\*$' "$log_file"
      echo "INFO: xcodebuild cleaned up after Phase 9.2 tests reported pass."
      rm -f "$log_file"
      set -e
      return 0
    fi

    if (( SECONDS >= deadline )); then
      kill "$test_pid" >/dev/null 2>&1
      wait "$test_pid" >/dev/null 2>&1
      cat "$log_file"
      rm -f "$log_file"
      echo "ERROR: Phase 9.2 tests timed out after ${timeout_seconds}s."
      set -e
      return 124
    fi

    sleep 1
  done

  wait "$test_pid"
  rc=$?
  cat "$log_file"
  rm -f "$log_file"
  set -e
  return "$rc"
}

echo "MenuBarDeclutter Phase 9.2 dogfood preflight"
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

echo "== Phase 9.2 Unit Tests =="
run_phase92_tests
echo

echo "== Privacy Boundary =="
"$ROOT_DIR/scripts/verify_privacy_boundary.sh"
echo

echo "== Release Artifact =="
if [[ -d "$ROOT_DIR/build/Release/MenuBarDeclutter.app" ]]; then
  APP_PATH="$ROOT_DIR/build/Release/MenuBarDeclutter.app" "$ROOT_DIR/scripts/verify_release_artifact.sh"
else
  echo "INFO: build/Release/MenuBarDeclutter.app not present; release artifact verification skipped."
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
echo "Preflight complete."
