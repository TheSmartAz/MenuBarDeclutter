#!/usr/bin/env bash
set -euo pipefail

requested_scheme="${SCHEME:-MenuBarDeclutter}"
fallback_scheme="MenuBar-Manager"
scheme="$requested_scheme"
DESTINATION="${DESTINATION:-platform=macOS}"
TEST_MODE="${TEST_MODE:-unit}"
RESULT_BUNDLE_PATH="${RESULT_BUNDLE_PATH:-}"
AD_HOC_SIGNING_OVERRIDES="${AD_HOC_SIGNING_OVERRIDES:-0}"

usage() {
  cat <<EOF
Usage: scripts/test.sh [--unit|--ui|--all] [--result-bundle PATH]

Modes:
  --unit        Run the focused hosted unit lane. This is the default.
  --ui          Run UI tests explicitly. This lane can be sensitive to local automation state.
  --all         Run the full scheme, including UI tests.

The unit lane uses Xcode's standard hosted test runner and excludes UI tests.

The script uses the project's local signing defaults by default.

Set AD_HOC_SIGNING_OVERRIDES=1 to force CI-style ad-hoc/no-account overrides:
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --unit)
      TEST_MODE=unit
      shift
      ;;
    --ui|--ui-tests)
      TEST_MODE=ui
      shift
      ;;
    --all|--full)
      TEST_MODE=all
      shift
      ;;
    --result-bundle)
      RESULT_BUNDLE_PATH="${2:-}"
      shift 2
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

if ! xcodebuild -list 2>/dev/null | grep -qx "        ${scheme}"; then
  if xcodebuild -list 2>/dev/null | grep -qx "        ${fallback_scheme}"; then
    scheme="$fallback_scheme"
  fi
fi

terminate_running_app_for_tests() {
  if [[ "${KEEP_RUNNING_APP_FOR_TESTS:-0}" == "1" ]]; then
    echo "INFO: KEEP_RUNNING_APP_FOR_TESTS=1; leaving running MenuBarDeclutter process alone."
    return
  fi

  if pgrep -x MenuBarDeclutter >/dev/null 2>&1; then
    echo "INFO: Terminating running MenuBarDeclutter before Xcode tests to avoid automation launch conflicts."
    pkill -x MenuBarDeclutter 2>/dev/null || true
    sleep 1
  fi
}

command=(xcodebuild test -scheme "$scheme" -destination "$DESTINATION" -enableCodeCoverage NO)
case "$TEST_MODE" in
  unit)
    command+=(-only-testing:MenuBarDeclutterTests)
    ;;
  ui)
    command+=(-only-testing:MenuBarDeclutterUITests)
    ;;
  all)
    ;;
  *)
    echo "Unknown TEST_MODE: $TEST_MODE" >&2
    usage >&2
    exit 2
    ;;
esac

if [[ -n "$RESULT_BUNDLE_PATH" ]]; then
  mkdir -p "$(dirname "$RESULT_BUNDLE_PATH")"
  rm -rf "$RESULT_BUNDLE_PATH"
  command+=(-resultBundlePath "$RESULT_BUNDLE_PATH")
fi

if [[ "$AD_HOC_SIGNING_OVERRIDES" == "1" ]]; then
  command+=(CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO)
fi

echo "MenuBarDeclutter test"
echo "Mode: $TEST_MODE"
echo "Scheme: $scheme"
echo "Destination: $DESTINATION"
echo

terminate_running_app_for_tests
printf "+"
printf " %q" "${command[@]}"
printf "\n"
"${command[@]}"
