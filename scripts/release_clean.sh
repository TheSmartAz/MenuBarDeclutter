#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOVE_DERIVED_DATA=0

for arg in "$@"; do
  case "$arg" in
    --derived-data)
      REMOVE_DERIVED_DATA=1
      ;;
    -h|--help)
      cat <<EOF
Usage: scripts/release_clean.sh [--derived-data]

Removes release workflow outputs under build/Archives, build/Export,
build/Dist, and build/Logs. DerivedData is removed only when --derived-data is
provided.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

run() {
  echo "+ $*"
  "$@"
}

cd "$ROOT_DIR"

run rm -rf build/Archives build/Export build/Dist build/Logs

if [[ "$REMOVE_DERIVED_DATA" -eq 1 ]]; then
  run rm -rf build/DerivedData
else
  echo "INFO: build/DerivedData left in place. Pass --derived-data to remove it."
fi

echo "Release build outputs cleaned."
