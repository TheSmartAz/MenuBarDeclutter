#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-MenuBarFixtureApp}"
DESTINATION="${DESTINATION:-platform=macOS}"
AD_HOC_SIGNING_OVERRIDES="${AD_HOC_SIGNING_OVERRIDES:-1}"

cd "$ROOT_DIR"

command=(xcodebuild build -scheme "$SCHEME" -destination "$DESTINATION")
if [[ "$AD_HOC_SIGNING_OVERRIDES" == "1" ]]; then
  command+=(CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO)
fi

printf "+"
printf " %q" "${command[@]}"
printf "\n"

"${command[@]}"
