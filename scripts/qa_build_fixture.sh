#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-MenuBarFixtureApp}"

cd "$ROOT_DIR"

command=(xcodebuild build -scheme "$SCHEME" -destination "platform=macOS")

printf "+"
printf " %q" "${command[@]}"
printf "\n"

"${command[@]}"
