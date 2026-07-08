# Workspaces Level-2 — Hardware Validation Pass

**Goal:** confirm that saving a Workspace's layout and applying it actually
reconfigures your **real** menu bar — real third-party icons moving into their
saved zones — with atomic rollback if a move fails.

This is the one thing that can't be checked in CI or headless: it needs a real
Mac, a granted Accessibility permission, and real apps in your menu bar.
(~10 minutes.)

---

## 0. Build & launch the latest code

- Build your current working copy (it has all the Level-2 code):
  `scripts/build_debug.sh`, then launch the built app — or just Run in Xcode.
- Your ~49 uncommitted files are still in the working tree; building the working
  copy includes everything.

## 1. Turn on the gate (once)

Real moves are gated behind the Assisted Move opt-in. In **Settings**:

- [ ] Optional **Pro** — on
- [ ] **Accessibility Discovery** — on
- [ ] Grant the **Accessibility** permission (System Settings → Privacy &
      Security → Accessibility) — required for any real move
- [ ] **Assisted Move** — on (`iconMovingEnabled`)
- [ ] Leave **"require confirmation" off** for a smooth run (a layout apply is a
      single action; per-move dialogs are already suppressed for it)

Now open **Settings → Workspaces** and scroll to the new **Menu Bar Layout**
section. The status should read **"Assisted Move On."** If it says *Off*, one of
the toggles above isn't set.

## 2. Save a layout

1. Manually arrange your real menu bar the way you want *this* Workspace — drag
   icons across MenuBarDeclutter's separators into the hidden / always-hidden
   zones (normal ⌘-drag).
2. In **Menu Bar Layout**, click **Save Current Layout**.
   - Expect: *"Saved N item target(s) for this Workspace."*
   - This records each non-system icon's current zone as this Workspace's target.

## 3. Change the bar, then apply

1. Manually move a couple of icons to different zones, so the bar no longer
   matches what you saved.
2. The section summary should now read something like **"2 moves, 1 to hide,
   1 to reveal."**
3. Click **Apply Layout Now**.
   - Expect: the real icons move back to their saved zones.
   - Expect outcome text: **"Applied N move(s)."**
   - Expect **no** per-move confirmation dialogs (batch apply suppresses them).

## 4. Test the safety net (rollback)

To confirm a failed move never leaves your bar scrambled:

- Save + apply a layout that targets a **stubborn app** (an Electron app, or one
  that rejects synthetic drags). If a move fails mid-apply:
  - Expect outcome: **"A move failed (step K); rolled back to keep the bar
    intact."**
  - Expect the bar back where it started (the already-applied moves were reversed).

## 5. Read the results

Each move is also recorded here:

```sh
cat "$HOME/Library/Application Support/MenuBarDeclutter/move-reliability.txt"
```

## What to send back

- The **outcome text** you saw for Apply (and for the rollback test).
- The top of `move-reliability.txt` (overall rate + the failure breakdown).
- Which apps, if any, failed to move.

Then:
- **All applied cleanly →** the real-control bet is validated; we harden and expand.
- **Some moves failed →** the failure reasons in the file point us at which
  apps/transitions to fix before leaning on it.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Section reads "Assisted Move Off" | Pro / Accessibility Discovery / the Accessibility permission / Assisted Move — one is off (step 1) |
| "Apply Layout Now" greyed out | No layout saved, the bar already matches (nothing to move), or the gate is off |
| "Save" records 0 targets | Discovery hasn't scanned — confirm Pro + Accessibility are on and the bar has non-system icons |
| Lots of `dragFailed` / `verificationFailed` in the file | The real signal — send it and we dig into those specific apps |
