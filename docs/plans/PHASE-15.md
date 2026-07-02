
# Phase 15 — v0.1.2 Core Product Polish + Manual QA

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar decluttering utility written in Swift, AppKit, and SwiftUI.

This phase follows Phase 14. Phase 14 should have introduced the product diet direction:

- General
- Hide & Reveal
- Arrange
- Find & Rescue
- Privacy
- Recovery
- Advanced

This phase is `v0.1.2`, not v0.2.

Do not use `v0.2`, `0.2`, or `v0.2.0` in current-facing docs, UI, release notes, artifact names, package names, roadmap copy, or code comments. v0.2 is a future release and is intentionally not part of this execution pack.

## Version Target

Set the active app version to:

- Marketing version: `0.1.2`
- Build number: increment from `2` to `3`, unless the project has already advanced its build numbering.

Release artifacts should use:

- `MenuBarDeclutter-v0.1.2.zip`
- `MenuBarDeclutter-v0.1.2-alpha.zip` only if an alpha/dogfood packaging path still exists.

## Phase Mission

v0.1.2 is a focused polish and QA release.

The goal is not to add broad new power-user features. The goal is to make the post-Phase-14 product feel coherent, light, understandable, and manually validated.

Core v0.1.2 story:

> Hide clutter without sensitive permissions. Arrange icons safely. Find hidden items when needed. Recover if layout breaks.

By the end of v0.1.2:

1. The Settings UI should feel lighter.
2. Guided Arrange should feel like a first-class normal user flow.
3. Find & Rescue should feel like one coherent workflow.
4. The status menu should support everyday use without clutter.
5. Manual QA should cover real menu bar behavior, notch, external displays, Launch at Login, Safe Mode, and Pro permission flows.
6. Public docs should explain the product clearly without overclaiming.
7. Advanced/Preview/Labs/Experimental features should not dominate the product.

## Hard Rules

1. Do not call this v0.2.
2. Do not add Screen Recording.
3. Do not add ScreenCaptureKit.
4. Do not add Apple Events scripting/control.
5. Do not add Input Monitoring.
6. Do not add network access, telemetry, analytics, crash upload, cloud sync, remote config, or update checks.
7. Do not use private Apple menu bar APIs.
8. Do not silently prompt for Accessibility.
9. Do not make fully automated icon moving stable.
10. Do not expose bulk icon moving.
11. Do not make broad third-party menu item activation stable.
12. Do not expose Spacing Labs apply/restore/reset in the normal flow.
13. Do not move Smart Triggers, broad App Intents, URL automation, Private Access, competitor migration, or Spacing Labs back into the main product pillars.
14. Do not weaken Basic Mode, Safe Mode, privacy verification, diagnostics export, or recovery.
15. Keep assisted icon moving Experimental.
16. Keep Pro Accessibility Discovery opt-in.

## Initial Repository Checks

Run before making changes:

