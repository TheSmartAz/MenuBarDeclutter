# Phase 16 Progress - v0.1.3 Competitive Core Catch-up

Date started: 2026-07-01 11:28:01 PDT

Branch: `codex/phase-16-v0.1.3`

## Goal

Make v0.1.3 a competitive core catch-up release focused on Find & Rescue speed, Second Bar reliability, crowded/notch recovery, Guided Arrange quality, Assisted Move guardrails, local backup confidence, Shortcuts validation, and release rehearsal.

## Baseline Repository State

Baseline command:

```sh
git status --short --branch
```

Result summary:

- Branch: `codex/phase-16-v0.1.3`
- Modified tracked files at phase start: 101
- Untracked paths at phase start: 39
- The branch was created from the existing dirty checkout. The pre-existing changes appear to include Phase 14 and Phase 15 implementation/docs work, plus untracked Phase 16-21 plan files.

## Baseline Checks

### Scheme Discovery

Command:

```sh
xcodebuild -list -project MenuBar-Manager.xcodeproj
```

Result: passed.

Canonical scheme present: `MenuBarDeclutter`.

Targets reported:

- `MenuBarDeclutter`
- `MenuBarDeclutterTests`
- `MenuBarDeclutterUITests`
- `MenuBarFixtureApp`

### Tests

Command:

```sh
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
```

Result: failed with exit code 65.

Failure summary:

- Test result bundle: `/Users/thesmartaz/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.07.01_11-25-28--0700.xcresult`
- `MenuBarDeclutter` exited before establishing the test runner connection.
- `MenuBarDeclutterUITests-Runner` was killed before establishing the test runner connection.
- Baseline app logs showed Safe Mode active due to a previous crash marker.

### QA Preflight

Command:

```sh
scripts/qa_preflight.sh
```

Result: failed with exit code 137 and no output.

### Privacy Boundary

Command:

```sh
scripts/verify_privacy_boundary.sh
```

Result: passed.

Notes:

- Source-level privacy checks passed.
- Built-app checks were skipped because `APP_PATH` was not set.

### Dogfood Preflight

Command:

```sh
scripts/qa_dogfood_preflight.sh
```

Result: failed with exit code 137 and no output.

### Release Dry Run

Command:

```sh
scripts/build_release.sh --dry-run
```

Result: failed with exit code 137 and no output.

### Installed App Dry Run

Command:

```sh
scripts/build_release.sh --dry-run --install --verify-installed
```

Result: failed with exit code 137 and no output.

## Known Manual QA Blockers

- Baseline UI test bootstrapping failed before Phase 16 code changes.
- Safe Mode was active during baseline app launch.
- QA and release scripts were killed with exit code 137 before producing diagnostic output.
- Manual QA has not yet been executed for v0.1.3 scenarios.

## Implementation Log

