# Dogfood QA Mode

Dogfood QA Mode is an internal, local-only feature for structured testing. It is not required for normal use and is disabled by default.

## What It Does

- Adds a separate `MenuBarFixtureApp` target and scheme for deterministic local menu bar item fixtures.
- Stores Dogfood Mode settings: enabled state, active run ID, and notes enablement.
- Creates local dogfood runs with gates A-E.
- Tracks checklist results as NOT TESTED, PASS, FAIL, or BLOCKED.
- Captures local notes during a run.
- Embeds dogfood controls in Diagnostics.
- Exports local dogfood bundles containing diagnostics, optional health report, run JSON, notes JSON, metadata, and a manifest.
- Provides fixture build/run/stop and dogfood preflight scripts.

## User Flow

1. Build and run `MenuBarFixtureApp` when fixture items are needed.
2. Open Settings -> Diagnostics.
3. Enable Dogfood Mode or start a dogfood run.
4. Work through the gate checklist.
5. Add local notes.
6. Export a dogfood bundle for local review.
7. Stop the fixture app when done.

## Privacy And Permissions

Dogfood Mode is local-only. It stores run/checklist/notes/export bundles under Application Support. Export bundles exclude screenshots, screen contents, live search text, selected item identity, telemetry, and network data. The shipping app has no runtime dependency on `MenuBarFixtureApp`.

## Implementation

- `Tools/MenuBarFixtureApp/MenuBarFixtureApp.swift`
- `MenuBar-Manager/Dogfood/DogfoodRun.swift`
- `MenuBar-Manager/Dogfood/DogfoodStore.swift`
- `MenuBar-Manager/Dogfood/DogfoodNotesView.swift`
- `MenuBar-Manager/Settings/DiagnosticsSettingsView.swift`
- `scripts/qa_build_fixture.sh`
- `scripts/qa_run_fixture.sh`
- `scripts/qa_stop_fixture.sh`
- `scripts/qa_dogfood_preflight.sh`

## Verification

- `MenuBar-ManagerTests/DogfoodStoreTests.swift`
- `MenuBar-ManagerTests/QAScriptsTests.swift`
- `docs/testing/dogfood/`
- `docs/progress/PROGRESS-phase-9.2.md`

## Known Limitations

- Dogfood QA Mode is developer/internal QA support, not a public product feature.
- Automated tests do not inspect screen contents or launch the fixture for visual assertions.
- Real fixture-based menu bar behavior still requires hands-on dogfood.
