#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  scripts/qa_second_bar_manual_gate_audit.sh [options] DIAGNOSTICS_JSON

Options:
  --min-visible-items N        Required last compact visible item count. Default: 1.
  --min-warmed-icons N         Required refreshed thumbnail count from the last warm-up. Default: 1.
  --max-fallback-icons N       Optional maximum last compact fallback icon count.
  --require-notch-avoidance    Require the last compact placement to report notch avoidance.
  --require-failure-row        Require at least one non-PASS direct activation log row.
  --matrix-output PATH         Also write direct activation matrix markdown rows to PATH.
  --date YYYY-MM-DD            Override matrix Date column when --matrix-output is used.
  --app-category VALUE         Set matrix App Category when --matrix-output is used.
  --dynamic-icon yes|no        Set matrix Dynamic Icon when --matrix-output is used.
  --retry-result VALUE         Set matrix Retry Result when --matrix-output is used.
  -h, --help                   Show this help.

Audits a diagnostics JSON export after hands-on Pro Second Bar compact-strip QA.
The audit is privacy-safe: it checks readiness, Accurate Icons warm-up,
aggregate compact-strip runtime fields, and direct-activation result metadata
already present in diagnostics.
USAGE
}

MIN_VISIBLE_ITEMS=1
MIN_WARMED_ICONS=1
MAX_FALLBACK_ICONS=""
REQUIRE_NOTCH_AVOIDANCE=0
REQUIRE_FAILURE_ROW=0
MATRIX_OUTPUT=""
MATRIX_DATE=""
MATRIX_APP_CATEGORY="unknown"
MATRIX_DYNAMIC_ICON="unknown"
MATRIX_RETRY_RESULT="not-recorded"
INPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-visible-items)
      MIN_VISIBLE_ITEMS="${2:-}"
      shift 2
      ;;
    --min-warmed-icons)
      MIN_WARMED_ICONS="${2:-}"
      shift 2
      ;;
    --max-fallback-icons)
      MAX_FALLBACK_ICONS="${2:-}"
      shift 2
      ;;
    --require-notch-avoidance)
      REQUIRE_NOTCH_AVOIDANCE=1
      shift
      ;;
    --require-failure-row)
      REQUIRE_FAILURE_ROW=1
      shift
      ;;
    --matrix-output)
      MATRIX_OUTPUT="${2:-}"
      shift 2
      ;;
    --date)
      MATRIX_DATE="${2:-}"
      shift 2
      ;;
    --app-category)
      MATRIX_APP_CATEGORY="${2:-}"
      shift 2
      ;;
    --dynamic-icon)
      MATRIX_DYNAMIC_ICON="${2:-}"
      shift 2
      ;;
    --retry-result)
      MATRIX_RETRY_RESULT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$INPUT_PATH" ]]; then
        echo "Unexpected extra input: $1" >&2
        usage >&2
        exit 2
      fi
      INPUT_PATH="$1"
      shift
      ;;
  esac
done

if [[ -z "$INPUT_PATH" ]]; then
  echo "Missing DIAGNOSTICS_JSON input." >&2
  usage >&2
  exit 2
fi

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Diagnostics JSON not found: $INPUT_PATH" >&2
  exit 1
fi

if ! [[ "$MIN_VISIBLE_ITEMS" =~ ^[0-9]+$ ]]; then
  echo "--min-visible-items must be a non-negative integer." >&2
  exit 2
fi

if ! [[ "$MIN_WARMED_ICONS" =~ ^[0-9]+$ ]]; then
  echo "--min-warmed-icons must be a non-negative integer." >&2
  exit 2
fi

if [[ -n "$MAX_FALLBACK_ICONS" ]] && ! [[ "$MAX_FALLBACK_ICONS" =~ ^[0-9]+$ ]]; then
  echo "--max-fallback-icons must be a non-negative integer." >&2
  exit 2
fi

if ! command -v ruby >/dev/null 2>&1; then
  echo "ruby is required to parse diagnostics JSON." >&2
  exit 1
fi

export SECOND_BAR_MIN_VISIBLE_ITEMS="$MIN_VISIBLE_ITEMS"
export SECOND_BAR_MIN_WARMED_ICONS="$MIN_WARMED_ICONS"
export SECOND_BAR_MAX_FALLBACK_ICONS="$MAX_FALLBACK_ICONS"
export SECOND_BAR_REQUIRE_NOTCH_AVOIDANCE="$REQUIRE_NOTCH_AVOIDANCE"
export SECOND_BAR_REQUIRE_FAILURE_ROW="$REQUIRE_FAILURE_ROW"

