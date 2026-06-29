
# Phase 9.2 — Private Dogfood + Real-System QA Harness

The goal is to turn the project from “implemented and tested in code” into “safe enough to use daily on your own Mac.”

Do **not** add ScreenCaptureKit. Do **not** add new Pro features. Do **not** polish branding yet beyond what is needed for install testing. The most valuable next work is to create a controlled QA environment, test with real menu bar items, and collect local-only failure evidence.

---

# Recommended roadmap after Phase 9.1

```text
Phase 9.2 — Private Dogfood + Real-System QA Harness
Phase 9.3 — Signed / Notarized Installed-App Alpha
Phase 9.4 — Dogfood Bugfix + Stability Sprint
Phase 9.5 — v0.1 Basic Stable Freeze
Phase 9.6 — Pro Mode Reliability Decision
Phase 10 — still deferred
```

The key shift is this:

```text
Before Phase 9.1:
Implementation-driven.

After Phase 9.1:
Validation-driven.
```

Apple’s notarization path matters once you distribute a Developer ID app outside the Mac App Store; Apple says Mac software built for distribution outside the Mac App Store with Developer ID must be notarized, and Developer ID software gets a notarization ticket for Gatekeeper trust. ([Apple Developer][1]) Launch at Login also needs installed-app validation, because `SMAppService` is the modern API family for registering and controlling Login Items, and Apple documents `mainApp` specifically for configuring the main app to launch at login. ([Apple Developer][2]) Pro Mode needs real Accessibility QA because `AXIsProcessTrustedWithOptions` only reports whether the current process is a trusted Accessibility client; the messy parts are user grant/revoke timing, stale permission state, and relaunch behavior. ([Apple Developer][3]) macOS 26 also deserves visual QA because Apple’s Tahoe update notes call out Liquid Glass and a transparent menu bar, which directly affect separator visibility and overlay readability. ([Apple Support][4])

---

# Phase 9.2 should focus on these 5 things

## 1. Build a local menu bar fixture app

This is the most useful next technical step.

Instead of immediately testing icon moving on random third-party apps, create a small local helper app that adds many fake menu bar items:

```text
MenuBarFixtureApp
- 8–15 status items
- icon-only items
- title-only items
- wide items
- dynamic-width items
- items with menus
- items that update every few seconds
- items with different bundle IDs if possible through helper variants
```

Why this matters:

```text
1. You can test Basic Mode collapse/expand safely.
2. You can test real Command-drag behavior.
3. You can test AX discovery against known items.
4. You can test Find Icon and Second Bar with predictable data.
5. You can test experimental icon moving without risking your real menu bar layout.
```

This fixture app should be **debug/QA-only** and should never ship as part of the main app.

---

## 2. Convert manual blockers into repeatable dogfood runs

Right now, your docs list the blockers. Phase 9.2 should turn them into actual run records:

```text
docs/testing/dogfood-runs/
  2026-06-28-basic-mode.md
  2026-06-28-pro-mode.md
  2026-06-28-icon-moving.md
  2026-06-28-external-display.md
  2026-06-28-launch-at-login.md
```

Each run should record:

```text
Environment:
- Mac model
- chip
- macOS version
- display setup
- notch or no notch
- external display
- appearance mode
- reduce transparency
- increase contrast

Build:
- commit hash
- scheme
- version
- debug/release
- installed path

Result:
- PASS
- FAIL
- BLOCKED
- NOT TESTED

Evidence:
- diagnostics export path
- health report path
- manual notes
- reproduction steps
```

No screenshots should be collected automatically, because your current privacy boundary says no screen capture.

---

## 3. Make Basic Mode the first alpha gate

Before caring about Pro Mode, prove this:

```text
Basic Mode must work for 3–5 days of daily use.
```

Basic Mode gate:

```text
1. App starts cleanly.
2. Onboarding is understandable.
3. Separator can be Command-dragged.
4. Collapse/expand works with real icons.
5. Always-hidden works.
6. Auto-rehide does not collapse while interacting.
7. Hover reveal does not flicker.
8. Hotkey does not conflict.
9. App survives sleep/wake.
10. App survives display changes.
11. App recovers after force quit.
12. Safe Mode works.
13. Reset layout works.
14. No Accessibility prompt appears.
15. No network connection appears.
```

If Basic Mode fails, do not spend time on Pro Mode yet.

---

## 4. Treat Pro Mode as three separate gates

Do not validate Pro Mode as one big feature. Split it:

