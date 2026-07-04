#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:-/Applications/MenuBarDeclutter.app}"
EXPECTED_BUNDLE_ID="${EXPECTED_BUNDLE_ID:-Yongjun-Zhang.MenuBarDeclutter}"
EXPECTED_CATEGORY="${EXPECTED_CATEGORY:-public.app-category.utilities}"
REQUIRE_NOTARIZED=0
FAILED=0
SPCTL_USED_TEMP_COPY=0

version_from_config() {
  awk '/^MARKETING_VERSION[[:space:]]*=/{ print $3; exit }' "$ROOT_DIR/Config/Shared.xcconfig"
}

build_from_config() {
  awk '/^CURRENT_PROJECT_VERSION[[:space:]]*=/{ print $3; exit }' "$ROOT_DIR/Config/Shared.xcconfig"
}

EXPECTED_MARKETING_VERSION="${EXPECTED_MARKETING_VERSION:-$(version_from_config)}"
EXPECTED_BUILD_VERSION="${EXPECTED_BUILD_VERSION:-$(build_from_config)}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --require-notarized)
      REQUIRE_NOTARIZED=1
      shift
      ;;
    -h|--help)
      cat <<EOF
Usage: scripts/verify_installed_app.sh [APP_PATH] [--require-notarized]
EOF
      exit 0
      ;;
    *)
      APP_PATH="$1"
      shift
      ;;
  esac
done

if [[ "${REQUIRE_NOTARIZED_ENV:-0}" == "1" ]]; then
  REQUIRE_NOTARIZED=1
fi

if [[ -z "$EXPECTED_MARKETING_VERSION" ]]; then
  echo "FAIL: could not derive MARKETING_VERSION from Config/Shared.xcconfig" >&2
  exit 1
fi

if [[ -z "$EXPECTED_BUILD_VERSION" ]]; then
  echo "FAIL: could not derive CURRENT_PROJECT_VERSION from Config/Shared.xcconfig" >&2
  exit 1
fi

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

expected_dry_run_spctl_failure() {
  local output="$1"
  if transient_spctl_failure "$output" ||
     printf '%s\n' "$output" | rg -qi "Operation not permitted|No such file|timed out|resource busy"; then
    return 1
  fi
  if printf '%s\n' "$output" | rg -qi ": rejected$"; then
    return 0
  fi
  printf '%s\n' "$output" | rg -qi "not notarized|no usable signature|bundle format unrecognized, invalid, or unsuitable|source=Unnotarized Developer ID|source=Unidentified Developer"
}

transient_spctl_failure() {
  local output="$1"
  printf '%s\n' "$output" | rg -qi "Too many open files|invalid resource directory"
}

expected_dry_run_stapler_failure() {
  local output="$1"
  if printf '%s\n' "$output" | rg -qi "Too many open files|Operation not permitted|No such file|timed out|resource busy"; then
    return 1
  fi
  printf '%s\n' "$output" | rg -qi "not stapled|no ticket|does not have a ticket|could not validate ticket|The staple and validate action failed"
}

raise_gatekeeper_file_limit() {
  local current
  current="$(ulimit -n)"
  if [[ "$current" == "unlimited" ]]; then
    return
  fi
  if [[ "$current" =~ ^[0-9]+$ && "$current" -ge 1048575 ]]; then
    return
  fi
  if [[ "$current" =~ ^[0-9]+$ && "$current" -ge 65536 ]]; then
    ulimit -n 1048575 2>/dev/null || true
    return
  fi
  ulimit -n 1048575 2>/dev/null || ulimit -n 65536 2>/dev/null || ulimit -n 8192 2>/dev/null || true
}