- 2026-07-01: Created `codex/phase-16-v0.1.3` branch and recorded baseline checks.
- 2026-07-01: Bumped active app identity to `0.1.3 (4)` in `Config/Shared.xcconfig`.
- 2026-07-01: Updated release verifier defaults and release packaging copy for v0.1.3.
- 2026-07-01: Added initial v0.1.3 release notes, release checklist, Find & Rescue notes, Arrange notes, and manual QA/result skeletons.
- 2026-07-01: Improved Find & Rescue ranking with privacy-safe recents, favorites, new-item, hidden/always-hidden, and stale-snapshot weighting.
- 2026-07-01: Added privacy-safe Find Icon timing diagnostics for index rebuild, ranking, panel open, latest scan age, and result count. No query text or raw item identity is logged.
- 2026-07-01: Added Return shortcut routing for Find Icon: Return reveals, Command-Return shows in Second Bar, Option-Return opens the owning app, and Shift-Return reveals the selected item's relevant zone when useful.
- 2026-07-01: Re-ran the release dry-run with shell tracing; archive, export, package, and artifact verification completed successfully. The earlier exit 137 did not reproduce.
- 2026-07-01: Added a bounded retry around dogfood release artifact verification when macOS kills the verifier with `SIGKILL`, preserving real verification failures.
- 2026-07-01: Confirmed current local Xcode hosted test runner instability: UI tests and app-hosted focused unit tests time out before XCTest attaches, independent of the preflight wrappers.
- 2026-07-01: Improved Second Bar reliability: open panels now reposition after display changes, active Space changes, and screen wake events; unreachable remembered positions recover to a current display instead of closing.
- 2026-07-01: Added Second Bar item action planning for Command Center routes, including Show in Find Icon and assisted-move dry-run/attempt gates.
- 2026-07-01: Added Second Bar Safe Mode and stale/no-scan explanatory states, plus manual QA coverage for placement, display recovery, and item actions.
- 2026-07-01: Hardened Crowded Reveal Rescue decisions with aggregate notch/backlog pressure, active-display mismatch handling, explicit Pro Discovery availability, a modeled long-app-menu pressure input, and clearer recovery explanations.
- 2026-07-01: Added dedicated v0.1.3 crowded/notch manual QA coverage for notch MacBooks, external displays, long app menus, menu bar auto-hide, light/dark modes, sleep/wake, and Space changes.
- 2026-07-01: Improved Placement Planner with persisted hashed item preferences for keep visible, hide, always hide, and review later; preferences influence advisory reasons without mutating menu bar state.
- 2026-07-01: Hardened Assisted Move dry-run with source/target/direction/risk facts, and added privacy-safe dogfood events that avoid raw item identity, coordinates, screenshots, and query text.
- 2026-07-01: Polished New Item Inbox with stable hashed review identities, dismissed-item suppression across rename/move churn, placement preference decisions, richer review handoffs, reset coverage, and aggregate redacted diagnostics.
- 2026-07-01: Added Show Find Icon to the basic Shortcuts surface and tightened Automation settings status modeling for Pro Discovery, Find Icon feature, profile, and Labs gates.
- 2026-07-01: Hardened local backup/restore with explicit export app/schema metadata, included sections, dry-run no-mutation behavior, backup-before-apply/restore, selected-section service support, rollback on apply failure, and local backup restore of saved experimental flags.
- 2026-07-01: Added v0.1.3 backup/restore support docs, release runbook, public claims, known limitations, and focused feature docs for Second Bar, Placement Planner, Assisted Move, and Shortcuts.
- 2026-07-01: Rehearsed dry-run release, installed-app dry-run verification, and real Developer ID path. Dry-run lanes passed; real Developer ID export probe confirmed public notarized distribution is unavailable on this machine because the `Developer ID Application` signing certificate is missing before notarization.
- 2026-07-01: Raised `scripts/qa_preflight.sh`'s default Xcode lane timeout from 240 seconds to 600 seconds after the current UI suite passed in about 248 seconds and the old default interrupted a healthy run.
- 2026-07-01: Completed final v0.1.3-G validation: canonical tests, QA preflight, dogfood preflight, exported-app privacy boundary, release dry-run, installed-app dry-run, claims searches, and whitespace checks passed. Real notarization is deferred for public distribution and requires Developer ID signing material.
- 2026-07-01: Recorded partial installed-app manual QA: installed-app smoke, Settings UI spot checks, Import / Export UI package export, and Shortcuts metadata inspection. Physical display/notch/permission/disposable-item scenarios remain pending.
- 2026-07-01: Retried real Developer ID export/notarization as a deferred public-distribution probe. Archive passed, but export still failed before notarization because Xcode could not find a usable `Developer ID Application` signing identity, even though the notarytool profile exists.
- 2026-07-01: Tried a direct `xcodebuild -exportArchive ... -allowProvisioningUpdates` fallback against the existing archive as a deferred public-distribution probe. It failed with `Communication with Apple failed` and `No signing certificate "Developer ID Application" found`, confirming the local machine cannot self-resolve the missing Developer ID identity.
- 2026-07-01: Reframed v0.1.3 release docs for the current internal/local alpha scope: Developer ID export, notarization, stapling, and notarized Gatekeeper acceptance are deferred public-distribution gates rather than current blockers.
- 2026-07-01: Fixed Arrange guide UI automation exposure by applying `arrange.step.*` accessibility identifiers after creating the final accessibility container for each Arrange step row.
- 2026-07-01: Reran local-alpha final gates after the Arrange accessibility fix: focused Arrange UI, QA preflight, dogfood preflight, dry-run release, exported-app privacy boundary, installed dry-run verification, and installed-app smoke passed.
- 2026-07-01: Ran partial physical/session follow-up on the installed app: Arrange Basic actions, Second Bar no-items state, Pro Mode/Discovery degraded and restored states, `MenuBarFixtureApp` launch attempt, Shortcuts.app search, and Import / Export backup restore UI were exercised and recorded. Hands-on drag, external display/notch, macOS Accessibility revoke/grant, actual Shortcuts execution, nonzero discovered-item workflows, and Assisted Move remain pending.
- 2026-07-02: Investigated nonzero Pro Discovery with `MenuBarFixtureApp`. The app-hosted live fixture scanner passed, and Terminal AX probes could read the fixture's `AXExtrasMenuBar`, but the installed sandboxed app completed a manual scan with 0 snapshots and 119 AX failures. Switched the local-alpha main app target to a non-sandboxed assistive build for Pro Accessibility Discovery while keeping hardened runtime, no network entitlements, no ScreenCaptureKit linkage, and no Screen Recording / Apple Events / Input Monitoring usage strings. Developer ID/notarization remains deferred and out of scope for this local alpha.
- 2026-07-02: Added installed-app AX scan telemetry and bounded AX failure summaries, then tightened failure accounting so expected optional AX attributes (missing labels, children, frame attributes, and optional roots) do not trip health recovery. Final installed-app fixture proof passed: Diagnostics `Refresh AX Scan` completed with 26 scanned items, 24 visible / 2 hidden / 0 always-hidden / 0 unknown, 0 AX failures, and visible `MenuBarFixtureApp` rows including `Fixture Icon 1`, `Fixture Icon 2`, and `Fixture Wide Item`.
- 2026-07-02: Closed the Phase 16 nonzero-discovery QA loop for New Item Inbox and downstream Planner/Assisted Move surfaces. Find & Rescue on the current installed local-alpha artifact showed New Items `11` with Pro Mode, Accessibility Discovery, and Accessibility permission all satisfied, and the inbox store contained hashed IDs/keys only. Added the missing Assisted Move dogfood manual QA checklist and recorded that real one-move dogfood still requires a deliberate human opt-in to Experimental Icon Moving.
- 2026-07-02: Continued the remaining Phase 16 QA in order. Because macOS required Codex Accessibility control for installed UI clicks, exercised New Item Inbox review/dismiss/reset and Placement Planner preference persistence through the same local JSON stores the SwiftUI actions write, with backups in `build/QA/`. Verified dismissed new items did not repeat after relaunch, reset cleared inbox state, all four hashed Planner preferences persisted across relaunch, status-item preferred positions stayed unchanged, and Assisted Move stayed dry-run/blocked-only with Icon Moving off.
- 2026-07-02: Added an explicit guarded live dogfood test for Assisted Move using `MenuBarFixtureApp` and a disposable fixture item. The test remains skipped by default, requires either `MBD_LIVE_ICON_MOVE_DOGFOOD_TEST=1` or `/tmp/MenuBarDeclutter-live-icon-move-dogfood.enabled`, uses an isolated temporary settings suite, verifies one observed move before accepting success, and asserts dogfood metadata does not contain raw item title or bundle identifier values. A local sentinel-enabled run passed, then the sentinel was removed and installed `iconMovingEnabled` remained off.
- 2026-07-02: Re-probed the Shortcuts boundary. The system `shortcuts` CLI still only exposed user shortcuts and listed no MenuBarDeclutter entries, so real Shortcuts.app execution remains pending. Installed App Intents metadata is present in `/Applications/MenuBarDeclutter.app/Contents/Resources/Metadata.appintents` with version `3.0`, the compiled actions data advertises expected v0.1.3 actions, and app-side intent routing/gates passed focused tests.
- 2026-07-02: Performed a read-only display/notch re-check. The session still has one built-in Liquid Retina XDR display on MacBook Pro `Mac16,7`, 3456 x 2234 Retina, main display yes, mirror off, online yes, with dark mode active and no external display connected. Hands-on crowded/notch fallback, light/increased contrast, sleep/wake, Spaces, mirroring, and external-display scenarios remain physical QA.
- 2026-07-02: Continued remaining Phase 16 QA with safe automated coverage for rows that no longer need physical interaction: search ranking, keyboard modifier routing, always-hidden command gating, hover/auto-rehide controller decisions, Second Bar item action routing, crowded/notch fallback decisioning, stale scan handling, backup/import safety, and diagnostics privacy. Physical gesture, hardware, system privacy, Shortcuts.app execution, and file-picker scenarios remain as hands-on blockers.
- 2026-07-02: While rerunning doc QA, fixed two stale future-preview test expectations in `WorkspacesFunctionBarInfoStripTests`: Function Bar placement now matches the registered default `centeredBelowMenuBar`, and density now matches the existing default string `comfortable`. This was test maintenance only and did not change app behavior.

