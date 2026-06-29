# Phase 13 v0.1.1 Pro Workflow Completion Progress

Date started: 2026-06-29
Last updated: 2026-06-29

## Summary

Phase 13 implementation is underway on the `v0.1.1` release line. This phase is not `v0.2`.

Branch context:

- Branch: `codex/phase-13-v0.1.1-command-center`
- Starting point: Phase 12 release-confidence branch commit `8dde17e`.
- Reason for stacked branch: Phase 13 depends on the Phase 12 release-state, trust, and feature-gate cleanup that is already open in PR #2.

Initial scope:

- Build a shared command model and command router for Pro workflows.
- Keep Basic Mode permission-free.
- Keep Pro Mode, Accessibility discovery, Private Access, Labs, and automation actions explicitly gated.
- Route Find Icon, Second Bar/Icon Panel, Groups, Dynamic Hotkeys, Profiles, App Intents, and URL automation through one predictable command/result model over the course of the phase.

Completed in this pass:

- Added the `CommandCenter/` source area with a shared command target/action/source vocabulary.
- Added structured command availability, gate, result, and diagnostics models.
- Added a closure-backed `MenuBarCommandRouter` that evaluates Safe Mode, App Intents, automation pause, Pro Mode, Accessibility Discovery, Accessibility permission, feature settings, Labs, Private Access lock status, experimental confirmation, and target compatibility.
- Kept command diagnostics privacy-safe by logging action/source/target kind/status/reason only, not profile names, item IDs, protected labels, or spacing preset values.
- Routed `AppIntentExecutionService` through the shared command router.
- Kept Spacing Labs apply honest by returning a dry-run-only result instead of claiming mutation through App Intents.
- Added focused Command Center unit tests for successful execution, Safe Mode, Pro and Accessibility gates, automation pause, Labs dry-run-only behavior, Private Access lock status, and diagnostic redaction.
- Migrated local `menubardeclutter://` URL automation to construct `MenuBarCommand` values and let the shared router enforce automation pause, profile automation opt-in, Pro gates, Labs gates, and profile availability.
- Migrated Dynamic Hotkey execution to route `HotkeyAction` values through the shared command router and record structured command failures instead of relying on boolean executor closures.
- Added router handlers for item reveal, item-in-Second-Bar, group panel, profile apply, and profile dry-run targets.
- Expanded focused tests for URL automation and Dynamic Hotkeys to cover shared Pro gates, automation pause, unavailable profile targets, and routed hotkey execution.
- Added a privacy-safe command availability summary model for user-facing Settings explanations.
- Added Command Center availability rows to Search, Second Bar/Icon Panel, Groups, and Profiles Settings surfaces, all backed by the shared router without executing commands.
- Added summary redaction coverage so profile target values do not leak through UI-facing command availability text.

Not in scope for the first slice:

- No `v0.2` naming.
- No ScreenCaptureKit or Screen Recording.
- No Apple Events or Input Monitoring.
- No network telemetry, cloud sync, analytics, crash upload, or remote config.
- No stable claim for Icon Moving.
- No Spacing Labs apply/restore/reset exposure unless backup and restore semantics are made reliable and tested.

## Baseline Results

These commands were run before Phase 13 implementation changes.

