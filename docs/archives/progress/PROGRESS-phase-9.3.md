# Progress: Phase 9.3

Status: implemented workflow; public notarized distribution remains credential-blocked.

## Tech Stack

- Xcode archive/export workflow for the `MenuBarDeclutter` scheme.
- Shell scripts for release cleaning, archive, export, package, notarization, stapling, Gatekeeper validation, local install/uninstall, installed verification, and installed network-watch probing.
- Existing privacy verification scripts and installed-app QA docs.

## Added

- `scripts/release_clean.sh`
- `scripts/release_archive.sh`
- `scripts/release_export_app.sh`
- `scripts/release_package_zip.sh`
- `scripts/release_notarize.sh`
- `scripts/release_staple.sh`
- `scripts/release_validate_gatekeeper.sh`
- `scripts/release_install_local.sh`
- `scripts/release_uninstall_local.sh`
- `scripts/verify_installed_app.sh`
- Installed alpha release docs, signing audit, notarization setup, notarization runbook, and installed-app QA run template.

## Modified

- `scripts/qa_network_watch.sh`: added installed-app support.
- Release docs now distinguish Xcode/DerivedData validation from installed `/Applications` validation.
- Launch at Login validation is documented as installed-app-only for reliable `SMAppService` behavior.

## Privacy And Permissions

- The release workflow does not require network unless real notarization is explicitly run.
- Dry-run notarization is supported when credentials are unavailable.
- Installed verification checks LSUIElement, URL scheme, entitlements, privacy strings, ScreenCaptureKit linkage, codesign, and expected local-only behavior.

## Verification

- `xcodebuild -list`: PASS.
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS' -quiet`: PASS.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -enableCodeCoverage NO -resultBundlePath build/TestResults/MenuBarDeclutter-Full.xcresult -quiet`: PASS.
- `scripts/verify_privacy_boundary.sh`: PASS.
- `scripts/release_clean.sh`: PASS.
- `scripts/release_archive.sh`: PASS.
- `scripts/release_export_app.sh`: PASS.
- `scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app`: PASS.
- `scripts/release_package_zip.sh`: PASS.
- `scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-alpha.zip`: PASS dry-run.
- `scripts/release_install_local.sh build/Export/MenuBarDeclutter.app`: PASS.
- `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app`: PASS with expected notarization warnings.
- `scripts/qa_network_watch.sh --installed`: PASS; installed-app `lsof` socket probe observed no network sockets.

## Notes

- Real notarization is blocked by missing Developer ID Application identity and missing notary credentials.
- Stapling and full Gatekeeper acceptance remain blocked until notarization succeeds.
- Launch at Login restart/login validation and interactive `sudo nettop` remain manual QA.
