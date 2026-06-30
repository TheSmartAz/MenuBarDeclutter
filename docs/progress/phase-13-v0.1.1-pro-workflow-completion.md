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
- Routed Find Icon result activation and result context actions through `MenuBarCommandRouter` for reveal, highlight, show in Second Bar, and open owning app.
- Routed Second Bar row activation and item context actions through `MenuBarCommandRouter` for reveal, highlight, and open owning app.
- Added real command handlers for highlight item and open owning app so those item actions no longer return executor-pending results.
- Routed status-menu Find Icon, Second Bar show/hide/toggle, automation pause/resume, Full Menu Bar Mode, and Layout Suggestions actions through the shared Command Center hook.
- Preserved Basic Mode recovery controls by keeping expand/collapse/toggle direct, while routing protected always-hidden reveal through Private Access when that resource is locked.
- Routed optional group status item Open Group actions through Command Center instead of bypassing the shared gate/result model.
- Added Private Access Settings command availability rows for protected app actions without executing those actions.
- Tightened Command Center availability so always-hidden reveal reports disabled when the always-hidden separator feature is off.
- Redacted Private Access diagnostics to log protected resource kinds instead of protected group IDs or other target values.

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

## Resume Baseline Results

These commands were run before the next Phase 13 implementation pass on 2026-06-29.

| Command | Result | Notes |
| --- | --- | --- |
| `git status --short` | PASS | Clean worktree before this pass. |
| `xcodebuild -list` | PASS | Canonical `MenuBarDeclutter` scheme is present. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | 333 Swift Testing tests in 61 suites passed; 7 UI tests passed. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_12-20-38--0700.xcresult`. |
| `scripts/qa_preflight.sh` | PASS | Full preflight passed, including 333 Swift Testing tests, 7 UI tests, and source privacy boundary verification. Result bundle: `build/TestResults/qa-preflight.xcresult`. |
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
- `MenuBar-Manager/App/MenuBarItemSurfaceCoordinator.swift`
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
- `MenuBar-Manager/PrivateAccess/PrivateAccessCoordinator.swift`
- `MenuBar-Manager/PrivateAccess/PrivateAccessSettingsView.swift`
- `MenuBar-Manager/PrivateAccess/ProtectedResource.swift`
- `MenuBar-Manager/Search/MenuItemActivator.swift`
- `MenuBar-Manager/Search/SearchRootView.swift`
- `MenuBar-Manager/Search/SearchWindowController.swift`
- `MenuBar-Manager/SecondBar/SecondBarRootView.swift`
- `MenuBar-Manager/SecondBar/SecondBarWindowController.swift`
- `MenuBar-Manager/Settings/SearchSettingsView.swift`
- `MenuBar-Manager/Settings/SecondBarSettingsView.swift`
- `MenuBar-Manager/Settings/SettingsActions.swift`
- `MenuBar-Manager/Settings/SettingsRootView.swift`
- `MenuBar-Manager/Shortcuts/AppIntentExecutionService.swift`
- `MenuBar-Manager/Shortcuts/AppIntentResultMapper.swift`
- `MenuBar-Manager/StatusBar/StatusBarMenuBuilder.swift`
- `MenuBar-ManagerTests/AutomationURLHandlerTests.swift`
- `MenuBar-ManagerTests/AppIntentExecutionServiceTests.swift`
- `MenuBar-ManagerTests/CommandCenter/MenuBarCommandRouterTests.swift`
- `MenuBar-ManagerTests/DynamicHotkeyRegistrationServiceTests.swift`
- `MenuBar-ManagerTests/ProtectedActionGateTests.swift`
- `MenuBar-ManagerTests/StatusBarMenuBuilderTests.swift`
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
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests` | PASS | 11 focused Command Center tests passed after adding item highlight/open-owning-app routing coverage. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_12-26-30--0700.xcresult`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Full run passed with 338 Swift Testing tests in 61 suites and 7 UI tests after routing Find Icon and Second Bar item actions through Command Center. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_12-27-25--0700.xcresult`. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed; built-app checks skipped because `APP_PATH` was not set. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/StatusBarMenuBuilderTests -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests` | PASS | 16 focused tests in 2 suites passed after status-menu routing and item utility handler wiring. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_12-26-51--0700.xcresult`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | FAIL | Swift Testing passed with 338 tests in 61 suites, but `testSearchUnavailableStateIsVisibleWithoutProMode` did not find the `Enable Find Icon` button after the disabled-state text appeared. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_12-27-32--0700.xcresult`. |
| `pkill -x MenuBarDeclutter || true`; `open -n ~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Build/Products/Debug/MenuBarDeclutter.app --args --ui-testing --ui-testing-show-search` | PASS | Codex Computer Use inspected the Search panel accessibility tree and screenshot state; `Find Icon Disabled` and the `Enable Find Icon` button were both visible. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests/MenuBar_ManagerUITests/testSearchUnavailableStateIsVisibleWithoutProMode` | PASS | Isolated retry of the full-suite UI failure passed. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_12-29-47--0700.xcresult`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Fresh full rerun passed with 338 Swift Testing tests in 61 suites and 7 UI tests; the prior Search unavailable-state UI case passed inside the full run. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_12-32-24--0700.xcresult`. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed after status-menu routing and documentation updates; built-app checks skipped because `APP_PATH` was not set. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/ProtectedActionGateTests -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests` | PASS | 21 focused tests in 2 suites passed after adding Private Access Settings availability rows, always-hidden reveal availability gating, and protected-group diagnostic redaction. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_20-20-13--0700.xcresult`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | FAIL | Swift Testing passed with 341 tests in 61 suites, then `MenuBarDeclutterUITests-Runner` failed before UI test execution with `Timed out while enabling automation mode`. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_20-21-52--0700.xcresult`. |
| `pkill -x MenuBarDeclutter || true`; `pkill -x MenuBarDeclutterUITests-Runner || true`; `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | INTERRUPTED | Swift Testing passed with 341 tests in 61 suites, then the UI runner stayed at `Running tests...` without individual test-case output; interrupted manually. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_20-23-17--0700.xcresult`. |
| `pkill -x MenuBarDeclutter || true`; `pkill -x MenuBarDeclutterUITests-Runner || true`; `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests` | INTERRUPTED | UI-only retry stayed at `Running tests...` without individual test-case output; interrupted manually. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_20-26-29--0700.xcresult`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -skip-testing:MenuBarDeclutterUITests` | INTERRUPTED | Non-UI retry was cancelled after the command remained active too long for the current pass. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_20-30-58--0700.xcresult`. |
| `rg -n "v0\.2\|0\.2\.0" README.md docs MenuBar-Manager scripts Config` | Hits inspected | Hits are explicit v0.1.1 guardrails, refusal text, or plan/progress docs; no current UI or release artifact names this phase `v0.2`. |
| `rg -n "ScreenCaptureKit\|NSScreenCaptureUsageDescription\|NSAppleEventsUsageDescription\|URLSession\|NWConnection\|analytics\|telemetry\|Sentry\|Firebase" MenuBar-Manager Config scripts docs` | Hits inspected | Hits are privacy verification scripts, historical/guardrail docs, or dogfood/export exclusion text. No direct app target network API, analytics SDK, ScreenCaptureKit import, or sensitive usage string was introduced. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed after Private Access Settings availability rows and diagnostic redaction updates; built-app checks skipped because `APP_PATH` was not set. |
| `git diff --check` | PASS | No whitespace errors after Private Access docs updates. |