| Command | Result | Notes |
| --- | --- | --- |
| `git status --short` | PASS | Clean worktree before baseline checks. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | 321 Swift Testing tests in 60 suites passed; 7 UI tests passed. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_11-38-36--0700.xcresult`. |
| `scripts/qa_preflight.sh` | PASS | Full preflight passed, including 321 Swift Testing tests, 7 UI tests, and source privacy boundary verification. Result bundle: `build/TestResults/qa-preflight.xcresult`. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed; built-app checks skipped because `APP_PATH` was not set. |
| `scripts/qa_dogfood_preflight.sh` | PASS | Main app build, 47 targeted dogfood/privacy tests, source privacy boundary, and fixture cleanup passed. Release artifact verification skipped because `build/Release/MenuBarDeclutter.app` is not present. |

## Planned Workstreams

Current execution order:

1. 13A - Command Center Core
2. 13B - Find Icon plus Second Bar / Icon Panel
3. 13C - Crowded Rescue plus Groups
4. 13D - Private Access plus Dynamic Hotkeys
5. 13E - Profiles plus App Intents / URL Automation
6. 13F - Import/Export plus Spacing Labs decision
7. 13G - Docs, tests, privacy verification, and release validation

## Changed Files

Current Phase 13 changes:

- `MenuBar-Manager/App/AppEnvironment.swift`
- `MenuBar-Manager/CommandCenter/MenuBarCommand.swift`
- `MenuBar-Manager/CommandCenter/MenuBarCommandAvailability.swift`
- `MenuBar-Manager/CommandCenter/MenuBarCommandDiagnostics.swift`
- `MenuBar-Manager/CommandCenter/MenuBarCommandResult.swift`
- `MenuBar-Manager/CommandCenter/MenuBarCommandRouter.swift`
- `MenuBar-Manager/CommandCenter/MenuBarCommandTarget.swift`
- `MenuBar-Manager/Groups/IconGroupsSettingsView.swift`
- `MenuBar-Manager/Hotkeys/DynamicHotkeyRegistrationService.swift`
- `MenuBar-Manager/Profiles/ProfileListView.swift`
- `MenuBar-Manager/Profiles/AutomationURLHandler.swift`
- `MenuBar-Manager/Profiles/ProfileAutomationCoordinator.swift`
- `MenuBar-Manager/Settings/SearchSettingsView.swift`
- `MenuBar-Manager/Settings/SecondBarSettingsView.swift`
- `MenuBar-Manager/Settings/SettingsActions.swift`
- `MenuBar-Manager/Settings/SettingsRootView.swift`
- `MenuBar-Manager/Shortcuts/AppIntentExecutionService.swift`
- `MenuBar-Manager/Shortcuts/AppIntentResultMapper.swift`
- `MenuBar-ManagerTests/AutomationURLHandlerTests.swift`
- `MenuBar-ManagerTests/AppIntentExecutionServiceTests.swift`
- `MenuBar-ManagerTests/CommandCenter/MenuBarCommandRouterTests.swift`
- `MenuBar-ManagerTests/DynamicHotkeyRegistrationServiceTests.swift`
- `docs/progress/phase-13-v0.1.1-pro-workflow-completion.md`
- `docs/project-summary.md`

## Validation Results

| Command | Result | Notes |
| --- | --- | --- |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests -only-testing:MenuBarDeclutterTests/AppIntentExecutionServiceTests` | PASS | 19 focused tests in 2 suites passed after fixing the router's Private Access checker ownership. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Full run passed with 330 Swift Testing tests in 61 suites and 7 UI tests. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_11-46-53--0700.xcresult`. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed; built-app checks skipped because `APP_PATH` was not set. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/AutomationURLHandlerTests -only-testing:MenuBarDeclutterTests/DynamicHotkeyRegistrationServiceTests -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests -only-testing:MenuBarDeclutterTests/AppIntentExecutionServiceTests` | PASS | 30 focused tests in 4 suites passed after migrating URL automation and Dynamic Hotkeys through the command router. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_11-56-19--0700.xcresult`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Final full run passed with 332 Swift Testing tests in 61 suites and 7 UI tests after the coordinator API cleanup. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_11-59-33--0700.xcresult`. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed; built-app checks skipped because `APP_PATH` was not set. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests` | PASS | 9 focused Command Center tests passed, including UI-facing availability summary redaction. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_12-05-47--0700.xcresult`. |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` | PASS | Build passed after adding Settings availability rows and tightening the Groups action button layout. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Full run passed with 333 Swift Testing tests in 61 suites and 7 UI tests. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_12-14-11--0700.xcresult`. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed after adding Settings command availability explanations; built-app checks skipped because `APP_PATH` was not set. |

## Manual QA Notes

Codex Computer Use manual QA was performed against the freshly built DerivedData app launched with `--ui-testing --ui-testing-show-settings`, keeping the run isolated from the user's real defaults and Application Support data.

Observed Settings behavior:

- Search shows `Command Center: Find Icon`, `Pro Required`, and the Pro Mode gate explanation without clipped text.
- Second Bar shows separate `Command Center: Second Bar` and `Command Center: Icon Panel` rows, both with Pro gate explanations and readable wrapping.
- Groups was checked by creating a disposable UI-testing group; the selected detail showed `Command Center: Group Panel`, `Available`, and `Available.`, and the Edit/Export/Delete controls fit after the small control-size tweak.
- Profiles was checked by creating a disposable UI-testing profile; the editor showed `Command Center: Apply Profile`, `Available`, and `Available.` without exposing the profile target value.

No Accessibility, Screen Recording, Apple Events, Input Monitoring, network, screenshot, or pixel-capture permission prompt was triggered by these Settings checks.

Phase 13 manual QA will be needed for:

- Live Find Icon and Second Bar degraded states.
- Command routing explanations in remaining status menu and protected-action surfaces.
- Protected Private Access actions.
- Dynamic hotkey execution and conflict recovery.
- App Intents in Shortcuts.
- Local `menubardeclutter://` automation URLs.
- Crowded reveal fallback behavior against a real crowded menu bar.

## Known Limitations

- The shared command router is implemented; App Intent execution, URL automation, and Dynamic Hotkey execution now route through it.
- Search, Second Bar/Icon Panel, Groups, and Profiles Settings now show user-facing command availability rows backed by the shared router.
- Some remaining advanced UI actions still use existing Phase 10/11 execution paths until their command execution surfaces are migrated end to end.
- Private Access is currently represented in the command router as a lock-status gate; UI-mediated unlock execution still needs to be wired for protected command paths.
- Import remains dry-run only from Phase 12.
- Spacing Labs remains guarded; apply/restore/reset must either become fully reliable and tested or stay safely deferred.
- Icon Moving remains Experimental and must stay explicitly gated.

## Remaining Deferred Work

- Refactor remaining advanced UI surfaces through the command router.
- Extend user-facing command availability/explanation rows to remaining status-menu and protected-action surfaces.
- Keep diagnostics privacy-safe by excluding live queries, selected item identities, protected names, protected target IDs, and full file paths unless explicitly chosen in a supported export flow.
