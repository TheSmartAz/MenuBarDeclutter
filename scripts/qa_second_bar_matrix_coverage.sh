#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/qa_second_bar_matrix_coverage.sh [options] MATRIX_MARKDOWN

Options:
  --min-utility N       Required utility/template PASS rows. Default: 2.
  --min-dynamic N       Required colored/dynamic PASS rows. Default: 2.
  --min-popover N       Required popover-style PASS rows. Default: 2.
  --min-menu N          Required menu-style PASS rows. Default: 2.
  --min-stale N         Required relaunch/stale rows. Default: 1.
  --min-permission N    Required permission-revoked rows. Default: 1.
  -h, --help            Show this help.

Reads the Pro Second Bar direct activation matrix markdown and checks whether
hands-on third-party coverage is broad enough for sign-off. The checker only
uses the text matrix rows already reviewed by the tester.
USAGE
}

MIN_UTILITY=2
MIN_DYNAMIC=2
MIN_POPOVER=2
MIN_MENU=2
MIN_STALE=1
MIN_PERMISSION=1
INPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-utility)
      MIN_UTILITY="${2:-}"
      shift 2
      ;;
    --min-dynamic)
      MIN_DYNAMIC="${2:-}"
      shift 2
      ;;
    --min-popover)
      MIN_POPOVER="${2:-}"
      shift 2
      ;;
    --min-menu)
      MIN_MENU="${2:-}"
      shift 2
      ;;
    --min-stale)
      MIN_STALE="${2:-}"
      shift 2
      ;;
    --min-permission)
      MIN_PERMISSION="${2:-}"
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
  echo "Missing MATRIX_MARKDOWN input." >&2
  usage >&2
  exit 2
fi

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Matrix markdown not found: $INPUT_PATH" >&2
  exit 1
fi

for value in "$MIN_UTILITY" "$MIN_DYNAMIC" "$MIN_POPOVER" "$MIN_MENU" "$MIN_STALE" "$MIN_PERMISSION"; do
  if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    echo "Minimum values must be non-negative integers." >&2
    exit 2
  fi
done

if ! command -v ruby >/dev/null 2>&1; then
  echo "ruby is required to parse matrix markdown." >&2
  exit 1
fi

export MIN_UTILITY
export MIN_DYNAMIC
export MIN_POPOVER
export MIN_MENU
export MIN_STALE
export MIN_PERMISSION

ruby - "$INPUT_PATH" <<'RUBY'
path = ARGV.fetch(0)
markdown = File.read(path)

def normalize(value)
  value.to_s.downcase.gsub("\\|", "|").gsub(/[^a-z0-9+_-]+/, " ").strip
end

def split_row(line)
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
      cells << current.strip
      current = +""
    else
      current << char
    end
  end
  cells << current.strip
  cells = cells[1..-1] if cells.first == ""
  cells = cells[0...-1] if cells.last == ""
  cells || []
end

rows = []
header = nil
markdown.each_line do |line|
  next unless line.lstrip.start_with?("|")
  cells = split_row(line)
  next if cells.empty?
  next if cells.all? { |cell| cell.match?(/\A:?-{3,}:?\z/) }

  if cells.include?("Activation Result") && cells.include?("App Category")
    header = cells
    next
  end
  next if cells.first == "YYYY-MM-DD"
  next if header.nil?
  next unless cells.length >= header.length

  rows << Hash[header.zip(cells)]
end

def row_text(row)
  [
    row["App Category"],
    row["Dynamic Icon"],
    row["Activation Result"],
    row["Retry Result"],
    row["Notes"]
  ].map { |value| normalize(value) }.join(" ")
end

successful_rows = rows.select { |row| normalize(row["Activation Result"]) == "pass" }

counts = {
  utility: successful_rows.count { |row|
    text = row_text(row)
    text.match?(/\butility\b|\btemplate\b|\bmonochrome\b|\bcommon\b/)
  },
  dynamic: successful_rows.count { |row|
    text = row_text(row)
    text.match?(/\bdynamic\b|\bcolored\b|\bcolour\b|\bcalendar\b|\bsync\b|\brecording\b|\bstateful\b/)
  },
  popover: successful_rows.count { |row|
    text = row_text(row)
    text.match?(/\bpopover\b/)
  },
  menu: successful_rows.count { |row|
    text = row_text(row)
    text.match?(/\bmenu\b/)
  },
  stale: rows.count { |row|
    text = row_text(row)
    result = normalize(row["Activation Result"])
    text.match?(/\bstale\b|\brelaunch\b|\brestarted\b|\bowner quit\b/) || result == "fail_stale_metadata"
  },
  permission: rows.count { |row|
    text = row_text(row)
    result = normalize(row["Activation Result"])
    text.match?(/\bpermission revoked\b|\baccessibility revoked\b|\breadiness gate\b|\bpermission\b/) || result == "blocked"
  }
}

requirements = {
  utility: Integer(ENV.fetch("MIN_UTILITY")),
  dynamic: Integer(ENV.fetch("MIN_DYNAMIC")),
  popover: Integer(ENV.fetch("MIN_POPOVER")),
  menu: Integer(ENV.fetch("MIN_MENU")),
  stale: Integer(ENV.fetch("MIN_STALE")),
  permission: Integer(ENV.fetch("MIN_PERMISSION"))
}

labels = {
  utility: "Utility/template icon PASS rows",
  dynamic: "Colored/dynamic icon PASS rows",
  popover: "Popover-style PASS rows",
  menu: "Menu-style PASS rows",
  stale: "Relaunch/stale rows",
  permission: "Permission-revoked rows"
}

failures = []
puts "Second Bar direct activation matrix coverage"
puts "Rows reviewed: #{rows.count}"
puts "PASS rows reviewed: #{successful_rows.count}"
requirements.each do |key, required|
  actual = counts.fetch(key)
  if actual >= required
    puts "PASS: #{labels.fetch(key)} - #{actual}/#{required}"
  else
    puts "FAIL: #{labels.fetch(key)} - #{actual}/#{required}"
    failures << key
  end
end

if rows.empty?
  puts "FAIL: Matrix has no reviewed rows."
  failures << :rows
end

if failures.empty?
  puts "Second Bar direct activation matrix coverage passed."
  exit 0
end

puts "Second Bar direct activation matrix coverage failed."
exit 1
RUBY
