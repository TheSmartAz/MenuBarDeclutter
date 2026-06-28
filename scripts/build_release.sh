#!/usr/bin/env bash
set -euo pipefail

requested_scheme="${SCHEME:-MenuBarDeclutter}"
fallback_scheme="MenuBar-Manager"
scheme="$requested_scheme"

if ! xcodebuild -list 2>/dev/null | grep -qx "        ${scheme}"; then
  if xcodebuild -list 2>/dev/null | grep -qx "        ${fallback_scheme}"; then
    scheme="$fallback_scheme"
  fi
fi

command=(xcodebuild -scheme "$scheme" -destination "platform=macOS" -configuration Release build)

printf "+"
printf " %q" "${command[@]}"
printf "\n"

"${command[@]}"