ruby -rjson - "$INPUT_PATH" <<'RUBY'
path = ARGV.fetch(0)
document = JSON.parse(File.read(path))
failures = []
warnings = []

def bool_label(value)
  value == true ? "true" : value == false ? "false" : value.inspect
end

def integer_value(value)
  Integer(value)
rescue ArgumentError, TypeError
  nil
end

def first_integer_in_text(value)
  value.to_s.scan(/\d+/).first&.to_i
end

def pass(label, detail)
  puts "PASS: #{label} - #{detail}"
end

def warn_item(warnings, label, detail)
  warnings << "#{label} - #{detail}"
  puts "WARN: #{label} - #{detail}"
end

def fail_item(failures, label, detail)
  failures << "#{label} - #{detail}"
  puts "FAIL: #{label} - #{detail}"
end

def expect_equal(failures, label, actual, expected)
  if actual == expected
    pass(label, actual.inspect)
  else
    fail_item(failures, label, "expected #{expected.inspect}, got #{actual.inspect}")
  end
end

def expect_true(failures, label, actual)
  if actual == true
    pass(label, bool_label(actual))
  else
    fail_item(failures, label, "expected true, got #{bool_label(actual)}")
  end
end

def expect_false(failures, label, actual)
  if actual == false
    pass(label, bool_label(actual))
  else
    fail_item(failures, label, "expected false, got #{bool_label(actual)}")
  end
end

readiness = document["secondBarReadiness"]
if readiness.nil?
  fail_item(failures, "Second Bar readiness", "missing secondBarReadiness block")
else
  expect_true(failures, "Readiness is ready", readiness["isReady"])
  expect_equal(failures, "Readiness state", readiness["readinessState"], "ready")
  expect_true(failures, "Entitlement active", readiness["entitlementActive"])
  expect_true(failures, "Accessibility Discovery enabled", readiness["accessibilityDiscoveryEnabled"])
  expect_equal(failures, "Accessibility permission", readiness["accessibilityPermission"], "granted")
  expect_true(failures, "Accurate Icons enabled", readiness["accurateIconsEnabled"])
  expect_equal(failures, "Screen Recording permission", readiness["screenCapturePermission"], "granted")
  expect_true(failures, "Primary-click compact opt-in", readiness["primaryClickOptIn"])
  expect_equal(failures, "Primary-click route", readiness["primaryClickRoute"], "toggleCompactStrip")
  expect_false(failures, "Safe Mode inactive", readiness["safeModeActive"])
end

runtime = document["secondBarRuntime"]
if runtime.nil?
  fail_item(failures, "Second Bar runtime", "missing secondBarRuntime block")
