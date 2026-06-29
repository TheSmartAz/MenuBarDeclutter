# Phase 10 Risk Register

Date: 2026-06-29

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Capacity estimates feel exact when they are approximate | User may distrust recommendations when real menu bar behavior differs | Label Basic estimates as approximate and show source/warnings |
| Crowded Reveal Rescue opens Second Bar unexpectedly | Reveal workflow could feel surprising | Keep the feature configurable, log the reason, and expose Reveal Inline Anyway |
| Full Menu Bar Mode fails to restore previous state | User may be left expanded or confused | Save prior visibility state, auto-exit by default, and skip restore if user changed state manually |
| Spacer status items add clutter | Feature meant to organize could make the menu bar more crowded | Spacers are app-owned, optional, hideable, resettable, and hidden by Safe Mode recovery |
| Corrupted spacer JSON blocks launch | App startup instability | Back up corrupted JSON and reset to an empty spacer set |
| Menu Bar Spacing Labs changes global defaults | System appearance may change outside the app | Labs is off by default, explicit, backed up, reversible, and never applied automatically |
| Spacing keys vary across macOS releases | Apply may be ineffective or unavailable | Keep defaults keys isolated, support dry-run/unavailable results, and document limitations |
| Health repair changes system defaults | Recovery could become destructive | Health repair resets app state only and does not silently mutate global spacing defaults |
| Pro AX snapshots are stale | Capacity recommendations may be wrong | Include stale snapshot warnings and fall back to conservative Basic estimates |
| Privacy verification regresses | Phase 10 could accidentally add sensitive capability | Keep no ScreenCaptureKit, Screen Recording, Apple Events, Input Monitoring, network, telemetry, or cloud sync in code and scripts |

## Open Follow-ups

- Add visual/manual QA on more display layouts, especially external monitors
  and notched displays.
- Add more UI automation for Layout settings once accessibility identifiers are
  stable across the redesigned settings surface.
- Revisit actual spacing defaults application only if macOS 26 behavior can be
  verified without weakening the privacy boundary.
