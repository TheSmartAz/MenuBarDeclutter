#!/usr/bin/env bash
set -euo pipefail

MODE="process"
TARGET="${1:-MenuBarDeclutter}"

if [[ "${1:-}" == "--installed" ]]; then
  MODE="installed"
  TARGET="MenuBarDeclutter"
fi

if [[ "$MODE" == "installed" ]]; then
  PID="$(pgrep -x "$TARGET" | head -n 1 || true)"
fi

cat <<EOF
MenuBarDeclutter network watch helper

Target process name or PID: $TARGET

This script prints local commands and, in installed-app mode, runs a local
lsof socket probe. It does not open network connections, does not upload data,
and does not require network access.

Manual checks:

1. If using a process name:
   pgrep -fl "$TARGET"
   lsof -nP -i -c "$TARGET"

2. If using a PID:
   lsof -nP -a -i -p "$TARGET"

3. Interactive live view:
   sudo nettop -p "$TARGET"

Installed-app mode:
EOF

if [[ "$MODE" == "installed" ]]; then
  if [[ -n "${PID:-}" ]]; then
    cat <<EOF
- Running PID: $PID
- Current local socket probe:
  lsof -nP -a -i -p "$PID"
EOF
    if lsof -nP -a -i -p "$PID"; then
      :
    else
      echo "  No network sockets observed for PID $PID."
    fi
    cat <<EOF
- Interactive observation:
  sudo nettop -p "$PID"
EOF
  else
    cat <<EOF
- MenuBarDeclutter is not running. Launch /Applications/MenuBarDeclutter.app, then rerun:
  scripts/qa_network_watch.sh --installed
EOF
  fi
else
  cat <<EOF
- Not active. Pass --installed after launching /Applications/MenuBarDeclutter.app.
EOF
fi

cat <<EOF

Expected Alpha RC result:
- Basic Mode opens no network connections.
- Pro Mode Accessibility discovery, Find Icon, Second Bar, icon moving,
  profiles, triggers, diagnostics, health, and Safe Mode open no network
  connections.
- Any network connection is a blocking alpha issue unless a future opt-in
  feature explicitly documents it.
EOF
