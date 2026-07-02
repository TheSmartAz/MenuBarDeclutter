#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
requested_scheme="${SCHEME:-MenuBarDeclutter}"
fallback_scheme="MenuBar-Manager"
scheme="$requested_scheme"
DRY_RUN=0
NOTARIZE=0
STAPLE=0
INSTALL=0
VERIFY_INSTALLED=0
VERSION="${VERSION:-}"
INSTALL_DESTINATION="${INSTALL_DESTINATION:-/Applications/MenuBarDeclutter.app}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/Archives/MenuBarDeclutter.xcarchive}"
EXPORT_DIR="${EXPORT_DIR:-$ROOT_DIR/build/Export}"
APP_PATH="${APP_PATH:-$EXPORT_DIR/MenuBarDeclutter.app}"
ZIP_PATH="${ZIP_PATH:-}"

usage() {
  cat <<EOF
Usage: scripts/build_release.sh [--dry-run] [--notarize] [--staple] [--install] [--verify-installed] [--version VERSION]

Modes:
  --dry-run          Build/archive/export/package locally without Developer ID export or notarization credentials.
  --notarize        Submit the release zip with notarytool. Requires credentials unless --dry-run is also set.
  --staple          Staple and validate the exported app after notarization.
  --install         Install the exported app locally.
  --verify-installed
                    Verify the installed app after install.
  --version VERSION Override MARKETING_VERSION-derived release version.

This release line is v0.1.7. The script refuses future-release artifact names.
EOF
}

version_from_config() {
  awk '/^MARKETING_VERSION[[:space:]]*=/{ print $3; exit }' "$ROOT_DIR/Config/Shared.xcconfig"
}

build_from_config() {
  awk '/^CURRENT_PROJECT_VERSION[[:space:]]*=/{ print $3; exit }' "$ROOT_DIR/Config/Shared.xcconfig"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --notarize)
      NOTARIZE=1
      shift
      ;;
    --staple)
      STAPLE=1
      shift
      ;;
    --install)
      INSTALL=1
      shift
      ;;
    --verify-installed)
      VERIFY_INSTALLED=1
      shift
      ;;
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$ROOT_DIR"

if ! xcodebuild -list 2>/dev/null | grep -qx "        ${scheme}"; then
  if xcodebuild -list 2>/dev/null | grep -qx "        ${fallback_scheme}"; then
    scheme="$fallback_scheme"
  fi
fi

VERSION="${VERSION:-$(version_from_config)}"
if [[ -z "$VERSION" ]]; then
  echo "FAIL: could not derive MARKETING_VERSION from Config/Shared.xcconfig" >&2
  exit 1
fi

if [[ "$VERSION" == "0.2" || "$VERSION" == "0.2.0" || "$VERSION" == v0.2* ]]; then
  echo "FAIL: v0.1.x release tooling must not build a v0.2 artifact." >&2
  exit 1
fi

EXPECTED_BUILD_VERSION="${EXPECTED_BUILD_VERSION:-$(build_from_config)}"
if [[ -z "$EXPECTED_BUILD_VERSION" ]]; then
  echo "FAIL: could not derive CURRENT_PROJECT_VERSION from Config/Shared.xcconfig" >&2
  exit 1
fi

if [[ -z "$ZIP_PATH" ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    ZIP_PATH="$ROOT_DIR/build/Dist/MenuBarDeclutter-v$VERSION-alpha.zip"
  else
    ZIP_PATH="$ROOT_DIR/build/Dist/MenuBarDeclutter-v$VERSION.zip"
  fi
fi

echo "MenuBarDeclutter release build"
echo "Scheme: $scheme"
echo "Version: $VERSION"
echo "Dry run: $DRY_RUN"
echo "Archive: $ARCHIVE_PATH"
echo "Exported app: $APP_PATH"
echo "Zip: $ZIP_PATH"
echo

SCHEME="$scheme" ARCHIVE_PATH="$ARCHIVE_PATH" bash scripts/release_archive.sh
DRY_RUN="$DRY_RUN" ARCHIVE_PATH="$ARCHIVE_PATH" EXPORT_DIR="$EXPORT_DIR" APP_PATH="$APP_PATH" bash scripts/release_export_app.sh
VERSION="$VERSION" APP_PATH="$APP_PATH" ZIP_PATH="$ZIP_PATH" bash scripts/release_package_zip.sh
APP_PATH="$APP_PATH" EXPECTED_MARKETING_VERSION="$VERSION" EXPECTED_BUILD_VERSION="$EXPECTED_BUILD_VERSION" bash scripts/verify_release_artifact.sh

if [[ "$NOTARIZE" -eq 1 ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    VERSION="$VERSION" bash scripts/release_notarize.sh --dry-run "$ZIP_PATH"
  else
    VERSION="$VERSION" bash scripts/release_notarize.sh "$ZIP_PATH"
  fi
else
  echo "INFO: notarization skipped. Pass --notarize to submit with notarytool."
fi

if [[ "$STAPLE" -eq 1 ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "INFO: stapling skipped in dry-run mode. Real stapling requires successful notarization."
  else
    bash scripts/release_staple.sh "$APP_PATH"
  fi
fi

if [[ "$INSTALL" -eq 1 ]]; then
  bash scripts/release_install_local.sh "$APP_PATH" --destination "$INSTALL_DESTINATION"
fi

if [[ "$VERIFY_INSTALLED" -eq 1 ]]; then
  EXPECTED_MARKETING_VERSION="$VERSION" EXPECTED_BUILD_VERSION="$EXPECTED_BUILD_VERSION" bash scripts/verify_installed_app.sh "$INSTALL_DESTINATION"
fi

echo "PASS: release build flow completed."
