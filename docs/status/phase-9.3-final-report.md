# Phase 9.3 Final Report

Status: implemented workflow; installed-app dry-run validation completed. Public notarized distribution remains credential-blocked.

## Completed

- Signing audit created at `docs/release/phase-9.3-signing-audit.md`.
- Archive/export/package/clean scripts added.
- Notarization, stapling, and Gatekeeper scripts added.
- Installed local install/uninstall scripts added.
- Installed app verification script added.
- Network watch helper now supports `--installed`.
- Installed-app QA docs and run template added.
- Final installed-app dry-run record updated at `docs/testing/phase-9.3-installed-alpha-qa-run.md`.

## Blocked Or Manual

- Real notarization is blocked by missing Developer ID Application identity and missing notary credentials.
- Stapling is blocked until notarization succeeds.
- Launch at Login restart/login behavior requires hands-on `/Applications` and System Settings validation.
- Interactive `sudo nettop` observation remains manual.

## Final Validation Results

- `xcodebuild -list`: PASS.
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS' -quiet`: PASS.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -enableCodeCoverage NO -resultBundlePath build/TestResults/MenuBarDeclutter-Full.xcresult -quiet`: PASS.
- `scripts/verify_privacy_boundary.sh`: PASS.
- `scripts/release_clean.sh`: PASS.
- `scripts/release_archive.sh`: PASS; `.xcarchive` created.
- `scripts/release_export_app.sh`: PASS; app exported by archive copy.
- `scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app`: PASS.
- `scripts/release_package_zip.sh`: PASS; alpha and v0.1.0 zips created.
- `scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-alpha.zip`: PASS dry-run.
- `scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app`: BLOCKED/expected until real notarization; codesign passed, `spctl` rejected, no stapled ticket.
- `scripts/release_install_local.sh build/Export/MenuBarDeclutter.app`: PASS; installed to `/Applications/MenuBarDeclutter.app`.
- `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app`: PASS with notarization warnings only.
- `scripts/qa_network_watch.sh --installed`: PASS; installed-app `lsof` socket probe observed no network sockets.

Recommendation: Phase 9.3 is complete for dry-run installed alpha distribution. Proceed only to public notarized distribution after Developer ID/notary credentials are available and stapling/Gatekeeper validation pass.
