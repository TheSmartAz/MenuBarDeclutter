# Experimental Icon Moving

Icon Moving is an optional Pro/Labs feature for explicit user-triggered menu bar item movement. It is experimental and disabled by default.

## What It Does

- Adds move commands to Find Icon and Second Bar context menus.
- Supports Move to Visible, Move to Hidden, Move to Always Hidden, Move Left, and Move Right.
- Requires Pro Mode, Accessibility Discovery, Accessibility permission, the Icon Moving setting, first-use confirmation, and per-move confirmation.
- Shows a first-use warning before enabling.
- Blocks MenuBarDeclutter's own items.
- Blocks likely system items by default.
- Allows one move at a time.
- Reveals the required zone, suspends auto-rehide/hover reveal, plans a conservative Command-drag, executes with `CGEvent`, rescans, verifies the destination, retries within configured limits, and restores visibility on failure.

## User Flow

1. Open Settings -> Advanced.
2. Enable Icon Moving and accept the warning.
3. Open Find Icon or Second Bar.
4. Right-click a result/item.
5. Choose a move command.
6. Review Diagnostics if the move fails or is skipped.

## Privacy And Permissions

Icon Moving is explicit user action only. It requires Pro Mode, Accessibility Discovery, and Accessibility because planning and verification depend on the local Accessibility snapshot. It uses public event APIs for simulated Command-drag behavior and does not use private APIs, Screen Recording, ScreenCaptureKit, pixel capture, network access, or background automation.

## Implementation

- `MenuBar-Manager/Moving/IconMoveService.swift`
- `MenuBar-Manager/Moving/DragPlan.swift`
- `MenuBar-Manager/Moving/DragExecutor.swift`
- `MenuBar-Manager/Moving/DragVerificationService.swift`
- `MenuBar-Manager/Moving/IconMoveSafetyRules.swift`
- `MenuBar-Manager/Moving/IconMoveResult.swift`
- `MenuBar-Manager/Moving/IconMoveError.swift`
- `MenuBar-Manager/Settings/AdvancedSettingsView.swift`

## Verification

- `MenuBar-ManagerTests/IconMovePlanningTests.swift`
- Manual QA: `docs/testing/manual-v0.1.3-system-qa.md`
- Dogfood fixture QA: `docs/testing/dogfood/icon-moving-experimental-gate.md`

## Known Limitations

- Real CGEvent drags are not run in automated tests.
- Third-party apps and system items may refuse or undo movement.
- Frame changes can change generated snapshot IDs, so verification uses ownership/metadata matching before ID fallback.
- The feature must never run from startup, wake, profile application, smart triggers, or URL automation.
