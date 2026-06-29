# Phase 13 v0.1.1 Pro Workflow Completion Progress

Date started: 2026-06-29
Last updated: 2026-06-29

## Summary

Phase 13 implementation has started on the `v0.1.1` release line. This phase is not `v0.2`.

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
- `MenuBar-Manager/Shortcuts/AppIntentExecutionService.swift`
- `MenuBar-Manager/Shortcuts/AppIntentResultMapper.swift`
- `MenuBar-ManagerTests/AppIntentExecutionServiceTests.swift`
- `MenuBar-ManagerTests/CommandCenter/MenuBarCommandRouterTests.swift`
- `docs/progress/phase-13-v0.1.1-pro-workflow-completion.md`

## Validation Results

| Command | Result | Notes |
| --- | --- | --- |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests -only-testing:MenuBarDeclutterTests/AppIntentExecutionServiceTests` | PASS | 19 focused tests in 2 suites passed after fixing the router's Private Access checker ownership. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Full run passed with 330 Swift Testing tests in 61 suites and 7 UI tests. Result bundle: `~/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Logs/Test/Test-MenuBarDeclutter-2026.06.29_11-46-53--0700.xcresult`. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed; built-app checks skipped because `APP_PATH` was not set. |

## Manual QA Notes

No new manual QA has been performed for Phase 13 yet.

Phase 13 manual QA will be needed for:

- Live Find Icon and Second Bar degraded states.
- Command routing explanations in Settings and status menu surfaces.
- Protected Private Access actions.
- Dynamic hotkey execution and conflict recovery.
- App Intents in Shortcuts.
- Local `menubardeclutter://` automation URLs.
- Crowded reveal fallback behavior against a real crowded menu bar.

## Known Limitations

- The shared command router is implemented, but only App Intent execution has been migrated to it so far.
- Find Icon, Second Bar/Icon Panel, Groups, Hotkeys, Profiles UI, and URL automation still use their existing Phase 10/11 paths until they are migrated.
- Private Access is currently represented in the command router as a lock-status gate; UI-mediated unlock execution still needs to be wired for protected command paths.
- Import remains dry-run only from Phase 12.
- Spacing Labs remains guarded; apply/restore/reset must either become fully reliable and tested or stay safely deferred.
- Icon Moving remains Experimental and must stay explicitly gated.

## Remaining Deferred Work

- Implement Command Center Core and unit tests.
- Refactor advanced action surfaces through the command router.
- Add a user-facing command availability/explanation model.
- Keep diagnostics privacy-safe by excluding live queries, selected item identities, protected names, protected target IDs, and full file paths unless explicitly chosen in a supported export flow.
