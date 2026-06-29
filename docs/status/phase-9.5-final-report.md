# Phase 9.5 Final Report

Date: 2026-06-28 local machine time
Status: v0.1 Basic Stable Freeze implemented; public stable release is not ready until external signing/notarization and manual system QA are completed.

## Scope And Defaults

- v0.1 scope is frozen in `docs/release/v0.1-scope-freeze.md`.
- Post-v0.1 work is moved to `docs/roadmap/post-v0.1.md`.
- v0.1 defaults are documented in `docs/release/v0.1-defaults.md` and implemented in `SettingsStore`.
- Fresh installs and Reset All Settings use safe defaults: Pro Mode disabled, Find Icon disabled, Second Bar disabled, Icon Moving disabled, Smart Triggers disabled, Automation paused, Auto-rehide disabled, Hover Reveal disabled, Hotkey disabled, Always-hidden disabled, Start Collapsed disabled.

## Migration

- `SettingsMigrationService` migrates older alpha settings to v0.1 safe defaults.
- Existing alpha settings are backed up under Application Support `backups/`.
- Risky alpha flags are reset, invalid separator lengths are repaired, stale permission/cache state is cleared, and a one-time v0.1 safe defaults notice is shown when migration changes existing settings.
- Unit tests cover fresh install stamping, alpha migration/backups, and current-version no-op behavior.

## Release Docs

- v0.1 release notes, known limitations, privacy, installation, uninstall, troubleshooting, FAQ, copy review, feature gates, blockers, regression suite, and changelog docs exist.
- Privacy docs and verification agree: no ScreenCaptureKit, no Screen Recording, no Apple Events, no Input Monitoring, no network entitlement, no telemetry, and Basic Mode requires no Accessibility.

## Final Validation Results

| Command | Result | Notes |
| --- | --- | --- |
| `xcodebuild -list` | PASS | Canonical scheme `MenuBarDeclutter` present; compatibility scheme `MenuBar-Manager` present |
| `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS' -quiet` | PASS | Exit 0 |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -enableCodeCoverage NO -resultBundlePath build/TestResults/MenuBarDeclutter-Full.xcresult -quiet` | PASS | Exit 0; raw coverage-enabled run completed tests but hung during Xcode log finalization, so preflight now disables coverage and writes a local result bundle |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/project privacy checks passed |
| `scripts/qa_preflight.sh` | PASS | Full tests passed; unit tests: 215 tests in 37 suites; UI tests: 7 tests; privacy boundary passed |
| `scripts/qa_dogfood_preflight.sh` | PASS | Main app build, fixture build, selected Phase 9.2 unit tests, and privacy boundary passed |
| `scripts/release_clean.sh` | PASS | Removed release output directories; left DerivedData unless explicitly requested |
| `scripts/release_archive.sh` | PASS | Created `build/Archives/MenuBarDeclutter.xcarchive`; Xcode warned that no App Category is set |
| `scripts/release_export_app.sh` | PASS | Created `build/Export/MenuBarDeclutter.app` by copying archive product because `Config/ExportOptions.plist` is absent |
| `scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app` | PASS | Version `0.1.0`; codesign valid; no network entitlement; no ScreenCaptureKit link; privacy usage strings absent |
| `scripts/release_package_zip.sh` | PASS | Created `build/Dist/MenuBarDeclutter-alpha.zip` and `build/Dist/MenuBarDeclutter-v0.1.0.zip` |
| `scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-alpha.zip` | PASS | Dry-run only; no credentials used or stored |
| `scripts/release_staple.sh build/Export/MenuBarDeclutter.app` | BLOCKED | Failed with stapler error 65 because no notarization ticket exists |
| `scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app` | BLOCKED | Codesign strict verification passed; `spctl` rejected and `stapler validate` found no ticket, expected for non-notarized dry-run artifact |
| `scripts/release_install_local.sh build/Export/MenuBarDeclutter.app` | PASS | Installed and launched `/Applications/MenuBarDeclutter.app` |
| `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` | PASS | Installed bundle verification passed; notarization checks were warnings only |
| `scripts/qa_network_watch.sh --installed` | PASS | Found installed app PID and observed no network sockets with `lsof -nP -a -i -p` |
| `bash -n` over release/QA scripts | PASS | Syntax check passed |

## Release Blocker Status

- No automated Basic Mode S0/S1 blocker is known.
- No privacy-boundary regression is known.
- No app-trapping or unrecoverable-state blocker is known from automated validation.
- Public distribution is blocked by missing Developer ID Application identity and notarization credentials.
- Stable release sign-off remains blocked by manual system-state QA: real menu bar behavior, Launch at Login restart/login cycle, Accessibility grant/revoke, Safe Mode option/crash recovery, external display/notch/sleep-wake/Spaces, and interactive `nettop` observation.

## Recommendation

Do not mark v0.1 as publicly stable yet. The code, docs, scripts, migration, v0.1 defaults, dry-run release artifact, installed-app verification, and automated regression checks are ready for final human QA and real notarization. After Developer ID/notary credentials are configured and the manual regression exceptions are resolved or explicitly accepted, v0.1 can proceed.
