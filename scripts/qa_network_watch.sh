#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-MenuBarDeclutter}"

cat <<EOF
MenuBarDeclutter network watch helper

Target process name or PID: $TARGET

This script prints local commands only. It does not open network connections,
does not upload data, and does not require network access.

Manual checks:

1. If using a process name:
   pgrep -fl "$TARGET"
   lsof -nP -i -c "$TARGET"

2. If using a PID:
   lsof -nP -i -p "$TARGET"

3. Interactive live view:
   sudo nettop -p "$TARGET"

Expected Alpha RC result:
- Basic Mode opens no network connections.
- Pro Mode Accessibility discovery, Find Icon, Second Bar, icon moving,
  profiles, triggers, diagnostics, health, and Safe Mode open no network
  connections.
- Any network connection is a blocking alpha issue unless a future opt-in
  feature explicitly documents it.
EOF