run_spctl_assessment() {
  local attempt max_attempts output status original_output original_status
  max_attempts=5
  SPCTL_USED_TEMP_COPY=0

  for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
    raise_gatekeeper_file_limit
    output="$(spctl --assess --type execute --verbose=4 "$APP_PATH" 2>&1)" && status=0 || status=$?
    SPCTL_OUTPUT="$output"
    SPCTL_STATUS="$status"

    if [[ "$status" -eq 0 ]] || ! transient_spctl_failure "$output"; then
      return 0
    fi

    if [[ "$attempt" -lt "$max_attempts" ]]; then
      warn "spctl assessment hit a transient Gatekeeper error; retrying ($attempt/$max_attempts)."
      sleep "$attempt"
    fi
  done

  if [[ "$REQUIRE_NOTARIZED" -eq 0 ]] && transient_spctl_failure "$SPCTL_OUTPUT"; then
    original_output="$SPCTL_OUTPUT"
    original_status="$SPCTL_STATUS"
    if run_spctl_assessment_temp_copy; then
      return 0
    fi
    SPCTL_OUTPUT="$original_output"
    SPCTL_STATUS="$original_status"
  fi
}

run_spctl_assessment_temp_copy() {
  local temp_dir temp_app output status

  temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/menubardeclutter-spctl.XXXXXX")" || return 1
  temp_app="$temp_dir/$(basename "$APP_PATH")"

  if ! ditto "$APP_PATH" "$temp_app" >/dev/null 2>&1; then
    rm -rf "$temp_dir"
    return 1
  fi

  warn "spctl assessment hit persistent transient Gatekeeper errors on the original path; assessing a temporary copy for dry-run classification."
  raise_gatekeeper_file_limit
  output="$(spctl --assess --type execute --verbose=4 "$temp_app" 2>&1)" && status=0 || status=$?
  rm -rf "$temp_dir"

  if [[ "$status" -eq 0 ]] || ! transient_spctl_failure "$output"; then
    SPCTL_OUTPUT="$output"
    SPCTL_STATUS="$status"
    SPCTL_USED_TEMP_COPY=1
    return 0
  fi

  return 1
}

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST" 2>/dev/null || true
}

echo "MenuBarDeclutter installed-app verification"
echo "App: $APP_PATH"
echo

if [[ -d "$APP_PATH" ]]; then
  pass "App exists"
else
  fail "App does not exist"
fi

