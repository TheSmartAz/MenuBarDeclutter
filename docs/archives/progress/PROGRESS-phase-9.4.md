# Progress: Phase 9.4

Status: implemented.

## Tech Stack

- Swift 6 with default `MainActor` isolation.
- Native macOS 26.0+.
- SwiftUI Settings and Diagnostics copy updates.
- Local settings migration support.
- Shell-based QA, dogfood, release-artifact, and installed-app verification.

## Added

- `Core/SettingsMigrationService.swift`: v0.1-safe migration and backup flow for older alpha settings.
- `MenuBar-ManagerTests/SettingsMigrationServiceTests.swift`: migration, backup, current-version no-op, and fresh-install coverage.
- Dogfood triage, bug index, and risk board docs.
- Release docs separating release blockers from accepted limitations.
- Status menu emergency recovery action: Reveal All + Reset Separators.

## Modified

- `SettingsStore`: v0.1-safe defaults keep risky/optional behavior off and `automationPaused` on.
- `GeneralSettingsView`: shows current bundle path and warns when not running from `/Applications` for Launch at Login validation.
- `DiagnosticsSettingsView`: surfaces bundle/install context and recovery status.
- `TriggerService`: keeps debounce/coalescing and automation pause behavior aligned with safe defaults.
- Release docs clarify Icon Moving remains disabled by default and experimental.

## Privacy And Permissions

- Basic Mode remains permission-free.
- Safe defaults disable Pro Mode, Accessibility Discovery, Find Icon, Second Bar, Icon Moving, Smart Triggers, Auto-rehide, Hover Reveal, Hotkey, Always-hidden, and Start Collapsed.
- Automation is paused by default to avoid surprise profile application.
- Migration backs up settings locally under Application Support and does not delete profiles.
- No ScreenCaptureKit, Screen Recording, Apple Events, Input Monitoring, network access, telemetry, or cloud sync was added.

## Verification

- `xcodebuild -list`: PASS.
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS' -quiet`: PASS.
- Full app/unit/UI tests via `scripts/qa_preflight.sh`: PASS; recorded unit coverage was 215 tests in 37 suites plus 7 UI tests.
- `scripts/verify_privacy_boundary.sh`: PASS.
- `scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app`: PASS.
- `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app`: PASS with expected non-notarized warnings.
- `scripts/qa_dogfood_preflight.sh`: PASS.

## Notes

- v0.1 remained blocked for public release by notarization credentials and manual system-state QA, not by known automated Basic Mode or privacy failures.
