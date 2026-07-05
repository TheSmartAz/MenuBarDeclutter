# Phase 10 Starting Audit

## Build Status
- `xcodebuild -list`: Schemes `MenuBarDeclutter`, `MenuBar-Manager`, `MenuBarFixtureApp`.
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'`: **BUILD SUCCEEDED**

## Existing Modules Audited
1. StatusBar module — `NSStatusItem` based, `StatusItemFactory`, `SeparatorController`.
2. Hiding module — `HidingService`, `HidingVisibilityState`, `ScreenGeometryService`.
3. SettingsStore — Key-based UserDefaults with clamping and defaults registration.
4. DiagnosticsLogger — Category-based logging with ring buffer.
5. HealthService — Settings validation and health checks.
6. SafeModeService — Crash marker and safe mode detection.
7. Privacy verification scripts — `scripts/verify_privacy_boundary.sh`.
8. Manual QA docs — `docs/testing/`.

## Phase 10 Non-Goals
- No ScreenCaptureKit.
- No visual pixel capture.
- No Screen Recording permission.
- No Apple Events.
- No Input Monitoring.
- No network.
- No telemetry.
- No automatic icon moving.

## Risks
- Menu Bar Spacing Labs relies on UserDefaults keys that may vary by macOS
  release. Mitigated by: Labs-only, off by default, dry-run mode, backup
  before apply, reversible.
- Capacity estimate accuracy depends on AX snapshot freshness. Mitigated by
  stale snapshot warnings.
- Spacer store corruption. Mitigated by backup-and-reset recovery.