else
  expect_false(failures, "Icon warm-up running", runtime["iconWarmUpInProgress"])

  min_warmed_icons = integer_value(ENV.fetch("SECOND_BAR_MIN_WARMED_ICONS", "1")) || 1
  warm_up_result = runtime["lastIconWarmUpResult"].to_s
  warmed_icon_count = first_integer_in_text(warm_up_result)
  if warmed_icon_count && warmed_icon_count >= min_warmed_icons
    pass("Last icon warm-up result", "#{warm_up_result} (#{warmed_icon_count} >= #{min_warmed_icons})")
  else
    fail_item(
      failures,
      "Last icon warm-up result",
      "expected at least #{min_warmed_icons} refreshed icon(s), got #{runtime["lastIconWarmUpResult"].inspect}"
    )
  end

  min_visible_items = integer_value(ENV.fetch("SECOND_BAR_MIN_VISIBLE_ITEMS", "1")) || 1
  visible_count = integer_value(runtime["lastCompactVisibleItemCount"])
  if visible_count && visible_count >= min_visible_items
    pass("Last compact visible items", "#{visible_count} >= #{min_visible_items}")
  else
    fail_item(failures, "Last compact visible items", "expected at least #{min_visible_items}, got #{runtime["lastCompactVisibleItemCount"].inspect}")
  end

  scan_state = runtime["lastCompactScanState"].to_s
  case scan_state
  when "Fresh"
    pass("Last compact scan state", scan_state)
  when "Stale"
    warn_item(warnings, "Last compact scan state", "Stale scan is usable but should be repeated fresh before release sign-off")
  else
    fail_item(failures, "Last compact scan state", "expected Fresh or Stale, got #{scan_state.inspect}")
  end

  fallback_count = integer_value(runtime["lastCompactFallbackIconCount"])
  if fallback_count.nil?
    fail_item(failures, "Last compact fallback icons", "missing or non-numeric value")
  else
    pass("Last compact fallback icons", fallback_count.to_s)
    max_fallback_icons = ENV.fetch("SECOND_BAR_MAX_FALLBACK_ICONS", "").strip
    unless max_fallback_icons.empty?
      max_value = integer_value(max_fallback_icons)
      if fallback_count <= max_value
        pass("Fallback icon ceiling", "#{fallback_count} <= #{max_value}")
      else
        fail_item(failures, "Fallback icon ceiling", "expected <= #{max_value}, got #{fallback_count}")
      end
    end
  end

  if ENV.fetch("SECOND_BAR_REQUIRE_NOTCH_AVOIDANCE", "0") == "1"
    expect_true(failures, "Last compact avoided notch", runtime["lastCompactAvoidedNotch"])
  elsif runtime.key?("lastCompactAvoidedNotch")
    pass("Last compact avoided notch recorded", bool_label(runtime["lastCompactAvoidedNotch"]))
  else
    warn_item(warnings, "Last compact avoided notch recorded", "field missing")
  end

  activation_result = runtime["lastActivationResult"]
  activation_matrix = runtime["lastActivationMatrixResult"]
  activation_zone = runtime["lastActivationTargetZone"]
  activation_visited = integer_value(runtime["lastActivationVisitedElementCount"])
  if activation_result.to_s.empty? || activation_matrix.to_s.empty? || activation_zone.to_s.empty?
    fail_item(failures, "Last direct activation runtime fields", "result/matrix/zone are required")
  else
    pass("Last direct activation runtime fields", "#{activation_result} / #{activation_matrix} / #{activation_zone}")
  end

  if activation_visited && activation_visited > 0
    pass("Last direct activation visited elements", activation_visited.to_s)
  else
    fail_item(failures, "Last direct activation visited elements", "expected positive count, got #{runtime["lastActivationVisitedElementCount"].inspect}")
  end
end

logs = document["logs"] || []
activation_logs = logs.select do |log|
  metadata = log["metadata"] || {}
  message = log["message"].to_s
  message.start_with?("Second Bar activation result") || metadata.key?("matrixResult")
end

if activation_logs.empty?
  fail_item(failures, "Direct activation logs", "no Second Bar activation result logs found")
else
  pass("Direct activation logs", "#{activation_logs.count} row(s)")
end

pass_count = activation_logs.count { |log| (log["metadata"] || {})["matrixResult"].to_s == "PASS" }
if pass_count.positive?
  pass("Direct activation PASS coverage", "#{pass_count} PASS row(s)")
else
  fail_item(failures, "Direct activation PASS coverage", "expected at least one PASS row")
end

failure_count = activation_logs.count do |log|
  result = (log["metadata"] || {})["matrixResult"].to_s
  !result.empty? && result != "PASS"
end
if ENV.fetch("SECOND_BAR_REQUIRE_FAILURE_ROW", "0") == "1"
  if failure_count.positive?
    pass("Direct activation failure coverage", "#{failure_count} failure row(s)")
  else
    fail_item(failures, "Direct activation failure coverage", "expected at least one non-PASS row")
  end
elsif failure_count.positive?
  pass("Direct activation failure rows recorded", "#{failure_count} row(s)")
else
  warn_item(warnings, "Direct activation failure rows recorded", "no failure row in this export")
end

puts ""
if failures.empty?
  puts "Second Bar manual gate audit passed with #{warnings.count} warning(s)."
  exit 0
end

puts "Second Bar manual gate audit failed with #{failures.count} failure(s) and #{warnings.count} warning(s)."
exit 1
RUBY

if [[ -n "$MATRIX_OUTPUT" ]]; then
  mkdir -p "$(dirname "$MATRIX_OUTPUT")"
  "$ROOT_DIR/scripts/qa_second_bar_activation_matrix.sh" \
    --with-header \
    --date "$MATRIX_DATE" \
    --app-category "$MATRIX_APP_CATEGORY" \
    --dynamic-icon "$MATRIX_DYNAMIC_ICON" \
    --retry-result "$MATRIX_RETRY_RESULT" \
    "$INPUT_PATH" > "$MATRIX_OUTPUT"
  echo "Wrote Second Bar activation matrix rows to $MATRIX_OUTPUT"
fi
