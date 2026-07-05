# Phase 14 Progress - v0.1.1 Product Diet + Guided Icon Placement

Date started: 2026-06-30 13:05:19 PDT

## Phase Goal

Make MenuBarDeclutter feel lighter for v0.1.1 by reducing the normal Settings surface, making manual icon arrangement a stable first-class workflow, keeping placement planning Preview, and keeping CGEvent-assisted moving Experimental and explicitly confirmed.

## Baseline Git Status

```text
 M docs/project-summary.md
 M docs/release/v0.1.1-local-dry-run.md
 M docs/release/v0.1.1-release-checklist.md
 M docs/release/v0.1.1-release-runbook.md
?? docs/plans/PHASE-14.md
```

## Baseline Scheme Check

Command:

```sh
xcodebuild -list -project MenuBar-Manager.xcodeproj
```

Result: passed. The canonical `MenuBarDeclutter` scheme is present, along with the deprecated `MenuBar-Manager` compatibility scheme and `MenuBarFixtureApp`.

## Baseline Test Results

- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`: failed after 162.526 seconds. The Swift Testing unit suite reported 410 tests passed, then `MenuBarDeclutterUITests-Runner` exited early before establishing a connection.
- `scripts/qa_preflight.sh`: not run yet.
- `scripts/verify_privacy_boundary.sh`: not run yet.
- `scripts/qa_dogfood_preflight.sh`: not run yet.

## Current Known Failures

- No current automated failures from the latest Phase 14 preflight and dogfood preflight runs.
- Remaining validation is physical/manual QA for real menu bar layouts, Pro Accessibility grant/revoke, Assisted Move on disposable third-party items, display topology changes, and installed-app dogfood behavior.

## Implementation Notes

- Preserve existing uncommitted changes unless they are directly merged with Phase 14 work.
- Keep current-facing language on the `v0.1.1` release line.
- Do not add Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network access, telemetry, analytics, cloud sync, or remote config.

## Summary

Phase 14 implemented the `v0.1.1` product diet around seven Settings areas:

- General
- Hide & Reveal
- Arrange
- Find & Rescue
- Privacy
- Recovery
- Advanced

Guided Manual Arrange is now the stable icon-placement path. Placement Planner is Preview and non-mutating. Assisted Move remains Experimental and single-item gated. Find Icon, Second Bar, Crowded Rescue, New Items, and lightweight collections are consolidated under Find & Rescue, while profiles, automation, migration, Private Access, Dynamic Hotkeys, Spacing Labs, and experimental controls are nested under Advanced.

## Changed Files

Code:

- `MenuBar-Manager/Core/FeatureVisibility.swift`
- `MenuBar-Manager/Arrange/ArrangeStep.swift`
- `MenuBar-Manager/Arrange/PlacementPlanner.swift`
- `MenuBar-Manager/Arrange/NewMenuBarItemInbox.swift`
- `MenuBar-Manager/Arrange/AssistedMoveGate.swift`
- `MenuBar-Manager/Arrange/AssistedMoveViewModel.swift`
- `MenuBar-Manager/Arrange/AssistedMoveIntroView.swift`
- `MenuBar-Manager/Arrange/AssistedMoveDryRunView.swift`
- `MenuBar-Manager/Arrange/AssistedMoveConfirmationView.swift`
- `MenuBar-Manager/Arrange/AssistedMoveResultView.swift`
- `MenuBar-Manager/Accessibility/MenuBarScanCoordinator.swift`
- `MenuBar-Manager/Core/AppSupportPaths.swift`
- `MenuBar-Manager/Core/LiveDiagnosticsStatus.swift`
- `MenuBar-Manager/Settings/ArrangeSettingsView.swift`
- `MenuBar-Manager/Settings/FindAndRescueSettingsView.swift`
- `MenuBar-Manager/Settings/RecoverySettingsView.swift`
- `MenuBar-Manager/Settings/SettingsRootView.swift`
- `MenuBar-Manager/Settings/AdvancedSettingsView.swift`
- `MenuBar-Manager/Settings/BehaviorSettingsView.swift`
- `MenuBar-Manager/Settings/SettingsActions.swift`
- `MenuBar-Manager/App/AppDelegate.swift`
- `MenuBar-Manager/App/AppEnvironment.swift`
- `MenuBar-Manager/App/MenuBarItemSurfaceCoordinator.swift`
- `MenuBar-Manager/StatusBar/StatusBarMenuBuilder.swift`
- `MenuBar-Manager/Moving/IconMoveService.swift`
- `MenuBar-Manager/Moving/IconMoveResult.swift`
- `MenuBar-Manager/Onboarding/OnboardingStep.swift`
- `MenuBar-Manager/Onboarding/OnboardingRootView.swift`
- `MenuBar-Manager/CommandCenter/MenuBarCommand.swift`
- `MenuBar-Manager/CommandCenter/MenuBarCommandAvailability.swift`
- `MenuBar-Manager/CommandCenter/MenuBarCommandRouter.swift`

Tests:

- `MenuBar-ManagerTests/Phase14ProductDietTests.swift`
- `MenuBar-ManagerTests/AppSupportPathsTests.swift`
- `MenuBar-ManagerTests/MenuBarScanCoordinatorTests.swift`
- `MenuBar-ManagerTests/StatusBarMenuBuilderTests.swift`
- `MenuBar-ManagerTests/OnboardingStepTests.swift`
- `MenuBar-ManagerTests/CommandCenter/MenuBarCommandRouterTests.swift`
- `MenuBar-ManagerUITests/MenuBar_ManagerUITests.swift`

Docs:

- `README.md`
- `docs/product/v0.1.1-product-taxonomy.md`
- `docs/product/v0.1.1-product-diet.md`
- `docs/design/phase-14-settings-simplification.md`
- `docs/features/arrange-v0.1.1.md`
- `docs/features/guided-manual-arrange-v0.1.1.md`
- `docs/features/placement-planner-v0.1.1.md`
- `docs/features/assisted-move-v0.1.1-experimental.md`
- `docs/features/find-rescue-v0.1.1.md`
- `docs/features/new-item-inbox-v0.1.1.md`
- `docs/support/settings-overview.md`
- `docs/support/arrange-menu-bar-items.md`
- `docs/support/icon-moving-boundary.md`
- `docs/release/v0.1.1-public-claims.md`
- `docs/release/v0.1.1-known-limitations.md`
- `docs/release/v0.1.1-feature-gates.md`
- `docs/testing/manual-v0.1.1-system-qa.md`

Scripts:

- `scripts/qa_preflight.sh`
- `scripts/qa_dogfood_preflight.sh`
- `scripts/test.sh`

## Test Results

- `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build`: passed, `** BUILD SUCCEEDED **`.
- `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS'`: passed, `** TEST BUILD SUCCEEDED **`.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/Phase14ProductDietTests -only-testing:MenuBarDeclutterTests/PlacementPlannerTests -only-testing:MenuBarDeclutterTests/NewMenuBarItemInboxTests -only-testing:MenuBarDeclutterTests/AssistedMoveGateTests`: passed after the Placement Planner and Assisted Move subflow updates, 14 tests in 4 suites. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.07.01_00-03-56--0700.xcresult`.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/StatusBarMenuBuilderTests -only-testing:MenuBarDeclutterTests/OnboardingStepTests -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests`: passed after updating the status-menu test helper, 35 tests in 3 suites.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`: failed after the unit target passed. The Swift Testing unit suite reported 421 tests passing, then `MenuBarDeclutterUITests-Runner` timed out while enabling automation mode.
- UI automation isolation: `pgrep -fl MenuBarDeclutter` showed an already-running installed `/Applications/MenuBarDeclutter.app`; after terminating it, `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests/MenuBar_ManagerUITests` passed, 9 UI tests with 0 failures in 98.078 seconds.
- `scripts/qa_preflight.sh`, `scripts/qa_dogfood_preflight.sh`, and `scripts/test.sh` now terminate a running `MenuBarDeclutter` process before Xcode tests to avoid same-bundle automation launch conflicts. Set `KEEP_RUNNING_APP_FOR_TESTS=1` to opt out.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/MenuBarScanCoordinatorTests -only-testing:MenuBarDeclutterTests/StatusBarMenuBuilderTests -only-testing:MenuBarDeclutterTests/AppSupportPathsTests -only-testing:MenuBarDeclutterTests/NewMenuBarItemInboxTests -only-testing:MenuBarDeclutterTests/Phase14ProductDietTests`: passed, 22 tests in 5 suites before the final New Items gate/label polish.
- Direct focused `xcodebuild test` retries after the final New Items gate/label polish hit the same Xcode launch-services class before executing any test bodies (`IDELaunchServicesLauncher - Failed to Launch` / early bootstrap exit). The debug app stayed running when launched directly, and `build-for-testing` plus `test-without-building` passed.
- `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS'`: passed after the final New Items gate/label polish, `** TEST BUILD SUCCEEDED **`.
- `xcodebuild test-without-building -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/StatusBarMenuBuilderTests -only-testing:MenuBarDeclutterTests/Phase14ProductDietTests -only-testing:MenuBarDeclutterTests/MenuBarScanCoordinatorTests -only-testing:MenuBarDeclutterTests/AppSupportPathsTests`: passed, 20 tests in 4 suites.
- `xcodebuild test-without-building -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/NewMenuBarItemInboxTests`: passed, 3 tests in 1 suite.
- `xcodebuild test-without-building -scheme MenuBarDeclutter -destination 'platform=macOS'`: passed. Swift Testing reported 424 tests in 72 suites; XCTest UI reported 11 tests with 0 failures.
- `scripts/verify_privacy_boundary.sh`: passed. Built-app checks were skipped because `APP_PATH` was not set.
- `scripts/qa_dogfood_preflight.sh`: first run hit an Xcode build database lock during concurrent fixture build; sequential rerun passed builds, then failed while launching the app host with `IDELaunchServicesLauncher - Failed to Launch ... No such process`.
- `scripts/qa_preflight.sh`: full unit target passed with 421 tests, then UI automation hung and was interrupted after several minutes.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests/MenuBar_ManagerUITests/testSettingsSearchFieldFocusAndFiltering`: passed after hardening the UI-test launch helper and focusing the search-field assertion on the filtered Privacy result.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests/MenuBar_ManagerUITests/testRedesignedSettingsPagesVisualSmoke`: passed after making visual-smoke launches wait for clean app termination and foreground relaunch.
- `scripts/qa_preflight.sh`: passed on 2026-06-30. The result bundle at `build/TestResults/qa-preflight.xcresult` reports 434 total tests, 0 failures, and 0 skipped tests; console output reported 424 Swift tests in 72 suites and 11 UI tests. Privacy-boundary verification also passed, with built-app checks skipped because `APP_PATH` was not set.
- `scripts/qa_dogfood_preflight.sh`: passed on 2026-06-30. Main app build, fixture build, focused Phase 9.2 dogfood/unit tests, privacy-boundary verification, and fixture-not-running check passed. The focused dogfood/unit set reported 47 tests in 6 suites. Release artifact verification was skipped because `build/Release/MenuBarDeclutter.app` was not present.
- `scripts/qa_preflight.sh`: passed on 2026-07-01 after the final Placement Planner and Assisted Move subflow updates. The result bundle at `build/TestResults/qa-preflight.xcresult` reports success; console output reported 428 Swift tests in 72 suites and 11 UI tests, all with 0 failures. Privacy-boundary verification also passed, with built-app checks skipped because `APP_PATH` was not set.
- `scripts/qa_dogfood_preflight.sh`: passed on 2026-07-01 after the final Placement Planner and Assisted Move subflow updates. Main app build, fixture build, focused dogfood/unit tests, privacy-boundary verification, and fixture-not-running check passed. The focused dogfood/unit set reported 47 tests in 6 suites. Release artifact verification was skipped because `build/Release/MenuBarDeclutter.app` was not present.
- `scripts/build_release.sh --dry-run`: passed. Expected dry-run warnings remain for non-notarized `spctl`/stapler validation; an existing Swift warning remains in `DynamicHotkeysSettingsView.swift`.
- `scripts/build_release.sh --dry-run --install --verify-installed`: passed again after the clean preflight/dogfood pass. It archived, dry-run exported, packaged, verified, installed, opened `/Applications/MenuBarDeclutter.app`, and verified the installed bundle. The same expected non-notarized `spctl`/stapler warnings remain.
- `scripts/verify_privacy_boundary.sh /Applications/MenuBarDeclutter.app`: passed for the installed app, including built-app checks for `LSUIElement`, local URL scheme, sensitive usage-string absence, no network entitlements, and no ScreenCaptureKit linkage.
- `scripts/qa_network_watch.sh --installed`: passed for installed PID `89817`; no network sockets were observed.
- Final sanity pass after documentation updates:
  - `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build`: passed, `** BUILD SUCCEEDED **`.
  - `scripts/verify_privacy_boundary.sh`: passed, with built-app checks skipped because `APP_PATH` was not set.
  - `git diff --check`: passed.

