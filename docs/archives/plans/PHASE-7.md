Implement Phase 7 — Programmatic Icon Moving.

Context:
Phase 4/5/6 can discover, search, reveal, and display menu bar items. Now implement optional explicit user-triggered icon moving using simulated Command-drag.

Important:
This is Pro Mode only.
This must never run automatically at startup.
This must only run after explicit user action.
Failure must not damage the user's menu bar layout.

Tasks:

1. Moving module.
   Create:
   - Moving/IconMoveService.swift
   - Moving/DragPlan.swift
   - Moving/DragExecutor.swift
   - Moving/DragVerificationService.swift
   - Moving/IconMoveResult.swift
   - Moving/IconMoveError.swift

2. User-facing actions.
   Add actions in Search and Second Bar:
   - Move to Visible
   - Move to Hidden
   - Move to Always Hidden
   - Move Left
   - Move Right

   Require confirmation on first use:
   - Explain that this simulates Command-drag.
   - Explain that it may fail depending on app/system item behavior.
   - Provide “do not show again”.

3. Drag planning.
   DragPlan fields:
   - sourceFrame
   - targetFrame
   - sourcePoint
   - targetPoint
   - modifierFlags: command
   - duration
   - retryCount
   - preMoveVisibilityState
   - targetZone

   Rules:
   - Always reveal needed sections before dragging.
   - Ensure source frame is visible before attempting drag.
   - Avoid dragging our own control/separator items unless specifically resetting layout.
   - Do not drag system critical items by default.
   - Use conservative sourcePoint: center of item frame.

4. Drag execution.
   Use CGEvent where appropriate:
   - move mouse to source.
   - mouse down with Command modifier.
   - drag to target.
   - mouse up.
   - restore mouse position optional.
   - log all steps.

   Add delay between steps to let macOS relayout.

5. Verification.
   After drag:
   - rescan menu bar.
   - locate item again.
   - verify zone changed.
   - if failed:
     - retry with updated frame up to limit.
     - restore pre-move visibility state.
     - report failure in UI.

6. Safety locks.
   - Only one move at a time.
   - Disable auto-rehide during move.
   - Disable hover reveal during move.
   - Disable second bar selection during move.
   - Timeout if move takes too long.

7. Settings.
   Add Advanced / Icon Moving:
   - Enable icon moving.
   - Require confirmation.
   - Max retries.
   - Drag duration.
   - Allow moving system items: default false.
   - Reset moving warnings.

8. Diagnostics.
   Add:
   - last move result.
   - last move error.
   - drag plan summary.
   - verification result.
   - retries count.

9. Tests.
   Unit tests:
   - DragPlan target calculation.
   - zone transition decision.
   - safety rules rejecting own separators.
   - safety rules rejecting system items by default.
   - verification result interpretation.

   Do not run real CGEvent drag in unit tests.

10. Manual QA.
   Add:
   - move a third-party app icon to hidden.
   - move it back to visible.
   - move to always-hidden.
   - attempt system item move and confirm blocked.
   - cancel confirmation.
   - revoke Accessibility and verify disabled.
   - external display.
   - notch.
   - auto-rehide disabled during move.

Acceptance criteria:
- User can explicitly move a supported third-party menu bar item between zones.
- App verifies result after move.
- Failure is reported clearly.
- No automatic moves occur on startup/wake.
- Basic Mode remains safe.
- Pro Mode can be disabled.

Out of scope:
- No bulk automatic layout optimizer.
- No startup auto-arrange.
- No private APIs.
- No ScreenCaptureKit.