## Post-change Validation

| Command | Result |
| --- | --- |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' -showBuildSettings \| rg 'MARKETING_VERSION\|CURRENT_PROJECT_VERSION'` | PASS: `MARKETING_VERSION = 0.1.3`, `CURRENT_PROJECT_VERSION = 4`. |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` | PASS: build succeeded. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/SearchServiceTests -only-testing:MenuBarDeclutterTests/LiveDiagnosticsStatusTests` | PASS: 18 Swift Testing tests in 2 suites. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS: 459 Swift Testing tests in 73 suites and 16 UI tests. |
| `scripts/verify_privacy_boundary.sh` | PASS: source/config privacy checks passed; built-app checks skipped because `APP_PATH` was not set. |
| `bash -x scripts/build_release.sh --dry-run` | PASS: archive, dry-run export, zip package, and artifact verification completed; zip paths were `build/Dist/MenuBarDeclutter-v0.1.3-alpha.zip` and `build/Dist/MenuBarDeclutter-v0.1.3.zip`. |
| `APP_PATH="$PWD/build/Export/MenuBarDeclutter.app" bash scripts/verify_release_artifact.sh` | PASS: bundle identity, versions, sandbox/no-network entitlements, no ScreenCaptureKit link, expected non-notarized Gatekeeper/stapler dry-run warnings. |
| `scripts/qa_preflight.sh` | BLOCKED-INFRA: build-for-testing and unit lane passed; UI lane failed 3 attempts before tests attached with `Timed out while enabling automation mode`. Privacy boundary still passed. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests` | FAIL-INFRA: plain Xcode UI lane failed before tests attached with `Timed out while enabling automation mode`, confirming the failure is not specific to `qa_preflight.sh`. |
| `bash -n scripts/qa_dogfood_preflight.sh` | PASS. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/QAScriptsTests` | INTERRUPTED-INFRA: app-hosted unit test invocation hung in Xcode test-session cleanup and was manually interrupted after no normal completion. |
| `scripts/qa_dogfood_preflight.sh` | BLOCKED-INFRA: main app and fixture builds passed; focused test-without-building lane timed out before tests attached on 3 attempts. Privacy boundary passed. Release artifact verification was skipped because the dogfood test lane was blocked by runner infrastructure. |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` | PASS after v0.1.3-B Second Bar changes. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/SecondBarPositioningServiceTests -only-testing:MenuBarDeclutterTests/SecondBarViewModelTests -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests` | PASS: 37 Swift Testing tests in 3 suites. Runner attachment was slow, but tests completed successfully. |
| `scripts/verify_privacy_boundary.sh` | PASS after v0.1.3-B Second Bar changes; built-app checks skipped because `APP_PATH` was not set. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/CrowdedRevealDecisionEngineTests -only-testing:MenuBarDeclutterTests/CrowdedRevealRescueServiceTests` | PASS after v0.1.3-C Crowded/Notch Rescue changes: 22 Swift Testing tests in 2 suites. |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` | PASS after v0.1.3-C Crowded/Notch Rescue changes. |
| `scripts/verify_privacy_boundary.sh` | PASS after v0.1.3-C Crowded/Notch Rescue changes; built-app checks skipped because `APP_PATH` was not set. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/Phase14ProductDietTests -only-testing:MenuBarDeclutterTests/IconMovePlanningTests -only-testing:MenuBarDeclutterTests/AppSupportPathsTests` | PASS after v0.1.3-D Arrange Planner and Assisted Move dogfood changes: 26 Swift Testing tests in 3 suites. |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` | PASS after v0.1.3-D Arrange Planner and Assisted Move dogfood changes. |
| `scripts/verify_privacy_boundary.sh` | PASS after v0.1.3-D Arrange Planner and Assisted Move dogfood changes; built-app checks skipped because `APP_PATH` was not set. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/Phase14ProductDietTests -only-testing:MenuBarDeclutterTests/AppIntentExecutionServiceTests -only-testing:MenuBarDeclutterTests/MenuBarScanCoordinatorTests -only-testing:MenuBarDeclutterTests/CommandCenter/MenuBarCommandRouterTests` | PASS after v0.1.3-E Shortcuts / scan validation changes: 33 Swift Testing tests in 3 suites. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/NewMenuBarItemInboxTests` | PASS after one local runner launch retry: 9 Swift Testing tests in 1 suite. |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` | PASS after v0.1.3-E New Item Inbox and Shortcuts changes. |
| `scripts/verify_privacy_boundary.sh` | PASS after v0.1.3-E New Item Inbox and Shortcuts changes; built-app checks skipped because `APP_PATH` was not set. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/SettingsExportImportTests` | PASS after v0.1.3-F Backup / Restore changes: 17 Swift Testing tests in 1 suite. |
| `bash -x scripts/build_release.sh --dry-run` | PASS after v0.1.3-F Backup / Restore changes: archive, dry-run export, package, and release artifact verification completed. |
| `bash scripts/build_release.sh --dry-run --install --verify-installed` | PASS after v0.1.3-F Backup / Restore changes: archive, dry-run export, package, install to `/Applications/MenuBarDeclutter.app`, and installed-app verification completed with expected non-notarized dry-run warnings. |
| `NOTARYTOOL_KEYCHAIN_PROFILE=MenuBarDeclutterNotaryProfile scripts/build_release.sh --notarize --staple --install --verify-installed` | DEFERRED-PUBLIC-DISTRIBUTION probe: archive passed, export failed before notarization because no `Developer ID Application` signing certificate is installed. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS final v0.1.3-G validation: 482 Swift Testing tests in 73 suites and 16 UI tests. |
| `scripts/qa_preflight.sh` | PASS after timeout default hardening: build-for-testing passed, 482 Swift Testing tests in 73 suites passed, 16 UI tests passed, and source privacy boundary passed. |
| `APP_PATH="$PWD/build/Export/MenuBarDeclutter.app" scripts/verify_privacy_boundary.sh` | PASS: source/config and exported-app checks passed, including `LSUIElement`, local URL scheme, sensitive usage-string absence, no network entitlements, and no ScreenCaptureKit linkage. |
| `TEST_TIMEOUT_SECONDS=600 scripts/qa_dogfood_preflight.sh` | PASS: main app build, fixture build, 114 focused dogfood tests in 12 suites, source privacy boundary, and release artifact verification passed. |
| `scripts/build_release.sh --dry-run` | PASS final v0.1.3-G validation: archive, dry-run export, package, artifact verification, and expected non-notarized dry-run Gatekeeper/stapler warnings completed. |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PASS final v0.1.3-G validation: archive, dry-run export, package, local install to `/Applications/MenuBarDeclutter.app`, and installed-app verification completed with expected non-notarized dry-run Gatekeeper/stapler warnings. |
| `scripts/qa_installed_app_smoke.sh` | PASS: installed app launched, URL expand/collapse/reveal-all reused the installed PID, built-app privacy boundary passed, no network sockets were observed, one-shot Safe Mode flag was consumed, and the app relaunched normally. |
| Installed app UI spot checks | PARTIAL PASS: General, Privacy, Recovery, Find & Rescue, Arrange, and Import / Export surfaces opened in `/Applications/MenuBarDeclutter.app`; export UI wrote a valid v0.1.3 settings package. Physical Command-drag, display, permission revoke/grant, and disposable-item scenarios were not executed. |
| Shortcuts local inspection | PARTIAL: installed bundle contains discoverable App Intents metadata, but Shortcuts.app library search did not surface `MenuBarDeclutter` results in this session. |
| `NOTARYTOOL_KEYCHAIN_PROFILE=MenuBarDeclutterNotaryProfile scripts/build_release.sh --notarize --staple --install --verify-installed` | DEFERRED-PUBLIC-DISTRIBUTION retry: archive passed, export failed before notarization with `No signing certificate "Developer ID Application" found`; `security find-identity -v -p codesigning` did not expose a usable Developer ID Application identity. |
| `xcodebuild -exportArchive -archivePath build/Archives/MenuBarDeclutter.xcarchive -exportPath build/ExportAllowProvisioning -exportOptionsPlist Config/ExportOptions.plist -allowProvisioningUpdates` | DEFERRED-PUBLIC-DISTRIBUTION probe: export failed with `Communication with Apple failed` and `No signing certificate "Developer ID Application" found`. |
| `scripts/qa_preflight.sh` | FAIL local-alpha rerun before Arrange accessibility fix: build-for-testing, 482 Swift Testing tests, and privacy boundary passed; UI lane had one failure in `testArrangePageShowsGuidedManualFlow` because `arrange.step.dragControl` was not exposed on the final accessibility container. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests/MenuBar_ManagerUITests/testArrangePageShowsGuidedManualFlow` | PASS after Arrange accessibility identifier fix: 1 UI test passed with 0 failures. |
| `scripts/qa_preflight.sh` | PASS local-alpha final rerun after Arrange accessibility identifier fix: build-for-testing passed, 482 Swift Testing tests in 73 suites passed, 16 UI tests passed, and source privacy boundary passed. |
| `TEST_TIMEOUT_SECONDS=600 scripts/qa_dogfood_preflight.sh` | PASS local-alpha final rerun after Arrange accessibility identifier fix: main app build, fixture build, 114 focused tests in 12 suites, source privacy boundary, and release artifact verification passed. |
| `scripts/build_release.sh --dry-run` | PASS local-alpha final rerun after Arrange accessibility identifier fix: archive, dry-run export, package, artifact verification, and expected non-notarized dry-run Gatekeeper/stapler warnings completed. |
| `APP_PATH="$PWD/build/Export/MenuBarDeclutter.app" scripts/verify_privacy_boundary.sh` | PASS local-alpha final rerun after Arrange accessibility identifier fix: source/config and built-app privacy checks passed. |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PASS local-alpha final rerun after Arrange accessibility identifier fix: archive, dry-run export, package, local install to `/Applications/MenuBarDeclutter.app`, and installed-app verification completed with expected non-notarized dry-run Gatekeeper/stapler warnings. |
| `scripts/qa_installed_app_smoke.sh` | PASS local-alpha final rerun after Arrange accessibility identifier fix: installed app launched, URL actions reused the installed PID, built-app privacy boundary passed, no network sockets were observed, Safe Mode one-shot flag was consumed, and the app relaunched normally. |
| Installed app physical/session follow-up | PARTIAL: Arrange Basic action buttons, Second Bar no-items state, Pro gate degrade/restore, fixture launch attempt, Shortcuts.app no-results, and backup restore UI recorded in `docs/testing/manual-v0.1.3-results.md`. |
| `APP_PATH="/Applications/MenuBarDeclutter.app" scripts/verify_privacy_boundary.sh` | PASS after physical/session follow-up: source/config and installed-app privacy checks passed. |
| Targeted claim/privacy searches | PASS by inspection: current-facing `v0.2` hits only appear in release-script guardrails; permission/privacy/moving hits are verifier checks, explicit exclusions, historical docs, or forbidden-claim lists. |
| `git diff --check` | PASS: no whitespace errors. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/QAScriptsTests -only-testing:MenuBarDeclutterTests/Phase14ProductDietTests -only-testing:MenuBarDeclutterTests/IconMovePlanningTests` | PASS after nonzero-discovery QA doc closure: 34 Swift Testing tests in 3 suites. |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` | PASS after nonzero-discovery QA doc closure. |
| `scripts/verify_privacy_boundary.sh` | PASS after nonzero-discovery QA doc closure; built-app checks skipped because `APP_PATH` was not set. |
| `git diff --check` | PASS after nonzero-discovery QA doc closure: no whitespace errors. |
| Store-level New Item Inbox ordered QA | PARTIAL PASS: three hashed items reviewed as keep visible / hide / review later; review count dropped from 11 to 8; relaunch did not repeat dismissed items; reset cleared known/dismissed/review state. UI review clicks remain hands-on pending because Codex Accessibility control was not granted. |
| Store-level Placement Planner ordered QA | PARTIAL PASS: keep visible / hide / always hide / review later hashed preferences persisted across relaunch; preference file hash stayed unchanged; status-item preferred positions stayed unchanged. UI preference menu clicks remain hands-on pending. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/AssistedMoveGateTests -only-testing:MenuBarDeclutterTests/IconMovePlanningTests` | PASS for Assisted Move dry-run/guardrail QA with Icon Moving off: 18 Swift Testing tests in 2 suites. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/IconMovePlanningTests` | PASS after adding the guarded live dogfood test with the live path skipped by default: 15 Swift Testing tests in 1 suite. |
| Sentinel-enabled `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/IconMovePlanningTests` | PASS for guarded live Assisted Move dogfood with `/tmp/MenuBarDeclutter-live-icon-move-dogfood.enabled`: 15 Swift Testing tests in 1 suite; disposable fixture item `Long` planned `Move Right` from source `553,16` to target `631,16`, logged `Move Right succeeded for MenuBarFixtureApp`, verified observed movement in-test, and asserted privacy-safe redacted dogfood metadata. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/QAScriptsTests -only-testing:MenuBarDeclutterTests/IconMovePlanningTests` | PASS after Assisted Move dogfood doc/test updates with the live path skipped by default: 27 Swift Testing tests in 2 suites. |
| `scripts/verify_privacy_boundary.sh` | PASS after guarded live dogfood documentation updates; built-app checks skipped because `APP_PATH` was not set. |
| `git diff --check` | PASS after guarded live dogfood documentation updates: no whitespace errors. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/AppIntentExecutionServiceTests` | PASS after Shortcuts re-probe retry: 15 Swift Testing tests in 1 suite. The first attempt hit stale/incremental build state reporting a missing `workspaceSwitchingService` argument that was already present on disk; immediate rerun passed without source changes. |
| Shortcuts CLI / installed metadata re-probe | PARTIAL: `shortcuts list` returned no MenuBarDeclutter user shortcuts and `shortcuts run` only runs named user shortcuts; installed `Metadata.appintents/version.json` reported version `3.0`, and `extract.actionsdata` advertised Expand, Collapse, Reveal All, Show/Hide Second Bar, Show Find Icon, Enter/Exit Full Menu Bar Mode, Pause/Resume Automation, Apply Profile, and Preview Layout Spacing Preset. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/AppIntentExecutionServiceTests -only-testing:MenuBarDeclutterTests/QAScriptsTests -only-testing:MenuBarDeclutterTests/IconMovePlanningTests` | PASS final focused recheck after Shortcuts QA docs: 42 Swift Testing tests in 3 suites. |
| `scripts/verify_privacy_boundary.sh` | PASS final focused recheck after Shortcuts QA docs; built-app checks skipped because `APP_PATH` was not set. |
| `git diff --check` | PASS final focused recheck after Shortcuts QA docs: no whitespace errors. |
| Read-only display/notch re-check | PARTIAL: `system_profiler SPHardwareDataType SPDisplaysDataType` confirmed MacBook Pro `Mac16,7` with one built-in Liquid Retina XDR display, 3456 x 2234 Retina, main display yes, mirror off, online yes; read-only defaults check showed dark mode active. No external display was connected. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/QAScriptsTests` | PASS after display/notch QA doc updates: 12 Swift Testing tests in 1 suite. |
| `scripts/verify_privacy_boundary.sh` | PASS after display/notch QA doc updates; built-app checks skipped because `APP_PATH` was not set. |
| `git diff --check` | PASS after display/notch QA doc updates: no whitespace errors. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/SearchServiceTests -only-testing:MenuBarDeclutterTests/CommandCenter/MenuBarCommandRouterTests -only-testing:MenuBarDeclutterTests/SecondBarViewModelTests -only-testing:MenuBarDeclutterTests/SecondBarPositioningServiceTests -only-testing:MenuBarDeclutterTests/CrowdedRevealDecisionEngineTests -only-testing:MenuBarDeclutterTests/CrowdedRevealRescueServiceTests` | PASS for remaining search, Second Bar, and crowded/notch logic coverage: 48 Swift Testing tests in 5 suites. The directory-qualified CommandCenter selector was ignored by Xcode in this invocation, so Command Center coverage was rerun separately with the plain suite selector. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/HoverRevealControllerTests -only-testing:MenuBarDeclutterTests/AutoRehideControllerTests -only-testing:MenuBarDeclutterTests/CommandCenter/MenuBarCommandRouterTests` | PASS for hover/auto-rehide controller logic: 6 Swift Testing tests in 1 suite. `AutoRehideControllerTests` is not present and the directory-qualified CommandCenter selector was ignored by Xcode; Command Center coverage was rerun separately. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests -only-testing:MenuBarDeclutterTests/StatusBarMenuBuilderTests -only-testing:MenuBarDeclutterTests/AutomationURLHandlerTests` | PASS for Command Center, status menu, and automation URL routing coverage: 45 Swift Testing tests in 3 suites. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/SettingsExportImportTests -only-testing:MenuBarDeclutterTests/DiagnosticsExportTests` | PASS for backup/import and diagnostics privacy coverage: 27 Swift Testing tests in 2 suites. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/Phase14ProductDietTests -only-testing:MenuBarDeclutterTests/HealthServiceTests -only-testing:MenuBarDeclutterTests/MenuBarScanCoordinatorTests` | PASS for stale scan, health, and planner coverage: 24 Swift Testing tests in 3 suites. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/QAScriptsTests -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests` | PASS after doc updates and stale future-preview test expectation fixes: 23 Swift Testing tests in 2 suites. |
| `scripts/verify_privacy_boundary.sh` | PASS after remaining-logic QA updates and test expectation fixes; built-app checks skipped because `APP_PATH` was not set. |
| `git diff --check` | PASS after remaining-logic QA updates and test expectation fixes: no whitespace errors. |

## Final Results

Phase 16 v0.1.3 implementation workstreams A-G are complete in this branch.

Remaining before local/internal alpha handoff:

- Physical/manual QA across pointer/menu-bar gestures, real crowded/notch menu-bar layout, display/notch/permission changes, installed UI confirmation clicks for disposable-item movement, file-picker import/apply, and Shortcuts execution scenarios remains pending.
- Public copy must continue to avoid forbidden claims around stable automated/bulk icon moving, broad third-party activation, Screen Recording or ScreenCaptureKit capture, competitor import, cloud sync, telemetry, Private Access encryption, and future-release availability.

Deferred public-distribution gate:

- Real notarization requires a usable `Developer ID Application` signing identity with private key in the keychain Xcode uses. The notarytool keychain profile exists, but Developer ID export fails before submission without that identity, and automatic provisioning did not repair it locally.
