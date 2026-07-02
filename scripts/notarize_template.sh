#!/usr/bin/env bash
# Template for notarizing and stapling a MenuBarDeclutter Release build.
#
# This script is a template: fill in the Apple Developer credentials and
# signing identity, then run it from the repo root after archiving a Release
# build. It never runs automatically and never submits secrets in source.
set -euo pipefail

# --- Required configuration (fill in before running) ---
APP_BUNDLE_ID="${APP_BUNDLE_ID:-Yongjun-Zhang.MenuBarDeclutter}"
APP_PATH="${APP_PATH:-build/Export/MenuBarDeclutter.app}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: Your Name (TEAMID)}"
NOTARY_API_KEY_PATH="${NOTARY_API_KEY_PATH:-private/AppStoreConnect_APIKey.p8}"
NOTARY_KEY_ID="${NOTARY_KEY_ID:-XXXXXXXXXX}"
NOTARY_ISSUER_ID="${NOTARY_ISSUER_ID:-00000000-0000-0000-0000-000000000000}"
NOTARY_SUBMITTER="${NOTARY_SUBMITTER:-notarytool}"

if [[ ! -f "${NOTARY_API_KEY_PATH}" ]]; then
  echo "Refusing to continue: notary API key not found at ${NOTARY_API_KEY_PATH}."
  echo "Fill in NOTARY_API_KEY_PATH (and NOTARY_KEY_ID, NOTARY_ISSUER_ID) before running."
  exit 1
fi

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Refusing to continue: app bundle not found at ${APP_PATH}."
  echo "Build and export a Release .app first (see scripts/build_release.sh)."
  exit 1
fi

echo "== 1/5 Verify codesign =="
codesign --verify --strict --verbose=4 "${APP_PATH}"

echo "== 2/5 Zip the app =="
ZIP_PATH="${APP_PATH}.zip"
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

echo "== 3/5 Submit to notarytool =="
if [[ "${NOTARY_SUBMITTER}" == "notarytool" ]]; then
  xcrun notarytool submit "${ZIP_PATH}" \
    --key "${NOTARY_API_KEY_PATH}" \
    --key-id "${NOTARY_KEY_ID}" \
    --issuer "${NOTARY_ISSUER_ID}" \
    --wait
else
  echo "Unknown notary submitter: ${NOTARY_SUBMITTER}"
  exit 1
fi

echo "== 4/5 Staple the ticket =="
xcrun stapler staple "${APP_PATH}"

echo "== 5/5 Validate the stapled bundle =="
xcrun stapler validate "${APP_PATH}"

echo "Notarization + staple complete for ${APP_PATH}."
echo "Reminder: re-zip into a DMG or signed zip for distribution."
