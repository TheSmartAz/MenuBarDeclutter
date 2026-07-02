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

terminate_running_app_for_tests() {
  if [[ "${KEEP_RUNNING_APP_FOR_TESTS:-0}" == "1" ]]; then
    echo "INFO: KEEP_RUNNING_APP_FOR_TESTS=1; leaving running MenuBarDeclutter process alone."
    return
  fi

  if pgrep -x MenuBarDeclutter >/dev/null 2>&1; then
    echo "INFO: Terminating running MenuBarDeclutter before Xcode tests to avoid automation launch conflicts."
    pkill -x MenuBarDeclutter 2>/dev/null || true
    sleep 1
  fi
}

command=(xcodebuild test -scheme "$scheme" -destination "platform=macOS")

printf "+"
printf " %q" "${command[@]}"
printf "\n"

terminate_running_app_for_tests
"${command[@]}"