## Manual QA Notes

Codex Computer Use manual QA was performed against the freshly built DerivedData app launched with `--ui-testing --ui-testing-show-settings`, keeping the run isolated from the user's real defaults and Application Support data.

Observed Settings behavior:

- Search shows `Command Center: Find Icon`, `Pro Required`, and the Pro Mode gate explanation without clipped text.
- Second Bar shows separate `Command Center: Second Bar` and `Command Center: Icon Panel` rows, both with Pro gate explanations and readable wrapping.
- Groups was checked by creating a disposable UI-testing group; the selected detail showed `Command Center: Group Panel`, `Available`, and `Available.`, and the Edit/Export/Delete controls fit after the small control-size tweak.
- Profiles was checked by creating a disposable UI-testing profile; the editor showed `Command Center: Apply Profile`, `Available`, and `Available.` without exposing the profile target value.
- Search unavailable-state follow-up was checked with `--ui-testing-show-search`; Codex Computer Use found the `Find Icon Disabled` text and `Enable Find Icon` button in the accessibility tree and screenshot.
- Private Access Settings was checked with Codex Computer Use against the DerivedData app launched with `--ui-testing --ui-testing-show-settings`; the new `Command Center` section showed protected action rows, default Basic Mode gates such as `Pro Required` and `Labs Required`, and `Reveal Always-Hidden Zone` correctly reported `Unavailable` while the always-hidden separator was disabled.

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
- Find Icon and Second Bar item activation/actions now route through the shared command router for reveal/highlight/open/show-in-Second-Bar flows.
- Advanced status-menu actions now route through the shared command router where they need shared Pro, automation, Safe Mode, Labs, or Private Access outcomes.
- Basic status-menu expand/collapse/toggle paths intentionally remain direct so Safe Mode recovery stays available without Pro gating.
- Search, Second Bar/Icon Panel, Groups, and Profiles Settings now show user-facing command availability rows backed by the shared router.
- Private Access Settings now shows protected command availability rows backed by the shared router.
- Some remaining protected-action explanations and non-menu UI utility actions still use existing Phase 10/11 execution paths until their command execution surfaces are migrated end to end.
- Private Access is represented in the command router as a lock-status gate; status-menu protected always-hidden reveal now uses the UI-mediated unlock gate before routing.
- Private Access diagnostics now log protected resource kinds rather than protected target IDs.
- Import remains dry-run only from Phase 12.
- Spacing Labs remains guarded; apply/restore/reset must either become fully reliable and tested or stay safely deferred.
- Icon Moving remains Experimental and must stay explicitly gated.

## Remaining Deferred Work

- Refactor remaining advanced UI surfaces through the command router.
- Extend user-facing command availability/explanation rows to remaining status-menu and protected-action surfaces.
- Keep diagnostics privacy-safe by excluding live queries, selected item identities, protected names, protected target IDs, and full file paths unless explicitly chosen in a supported export flow.