## Targeted Search Results

- `rg -n "v0\.2|0\.2\.0" README.md docs MenuBar-Manager scripts Config || true`: only historical/guardrail/plan/progress references were found.
- `rg -n "ScreenCaptureKit|NSScreenCaptureUsageDescription|NSAppleEventsUsageDescription|InputMonitoring|URLSession|NWConnection|analytics|telemetry|Sentry|Firebase" MenuBar-Manager Config scripts docs || true`: app-code hits were privacy exclusions/redaction terms, not active use.
- `rg -n "stable icon moving|stable automated move|bulk move|Screen Recording|screen capture|pixel capture" README.md docs MenuBar-Manager || true`: inspected hits were privacy exclusions, guardrails, or explicit non-claims.
- `rg -n "Private Access.*encrypt|Private Access.*hide.*third-party|Touch ID.*hide.*visible" README.md docs MenuBar-Manager || true`: inspected hits were disclaimers that Private Access is not encryption and cannot hide already-visible third-party items.

## Manual QA Notes

Manual QA still needs physical validation for:

- Arrange command-drag on real menu bar layouts.
- Placement Planner with live Pro Discovery scans and Accessibility grant/revoke.
- Assisted Move dry-run/cancel/confirmed single-item behavior on a disposable third-party item.
- New Item Inbox with fixture items to confirm live scan persistence, Find & Rescue count updates, and the conditional status-menu New Items row on a real installed app.
- Notch/external display, Spaces, sleep/wake, and menu bar auto-hide combinations.

