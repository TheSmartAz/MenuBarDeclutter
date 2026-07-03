#!/usr/bin/env bash
set -euo pipefail

requested_scheme="${SCHEME:-MenuBarDeclutter}"
fallback_scheme="MenuBar-Manager"
scheme="$requested_scheme"
DESTINATION="${DESTINATION:-platform=macOS}"
AD_HOC_SIGNING_OVERRIDES="${AD_HOC_SIGNING_OVERRIDES:-1}"

if ! xcodebuild -list 2>/dev/null | grep -qx "        ${scheme}"; then
  if xcodebuild -list 2>/dev/null | grep -qx "        ${fallback_scheme}"; then
    scheme="$fallback_scheme"
  fi
fi

command=(xcodebuild -scheme "$scheme" -destination "$DESTINATION" -configuration Debug build)
if [[ "$AD_HOC_SIGNING_OVERRIDES" == "1" ]]; then
  command+=(CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO)
fi

printf "+"
printf " %q" "${command[@]}"
printf "\n"

"${command[@]}"
