# Phase 14 Settings Simplification

Phase 14 reduces the normal Settings surface for `v0.1.1` to seven top-level areas:

1. General
2. Hide & Reveal
3. Arrange
4. Find & Rescue
5. Privacy
6. Recovery
7. Advanced

The design goal is to make the app understandable as:

> Hide clutter. Arrange icons safely. Find hidden icons. Recover if something goes wrong.

## Sidebar Mapping

| New Area | Previous Top-Level Sections Folded In |
| --- | --- |
| General | General setup, Launch at Login, onboarding reset, version. |
| Hide & Reveal | Behavior, Basic hotkey, auto-rehide, hover reveal, always-hidden zone. |
| Arrange | Layout basics, command-drag guide, placement test, Placement Planner, Assisted Move pointer. |
| Find & Rescue | Menu Bar Items, Search, Second Bar, Crowded Rescue, lightweight collections. |
| Privacy | Privacy and permission boundary. |
| Recovery | Diagnostics, health, Safe Mode, reset and repair actions. |
| Advanced | Profiles, Smart Triggers, Dynamic Hotkeys, Private Access, Groups power controls, Automation, Import / Export, Spacing Labs, Experimental Icon Moving. |

Legacy routes remain available for deep links and Advanced navigation, but the visible sidebar is limited to the seven areas above.

## Status Treatment

The Settings shell and docs use these maturity labels:

- Stable
- Preview
- Labs
- Experimental
- Deferred
- Internal

`Disabled` and `Unavailable` are runtime states, not maturity claims.

## Product Decisions

- Guided Manual Arrange is a main Settings area because icon placement is required for a successful separator-based hiding setup.
- Find Icon and Second Bar live together under Find & Rescue instead of reading as separate product pillars.
- Profiles, triggers, automation, migration, Private Access, and Labs stay accessible from Advanced without dominating first-run comprehension.
- Spacing Labs does not appear as a normal Arrange action.
- Assisted Move is visible from Arrange, but remains Experimental and points to Advanced opt-in controls.

## Verification

Phase 14 UI smoke expectations were updated so the visible Settings pages are:

- General
- Hide & Reveal
- Arrange
- Find & Rescue
- Privacy
- Recovery
- Advanced

Automated UI launch remains subject to the current macOS UI automation runner bootstrap issue recorded in the Phase 14 progress file.
