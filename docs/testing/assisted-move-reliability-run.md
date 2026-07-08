# Your Action List — Measure Assisted-Move Reliability

**This doc is for you (the human).** It's the one thing only you can do right now,
because it needs a real Mac with real apps in the menu bar — my environment has
neither.

**Why it matters in one line:** this produces the *number* that decides whether we
build Workspaces on real icon moving, or fix the mover first. Nothing big proceeds
until this runs. (Full reasoning:
[`docs/roadmap/feature-rationalization-2026-07-07.md`](../roadmap/feature-rationalization-2026-07-07.md).)

---

## TL;DR (5 steps, ~20 minutes)

1. Build & run the app from your **current working copy**.
2. Turn on Pro + Accessibility, grant the permission, enable Assisted Move.
3. Move ~20+ real menu-bar icons around (a few apps, a few directions).
4. Open `~/Library/Application Support/MenuBarDeclutter/move-reliability.txt`.
5. Read the **PASS / FAIL** line and send it to me.

Then I take it from there.

---

## Step 0 — Make sure it's actually collecting (read this once)

The code that records each move is wired in through ~4 lines that are **sitting
uncommitted in your working tree** (in `App/AppEnvironment.swift` and
`App/MenuBarItemSurfaceCoordinator.swift`). I left them there because those files
are tangled with your Second Bar work.

- ✅ **If you build from your current checkout** (what's on disk now), it collects.
- ❌ **If you `git checkout .` / discard changes or build the bare committed branch**,
  the collector is not wired in and **no data is recorded**.

> If you'd rather not worry about it, tell me and I'll commit just those 4 lines to
> the branch so it's safe.

## Step 1 — Build & run

- Xcode: open `MenuBar-Manager.xcodeproj`, scheme **MenuBarDeclutter**, Run.
- Or terminal: `scripts/build_debug.sh`, then launch the built app.

## Step 2 — Enable the assisted mover

In the app's **Settings** (the toggles live under Privacy / Advanced — exact list
in the matrix doc's *Setup* section):

- [ ] Optional **Pro** on
- [ ] **Accessibility Discovery** on
- [ ] Grant the **Accessibility** permission when prompted (System Settings →
      Privacy & Security → Accessibility)
- [ ] **Assisted Move** on (`iconMovingEnabled`)
- [ ] Turn **off** "require confirmation" for a fast batch run
      (`iconMovingRequireConfirmation`) — leave it on for at least one move to
      confirm the confirm/cancel path also records

To start from a clean slate: quit the app and delete
`~/Library/Application Support/MenuBarDeclutter/move-outcomes.json` and
`move-reliability.txt`.

## Step 3 — Do the moves

Trigger assisted moves on **real third-party icons** — mix a few apps and a few
directions until you have **at least 20** attempts. The full recommended spread
(app types × zone transitions × display setups) is in
[`assisted-move-reliability-matrix.md`](assisted-move-reliability-matrix.md); a
quick first pass is fine to start:

- Move Slack / Dropbox / Spotify (or whatever you have) between hidden ↔ visible.
- Try a couple in the always-hidden zone.
- If you have an external display or a notch, repeat a few there.

**System items (Wi-Fi, Battery, Clock) are *supposed* to be skipped** by the safety
rules — that's correct, not a failure.

## Step 4 — Read the number

```sh
cat "$HOME/Library/Application Support/MenuBarDeclutter/move-reliability.txt"
```

The top three lines are what matter:

```
Assisted Move Reliability
Gate: success rate ≥ 95.0% over ≥ 20 samples → PASS | FAIL | INSUFFICIENT DATA
Success rate: __._% (__/__ samples)
```

Below that: first-attempt rate, latency, a failure breakdown, and per-app and
per-zone-transition rates (so you can see *which* apps or moves are weak).

- **INSUFFICIENT DATA** → keep moving icons until you pass 20 samples.
- The raw records are in `move-outcomes.json` next to it (local only; neither file
  is included in the diagnostics export).

## Step 5 — Send it to me

Paste the top of `move-reliability.txt` (or the whole file). Then:

| Result | What I do next |
|---|---|
| **PASS** (≥ 95%, ≥ 20 samples) | Rewire Workspaces to real Level-2 moves — the foundation holds. |
| **FAIL** (< 95%) | Look at the weakest apps/transitions in the breakdown and fix the mover there before building on it. |

---

## If something looks off

- **The `.txt` file never appears** → the collector isn't wired (see Step 0), or no
  *attempted* move has happened yet (all attempts were skipped by gating).
- **Everything shows as "gating skips" / rate is 0** → Pro, Accessibility Discovery,
  the Accessibility permission, or Assisted Move is still off (Step 2).
- **Lots of `dragFailed`** → the synthetic drag isn't landing; that's exactly the
  signal we're after — send it and we'll dig in.
- **Lots of `verificationFailed`** → the drag ran but the icon didn't end up where
  expected (notch/geometry/re-match). Also useful — send it.
