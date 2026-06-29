# Phase 9.2 Final Report

Date: 2026-06-28

## Completed Tasks

- Added private dogfood documentation under `docs/testing/dogfood/` for gates A-E, run notes, bug reports, daily-use notes, and Phase 9.1 blocker coverage.
- Added the local-only `MenuBarFixtureApp` target and shared scheme in `MenuBar-Manager.xcodeproj`.
- Added fixture source under `Tools/MenuBarFixtureApp/` with deterministic AppKit `NSStatusItem` coverage for icon, title, wide, dynamic, badge, menu, hidden-test, noisy, reset, pause/resume, and quit scenarios.
- Added fixture QA scripts: `scripts/qa_build_fixture.sh`, `scripts/qa_run_fixture.sh`, `scripts/qa_stop_fixture.sh`, and `scripts/qa_dogfood_preflight.sh`.
- Added local Dogfood Mode settings: `dogfoodModeEnabled`, `dogfoodRunID`, and `dogfoodNotesEnabled`.
- Added local App Support dogfood folders under `Application Support/MenuBarDeclutter/Dogfood/`.
- Added pure dogfood models and store support for run IDs, gates, checklist transitions, notes, local save/load, and privacy-safe export bundles.
- Added Diagnostics dogfood UI for run lifecycle, gate checklists, notes, and bundle export.
- Extended diagnostics and health output with optional dogfood run ID only when Dogfood Mode is enabled.
- Added unit coverage for dogfood run IDs, save/load, notes, checklist updates, privacy exclusions, diagnostics schema changes, and QA script/fixture project wiring.

## Non-Changes

- No ScreenCaptureKit, Screen Recording permission, Apple Events, Input Monitoring, telemetry, screenshots, screen-content capture, network access, or new Pro capability was added.
- Icon moving remains opt-in/experimental and was not made default-on.
- `MenuBarDeclutter` has no runtime dependency on `MenuBarFixtureApp`.
- Dogfood Mode is off by default and local-only.

## Validation Results

1. `xcodebuild -list`
   - Result: succeeded.
   - Targets listed: `MenuBarDeclutter`, `MenuBarDeclutterTests`, `MenuBarDeclutterUITests`, `MenuBarFixtureApp`.
   - Schemes listed: `MenuBar-Manager`, `MenuBarDeclutter`, `MenuBarFixtureApp`.

2. `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'`
   - Result: `BUILD SUCCEEDED`.
   - Note: Xcode emitted the existing duplicate matching macOS destinations warning.

3. `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`
   - Result: `TEST FAILED` in the UI test bundle.
   - Swift Testing/unit tests passed first in the canonical full run: 211 tests in 36 suites.
   - Isolated rerun of `testPrivacyWorkflowKeepsBasicModePermissionFree` passed.
   - Clean single-process rerun still failed in existing UI automation paths: `testSecondBarSettingsShowsRequirementsWithoutProMode` could not find `Disabled` after a swipe, and one launch screenshot test reported that the app had not loaded accessibility.
   - Earlier duplicated/stale UI test processes also caused extra UI failures; those processes were cleaned up before the final preflight.

4. Focused Phase 9.2 unit coverage
   - Command: `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` with `-only-testing` filters for `DogfoodStoreTests`, `QAScriptsTests`, `AppSupportPathsTests`, `SettingsStoreTests`, `DiagnosticsExportTests`, and `HealthReportTests`.
   - Result: passed.
   - Swift Testing result: 46 tests in 6 suites passed.
   - Note: broad unit-only selector runs exposed state/order-sensitive failures in `TriggerService`, `TriggerService persistence`, `StatusBarMenuBuilder`, `SettingsMigrationService`, and one diagnostics snapshot assertion. The focused Phase 9.2 suites passed, so there is no evidence these failures come from the dogfood harness changes, but they remain test-suite blockers.

5. `xcodebuild build -scheme MenuBarFixtureApp -destination 'platform=macOS'`
   - Result: `BUILD SUCCEEDED`.
   - Entitlements observed in Debug: app sandbox and get-task-allow only.

6. `scripts/verify_privacy_boundary.sh`
   - Result: passed.
   - Confirmed no network entitlements, no ScreenCaptureKit imports, no Screen Recording / Apple Events / Input Monitoring usage strings, expected Accessibility references for opt-in Pro discovery, local URL scheme, local App Support paths, and diagnostics privacy exclusions.

7. `scripts/qa_dogfood_preflight.sh`
   - Result: passed.
   - Ran scheme listing, main app build, fixture build, focused Phase 9.2 tests, privacy boundary verification, release-artifact presence check, and fixture running-state check.
   - Focused Phase 9.2 tests passed: 46 tests in 6 suites.
   - The script cleans up a lingering `xcodebuild` process after Swift Testing reports pass, because hosted menu-bar app tests can otherwise leave the preflight wedged.
   - Release artifact verification was skipped because `build/Release/MenuBarDeclutter.app` was not present.
   - Fixture running-state check reported `MenuBarFixtureApp is not running`.

## Fixture Status

- `MenuBarFixtureApp` builds as a separate app target and shared scheme.
- `LSUIElement` is enabled in `Config/MenuBarFixtureApp-Info.plist`.
- `SKIP_INSTALL = YES` is set on the fixture target.
- The fixture has no dependency edge from the shipping app target.
- The fixture launch/stop scripts are present and executable, but automated tests intentionally do not launch the fixture or inspect screen contents.

## Remaining Manual QA Blockers

- Full UI automation suite stability on this machine.
- Broad unit-only selector stability for pre-existing TriggerService/menu/migration tests.
- Manual fixture launch and visual confirmation of deterministic menu bar items.
- Basic Mode dogfood Gate A with the fixture running.
- Pro read-only and Pro assisted gates with real Accessibility grant/revoke behavior.
- Experimental icon-moving gate with explicit opt-in only.
- Installed app/release artifact validation from a built, signed app bundle.
- External display, notch, sleep/wake, and display disconnect behavior.

## Phase 9.3 Recommendation

Proceed to Phase 9.3 packaging/install preparation only after one manual Gate A dogfood pass with `MenuBarFixtureApp` running. Keep the full UI automation instability and broad unit-only selector failures as Phase 9.3/9.4 blockers, but do not block private local Dogfood Mode smoke runs on them because the main build, fixture build, focused Phase 9.2 tests, privacy boundary, and dogfood preflight pass.
