#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/qa_second_bar_activation_matrix.sh [options] DIAGNOSTICS_JSON

Options:
  --date YYYY-MM-DD          Override the matrix Date column.
  --app-category VALUE       Set App Category for all generated rows.
  --dynamic-icon yes|no      Set Dynamic Icon for all generated rows.
  --retry-result VALUE       Set Retry Result for all generated rows.
  --with-header              Include the markdown table header.
  -h, --help                 Show this help.

Reads a MenuBarDeclutter diagnostics JSON export and prints markdown rows for
Second Bar direct activation matrix collection. The script only uses sanitized
diagnostic metadata already present in the export.
USAGE
}

DATE_OVERRIDE=""
APP_CATEGORY="unknown"
DYNAMIC_ICON="unknown"
RETRY_RESULT="not-recorded"
WITH_HEADER=0
INPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --date)
      DATE_OVERRIDE="${2:-}"
      shift 2
      ;;
    --app-category)
      APP_CATEGORY="${2:-}"
      shift 2
      ;;
    --dynamic-icon)
      DYNAMIC_ICON="${2:-}"
      shift 2
      ;;
    --retry-result)
      RETRY_RESULT="${2:-}"
      shift 2
      ;;
    --with-header)
      WITH_HEADER=1
      shift
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

if ! command -v ruby >/dev/null 2>&1; then
  echo "ruby is required to parse diagnostics JSON." >&2
  exit 1
fi

export MATRIX_DATE_OVERRIDE="$DATE_OVERRIDE"
export MATRIX_APP_CATEGORY="$APP_CATEGORY"
export MATRIX_DYNAMIC_ICON="$DYNAMIC_ICON"
export MATRIX_RETRY_RESULT="$RETRY_RESULT"
export MATRIX_WITH_HEADER="$WITH_HEADER"

ruby -rjson -rdate - "$INPUT_PATH" <<'RUBY'
path = ARGV.fetch(0)
document = JSON.parse(File.read(path))

def field(value, fallback = "unknown")
  text = value.to_s.strip
  text = fallback if text.empty?
  text.gsub("|", "\\|").gsub(/\s+/, " ")
end

def date_for(log)
  override = ENV.fetch("MATRIX_DATE_OVERRIDE", "").strip
  return override unless override.empty?

  timestamp = log["timestamp"].to_s
  return timestamp[0, 10] if timestamp.match?(/\A\d{4}-\d{2}-\d{2}/)

  Date.today.iso8601
end

application = document["application"] || {}
system = document["system"] || {}
logs = document["logs"] || []

activation_logs = logs.select do |log|
  metadata = log["metadata"] || {}
  message = log["message"].to_s
  message.start_with?("Second Bar activation result") || metadata.key?("matrixResult")
end

if ENV.fetch("MATRIX_WITH_HEADER", "0") == "1"
  puts "| Date | macOS Build | App Build | App Category | Item Zone | Dynamic Icon | Activation Result | Retry Result | targetID | targetZone | visitedElementCount | axError | Notes |"
  puts "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |"
end

if activation_logs.empty?
  warn "No Second Bar activation result logs found in #{path}."
  exit 3
end

app_build = [
  application["marketingVersion"],
  application["buildNumber"] && "build #{application["buildNumber"]}"
].compact.join(" ")

activation_logs.each do |log|
  metadata = log["metadata"] || {}
  target_zone = field(metadata["targetZone"])
  row = [
    field(date_for(log)),
    field(system["macOSVersion"]),
    field(app_build, "unknown"),
    field(ENV.fetch("MATRIX_APP_CATEGORY", "unknown")),
    target_zone,
    field(ENV.fetch("MATRIX_DYNAMIC_ICON", "unknown")),
    field(metadata["matrixResult"]),
    field(ENV.fetch("MATRIX_RETRY_RESULT", "not-recorded")),
    field(metadata["targetID"]),
    target_zone,
    field(metadata["visitedElementCount"], "0"),
    field(metadata["axError"], "none"),
    field(metadata["message"] || log["message"], "generated-from-diagnostics")
  ]
  puts "| #{row.join(" | ")} |"
end
RUBY