```bash
git status --short
xcodebuild -list -project MenuBar-Manager.xcodeproj
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
scripts/build_release.sh --dry-run
````

Create the progress file:

`docs/progress/phase-15-v0.1.2-core-polish-manual-qa.md`

Record:

* baseline git status
* baseline build/test results
* baseline privacy verification result
* baseline dry-run release result
* known failures or skipped manual gates
* exact date
* short phase goal

---

# Workstream 15.1 — Version and Release Identity

## Goal

Move the active release line from `0.1.1` to `0.1.2` cleanly.

## Tasks

1. Search for version references:

```bash
rg -n "0\.1\.1|v0\.1\.1|0\.1\.2|v0\.1\.2|0\.2|v0\.2|MARKETING_VERSION|CURRENT_PROJECT_VERSION|CFBundleShortVersionString|CFBundleVersion" .
```

2. Update active version/build values to:

* `0.1.2`
* build `3`

3. Update release scripts and docs that produce artifact names.

4. Add or update release notes:

`docs/release/v0.1.2-release-notes.md`

5. Add or update checklist:

`docs/release/v0.1.2-release-checklist.md`

6. Keep historical phase docs intact unless they confuse current release state.

7. Add a targeted guard in release docs:

> v0.1.2 is a polish and manual-QA release. It is not v0.2.

## Acceptance Criteria

* App bundle reports `0.1.2`.
* Build number is `3` or an explicitly documented next build number.
* Release zip names use `v0.1.2`.
* No current-facing docs or UI call this v0.2.

---

# Workstream 15.2 — Settings Diet Lock

## Goal

Make the simplified Phase 14 Settings structure stable and test-covered.

Expected top-level Settings sections:

1. General
2. Hide & Reveal
3. Arrange
4. Find & Rescue
5. Privacy
6. Recovery
7. Advanced

## Tasks

1. Inspect current Settings route model:

* `MenuBar-Manager/Settings/`
* `MenuBar-Manager/DesignSystem/`
* `MenuBar-Manager/App/`
* UI tests under `MenuBar-ManagerUITests/`

2. Ensure no old heavy sections appear as top-level routes:

* Private Access
* Groups
* Hotkeys
* Profiles
* Automation
* Import / Export
* Spacing Labs
* Icon Moving
* Dogfood

These may exist under Advanced only.

3. Add a route inventory test.

Suggested test:

* launch Settings in UI-test isolation
* verify top-level sections equal the expected seven
* verify Advanced contains nested Preview/Labs/Experimental items
* verify direct deep links still land correctly if supported

4. Add or update Settings route docs:

`docs/support/settings-overview.md`

5. Add visual clarity:

* Stable badge for core features
* Preview badge for Find & Rescue Pro surfaces
* Labs badge for Spacing Labs
* Experimental badge for Assisted Move
* Deferred/Internal labels where appropriate

6. Ensure main pages do not feel like long toggle lists.

Prefer:

* short explanation
* primary action
* status card
* secondary options collapsed under “More Options”
* link to Advanced for power-user surfaces

## Acceptance Criteria

* Settings top-level sidebar has exactly the simplified structure.
* Advanced contains heavy features.
* Main pages do not expose Labs/Experimental functionality as stable.
* UI smoke tests pass.
* Docs match the Settings structure.

---

# Workstream 15.3 — Guided Arrange Polish

## Goal

Make Arrange feel like a normal, safe, stable user workflow.

The user should understand how to arrange the menu bar without Pro, Accessibility, Screen Recording, screenshots, or automation.

## Stable Arrange Claims

Stable:

* command-drag guide
* control item explanation
* primary separator explanation
* hidden area explanation
* optional always-hidden area explanation
* test collapse/reveal
* reset layout
* recovery link

Preview:

* Pro Placement Planner

Experimental:

* Assisted Move

## Tasks

1. Inspect:

* `MenuBar-Manager/Settings/ArrangeSettingsView.swift`
* `MenuBar-Manager/Arrange/`
* `MenuBar-Manager/StatusBar/`
* `MenuBar-Manager/Hiding/`
* onboarding files under `MenuBar-Manager/Onboarding/`

2. Polish the Arrange page.

Required cards:

* “How menu bar hiding works”
* “Step 1: place the control item”
* “Step 2: place the separator”
* “Step 3: move clutter into the hidden area”
* “Step 4: test collapse”
* “Step 5: test reveal”
* “Optional: always-hidden area”
* “Need help? Reset layout or open Recovery”

3. Add simple app-owned SwiftUI diagrams.

Rules:

* no screenshots
* no screen capture
* no ScreenCaptureKit
* no live pixel sampling
* no private APIs

4. Add placement test buttons:

* Expand
* Collapse
* Reveal All
* Reset Layout
* Show Drag Hint

5. Add contextual warnings:

* “This uses normal macOS Command-drag behavior.”
* “MenuBarDeclutter does not directly control third-party menu extras in Basic Mode.”
* “Assisted Move is experimental and optional.”

6. Improve onboarding:

* native Apple cleanup step
* command-drag step
* test collapse/reveal step
* recovery/reset explanation

7. Add status menu route:

* `Arrange Items…`

It should open Settings directly to Arrange.

8. Add tests:

* Arrange page renders
* buttons are present
* no Pro required
* no Accessibility prompt
* status menu route opens Arrange
* onboarding arrange step renders
* diagrams do not depend on screenshots

## Acceptance Criteria

* Arrange is understandable without reading docs.
* Arrange works in Basic Mode.
* Arrange does not request Accessibility.
* User can test collapse/reveal from the Arrange page.
* Assisted Move is visible only as Experimental.
* UI tests cover the route.

---

# Workstream 15.4 — Find & Rescue Polish

## Goal

Make Find Icon, Second Bar, New Item Inbox, and Crowded Rescue feel like one coherent workflow.

This is not a broad new feature phase. It is a polish and consolidation phase.

## Tasks

1. Inspect:

* `MenuBar-Manager/Search/`
* `MenuBar-Manager/SecondBar/`
* `MenuBar-Manager/Arrange/`
* `MenuBar-Manager/Layout/`
* `MenuBar-Manager/Groups/`
* `MenuBar-Manager/CommandCenter/`
* `MenuBar-Manager/Settings/FindAndRescueSettingsView.swift`

2. Polish the Find & Rescue page.

Required cards:

* Pro Discovery status
* Find Icon
* Second Bar
* New Items
* Crowded Reveal fallback
* Collections / lightweight groups
* Item actions

3. Reduce terminology overload.

Preferred user-facing terms:

* “Find hidden icons”
* “Second Bar”
* “New Items”
* “Collections”
* “Crowded menu rescue”

Avoid overemphasizing:

* Command Center
* trigger runtime
* automation router
* metadata snapshot details
* zone classification internals

4. Find Icon polish:

* fast opening
* clear empty state
* clear Pro off state
* clear Accessibility missing state
* keyboard navigation visible in help text
* recents/favorites visible only if useful
* no live query in diagnostics

5. Second Bar polish:

* labels/density defaults are sane
* placement state is explained
* unavailable states are clear
* “This uses app icons and metadata, not screenshots” copy appears where appropriate

6. New Item Inbox polish:

* only visible when Pro Discovery is available or when explaining why unavailable
* no spammy notification
* review/dismiss/reset actions
* integration with Arrange and Find Icon

7. Crowded Rescue polish:

* simple preference choices:

  * try inline first
  * open Second Bar when crowded
  * ask before switching
  * use Full Menu Bar Mode
* move advanced capacity details under Advanced

8. Add tests:

* Find & Rescue page renders
* Pro unavailable state renders
* Find Icon opens from page
* Second Bar opens from page
* New Item Inbox count appears only when applicable
* Crowded Rescue preferences persist
* diagnostics redaction for query and item identity

## Acceptance Criteria

* Find & Rescue feels like one product surface.
* Find Icon and Second Bar are easy to discover.
* New Item Inbox is understandable but not noisy.
* Crowded Rescue no longer feels like a separate layout science project.
* Tests pass.

---

# Workstream 15.5 — Status Menu Simplification

## Goal

Make the everyday menu bar status menu short, useful, and aligned with the focused product story.

## Recommended Default Status Menu

Primary:

* Hide Menu Bar Items
* Show Menu Bar Items
* Reveal All
* Arrange Items…
* Find Icon…
* Show Second Bar
* Full Menu Bar Mode
* Settings…
* Recovery
* Diagnostics
* Quit

Conditional:

* Review New Items…, only if Pro Discovery is enabled and inbox has items
* Advanced submenu, only when advanced features are enabled or relevant

Advanced submenu:

* Apply Profile
* Pause Automation
* Spacing Labs
* Assisted Move tools
* Dogfood/internal tools

## Tasks

1. Inspect:

* `MenuBar-Manager/StatusBar/`
* status menu presenter
* status menu tests
* `AppEnvironment` callbacks

2. Remove or nest rarely used advanced actions from the default menu.

3. Add `Arrange Items…`.

4. Add conditional `Review New Items…`.

5. Add disabled-state explanations for:

* Pro off
* Accessibility missing
* Safe Mode active
* feature disabled
* Labs off
* Experimental disabled

6. Make Safe Mode menu recovery-first:

* Show MenuBarDeclutter
* Reset Layout
* Open Settings
* Export Diagnostics
* Quit

7. Add tests:

* default menu contains focused actions
* Advanced submenu appears only when needed
* Arrange route works
* Review New Items row appears only with inbox count
* Safe Mode menu is recovery-first

## Acceptance Criteria

* Status menu is not overloaded.
* Arrange and Find & Rescue are first-class.
* Advanced features do not clutter normal use.
* Safe Mode status menu remains simple.

---

# Workstream 15.6 — Pro Setup and Permission Explanation Polish

## Goal

Make Pro setup trustworthy and understandable.

Pro should not feel like a scary mode switch. It should feel like an optional capability that powers Find & Rescue and Placement Planner.

## Tasks

1. Inspect:

* `MenuBar-Manager/Permissions/`
* `MenuBar-Manager/Accessibility/`
* `MenuBar-Manager/Settings/Privacy`
* `MenuBar-Manager/Settings/FindAndRescue`
* `MenuBar-Manager/Settings/Arrange`

2. Add or polish Pro setup panel.

It should explain:

* Pro Mode is optional.
* Accessibility Discovery is optional.
* macOS Accessibility permission is requested only by explicit user action.
* The app reads menu bar metadata.
* The app does not read pixels.
* The app does not use Screen Recording.
* The app does not use ScreenCaptureKit.
* The app does not use network telemetry.

3. Make the setup flow explicit:

* Enable Pro Mode
* Enable Accessibility Discovery
* Open Accessibility Settings / Request Permission
* Rescan
* Confirm Find & Rescue availability

4. Add a “Turn Pro Off” path.

5. Add degraded-state copy for:

* Find Icon
* Second Bar
* Placement Planner
* New Item Inbox
* Assisted Move

6. Add tests:

* no prompt on launch
* no prompt when opening Settings
* explicit permission action is required
* Pro off degraded states render
* Accessibility revoked degraded states render
* privacy docs text remains accurate

## Acceptance Criteria

* Pro setup is understandable.
* No silent Accessibility prompt.
* Privacy boundary remains strong.
* Pro features degrade gracefully.
* Tests pass.

---

# Workstream 15.7 — Recovery and “I Lost My Icons” Flow

## Goal

Make recovery user-facing, not just internal diagnostics.

A user should know what to do when icons look wrong, the control item is hard to find, or layout breaks.

## Tasks

1. Inspect:

* `MenuBar-Manager/Health/`
* `MenuBar-Manager/Diagnostics/` if present
* `MenuBar-Manager/Settings/Recovery`
* `MenuBar-Manager/StatusBar/`
* `docs/support/`

2. Add a Recovery page with clear actions:

* Expand / Reveal All
* Reset Layout
* Recreate Status Items
* Disable Pro Temporarily
* Disable Hover/Auto-rehide Temporarily
* Enter Safe Mode on next launch
* Export Diagnostics
* Open Troubleshooting Guide

3. Add an “I can’t find my icons” guide.

Suggested doc:

`docs/support/i-cant-find-my-icons.md`

4. Add in-app copy:

* “MenuBarDeclutter uses your menu bar layout. If items appear missing, start with Reveal All or Reset Layout.”
* “Safe Mode starts expanded and disables optional behaviors.”

5. Add tests:

* Recovery page renders
* Reset Layout action calls existing service
* Safe Mode request persists one-shot flag
* diagnostics export remains redacted
* Safe Mode suppresses optional surfaces

## Acceptance Criteria

* User can recover from confusing layout without reading source docs.
* Recovery is visible in Settings and status menu.
* Safe Mode remains permission-free.
* Diagnostics remain privacy-safe.

---

# Workstream 15.8 — Visual UI Polish Pass

## Goal

Make the app feel like a native macOS utility rather than a developer control panel.

This is a design polish pass, not a theme engine.

## Tasks

1. Inspect existing design docs:

* `docs/design/hig-native-2026-06-30/`
* `docs/design/redesign-2026-06/`
* `MenuBar-Manager/DesignSystem/`
* Settings page components

2. Apply consistent page structure:

* page title
* short subtitle
* primary status card
* primary actions
* secondary settings
* advanced disclosure
* footer help link where useful

3. Reduce visual noise:

* avoid long lists of raw toggles
* group related options
* hide developer/debug detail behind disclosure
* use clear Stable/Preview/Labs/Experimental badges
* avoid repeating permission warnings excessively

4. Polish panels:

* Find Icon
* Second Bar
* New Items
* Recovery
* Arrange

5. Add accessibility labels for important buttons.

6. Avoid adding decorative styling/theme engine.

7. Update UI snapshots or smoke tests if the project uses them.

## Acceptance Criteria

* Main Settings pages are visually consistent.
* Feature status badges are consistent.
* Advanced sections are discoverable but not noisy.
* UI tests pass.
* No new privacy-sensitive APIs are introduced.

---

# Workstream 15.9 — Manual System QA Execution

## Goal

Turn manual QA from a checklist into actual v0.1.2 release evidence.

## Tasks

1. Update or create:

`docs/testing/manual-v0.1.2-system-qa.md`

2. Add a result record:

`docs/testing/manual-v0.1.2-results.md`

3. Execute or prepare exact steps for:

### Basic Live Menu Bar

* command-drag control
* command-drag separator
* collapse
* expand
* reveal all
* always-hidden reveal
* reset layout

### Arrange

* guided flow
* diagrams readable
* placement test buttons
* no permission prompt

### Find & Rescue

* Find Icon
* Second Bar
* New Item Inbox with fixture app
* crowded fallback

### Pro Permission

* Pro off
* Discovery off
* grant Accessibility
* revoke Accessibility
* restart app
* degraded states

### Notch / Crowded

* notch MacBook if available
* many third-party items
* long app menus
* Second Bar fallback

### External Displays

* attach
* detach
* switch main display
* mirror mode
* sleep/wake after display change

### Launch at Login

* install app to `/Applications`
* enable Launch at Login
* logout/login
* restart if possible
* disable Launch at Login

### Recovery

* Safe Mode by Option launch
* one-shot Safe Mode flag
* crash marker recovery
* reset layout

### Installed App

* dry-run install
* installed app verification
* no-network watch
* URL scheme smoke
* diagnostics export

4. Record Pass / Fail / Blocked / Deferred for each.

5. Any failing stable claim must be fixed or downgraded.

## Acceptance Criteria

* Manual QA docs exist.
* Results are recorded.
* Stable claims have evidence.
* Blocked items are clearly listed.
* v0.1.2 release checklist links to QA results.

---

# Workstream 15.10 — Release Docs and Support Docs

## Goal

Make v0.1.2 easy to understand, install, use, recover, and uninstall.

## Update or Create

* `README.md`
* `docs/release/v0.1.2-release-notes.md`
* `docs/release/v0.1.2-release-checklist.md`
* `docs/release/v0.1.2-known-limitations.md`
* `docs/support/settings-overview.md`
* `docs/support/arrange-menu-bar-items.md`
* `docs/support/i-cant-find-my-icons.md`
* `docs/support/permissions.md`
* `docs/support/safe-mode.md`
* `docs/support/troubleshooting.md`
* `docs/support/uninstall.md`
* `docs/features/find-rescue-v0.1.2.md`
* `docs/features/arrange-v0.1.2.md`

## Required Messaging

Use this product message:

> MenuBarDeclutter is a privacy-first menu bar declutter tool. Hide clutter without sensitive permissions, arrange icons safely, find hidden items when needed, and recover if layout breaks.

Explain:

* Basic Mode is stable.
* Guided Manual Arrange is stable.
* Find Icon and Second Bar require Pro Discovery.
* Pro Discovery uses Accessibility metadata only.
* No Screen Recording.
* No ScreenCaptureKit.
* No network telemetry.
* Assisted Move remains Experimental.
* Spacing Labs remains Labs/Advanced.
* Smart Triggers and broad automation are Advanced/Preview.
* v0.1.2 is not v0.2.

## Acceptance Criteria

* Docs match app UI.
* Docs do not overclaim.
* No current-facing v0.2 references.
* User can recover using docs alone.

---

# Workstream 15.11 — Final Validation

## Required Commands

Run:

```bash
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
```

Run targeted searches:

```bash
rg -n "v0\.2|0\.2\.0" README.md docs MenuBar-Manager scripts Config || true
rg -n "ScreenCaptureKit|NSScreenCaptureUsageDescription|NSAppleEventsUsageDescription|InputMonitoring|URLSession|NWConnection|analytics|telemetry|Sentry|Firebase" MenuBar-Manager Config scripts docs || true
rg -n "stable automated move|stable icon moving|bulk move|screen capture|pixel capture|Screen Recording" README.md docs MenuBar-Manager || true
rg -n "Private Access.*encrypt|Private Access.*hide.*third-party|Touch ID.*hide.*visible" README.md docs MenuBar-Manager || true
```

Inspect results manually. Fix current-facing overclaims. Historical docs may remain only if clearly historical.

## Acceptance Criteria

* All required commands pass or failures are documented and clearly non-blocking.
* Privacy boundary passes.
* Dry-run release works.
* Installed-app verification works.
* v0.1.2 docs are accurate.
* Phase progress file records final results.

---

# v0.1.2 Definition of Done

v0.1.2 is complete when:

1. App version is `0.1.2`.
2. Current-facing docs/UI do not reference v0.2.
3. Settings top-level sidebar is simplified and test-covered.
4. Arrange is polished and useful without Pro.
5. Find & Rescue is polished and coherent.
6. Status menu is simplified.
7. Pro setup explanation is clear and explicit.
8. Recovery and “I lost my icons” flow are visible.
9. Manual QA matrix and results exist.
10. Stable public claims have supporting QA or tests.
11. Advanced/Preview/Labs/Experimental features are nested and clearly labeled.
12. Assisted Move remains Experimental.
13. Privacy boundary remains intact.
14. Release dry-run and installed-app verification pass.
15. `docs/progress/phase-15-v0.1.2-core-polish-manual-qa.md` includes:

    * summary
    * changed files
    * test results
    * manual QA results
    * known limitations
    * deferred work for v0.1.3

---

# Suggested Execution Order

## v0.1.2 slices

Use these as smaller Codex tasks.

### v0.1.2-A — Version + Settings Diet Lock

```markdown
Implement v0.1.2-A only:
- bump version to 0.1.2 build 3
- update release artifact naming
- lock Settings sidebar to General, Hide & Reveal, Arrange, Find & Rescue, Privacy, Recovery, Advanced
- move heavy surfaces under Advanced
- update UI tests and docs
- do not add new power features
- do not mention v0.2
````

### v0.1.2-B — Guided Arrange Polish

```markdown
Implement v0.1.2-B only:
- polish Arrange page
- add command-drag guide diagrams using SwiftUI only
- add placement test actions
- add status menu “Arrange Items…”
- connect onboarding to Arrange
- add tests
- no Pro required
- no Accessibility prompt
```

### v0.1.2-C — Find & Rescue Polish

```markdown
Implement v0.1.2-C only:
- polish Find & Rescue page
- improve Find Icon, Second Bar, New Item Inbox, Crowded Rescue cards
- reduce terminology overload
- add clear Pro unavailable states
- add tests for page rendering, preferences, and privacy redaction
```

### v0.1.2-D — Status Menu + Recovery + Pro Setup

```markdown
Implement v0.1.2-D only:
- simplify status menu
- add recovery-first Safe Mode menu
- polish Pro setup and permission explanation
- add “I can’t find my icons” recovery flow
- add tests
```

### v0.1.2-E — Manual QA + Docs + Validation

```markdown
Implement v0.1.2-E only:
- update manual QA matrix and result docs
- update release notes/support docs
- run full validation commands
- record final results in phase progress doc
```