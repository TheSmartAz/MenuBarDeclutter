#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ID="${TEST_ID:-MenuBarDeclutterUITests/testRedesignedSettingsPagesVisualSmoke()}"
STAMP="$(date -u +"%Y-%m-%d_%H%M%S")"

usage() {
  cat <<'USAGE'
Usage:
  scripts/export_visual_smoke_screenshots.sh [result.xcresult] [output-run-dir]

If result.xcresult is omitted, the latest Test-MenuBarDeclutter result bundle
under Xcode DerivedData is used. The output directory defaults to:
  docs/testing/v0.1.10-visual-smoke/<UTC timestamp>

The script exports only the v0.1.10 Settings visual smoke attachments and
writes normalized screenshots into <output-run-dir>/screenshots.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

find_latest_result() {
  local result_root="${RESULT_ROOT:-$HOME/Library/Developer/Xcode/DerivedData}"
  find "$result_root" -path "*/Logs/Test/Test-MenuBarDeclutter-*.xcresult" -print 2>/dev/null |
    sort |
    tail -n 1
}

XCRESULT_PATH="${1:-}"
if [[ -z "$XCRESULT_PATH" ]]; then
  XCRESULT_PATH="$(find_latest_result)"
fi

if [[ -z "$XCRESULT_PATH" || ! -d "$XCRESULT_PATH" ]]; then
  echo "error: result bundle not found. Pass a .xcresult path or run tests first." >&2
  exit 1
fi

RUN_DIR="${2:-$ROOT_DIR/docs/testing/v0.1.10-visual-smoke/$STAMP}"
SCREENSHOT_DIR="$RUN_DIR/screenshots"
RAW_DIR="$(mktemp -d "${TMPDIR:-/tmp}/menubar-visual-smoke.XXXXXX")"
trap 'rm -rf "$RAW_DIR"' EXIT

mkdir -p "$SCREENSHOT_DIR"

xcrun xcresulttool export attachments \
  --path "$XCRESULT_PATH" \
  --test-id "$TEST_ID" \
  --output-path "$RAW_DIR"

python3 - "$RAW_DIR" "$RUN_DIR" "$SCREENSHOT_DIR" "$XCRESULT_PATH" <<'PY'
import json
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

raw_dir = Path(sys.argv[1])
run_dir = Path(sys.argv[2])
screenshot_dir = Path(sys.argv[3])
xcresult_path = sys.argv[4]
manifest_path = raw_dir / "manifest.json"

if not manifest_path.exists():
    raise SystemExit("error: xcresult attachment export did not produce manifest.json")

pages = [
    ("General", "01-general.png"),
    ("Hide & Reveal", "02-hide-reveal.png"),
    ("Arrange", "03-arrange.png"),
    ("Find & Rescue", "04-find-rescue.png"),
    ("Workspaces", "05-workspaces.png"),
    ("Privacy", "06-privacy.png"),
    ("Recovery", "07-recovery.png"),
    ("Advanced", "08-advanced.png"),
]

def normalize(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")

expected = {normalize(name): (name, filename) for name, filename in pages}
exported = {}
data = json.loads(manifest_path.read_text())

for test_entry in data:
    for attachment in test_entry.get("attachments", []):
        suggested = attachment.get("suggestedHumanReadableName", "")
        title = suggested.split("_0_", 1)[0]
        if title.startswith("Settings - "):
            title = title[len("Settings - "):]
        key = normalize(title)
        if key in expected:
            exported[key] = attachment

missing = [name for key, (name, _) in expected.items() if key not in exported]
if missing:
    raise SystemExit("error: missing visual smoke screenshots: " + ", ".join(missing))

copied = []
for key, (name, filename) in expected.items():
    attachment = exported[key]
    source = raw_dir / attachment["exportedFileName"]
    destination = screenshot_dir / filename
    shutil.copy2(source, destination)
    copied.append((name, destination.name, attachment.get("suggestedHumanReadableName", "")))

shutil.copy2(manifest_path, run_dir / "xcresult-attachments-manifest.json")

lines = [
    "# v0.1.10 Settings Visual Smoke",
    "",
    f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}",
    f"Source result bundle: `{xcresult_path}`",
    "",
    "Screenshots:",
]

for name, filename, suggested in copied:
    lines.append(f"- {name}: `screenshots/{filename}`")

lines.extend([
    "",
    "Source attachment names:",
])

for name, filename, suggested in copied:
    lines.append(f"- {name}: `{suggested}`")

(run_dir / "README.md").write_text("\n".join(lines) + "\n")
print(f"Exported {len(copied)} visual smoke screenshots to {screenshot_dir}")
print(run_dir)
PY
