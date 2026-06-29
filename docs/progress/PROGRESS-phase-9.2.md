# Progress: Phase 9.2

Status: implemented.

## Tech Stack

- Swift 6 with app/runtime code isolated to `MainActor`.
- Native macOS 26.0+.
- AppKit `NSStatusItem` fixture app for deterministic local menu bar QA.
- SwiftUI Diagnostics UI for local dogfood run controls.
- JSON persistence in Application Support.
- Shell scripts for fixture build/run/stop and dogfood preflight.
- Swift Testing for dogfood store, diagnostics schema, QA script wiring, and fixture project wiring.

## Added

- `Tools/MenuBarFixtureApp/MenuBarFixtureApp.swift`: separate local-only fixture app target with deterministic menu bar items for Basic and Pro dogfood.
- `Config/MenuBarFixtureApp-Info.plist`: LSUIElement fixture app plist.
- Shared `MenuBarFixtureApp` scheme and `MenuBarFixtureApp` target in the Xcode project.
- `Dogfood/DogfoodRun.swift`: dogfood gates, checklist items, results, run model, note model, and export metadata.
- `Dogfood/DogfoodStore.swift`: local run lifecycle, checklist updates, note persistence, and privacy-safe export bundle creation.
- `Dogfood/DogfoodNotesView.swift`: Diagnostics-embedded dogfood controls for start/end run, checklist, notes, and bundle export.
- `scripts/qa_build_fixture.sh`, `scripts/qa_run_fixture.sh`, `scripts/qa_stop_fixture.sh`, and `scripts/qa_dogfood_preflight.sh`.
- Dogfood docs under `docs/testing/dogfood/`.
- Unit coverage in `DogfoodStoreTests`, `QAScriptsTests`, and related diagnostics/App Support tests.

## Modified

- `SettingsStore`: added `dogfoodModeEnabled`, `dogfoodRunID`, and `dogfoodNotesEnabled`, all local-only and off/non-active by default.
- `AppSupportPaths`: added `Dogfood/`, `Dogfood/runs/`, and `Dogfood/exports/`.
- `DiagnosticsSettingsView`: embeds Dogfood Mode controls and exports dogfood bundles.
- `DiagnosticsExporter`: includes Dogfood Mode settings and optional run ID only when Dogfood Mode is enabled.
- `HealthReport`: supports dogfood metadata in local export flows.

## Privacy And Permissions

- Dogfood Mode is local-only and disabled by default.
- The shipping `MenuBarDeclutter` target has no runtime dependency on `MenuBarFixtureApp`.
- Dogfood export bundles exclude screenshots, screen contents, live search text, selected item identity, telemetry, and network data.
- No ScreenCaptureKit, Screen Recording, Apple Events, Input Monitoring, network access, telemetry, or cloud sync was added.

## Verification

- `xcodebuild -list`
  - Result: succeeded.
  - Targets included `MenuBarFixtureApp`.
  - Schemes included `MenuBarFixtureApp`.
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'`
  - Result: `BUILD SUCCEEDED`.
- `xcodebuild build -scheme MenuBarFixtureApp -destination 'platform=macOS'`
  - Result: `BUILD SUCCEEDED`.
- Focused Phase 9.2 unit coverage through dogfood preflight
  - Result: passed.
  - Recorded focused coverage: 46 tests in 6 suites.
- `scripts/verify_privacy_boundary.sh`
  - Result: passed.
- `scripts/qa_dogfood_preflight.sh`
  - Result: passed.

## Notes

- The broad UI automation suite had machine-local instability in the Phase 9.2 report, but focused dogfood/unit coverage and fixture builds passed.
- Manual dogfood gates remained required for real menu bar behavior, real Accessibility grant/revoke, real icon moving, and installed-app release validation.
