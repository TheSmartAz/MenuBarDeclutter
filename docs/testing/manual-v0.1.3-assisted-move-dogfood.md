# v0.1.3 Assisted Move Dogfood Manual QA

Status: automated guardrails pass; guarded one-move local dogfood passed for a disposable fixture item. Installed-app hands-on UI dry-run and confirmation clicks remain pending.

Assisted Move is Experimental. The stable v0.1.3 arrangement path remains normal macOS Command-drag from the Arrange guide.

## Scope

Use this checklist to dogfood one item at a time without turning Assisted Move into a stable or bulk-moving claim.

- Pro Mode, Accessibility Discovery, Accessibility permission, Icon Moving, Safe Mode, target-zone, source-frame, own-app item, likely-system-item, first-use confirmation, and per-move confirmation gates must be visible or testable.
- Dry-run must show source zone, target zone, planned direction, and risk before any move attempt.
- Dry-run must not post drag events.
- A real move attempt is optional and must use a disposable non-system item.
- Dogfood metadata must stay privacy-safe: no raw item titles, app names, bundle identifiers, selected item IDs, coordinates, screenshots, screen contents, query text, or network data.

## Preflight

| Step | Expected Result | Evidence |
| --- | --- | --- |
| Install and launch the local-alpha app from `/Applications`. | Settings opens and Basic Mode surfaces remain usable. | |
| Enable Pro Mode and Accessibility Discovery from Privacy. | No silent permission prompt; Accessibility permission is granted only through explicit user/system action. | |
| Confirm Safe Mode is inactive. | Assisted Move may show normal gates instead of Safe Mode blocking. | |
| Launch a disposable fixture or third-party menu bar item. | Diagnostics scan completes with nonzero discovered items. | 2026-07-02 current installed artifact: fixture scan completed with 26 scanned items, 24 visible, 2 hidden, 0 always-hidden, 0 unknown, and 0 AX failures. |
| Keep Icon Moving disabled before dry-run. | Dry-run can explain the disabled gate; no movement can execute. | |

## Dry-Run Checklist

| Step | Expected Result | Evidence |
| --- | --- | --- |
| Open Settings -> Arrange -> Assisted Move. | Assisted Move is labeled Experimental and single-item only. | |
| Select one disposable non-system item. | Own app items and likely system items are blocked by default. | |
| Choose a target zone. | Target picker offers visible, hidden, and always-hidden zones. | |
| Click Dry Run. | The plan shows source, target, direction, and risk. | |
| Inspect the plan and diagnostics summary. | Summary says redacted; no raw title, bundle ID, coordinates, screenshot, or query text appears. | |
| Click Cancel. | No movement is attempted and the current dry-run/result state clears. | |

## Optional One-Move Dogfood

Only run this section when a disposable non-system item is safe to move.

| Step | Expected Result | Evidence |
| --- | --- | --- |
| Enable Experimental Icon Moving in Advanced. | Try One Move remains unavailable until confirmations and a ready dry-run exist. | |
| Accept first-use confirmation and per-move confirmation. | Both confirmations are explicit in Arrange. | |
| Run Dry Run again. | Plan is Ready only when every gate passes. | |
| Click Try One Move once. | The app attempts one Command-drag path only; no bulk move exists. | |
| Verify result. | Success verifies the target zone; failure, timeout, cancellation, or stale metadata shows recovery actions. | 2026-07-02 guarded local dogfood: `/tmp/MenuBarDeclutter-live-icon-move-dogfood.enabled` explicitly enabled `IconMovePlanningTests/liveDogfoodMovesOneFixtureItemWhenExplicitlyEnabled`. The disposable `MenuBarFixtureApp` item `Long` planned `Move Right` from source `553,16` to target `631,16`, the service logged `Move Right succeeded for MenuBarFixtureApp`, and the in-test verification required observed movement before accepting the result. |
| Use recovery actions if needed. | Reveal All, Reset Layout, Retry Dry Run, and Recovery remain available. | |
| Disable Experimental Icon Moving after the pass. | Default safety posture is restored. | 2026-07-02: installed default `iconMovingEnabled` remained `0`; the live test used an isolated temporary settings suite and the `/tmp` sentinel was removed after the run. |

## Dogfood Log Review

| Step | Expected Result | Evidence |
| --- | --- | --- |
| Open Diagnostics after a blocked, cancelled, failed, or successful attempt. | Dogfood event metadata uses aggregate fields only. | 2026-07-02 guarded local dogfood asserted the recorded dogfood event had `moveAttempted=true`, `sourceZone=visible`, `targetZone=visible`, `result=succeeded`, and `redacted=true`. |
| Export diagnostics or dogfood bundle if Dogfood Mode is active. | Export excludes raw item identity, bundle ID, coordinates, screenshots, screen contents, query text, and network data. | |
| Confirm metadata fields. | Expected fields include `moveAttempted`, `sourceZone`, `targetZone`, `result`, `failureReason`, `durationBucket`, and `redacted=true`. | 2026-07-02 guarded local dogfood asserted dogfood metadata values did not contain the raw item title `Long` or the fixture bundle identifier. |

## Current Known State

- 2026-07-02: the previous installed-app blocker, `Discovered 0`, was resolved by using a non-sandboxed assistive local-alpha app target for Pro Accessibility Discovery while keeping no-network and no-screen-capture invariants.
- 2026-07-02: New Item Inbox and Placement Planner now have nonzero fixture metadata available for installed-app inspection.
- 2026-07-02: one guarded local move against a disposable fixture item passed with explicit `/tmp` sentinel opt-in. Broader hands-on installed UI dry-run, first-use confirmation, per-move confirmation, and repeated physical drag scenarios remain pending.
