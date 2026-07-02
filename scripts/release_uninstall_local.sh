#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${APP_PATH:-/Applications/MenuBarDeclutter.app}"
YES=0
PURGE_USER_DATA=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      APP_PATH="${2:-}"
      shift 2
      ;;
    --yes)
      YES=1
      shift
      ;;
    --purge-user-data)
      PURGE_USER_DATA=1
      shift
      ;;
    -h|--help)
      cat <<EOF
Usage: scripts/release_uninstall_local.sh [--path APP] [--yes] [--purge-user-data]

Removes the installed app. User data is kept unless --purge-user-data is
provided.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

confirm() {
  local prompt="$1"
  if [[ "$YES" -eq 1 ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    echo "Refusing without --yes in a non-interactive shell: $prompt" >&2
    return 1
  fi
  read -r -p "$prompt [y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]]
}

echo "MenuBarDeclutter local uninstall"
echo "App: $APP_PATH"
echo

echo "+ pkill -x MenuBarDeclutter || true"
pkill -x MenuBarDeclutter 2>/dev/null || true

if [[ -d "$APP_PATH" ]]; then
  if confirm "Remove $APP_PATH?"; then
    echo "+ rm -rf \"$APP_PATH\""
    rm -rf "$APP_PATH"
  else
    echo "Skipped app removal."
  fi
else
  echo "INFO: app is not installed at $APP_PATH"
fi

if [[ "$PURGE_USER_DATA" -eq 1 ]]; then
  SUPPORT="$HOME/Library/Application Support/MenuBarDeclutter"
  PREFS="$HOME/Library/Preferences/Yongjun-Zhang.MenuBarDeclutter.plist"
  CACHES="$HOME/Library/Caches/Yongjun-Zhang.MenuBarDeclutter"
  CONTAINER="$HOME/Library/Containers/Yongjun-Zhang.MenuBarDeclutter"
  CONTAINER_SUPPORT="$CONTAINER/Data/Library/Application Support/MenuBarDeclutter"
  CONTAINER_PREFS="$CONTAINER/Data/Library/Preferences/Yongjun-Zhang.MenuBarDeclutter.plist"
  CONTAINER_CACHES="$CONTAINER/Data/Library/Caches/Yongjun-Zhang.MenuBarDeclutter"
  DATA_PATHS=(
    "$SUPPORT"
    "$PREFS"
    "$CACHES"
    "$CONTAINER_SUPPORT"
    "$CONTAINER_PREFS"
    "$CONTAINER_CACHES"
    "$CONTAINER"
  )
  echo "User data paths selected for purge:"
  for path in "${DATA_PATHS[@]}"; do
    echo "- $path"
  done
  if confirm "Remove these MenuBarDeclutter user data paths?"; then
    echo "+ rm -rf selected MenuBarDeclutter data paths"
    rm -rf "${DATA_PATHS[@]}"
  else
    echo "Skipped user data purge."
  fi
else
  echo "INFO: user data kept. Pass --purge-user-data for an explicit data purge."
fi

echo "Uninstall workflow complete."
