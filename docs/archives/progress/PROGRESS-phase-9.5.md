# Progress: Phase 9.5

Status: v0.1 Basic Stable Freeze implemented; public stable release is not ready until external signing/notarization and manual system QA are completed.

## Tech Stack

- Swift 6 with default `MainActor` isolation.
- Native macOS 26.0+.
- SwiftUI Settings/Diagnostics surfaces.
- Local UserDefaults migration and Application Support backups.
- Release, privacy, QA, dogfood, installed-app, and notarization dry-run scripts.

## Added

- v0.1 release notes, scope freeze, defaults, feature gates, privacy, FAQ, installation, uninstall, troubleshooting, copy review, known limitations, and release blocker docs.
- v0.1 regression docs and installed-app release templates.
- Post-v0.1 roadmap separation.
- Changelog coverage for the v0.1 stable freeze.

## Modified

- `SettingsMigrationService`: finalized v0.1-safe migration behavior and one-time notice semantics.
- `SettingsStore`: defaults match v0.1 docs.
- Release scripts and QA scripts support the frozen v0.1 release workflow.
- Docs consistently frame Pro surfaces as optional, gated, and degraded when Accessibility is unavailable.

## v0.1 Defaults

- Basic Mode enabled.
- Pro Mode disabled.
- Accessibility Discovery disabled.
- Find Icon disabled.
- Second Bar disabled.
- Icon Moving disabled.
- Smart Triggers disabled.
- Automation paused.
- Auto-rehide disabled.
- Hover Reveal disabled.
- Global hotkey disabled.
- Always-hidden disabled.
- Start Collapsed disabled.

## Privacy And Permissions

- Basic Mode requires no sensitive permissions.
- Pro Mode requests Accessibility only after explicit opt-in and explicit permission request.
- Diagnostics, dogfood bundles, migration backups, health reports, and crash markers are local artifacts.
- No ScreenCaptureKit, Screen Recording, Apple Events permission, Input Monitoring, network access, telemetry, cloud sync, or private APIs are included.

## Verification

- `xcodebuild -list`: PASS.
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS' -quiet`: PASS.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -enableCodeCoverage NO -resultBundlePath build/TestResults/MenuBarDeclutter-Full.xcresult -quiet`: PASS.
- `scripts/verify_privacy_boundary.sh`: PASS.
- `scripts/qa_preflight.sh`: PASS; recorded unit coverage was 215 tests in 37 suites plus 7 UI tests.
- `scripts/qa_dogfood_preflight.sh`: PASS.
- `scripts/release_clean.sh`: PASS.
- `scripts/release_archive.sh`: PASS.
- `scripts/release_export_app.sh`: PASS.
- `scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app`: PASS; version `0.1.0`.
- `scripts/release_package_zip.sh`: PASS.
- `scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-alpha.zip`: PASS.
- `scripts/release_install_local.sh build/Export/MenuBarDeclutter.app`: PASS.
- `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app`: PASS with notarization warnings only.
- `scripts/qa_network_watch.sh --installed`: PASS; installed-app socket probe observed no network sockets.

## Notes

- Public distribution remains blocked by missing Developer ID Application identity and notarization credentials.
- Stable sign-off remains blocked by manual system-state QA: real menu bar behavior, Launch at Login restart/login cycle, Accessibility grant/revoke, Safe Mode option/crash recovery, external display/notch/sleep-wake/Spaces, and interactive `nettop` observation.