```text
Pro A — read-only:
- Accessibility discovery
- diagnostics table
- Find Icon
- highlight overlay

Pro B — assisted UI:
- Second Bar
- profiles
- URL automation
- trigger pause/resume

Pro C — experimental:
- icon moving
```

For private alpha, I would ship:

```text
Basic Mode: enabled
Pro A: available
Pro B: available but conservative
Pro C icon moving: disabled by default, Labs only
```

Icon moving should **not** block v0.1 Basic Stable.

---

## 5. Prepare for installed-app validation, but do not over-invest in branding yet

Your summary says `MenuBarDeclutter` is temporary and the final product name will be chosen later. That means:

```text
Private dogfood:
- okay to use MenuBarDeclutter

Public alpha:
- choose final product name first

v0.1 stable:
- final product name, bundle ID, app support path, URL scheme, release identity should be decided
```

Otherwise, you will create annoying migration work later.

---

# Phase 9.2 Codex execution package

You can give this directly to Codex.

```text
Implement Phase 9.2 — Private Dogfood + Real-System QA Harness.

Context:
Phases 0–9.1 are implemented for MenuBarDeclutter. Phase 10 ScreenCaptureKit visual capture remains intentionally deferred. The app targets macOS 26.0+ only.

Current status:
- Canonical scheme: MenuBarDeclutter.
- Deprecated compatibility scheme: MenuBar-Manager.
- Basic Mode is permission-free.
- Pro Mode is opt-in and Accessibility-only.
- Release artifact verification passed locally.
- Notarization and installed-app Launch at Login validation are not tested.
- Manual QA blockers remain for real menu bar drag/use, Accessibility grant/revoke, icon moving, external display/notch/sleep-wake/Space behavior, profiles/triggers/Safe Mode, installed Launch at Login, interactive network watch, archive, and notarization.

Phase goal:
Do not add user-facing product features. Build a private dogfood harness, a local menu bar fixture app, repeatable QA run templates, and stricter alpha gates so real macOS behavior can be validated safely.

Hard constraints:
1. Do not implement Phase 10.
2. Do not add ScreenCaptureKit.
3. Do not add Screen Recording permission.
4. Do not add Apple Events.
5. Do not add Input Monitoring.
6. Do not add network access.
7. Do not add telemetry.
8. Do not automatically collect screenshots.
9. Keep Basic Mode fully usable without Accessibility.
10. Keep icon moving disabled by default.
11. Any new fixture/helper must be debug/QA-only and not part of the shipping product.
```

---

## Task 1 — Create dogfood documentation structure

```text
Create:
- docs/testing/dogfood/README.md
- docs/testing/dogfood/dogfood-plan.md
- docs/testing/dogfood/basic-mode-gate.md
- docs/testing/dogfood/pro-readonly-gate.md
- docs/testing/dogfood/pro-assisted-gate.md
- docs/testing/dogfood/icon-moving-experimental-gate.md
- docs/testing/dogfood/release-install-gate.md
- docs/testing/dogfood/run-template.md
- docs/testing/dogfood/bug-report-template.md
- docs/testing/dogfood/daily-use-template.md

The plan should define these gates:

Gate A — Basic Mode Daily Use:
- first launch
- onboarding
- Command-drag separator placement
- collapse/expand
- reveal all
- always-hidden
- auto-rehide
- hover reveal
- hotkey
- sleep/wake
- display change
- force quit recovery
- Safe Mode
- reset layout
- diagnostics export
- no Accessibility prompt
- no network connection

Gate B — Pro Read-only:
- enable Pro Mode
- request Accessibility permission
- grant permission
- revoke permission
- scan refresh
- diagnostics table
- Find Icon
- highlight overlay
- permission degradation

Gate C — Pro Assisted:
- Second Bar
- profiles
- triggers paused/resumed
- URL automation
- conservative profile apply
- no silent bulk icon moves

Gate D — Icon Moving Experimental:
- disabled by default
- first-use warning
- local fixture item move
- third-party item move only after fixture pass
- own app item blocked
- system item blocked by default
- failed move recovers cleanly

Gate E — Installed Release:
- archive
- install to /Applications or private test location
- Launch at Login from installed app
- restart login test
- codesign verification
- notarization placeholder or real notarization when credentials are available
```

Acceptance criteria:

```text
- Dogfood docs exist.
- Gates clearly distinguish Basic, Pro read-only, Pro assisted, and experimental icon moving.
- Manual blockers from Phase 9.1 are converted into explicit test cases.
```

