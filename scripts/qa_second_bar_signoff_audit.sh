#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  scripts/qa_second_bar_signoff_audit.sh [options]

Options:
  --manual-qa PATH              Manual compact strip QA markdown.
                                Default: docs/testing/manual-pro-second-bar-compact-strip-qa.md
  --dogfood-gate PATH           Gate C dogfood markdown.
                                Default: docs/testing/dogfood/pro-assisted-gate.md
  --matrix PATH                 Direct activation matrix markdown.
                                Default: docs/testing/pro-second-bar-direct-activation-matrix.md
  --screenshot-manifest PATH    Screenshot QA manifest TSV.
                                Default: docs/testing/screenshot-qa/2026-07-06_secondbar-requirements-states-final2/manifest.tsv
  -h, --help                    Show this help.

Aggregates the privacy-safe evidence required before treating Pro Second Bar
compact strip work as complete. It intentionally fails while real hands-on
Gate C dogfood rows or direct activation matrix coverage are still missing.
USAGE
}

MANUAL_QA_PATH="docs/testing/manual-pro-second-bar-compact-strip-qa.md"
DOGFOOD_GATE_PATH="docs/testing/dogfood/pro-assisted-gate.md"
MATRIX_PATH="docs/testing/pro-second-bar-direct-activation-matrix.md"
SCREENSHOT_MANIFEST_PATH="docs/testing/screenshot-qa/2026-07-06_secondbar-requirements-states-final2/manifest.tsv"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manual-qa)
      MANUAL_QA_PATH="${2:-}"
      shift 2
      ;;
    --dogfood-gate)
      DOGFOOD_GATE_PATH="${2:-}"
      shift 2
      ;;
    --matrix)
      MATRIX_PATH="${2:-}"
      shift 2
      ;;
    --screenshot-manifest)
      SCREENSHOT_MANIFEST_PATH="${2:-}"
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
      echo "Unexpected input: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

resolve_path() {
  local path="$1"
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s\n' "$ROOT_DIR/$path"
  fi
}

MANUAL_QA_PATH="$(resolve_path "$MANUAL_QA_PATH")"
DOGFOOD_GATE_PATH="$(resolve_path "$DOGFOOD_GATE_PATH")"
MATRIX_PATH="$(resolve_path "$MATRIX_PATH")"
SCREENSHOT_MANIFEST_PATH="$(resolve_path "$SCREENSHOT_MANIFEST_PATH")"

for path in "$MANUAL_QA_PATH" "$DOGFOOD_GATE_PATH" "$MATRIX_PATH" "$SCREENSHOT_MANIFEST_PATH"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing sign-off input: $path" >&2
    exit 1
  fi
done

if ! command -v ruby >/dev/null 2>&1; then
  echo "ruby is required to parse sign-off evidence." >&2
  exit 1
fi

failures=0

echo "Second Bar sign-off audit"
echo "Manual QA: $MANUAL_QA_PATH"
echo "Dogfood gate: $DOGFOOD_GATE_PATH"
echo "Matrix: $MATRIX_PATH"
echo "Screenshot manifest: $SCREENSHOT_MANIFEST_PATH"
echo ""

set +e
matrix_output="$("$ROOT_DIR/scripts/qa_second_bar_matrix_coverage.sh" "$MATRIX_PATH" 2>&1)"
matrix_rc="$?"
set -e

if [[ "$matrix_rc" -eq 0 ]]; then
  echo "PASS: Direct activation matrix coverage"
else
  echo "$matrix_output"
  echo "FAIL: Direct activation matrix coverage"
  failures=$((failures + 1))
fi

export SECOND_BAR_SIGNOFF_MANUAL_QA="$MANUAL_QA_PATH"
export SECOND_BAR_SIGNOFF_DOGFOOD_GATE="$DOGFOOD_GATE_PATH"
export SECOND_BAR_SIGNOFF_SCREENSHOT_MANIFEST="$SCREENSHOT_MANIFEST_PATH"

set +e
ruby <<'RUBY'
failures = []

def normalize(value)
  value.to_s.gsub("\\|", "|").gsub(/\s+/, " ").strip
end

def split_markdown_row(line)
  cells = []
  current = +""
  escaped = false
  line.each_char do |char|
    if escaped
      current << char
      escaped = false
    elsif char == "\\"
      escaped = true
    elsif char == "|"
      cells << normalize(current)
      current = +""
    else
      current << char
    end
  end
  cells << normalize(current)
  cells = cells[1..-1] if cells.first == ""
  cells = cells[0...-1] if cells.last == ""
  cells || []
