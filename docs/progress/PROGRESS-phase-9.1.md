# Progress: Phase 9.1

Status: implemented.

Historical snapshot: this file records the end-of-phase state for Phase 9.1. Later progress files, `docs/project-summary.md`, and release docs supersede old scheme names, test counts, defaults, and deferred-scope notes.

## Tech Stack

- Swift 6 with default `MainActor` isolation.
- Native macOS 26.0+.
- AppKit `NSStatusItem` status menu updates.
- SwiftUI Settings and Diagnostics updates.
- Shell scripts for local-only privacy and QA validation.

## Added

- Shared Xcode schemes:
  - `MenuBarDeclutter` canonical Alpha RC scheme.
  - `MenuBar-Manager` deprecated compatibility scheme.
- Temporary Xcode identity rename:
  - App target, built wrapper/executable, and bundle identifier now use `MenuBarDeclutter`.
  - Unit/UI test targets and bundle identifiers now use `MenuBarDeclutterTests` / `MenuBarDeclutterUITests`.
  - The `.xcodeproj` package and source/test folders intentionally retain `MenuBar-Manager` names until the final product name is chosen.
- `scripts/verify_privacy_boundary.sh`: checks project/source and optional built app bundle for privacy boundary regressions.
- `scripts/qa_preflight.sh`: prints system/toolchain context, lists schemes, runs canonical tests, and runs privacy verification.
- `scripts/qa_collect_artifacts.sh`: collects local diagnostics/test artifacts without screenshots or uploads.
- `scripts/qa_network_watch.sh`: prints manual `lsof` / `nettop` network-watch commands.
- `scripts/verify_release_artifact.sh`: checks local app bundle, codesign, entitlements, LSUIElement, URL scheme, and ScreenCaptureKit linkage.
- `docs/status/phase-9.1-audit.md`: repository, build settings, identity, entitlements, Info.plist, and privacy audit.
- `docs/privacy/privacy-boundary.md` and `docs/testing/privacy-qa.md`.
- `docs/testing/alpha-rc-qa-matrix.md`, `docs/testing/alpha-rc-qa-run-template.md`, and `docs/testing/known-risk-areas.md`.
- `docs/release/alpha-rc-checklist.md`, `docs/release/alpha-rc-known-limitations.md`, and `docs/release/alpha-rc-release-notes-template.md`.

## Modified

- `SettingsStore`: added `automationPaused`. The later v0.1 safe-default pass sets its current registered default to `true`.
- `TriggerService` and `SettingsRuntimeCoordinator`: stop and skip smart trigger evaluation while automation is paused.
- `StatusBarMenuBuilder` and `AppEnvironment`: added Pause Automation / Resume Automation status menu action.
- `AdvancedSettingsView`: added Labs / Experimental section, global pause toggle, and an enablement warning for icon moving.
- `ProfileListView`: added Pause All Automation control.
- `DiagnosticsLogger`: added structured categories, severity, and optional privacy-safe metadata while preserving existing log calls.
- `DiagnosticsExporter`: exports category/severity/metadata, supports filtered event exports, and documents stronger privacy exclusions.
- `DiagnosticsSettingsView`: added severity/category filters, Copy Selected, Export Filtered, experimental state, automation pause state, and Launch at Login status.
- `LaunchAtLoginService` and `GeneralSettingsView`: surfaced `SMAppService` status, last registration result, status refresh, and Open Login Items Settings.
- Existing docs: `docs/PLAN.md`, `docs/release-checklist.md`, and `docs/testing/manual-qa.md` updated for Phase 9.1.

## Privacy And Permissions

- No ScreenCaptureKit, Screen Recording permission, Apple Events, Input Monitoring, or network access was added.
- Basic Mode remains permission-free.
- Pro Mode remains opt-in and Accessibility-gated.
- Icon moving remains disabled by default and now visibly experimental.
- Automation pause affects smart triggers; profile apply still never runs bulk icon moves.

## Verification

- `xcodebuild -list`: both `MenuBarDeclutter` and `MenuBar-Manager` schemes listed.
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'`: `BUILD SUCCEEDED`.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`: `TEST SUCCEEDED` in the original Phase 9.1 run (131 Swift tests, 7 UI tests at that time).
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`: `TEST SUCCEEDED` in the original Phase 9.1 run (131 Swift tests, 7 UI tests at that time).
- `scripts/verify_privacy_boundary.sh`: passed.
- `scripts/qa_preflight.sh`: passed.
- `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' -configuration Release -derivedDataPath build/DerivedData build`: `BUILD SUCCEEDED`.
- `scripts/verify_release_artifact.sh build/MenuBarDeclutter.app`: passed.
- `APP_PATH=build/DerivedData/Build/Products/Release/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh`: passed.
- `scripts/qa_network_watch.sh MenuBarDeclutter`: helper ran; exact process/socket probe found no running app after tests, so live `nettop` remains manual.
- Full details are recorded in `docs/status/phase-9.1-final-report.md`.

## Notes

- The `.xcodeproj` package and source/test folders still use `MenuBar-Manager`; this is intentional because `MenuBarDeclutter` is temporary and will be renamed again once the final product name is chosen.
- Launch at Login must still be validated from an installed, signed app.
- External display, notch, real icon moving, Accessibility grant/revoke, and network-watch checks remain manual QA blockers for Alpha RC readiness.