The manual QA matrix was updated with Phase 14 rows for Arrange, Placement Planner, Assisted Move, and New Item Inbox.

## Known Limitations

- Placement Planner provides pure recommendation logic and an Arrange-page preview list from available live scan status. Rows now include local new/favorite indicators, reviewed marks, suggested zone, and command hooks for highlight, Second Bar, owning app, group creation, and Assisted Move dry-run. A larger dedicated planner surface remains future work.
- New Item Inbox currently has privacy-safe model/store/test coverage, automatic runtime scan persistence, Find & Rescue count plumbing, a dedicated review list with generic labels and dismiss/reset controls, and a conditional status-menu New Items row behind Pro Discovery gates. Richer per-item placement actions remain deferred to Placement Planner work.
- Assisted Move has shared gates, command vocabulary, and a dedicated Arrange subflow with item/target selection, dry-run, first-use and per-move confirmations, confirmed execution through the existing moving service, result display, and recovery actions. Physical/manual validation on disposable third-party menu bar items remains required.
- Earlier full UI automation was blocked by runner bootstrap/launch instability when an installed app with the same bundle identity was already running. Focused UI automation passed after terminating the installed app, local test scripts now guard against that condition, and the latest `scripts/qa_preflight.sh` run passed the full automated suite.

## Deferred Work

- A larger dedicated Placement Planner surface with filtering/sorting across all scanned items.
- Rich New Item Inbox per-item placement actions beyond the current generic review list.
- Further automation/import-export/spacing copy diet inside the detailed Advanced pages.