---

## Task 2 — Add local MenuBarFixtureApp target

```text
Add a debug/QA-only macOS helper target named MenuBarFixtureApp.

Purpose:
A local fixture app that creates many NSStatusItem menu bar items so MenuBarDeclutter can be tested against predictable real menu bar items.

Requirements:
1. Native macOS app.
2. LSUIElement = YES.
3. No Dock icon.
4. No network.
5. No Accessibility.
6. No Screen Recording.
7. No App Events.
8. Not included in Release distribution.
9. Only built manually or through QA scripts.

Fixture status items:
- Fixture Icon 1: icon-only, static.
- Fixture Icon 2: icon-only, static.
- Fixture Title 1: short text.
- Fixture Wide 1: long title.
- Fixture Dynamic 1: title updates every few seconds.
- Fixture Menu 1: opens simple menu.
- Fixture Badge 1: changes image/title state.
- Fixture Hidden Test 1: stable item for moving tests.
- Fixture Hidden Test 2: stable item for moving tests.
- Fixture Long Menu: item with multiple menu options.

Each item should have:
- accessibility label if possible.
- deterministic title/identifier where possible.
- simple menu showing item name and Quit Fixture.

Add fixture controls:
- Reset fixture items.
- Toggle dynamic updates.
- Add/remove extra noisy items.
- Quit Fixture.
```

Acceptance criteria:

```text
- MenuBarFixtureApp builds.
- Running it creates multiple real menu bar items.
- It can be used to test Basic Mode hiding.
- It can be used to test AX discovery.
- It can be used to test icon moving without touching real third-party apps.
```

---

## Task 3 — Add QA fixture scripts

```text
Create:
- scripts/qa_build_fixture.sh
- scripts/qa_run_fixture.sh
- scripts/qa_stop_fixture.sh
- scripts/qa_dogfood_preflight.sh

qa_build_fixture.sh:
- builds MenuBarFixtureApp.

qa_run_fixture.sh:
- launches MenuBarFixtureApp.
- prints instructions for dragging fixture items.

qa_stop_fixture.sh:
- terminates MenuBarFixtureApp safely.

qa_dogfood_preflight.sh:
- runs test suite.
- runs privacy verification.
- verifies release artifact if present.
- prints dogfood docs path.
- prints whether fixture app is running.
```

Acceptance criteria:

```text
- Scripts are executable.
- Scripts use set -euo pipefail.
- Scripts do not require network.
- Scripts do not collect screen contents.
```

---

## Task 4 — Add local dogfood mode

```text
Add a local-only Dogfood Mode setting.

Purpose:
Make manual QA easier without adding telemetry.

Settings:
- dogfoodModeEnabled: Bool default false
- dogfoodRunID: String?
- dogfoodNotesEnabled: Bool default true

Behavior:
When dogfood mode is enabled:
- Diagnostics shows current dogfood run ID.
- Diagnostics export includes dogfood run ID.
- Health report includes dogfood run ID.
- User can add a short local note from Diagnostics.
- Notes are stored locally in Application Support/MenuBarDeclutter/Dogfood/.
- No notes are uploaded.
- No screenshots are captured.
- No screen contents are captured.
- No live search query text is exported unless already privacy-safe/redacted.

Create:
- Dogfood/DogfoodRun.swift
- Dogfood/DogfoodStore.swift
- Dogfood/DogfoodNotesView.swift
```

Acceptance criteria:

```text
- Dogfood Mode is off by default.
- Enabling it changes only local diagnostics behavior.
- Export remains privacy-safe.
- Dogfood notes can be attached to a QA run.
```

---

## Task 5 — Add Basic Mode daily-use checklist inside Diagnostics

```text
Add a Diagnostics > Dogfood section.

It should show:
- current dogfood run ID.
- Basic Mode gate checklist.
- Pro Read-only gate checklist.
- Pro Assisted gate checklist.
- Icon Moving experimental gate checklist.
- buttons:
  - Start Dogfood Run
  - End Dogfood Run
  - Add Note
  - Export Dogfood Bundle

Export Dogfood Bundle should include:
- diagnostics export
- health report
- dogfood notes
- app version/build
- macOS version
- architecture
- display frames
- no screenshots
- no screen contents
- no network logs unless user manually attached a text file
```

Acceptance criteria:

```text
- Dogfood UI is useful during manual QA.
- Export is local-only.
- Export does not violate privacy boundary.
```

---

## Task 6 — Add fixture-aware tests where possible