INFO_PLIST="$APP_PATH/Contents/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
  pass "Info.plist exists"

  BUNDLE_ID="$(plist_value CFBundleIdentifier)"
  [[ "$BUNDLE_ID" == "$EXPECTED_BUNDLE_ID" ]] && pass "Bundle identifier is $EXPECTED_BUNDLE_ID" || fail "Bundle identifier is $BUNDLE_ID"

  MARKETING_VERSION="$(plist_value CFBundleShortVersionString)"
  [[ "$MARKETING_VERSION" == "$EXPECTED_MARKETING_VERSION" ]] && pass "Marketing version is $EXPECTED_MARKETING_VERSION" || fail "Marketing version is $MARKETING_VERSION"

  BUILD_VERSION="$(plist_value CFBundleVersion)"
  [[ "$BUILD_VERSION" == "$EXPECTED_BUILD_VERSION" ]] && pass "Build version is $EXPECTED_BUILD_VERSION" || fail "Build version is $BUILD_VERSION"

  CATEGORY="$(plist_value LSApplicationCategoryType)"
  [[ "$CATEGORY" == "$EXPECTED_CATEGORY" ]] && pass "App category is $EXPECTED_CATEGORY" || fail "App category is $CATEGORY"

  if plist_value LSUIElement | rg -q "true|1|YES"; then
    pass "LSUIElement is enabled"
  else
    fail "LSUIElement is not enabled"
  fi

  if /usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" "$INFO_PLIST" 2>/dev/null | rg -q "^menubardeclutter$"; then
    pass "URL scheme is menubardeclutter"
  else
    fail "URL scheme is missing or different"
  fi

  if /usr/libexec/PlistBuddy -c "Print :NSScreenCaptureUsageDescription" "$INFO_PLIST" 2>/dev/null | rg -q "Accurate Icons"; then
    pass "NSScreenCaptureUsageDescription is present for Accurate Icons"
  else
    fail "NSScreenCaptureUsageDescription is missing or not scoped to Accurate Icons"
  fi

  for key in NSAppleEventsUsageDescription NSInputMonitoringUsageDescription; do
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

  if codesign -d --entitlements :- "$APP_PATH" >/tmp/menubardeclutter-installed-entitlements.plist 2>/dev/null; then
    pass "Entitlements are readable"
    if rg -q "com\\.apple\\.security\\.app-sandbox" /tmp/menubardeclutter-installed-entitlements.plist; then
      fail "Sandbox entitlement present; Pro Accessibility Discovery requires a non-sandboxed assistive build"
    else
      pass "Sandbox entitlement absent for Pro Accessibility Discovery"
    fi
    if rg -q "com\\.apple\\.security\\.network\\.(client|server)" /tmp/menubardeclutter-installed-entitlements.plist; then
      fail "Network entitlement present"
    else
      pass "No network entitlements present"
    fi
  else
    fail "Could not read entitlements; assistive/no-network invariants cannot be verified."
  fi

  if codesign -dvv "$APP_PATH" >/tmp/menubardeclutter-installed-codesign-detail.txt 2>&1 &&
     rg -q "Runtime Version|flags=.*runtime" /tmp/menubardeclutter-installed-codesign-detail.txt; then
    pass "Hardened runtime metadata is present"
  else
    fail "Hardened runtime metadata was not confirmed"
  fi

  EXECUTABLE_NAME="$(plist_value CFBundleExecutable)"
  EXECUTABLE="$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"
  if [[ -f "$EXECUTABLE" ]]; then
    if otool -L "$EXECUTABLE" | rg -q "ScreenCaptureKit"; then
      pass "Executable links ScreenCaptureKit for Accurate Icons"
    else
      pass "Executable does not link ScreenCaptureKit directly"
    fi
  else
    fail "Executable is missing"
  fi

  run_spctl_assessment
  if [[ "$SPCTL_STATUS" -eq 0 ]]; then
    printf '%s\n' "$SPCTL_OUTPUT"
    if [[ "$SPCTL_USED_TEMP_COPY" -eq 1 ]]; then
      warn "spctl assessment used a temporary copy after persistent transient errors on the original path."
    fi
    pass "spctl assessment passed"
  elif [[ "$REQUIRE_NOTARIZED" -eq 1 ]]; then
    printf '%s\n' "$SPCTL_OUTPUT"
    fail "spctl assessment failed"
  elif expected_dry_run_spctl_failure "$SPCTL_OUTPUT"; then
    printf '%s\n' "$SPCTL_OUTPUT"
    if [[ "$SPCTL_USED_TEMP_COPY" -eq 1 ]]; then
      warn "spctl assessment used a temporary copy after persistent transient errors on the original path."
    fi
    warn "spctl assessment failed with an expected non-notarized dry-run rejection."
  elif transient_spctl_failure "$SPCTL_OUTPUT"; then
    printf '%s\n' "$SPCTL_OUTPUT"
    warn "spctl assessment ended with a persistent local Gatekeeper resource error after retries; dry-run verification is continuing because notarization is not required."
  else
    printf '%s\n' "$SPCTL_OUTPUT"
    fail "spctl assessment failed with an unexpected error; not treating it as a notarization warning."
  fi

  raise_gatekeeper_file_limit
  STAPLER_OUTPUT="$(xcrun stapler validate "$APP_PATH" 2>&1)" && STAPLER_STATUS=0 || STAPLER_STATUS=$?
  if [[ "$STAPLER_STATUS" -eq 0 ]]; then
    printf '%s\n' "$STAPLER_OUTPUT"
    pass "Stapler validation passed"
  elif [[ "$REQUIRE_NOTARIZED" -eq 1 ]]; then
    printf '%s\n' "$STAPLER_OUTPUT"
    fail "Stapler validation failed"
  elif expected_dry_run_stapler_failure "$STAPLER_OUTPUT"; then
    printf '%s\n' "$STAPLER_OUTPUT"
    warn "Stapler validation failed with an expected missing-ticket dry-run result."
  else
    printf '%s\n' "$STAPLER_OUTPUT"
    fail "Stapler validation failed with an unexpected error; not treating it as a notarization warning."
  fi
fi

echo
if [[ "$FAILED" -ne 0 ]]; then
  echo "Installed-app verification failed."
  exit 1
fi

echo "Installed-app verification passed."