end

def markdown_rows(path)
  rows = []
  File.readlines(path).each do |line|
    next unless line.lstrip.start_with?("|")
    cells = split_markdown_row(line)
    next if cells.length < 2
    next if cells.all? { |cell| cell.match?(/\A:?-{3,}:?\z/) }
    next if ["Area", "Scenario", "Category"].include?(cells.first)
    rows << cells
  end
  rows
end

def status_for(rows, label)
  row = rows.find { |cells| cells.first == label }
  row && row[1].to_s.upcase
end

def require_status(failures, source, rows, label, expected)
  actual = status_for(rows, label)
  if actual == expected
    puts "PASS: #{source} - #{label} is #{expected}"
  elsif actual.nil?
    puts "FAIL: #{source} - #{label} is missing"
    failures << "#{source}: #{label} missing"
  else
    puts "FAIL: #{source} - #{label} expected #{expected}, got #{actual}"
    failures << "#{source}: #{label} #{actual}"
  end
end

manual_rows = markdown_rows(ENV.fetch("SECOND_BAR_SIGNOFF_MANUAL_QA"))
manual_required = [
  "Latest installed app",
  "Installed privacy and network boundary",
  "App Intent readiness gate",
  "URL automation readiness gate",
  "Direct activation matrix logging",
  "Direct activation matrix helper",
  "Manual gate audit helper",
  "Primary-click opt-in gate",
  "Activation failure retry state",
  "Compact strip item inclusion",
  "Compact strip scan state",
  "Compact strip diagnostics export",
  "Compact strip screenshot QA",
  "Warm-up diagnostics",
  "Readiness diagnostics export"
]
manual_required.each do |label|
  require_status(failures, "Manual QA automated evidence", manual_rows, label, "PASS")
end

dogfood_rows = markdown_rows(ENV.fetch("SECOND_BAR_SIGNOFF_DOGFOOD_GATE"))
dogfood_required = [
  "Second Bar setup gates ready",
  "Second Bar compact strip opens and closes",
  "Second Bar Accurate Icons warm-up",
  "Second Bar notch placement",
  "Second Bar external display placement",
  "Second Bar direct activation matrix",
  "Second Bar manual gate audit passes"
]
dogfood_required.each do |label|
  require_status(failures, "Gate C dogfood", dogfood_rows, label, "PASS")
end

manifest_path = ENV.fetch("SECOND_BAR_SIGNOFF_SCREENSHOT_MANIFEST")
lines = File.readlines(manifest_path, chomp: true)
if lines.empty?
  puts "FAIL: Screenshot manifest is empty"
  failures << "screenshot manifest empty"
else
  header = lines.shift.split("\t")
  rows = lines.map do |line|
    Hash[header.zip(line.split("\t", -1))]
  end
  required_slugs = {
    "32-compact-second-bar" => "ready compact strip",
    "33-compact-second-bar-fallback-icons" => "fallback icon compact strip",
    "34-compact-second-bar-accessibility-required" => "Accessibility requirements strip",
    "35-compact-second-bar-accurate-icons-required" => "Accurate Icons requirements strip",
    "36-compact-second-bar-screen-recording-required" => "Screen Recording requirements strip"
  }
  required_slugs.each do |slug, description|
    row = rows.find { |entry| entry["slug"] == slug }
    if row.nil?
      puts "FAIL: Screenshot manifest - #{description} row missing"
      failures << "screenshot #{slug} missing"
      next
    end

    status = row["status"].to_s
    title = row["title"].to_s
    width = row["width"].to_i
    height = row["height"].to_i
    if status == "captured" && title.include?("Second Bar Compact Strip") && width.positive? && height >= 40
      puts "PASS: Screenshot manifest - #{description} captured at #{width}x#{height}"
    else
      puts "FAIL: Screenshot manifest - #{description} invalid status/title/size"
      failures << "screenshot #{slug} invalid"
    end
  end
end

exit(failures.empty? ? 0 : 1)
RUBY
ruby_rc="$?"
set -e

if [[ "$ruby_rc" -ne 0 ]]; then
  failures=$((failures + 1))
fi

echo ""
if [[ "$failures" -eq 0 ]]; then
  echo "Second Bar sign-off audit passed."
  exit 0
fi

echo "Second Bar sign-off audit failed."
exit 1