```text
Add unit tests for fixture-independent logic.

Tests:
- DogfoodRun ID creation.
- DogfoodStore save/load.
- Dogfood export privacy rules.
- Dogfood checklist state transitions.
- Fixture app build settings if practical.
- QA script existence/executable bit if practical.
```

Acceptance criteria:

```text
- xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' passes.
- Existing 203+ tests remain passing.
- New tests do not require actually launching MenuBarFixtureApp.
```

---

## Task 7 — Add dogfood final report

```text
Create:
- docs/status/phase-9.2-final-report.md

The report should include:
- what changed.
- what did not change.
- confirmation that Phase 10 remains deferred.
- test results.
- fixture app status.
- dogfood docs status.
- remaining manual QA blockers.
- recommendation for Phase 9.3.
```

Acceptance criteria:

```text
- Final report exists.
- It clearly states whether the app is ready for private daily dogfood.
```

---

## Task 8 — Final validation commands

```text
Run and record:

1. xcodebuild -list
2. xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'
3. xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
4. xcodebuild build -scheme MenuBarFixtureApp -destination 'platform=macOS'
5. scripts/verify_privacy_boundary.sh
6. scripts/qa_dogfood_preflight.sh

If MenuBarFixtureApp cannot be added as a separate scheme safely, document the reason and create the fixture as a separate local Xcode target or standalone mini-project under tools/MenuBarFixtureApp/.
```

Acceptance criteria:

```text
- Main app builds/tests.
- Fixture app builds.
- Privacy verification passes.
- Dogfood preflight passes.
- Remaining manual work is documented.
```

---

# What Phase 9.2 should not do

```text
Do not add ScreenCaptureKit.
Do not add visual icon capture.
Do not add cloud sync.
Do not add telemetry.
Do not add automatic screenshots.
Do not add Apple Events.
Do not make icon moving default-on.
Do not silently run profile-based icon moves.
Do not rename final product identity yet unless the final name is chosen.
```

---

# After Phase 9.2

## Phase 9.3 — Signed / Notarized Installed-App Alpha

Do this only after the fixture and Basic dogfood gate are usable.

Main tasks:

```text
1. Archive Release build.
2. Developer ID sign.
3. Hardened runtime verification.
4. Notarization script with notarytool.
5. Staple notarization ticket.
6. Verify with spctl and codesign.
7. Install to /Applications.
8. Test Launch at Login from installed app.
9. Restart machine and confirm launch.
10. Confirm LSUIElement behavior from installed app.
11. Confirm URL scheme opens installed app.
12. Confirm no unexpected network connection.
```

This phase is where the release artifact becomes a real app, not just a build product.

---

## Phase 9.4 — Dogfood Bugfix + Stability Sprint

This phase should be driven by actual dogfood results.

Bug buckets:

```text
Basic Mode:
- separator placement
- collapse/expand
- auto-rehide timing
- hover flicker
- hotkey conflict
- display changes
- Safe Mode

Pro Read-only:
- AX stale data
- search mismatch
- highlight wrong frame
- permission revoke weirdness

Second Bar:
- wrong screen
- wrong placement
- keyboard focus
- item cache stale

Icon Moving:
- drag plan wrong
- verification false negative
- failed move not recovering
- item blocked incorrectly

Profiles/Triggers:
- trigger loops
- automation pause not respected
- profile apply confusion
```

The output should be a more stable **Alpha 2**.

---

## Phase 9.5 — v0.1 Basic Stable Freeze

This is the first version I would consider “stable enough” for your own daily use.

Scope:

```text
Must be excellent:
- Basic Mode
- onboarding
- settings
- diagnostics
- Safe Mode
- Launch at Login
- release install

Can remain optional:
- Pro Discovery
- Find Icon
- Second Bar

Should remain experimental:
- icon moving
- triggers
```

v0.1 should be positioned as:

```text
A privacy-first macOS 26+ menu bar decluttering utility.
Basic Mode is stable.
Pro Mode is optional.
Icon moving is experimental.
```

---

# My recommendation

Do this next:

```text
Phase 9.2 — Private Dogfood + Real-System QA Harness
```

The single most useful addition is the **MenuBarFixtureApp**. It gives you safe, repeatable, real menu bar items for testing collapse/expand, AX discovery, Find Icon, Second Bar, and icon moving before you risk your actual menu bar layout.

Only after Phase 9.2 proves Basic Mode in real daily use should you move to notarization and installed-app release testing.

