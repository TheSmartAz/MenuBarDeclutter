# Assisted Move Reliability Matrix

**Purpose.** Measure the real-world success rate of the single-item move
primitive (`IconMoveService`) *before* building Level-2 Workspaces on top of it.
Per the feature-rationalization decision record
([`docs/roadmap/feature-rationalization-2026-07-07.md`](../roadmap/feature-rationalization-2026-07-07.md)),
a workspace switch chains several of these moves, so their reliability is the
load-bearing unknown for the whole plan. Unit tests cover the *planning* logic;
this matrix measures whether a synthetic Command-drag actually lands against real
third-party icons on real hardware.

## Go / no-go gate

> **PASS = success rate ≥ 95% over ≥ 20 reliability samples** on common
> third-party apps.

- **PASS** → proceed to wire Workspaces to Level-2 real moves.
- **FAIL** (< 95% with enough samples) → do not build Workspaces on this yet;
  triage the failing apps/transitions first.
- **INSUFFICIENT DATA** (< 20 samples) → keep running the matrix.

"Reliability sample" = an attempt that actually ran the drag to a
succeeded/failed conclusion. **Gating skips** (Pro/permission/safety) and
**user/Task cancellations** are excluded from the rate — they do not measure the
mechanism. System items are *expected* to be skipped by the safety rules; that is
correct behavior, not a failure.

## Where the number comes from

The running app collects one `MoveOutcome` per attempt (privacy-safe, local only)
and, after every move, rewrites a human-readable summary. Read:

- **Summary (read this):**
  `~/Library/Application Support/MenuBarDeclutter/move-reliability.txt`
- **Raw records (for deeper analysis):**
  `~/Library/Application Support/MenuBarDeclutter/move-outcomes.json`

The summary shows the gate status, overall rate, first-attempt rate, latency,
a failure histogram, and per-zone-transition and **per-app** breakdowns. Neither
file is included in the diagnostics export.

> Tip: `cat "~/Library/Application Support/MenuBarDeclutter/move-reliability.txt"`

## Setup

1. Enable **Optional Pro** and **Accessibility Discovery**, and grant the
   Accessibility permission.
2. Enable **Assisted Move** (`iconMovingEnabled`).
3. For a batch run, turn **off** the per-move confirmation
   (`iconMovingRequireConfirmation = false`) so you can repeat quickly. (Leave it
   on for at least one pass to confirm the confirm/cancel path also records.)
4. Optionally raise `iconMovingMaxRetries` to the value you intend to ship, so the
   measured rate reflects retries.
5. To start clean, quit the app and delete the two files above.

## The matrix

Run **≥ 5 moves per cell**, mixing directions, until you have ≥ 20 samples per
app and ≥ 20 overall. Reset visible arrangement between cells as needed.

### Apps (rows)

| Class | Examples | Why |
|---|---|---|
| Well-behaved native | 1Password, Dropbox, Bartender-free status apps | Baseline — should be near 100% |
| Electron / cross-platform | Slack, Discord, VS Code helpers | Often the fragile cases |
| Media / background | Spotify, Zoom, Cleanshot | Odd AX frames / redraw timing |
| System items | Wi-Fi, Battery, Clock, Control Center | Must be **skipped** by safety, not moved |

### Zone transitions & directions (columns)

- `hidden → visible`
- `visible → hidden`
- `visible → alwaysHidden`
- `alwaysHidden → visible`
- `moveLeft` / `moveRight` (relative)

### Display configurations (repeat the grid)

- Built-in display **with notch**
- Built-in display **without notch** (or notch hidden)
- **External** display as primary
- **Multi-display** (menu bar on secondary)

## Recording template

| Display | App | Transition | Attempts | Successes | Notes (failure reason) |
|---|---|---|---|---|---|
| notch | Slack | hidden→visible | 5 | | |
| notch | Slack | visible→alwaysHidden | 5 | | |
| external | Spotify | moveRight | 5 | | |
| … | | | | | |

After each session, record the **summary file's** gate line and overall rate
here, plus any app or transition that sits below 95%:

```
Date:
Overall: __.__%  (__/__ samples)  → PASS / FAIL / INSUFFICIENT DATA
Worst app:
Worst transition:
Dominant failure reason:
```

## Interpreting failures

- `dragFailed` — the synthetic Command-drag itself did not complete. Suspect
  event-tap timing or the app rejecting synthetic input.
- `verificationFailed` — the drag ran but the post-move rescan did not find the
  item in the target zone (`notFound` = re-match/vanish; `wrongZone` = landed in
  the wrong place). Suspect AX frame accuracy, notch geometry, or re-match logic.
- `missingSourceFrame` / `planningFailed` — discovery/geometry gap before the drag.

A low rate concentrated in one app class or one transition is a scoping signal:
it may be acceptable to ship Level-2 Workspaces that only performs the reliable
transitions, and treats the fragile ones as best-effort with rollback.
