# Progress: Phase 7

Status: implemented.

Historical snapshot: this file records the end-of-phase state for Phase 7. Later progress files, `docs/project-summary.md`, and release docs supersede old scheme names, test counts, defaults, and deferred-scope notes.

## Tech Stack

- Swift 6 with app declarations isolated to `MainActor`.
- Native macOS 26.0+.
- AppKit and CoreGraphics for explicit, user-triggered Command-drag simulation.
- SwiftUI context menus in Search and Second Bar for move commands.
- Swift Testing for drag planning, safety rules, and verification interpretation.

## Added

- `Moving/IconMoveService.swift`: gated async move coordinator for explicit Pro Mode icon moves. It validates settings, permission, safety rules, confirmation state, one-at-a-time locking, visibility reveal, runtime suspension, retries, verification, diagnostics, and failure recovery without blocking the UI actor during wait intervals.
- `Moving/DragPlan.swift`: drag command modeling, planning context, source/target points, target zone, modifier flags, duration, retry count, and plan summaries.
- `Moving/DragExecutor.swift`: nonisolated async `CGEvent`-based executor for mouse move, Command mouse down, drag, and mouse up. Unit tests do not run real drags.
- `Moving/DragVerificationService.swift`: rescanned-snapshot matching and target-zone verification.
- `Moving/IconMoveResult.swift`: command/outcome/result values and user-facing summaries.
- `Moving/IconMoveError.swift`: explicit failure reasons for disabled state, permission, safety blocks, planning, execution, and verification.
- `MenuBar-ManagerTests/IconMovePlanningTests.swift`: coverage for target calculations, left/right movement, own-item safety, system-item safety, wrong-zone verification, and async move-service cleanup.

## Modified

- `Search/SearchRootView.swift`: added move context menu commands to search results and awaits move completion from a task before updating status text.
- `Search/SearchWindowController.swift`: passes async move actions into the SwiftUI root view.
- `SecondBar/SecondBarRootView.swift`: added move context menu commands to Second Bar items and awaits move completion from a task before updating status text.
- `Settings/AdvancedSettingsView.swift`: added Icon Moving settings for enablement, first-use confirmation, retry count, drag duration, system item allowance, and warning reset.
- `App/AppEnvironment.swift`: owns `IconMoveService`, suspends auto-rehide/hover interactions during moves, restores visibility on failure, and shares move commands between Search and Second Bar.
- `Core/SettingsStore.swift`: added Phase 7 icon moving settings, defaults, clamping, and restore-default handling.
- `Core/LiveDiagnosticsStatus.swift`: added move-in-progress, result, error, drag plan, verification, and retry diagnostics.
- `Settings/DiagnosticsSettingsView.swift`: surfaces live icon moving diagnostics.
- `Core/DiagnosticsExporter.swift`: includes icon moving settings in privacy-safe diagnostics exports.
- `docs/architecture/architecture-overview.md`, `docs/project-summary.md`, and `docs/testing/manual-qa.md`: updated for Phase 7.

## Privacy And Permissions

- Icon moving is Pro Mode only and requires Accessibility permission.
- It is disabled by default and never runs automatically on launch, wake, profile application, or trigger evaluation.
- Every move starts from an explicit user action in Search or Second Bar.
- First use explains that the app simulates a Command-drag and may fail depending on the app or system item.
- Own MenuBarDeclutter items and likely system items are blocked by default.
- Basic Mode remains fully usable with icon moving disabled, Pro Mode disabled, or permission missing.

## Verification

- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - Final result: `TEST SUCCEEDED`.
  - Passing Phase 7 tests include:
    - `IconMovePlanningTests/dragPlanTargetsVisibleSideOfPrimarySeparator()`
    - `IconMovePlanningTests/movingLeftKeepsCurrentZoneAndMovesTargetLeft()`
    - `IconMovePlanningTests/safetyRejectsOwnSeparatorItems()`
    - `IconMovePlanningTests/safetyRejectsSystemItemsByDefault()`
    - `IconMovePlanningTests/verificationReportsWrongZoneWhenItemIsFoundElsewhere()`
    - `IconMovePlanningTests/moveServiceAwaitsDragAndClearsProgress()`

## Notes

- Real CGEvent dragging is intentionally excluded from automated tests.
- Runtime moves rescan and verify after execution. If verification fails, the previous visibility state is restored and the result is reported in UI/Diagnostics.
- Drag timing and post-drag verification waits use `Task.sleep` so the app does not block the MainActor while a requested move is in flight.
