
# Phase 22 — v0.1.9 Workspace MVP Design RC + QA Freeze

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar decluttering utility written in Swift, AppKit, and SwiftUI.

This phase follows:

- Phase 17 / v0.1.4 Workspaces Foundation
- Phase 18 / v0.1.5 Set Switcher + Virtual Function Bar MVP
- Phase 19 / v0.1.6 Linked Groups + Set Builder MVP
- Phase 20 / v0.1.7 Info Strip MVP
- Phase 21 / v0.1.8 Workspace Integration Pack

The active release line for this phase is:

`v0.1.9`

This phase is **not v0.2**.

Phase 22 is the v0.2 design-release candidate foundation. It may prepare v0.2 scope, claims, QA evidence, and UI readiness, but it must not bump the app to v0.2, create v0.2 artifacts, or claim v0.2 has shipped.

## Phase Mission

Phase 22 turns the Workspace MVP into a coherent release candidate.

The goal is:

> Make MenuBarDeclutter feel like a polished privacy-first menu bar workspace app, not a collection of preview modules.

By the end of Phase 22:

1. The main product information architecture is finalized for the upcoming v0.2 release.
2. Workspaces becomes a polished top-level Preview section, while still not claiming stable v0.2 release status.
3. Function Bar, Set Builder, Linked Groups, Info Strip, Find & Rescue, Arrange, and Recovery feel connected.
4. First-run onboarding explains the full product flow:
   - native Apple cleanup
   - manual menu bar arrangement
   - Basic hide/reveal
   - Find & Rescue
   - Workspaces
   - Function Bar
   - Linked Groups
   - optional Info Strip
   - Recovery
   - privacy boundary
5. The app has a clean visual design pass for macOS 26-style native UI.
6. Preview/Labs/Experimental statuses are consistent and honest.
7. Public claims for the future v0.2 release are frozen in docs.
8. Manual QA is expanded and recorded.
9. Privacy boundary is re-verified.
10. Release dry-run and installed-app validation pass.
11. Developer ID / notarization path is rehearsed if credentials exist, or clearly documented as externally blocked.
12. Basic Mode remains stable and permission-free.

Phase 22 should avoid adding large new feature pillars. This is a design, polish, QA, documentation, and release-readiness phase.

## Product Story After Phase 22

Use this product story:

> MenuBarDeclutter is a privacy-first menu bar declutter and workspace tool. Hide clutter without sensitive permissions, arrange icons safely, find hidden items when needed, create menu bar workspaces with reusable groups, show a lightweight Function Bar or Info Strip, and recover if layout breaks.

## Version Target

Set active app version to:

- Marketing version: `0.1.9`
- Build number: increment from `9` to `10`, unless the project has already advanced build numbering.

Release artifacts should use:

- `MenuBarDeclutter-v0.1.9.zip`
- `MenuBarDeclutter-v0.1.9-alpha.zip` only if alpha/dogfood packaging still exists.

Do not create:

- `MenuBarDeclutter-v0.2.zip`
- `MenuBarDeclutter-v0.2.0.zip`
- v0.2 release package
- v0.2 notarization artifact
- v0.2 release notes as current shipped release

It is acceptable to create a future-scope document such as:

- `docs/release/v0.2-scope-freeze-draft.md`
- `docs/release/v0.2-public-claims-draft.md`

Those docs must clearly say **draft / future / not shipped**.

## Current Project Facts

- Product name: `MenuBarDeclutter`
- Xcode project: `MenuBar-Manager.xcodeproj`
- Canonical scheme: `MenuBarDeclutter`
- Compatibility scheme: `MenuBar-Manager`
- Local fixture scheme: `MenuBarFixtureApp`
- Bundle ID: `Yongjun-Zhang.MenuBarDeclutter`
- Deployment target: macOS `26.0`
- Swift version: `6.0`
- Runtime: `LSUIElement`
- App sandbox and hardened runtime are enabled.
- Existing app URL scheme: `menubardeclutter://`
- Basic Mode remains stable and permission-free.
- Workspaces, Function Bar, Set Builder, Linked Groups, Info Strip, and Workspace Integration are Preview before v0.2.
- Icon Moving remains Experimental.
- Spacing Labs remains Labs.
- Smart Triggers and broad automation remain Advanced/Preview.

## Hard Rules

1. Do not bump app version to v0.2.
2. Do not create v0.2 shipped release artifacts.
3. Do not add Screen Recording.
4. Do not add ScreenCaptureKit.
5. Do not add Apple Events scripting/control.
6. Do not add Input Monitoring.
7. Do not add network access, telemetry, analytics, crash upload, cloud sync, remote config, update checks, or license checks.
8. Do not add weather/news/stocks/online widgets.
9. Do not add media controls that require private APIs.
10. Do not scrape Notification Center.
11. Do not use private Apple menu bar APIs.
12. Do not silently prompt for Accessibility, Calendar, Reminders, or any other permission.
13. Do not claim Workspaces replace the macOS menu bar.
14. Do not claim Function Bar is a live clone of system menu bar icons.
15. Do not claim Info Strip is a Dynamic Island clone.
16. Do not make physical workspace switching stable.
17. Do not automatically apply physical profiles when switching Workspace.
18. Do not implement bulk icon moving.
19. Do not make Assisted Move stable.
20. Do not expose broad third-party menu item activation as stable.
21. Do not mutate real menu bar layout from Workspaces, Function Bar, Info Strip, Set Builder, Find Icon, Placement Planner, New Item Inbox, or Crowded Rescue.
22. Do not promote Spacing Labs into the normal user flow.
23. Do not promote Smart Triggers into the normal user flow.
24. Do not promote competitor import as stable.
25. Diagnostics must not export raw workspace names, raw workspace item names, raw menu bar item identities, protected group names, protected workspace names, calendar event titles, reminder titles, live search text, drag payload values, or file paths by default.

---

# Initial Repository Checks

Before making changes, run:

```bash
git status --short
xcodebuild -list -project MenuBar-Manager.xcodeproj
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
````

Create the progress file immediately:

`docs/progress/phase-22-v0.1.9-workspace-mvp-design-rc.md`

Record:

* baseline git status
* baseline version/build
* baseline test results
* baseline privacy verification result
* baseline release dry-run result
* baseline installed-app verification result
* known limitations from Phase 21
* exact date
* short phase goal

---

# Workstream 22.1 — Version and Release Identity

## Goal

Move the active release line from `0.1.8` to `0.1.9`.

## Tasks

1. Search version references:

```bash
rg -n "0\.1\.8|v0\.1\.8|0\.1\.9|v0\.1\.9|0\.2|v0\.2|MARKETING_VERSION|CURRENT_PROJECT_VERSION|CFBundleShortVersionString|CFBundleVersion" .
```

2. Update active version/build values to:

* `0.1.9`
* build `10`

3. Update release artifact naming.

4. Add release notes placeholder:

`docs/release/v0.1.9-release-notes.md`

5. Add release checklist:

`docs/release/v0.1.9-release-checklist.md`

6. Add v0.2 draft docs only if clearly marked draft/future:

```text
docs/release/v0.2-scope-freeze-draft.md
docs/release/v0.2-public-claims-draft.md
docs/release/v0.2-known-limitations-draft.md
```

7. Do not create v0.2 shipped release docs.

8. Update latest-progress docs that list current release line.

9. If historical docs mention v0.2, leave them only if clearly historical/future.

## Acceptance Criteria

* App bundle reports `0.1.9`.
* Build number is `10` or documented next build number.
* Release artifacts use `v0.1.9`.
* Current shipped-release docs/UI do not call this v0.2.
* v0.2 docs, if created, are clearly draft/future.
* Release dry-run still works.

---

# Workstream 22.2 — Product Scope Freeze and Feature Status Audit

## Goal

Freeze the feature scope that will become the future v0.2 Workspace MVP.

This workstream prevents scope creep.

## Feature Status Categories

Use existing categories consistently:

* Stable
* Preview
* Labs
* Experimental
* Deferred
* Internal

## Stable in v0.1.9

Stable claims should remain:

* Basic hide/show/reveal
* app-owned control item and separator behavior
* Guided Manual Arrange
* auto-rehide
* hover reveal
* Basic global hotkey
* always-hidden zone
* Launch at Login opt-in
* Safe Mode / recovery
* diagnostics export
* privacy boundary
* local backup if fully tested

## Preview in v0.1.9

Preview claims:

* Workspaces
* Function Bar
* Set Switcher
* Set Builder
* Linked Groups
* Detached Group Copies
* Info Strip local tiles
* Workspace-aware Find Icon
* Workspace-aware New Item Inbox assignment
* Workspace-aware Placement Planner
* Crowded Rescue Function Bar fallback
* Workspace physical profile dry-run
* basic Shortcuts actions if already validated

## Labs in v0.1.9

Labs:

* Menu Bar Spacing Labs
* any global defaults mutation
* any risky layout experiment

## Experimental in v0.1.9

Experimental:

* Assisted Move actual execution
* broad icon activation if present
* physical icon movement beyond manual guidance
* group status items if not fully proven

## Deferred Beyond v0.2

Keep deferred:

* ScreenCaptureKit visual capture
* Screen Recording
* online widgets
* weather/news/stocks/RSS widgets
* media controls requiring private APIs
* notification scraping
* file shelf
* stable competitor import
* stable bulk physical workspace switching
* stable broad third-party item activation
* cloud sync
* telemetry
* theme engine

## Tasks

1. Audit all Settings pages.
2. Audit README and feature docs.
3. Audit release docs.
4. Audit status menu copy.
5. Audit onboarding copy.
6. Audit Command Center action labels.
7. Audit diagnostics labels.
8. Ensure every Preview/Labs/Experimental surface is labeled consistently.
9. Create or update:

```text
docs/release/v0.1.9-feature-status-audit.md
docs/release/v0.2-scope-freeze-draft.md
docs/release/v0.2-public-claims-draft.md
```

## Acceptance Criteria

* No feature is overclaimed.
* No Preview feature is described as Stable.
* No v0.2 shipped-release claim appears.
* Scope freeze docs exist.
* Docs and UI use the same status vocabulary.

---

# Workstream 22.3 — Final Information Architecture

## Goal

Finalize the app’s information architecture before v0.2.

## Target Main Settings Sidebar

Use this structure:

1. General
2. Hide & Reveal
3. Arrange
4. Find & Rescue
5. Workspaces
6. Privacy
7. Recovery
8. Advanced

## Section Responsibilities

### General

* app version
* Launch at Login
* startup behavior
* onboarding reset
* basic app preferences

### Hide & Reveal

* collapse/expand/reveal
* always-hidden zone
* auto-rehide
* hover reveal
* Basic hotkey
* Full Menu Bar Mode, if still part of Basic flow

### Arrange

* manual command-drag guide
* control/separator placement
* placement test
* Placement Planner Preview
* Assisted Move Experimental entry point
* physical arrangement boundaries

### Find & Rescue

* Find Icon
* Second Bar
* New Item Inbox
* Workspace filters
* crowded rescue
* item actions
* open owner app
* reveal/highlight

### Workspaces

This becomes a top-level Preview section in v0.1.9.

Include:

* active Workspace
* Workspace list
* Function Bar preview
* Set Builder
* Linked Groups
* Info Strip
* Workspace integration dashboard
* physical profile binding Preview
* backup/restore links
* Preview badge

### Privacy

* privacy boundary
* Basic vs Pro
* Accessibility explanation
* no Screen Recording
* no ScreenCaptureKit
* no network
* diagnostics redaction
* optional Calendar/Reminder tiles explanation if implemented

### Recovery

* health
* Safe Mode
* reset layout
* reset Workspaces
* clean missing references
* export diagnostics
* backup settings
* troubleshooting links

### Advanced

Keep here:

* Smart Triggers
* dynamic hotkeys beyond core
* broad automation
* App Intents advanced actions
* URL automation
* Private Access
* Spacing Labs
* Icon Moving internals
* migration assistant
* dogfood/internal tools
* developer tools

## Tasks

1. Refactor Settings route model.
2. Move Workspaces from Advanced-only into top-level Preview section.
3. Keep Advanced entry for deeper power-user settings.
4. Add transition redirects from old routes to new routes if route IDs are persisted or URL-addressable.
5. Update UI tests.
6. Update docs:

```text
docs/support/settings-overview.md
docs/design/v0.1.9-information-architecture.md
```

## Acceptance Criteria

* Settings sidebar matches target structure.
* Workspaces is top-level but clearly Preview.
* Advanced no longer hides the main Workspace MVP.
* Heavy Labs/Experimental surfaces remain Advanced.
* Route tests pass.
* Docs match UI.

---

# Workstream 22.4 — Workspaces Landing Page Polish

## Goal

Create a polished top-level Workspaces page that explains the Workspace MVP.

## Page Structure

The Workspaces page should include:

1. Header:

   * “Workspaces”
   * Preview badge
   * one-sentence explanation

2. Active Workspace card:

   * active name/icon
   * Function Bar status
   * Info Strip status
   * item count
   * linked group count
   * new/unassigned item count
   * profile binding status

3. Quick actions:

   * Show Function Bar
   * Show Info Strip
   * Open Set Builder
   * Review New Items
   * Create Workspace
   * Duplicate Workspace

4. Workspace list:

   * name/icon
   * active indicator
   * item count
   * group count
   * Info Strip enabled state
   * profile binding badge
   * missing reference badge

5. Workspace Builder entry:

   * short explanation
   * open builder

6. Linked Groups card:

   * total groups
   * used in workspaces count
   * “Edit Groups” action
   * explanation of linked vs detached

7. Info Strip card:

   * selected tiles
   * idle/hover behavior
   * preview action

8. Integration health card:

   * missing references
   * unassigned items
   * stale proxies
   * open Recovery action

## Copy

Must say:

> Workspaces configure MenuBarDeclutter’s app-owned Function Bar and Info Strip. They do not replace or control the macOS system menu bar.

## Tests

Add UI tests:

* Workspaces top-level route renders.
* Preview badge visible.
* Active Workspace card renders.
* Show Function Bar action works.
* Show Info Strip action works.
* Set Builder action works.
* Linked Groups card renders.
* Info Strip card renders.
* Integration health card renders.
* No Accessibility prompt appears.

## Acceptance Criteria

* Workspaces page is polished and understandable.
* It is clearly Preview in v0.1.9.
* Users can reach main Workspace actions in one place.
* UI tests pass.

---

# Workstream 22.5 — Onboarding v2

## Goal

Rewrite onboarding around the final product story.

## Required Onboarding Flow

1. Welcome

   * privacy-first menu bar declutter and workspace tool

2. Native Apple cleanup

   * open Apple Menu Bar / Control Center settings
   * explain complementary role

3. Basic Hide & Reveal

   * app-owned control item
   * separator
   * hide/reveal concept

4. Arrange

   * command-drag guide
   * test collapse/reveal
   * reset layout

5. Find & Rescue

   * Find Icon
   * Second Bar
   * New Item Inbox
   * Pro Discovery explanation

6. Workspaces

   * create different menu bar workspaces
   * Function Bar
   * Linked Groups
   * Info Strip

7. Privacy Boundary

   * Basic needs no Accessibility
   * Pro Discovery is optional
   * no Screen Recording
   * no ScreenCaptureKit
   * no network telemetry

8. Recovery

   * Safe Mode
   * reset layout
   * export diagnostics

9. Finish

   * open Settings
   * open Arrange
   * create first Workspace
   * skip advanced setup

## Requirements

* Do not prompt for Accessibility automatically.
* Do not prompt for Calendar/Reminder permissions automatically.
* Do not enable Preview/Labs/Experimental features automatically.
* Offer “Create a sample Workspace” only if it creates app-owned local config and no permissions.
* Offer “Enable Pro Discovery” only as an explicit optional step.

## Optional Sample Workspace

If implemented:

* `Default`
* `Focus`
* `Meeting`

Items should be safe commands only:

* Find Icon
* Show Second Bar
* Reveal All
* Open Recovery

No raw third-party item references by default.

## Tests

Add UI tests:

* onboarding flow renders.
* native cleanup step renders.
* Arrange step renders.
* Workspaces step renders.
* Privacy step renders.
* Skip flow works.
* Create sample Workspace does not request permissions.
* Finish opens correct route.

## Acceptance Criteria

* Onboarding explains the product in a coherent order.
* No silent permission prompts.
* Preview features remain opt-in.
* Tests pass.

---

# Workstream 22.6 — Function Bar Polish

## Goal

Polish Function Bar for v0.2 readiness.

## Tasks

1. Improve visual consistency:

   * compact capsule layout
   * clear item spacing
   * dark/light mode support
   * hover/focus states
   * active Workspace label
   * Preview badge, subtle

2. Improve behavior:

   * fast open/close
   * no flicker
   * Escape closes
   * outside click closes if enabled
   * keyboard navigation
   * Set Switcher smoothness
   * “More” overflow for many items

3. Improve item states:

   * missing
   * stale
   * protected
   * linked group
   * detached group
   * new
   * unassigned
   * requires Pro
   * requires Accessibility

4. Improve action feedback:

   * command success
   * unavailable
   * blocked by Safe Mode
   * requires Pro
   * stale proxy
   * protected/locked

5. Improve placement:

   * below icon
   * near mouse
   * last position
   * external display
   * notch estimate
   * menu bar auto-hide edge cases

## Tests

Add or update:

* Function Bar visual state unit tests.
* placement tests.
* keyboard action tests.
* overflow tests.
* Safe Mode tests.
* protected/missing/stale state tests.

## Acceptance Criteria

* Function Bar feels usable as a daily Preview feature.
* It does not look like a system menu bar replacement.
* Edge states are understandable.
* Tests pass.

---

# Workstream 22.7 — Info Strip Polish

## Goal

Make Info Strip feel like a lightweight companion to Function Bar.

## Tasks

1. Polish panel:

   * compact tile layout
   * progress/rotation indicator
   * severity styling
   * hover target
   * click behavior
   * empty state
   * Preview badge

2. Polish rotation:

   * no fast loops
   * skip unavailable tiles
   * manual next tile
   * pause when Function Bar pinned
   * pause in Safe Mode
   * reset timer on Workspace switch

3. Polish local tiles:

   * Current Workspace
   * Clock
   * Battery
   * Hidden Count
   * New Items Count
   * Recovery Warning
   * Stale Scan Warning

4. Optional Calendar/Reminder tiles:

   * remain disabled unless explicitly implemented safely
   * no automatic prompt
   * redacted diagnostics

5. Polish hover-to-Function-Bar:

   * no flicker
   * consistent delay
   * no global event tap
   * no Input Monitoring

## Tests

Add or update:

* Info Strip view tests.
* rotation tests.
* hover state machine tests.
* tile provider tests.
* diagnostics redaction tests.
* Safe Mode tests.

## Acceptance Criteria

* Info Strip is useful and not distracting.
* It remains local/no-network.
* Hover-to-Function-Bar behavior is stable.
* Tests pass.

---

# Workstream 22.8 — Set Builder and Linked Groups Polish

## Goal

Make Set Builder understandable enough for v0.2 MVP.

## Tasks

1. Improve Set Builder layout:

   * clearer Workspace list
   * clearer Function Bar canvas
   * clearer Library
   * clearer Inspector
   * better empty states

2. Improve item editing:

   * add command
   * add menu bar proxy
   * add group
   * add spacer/divider
   * reorder
   * remove
   * duplicate
   * commit/revert

3. Improve Linked Group UX:

   * clear linked badge
   * clear detached badge
   * “used in N Workspaces”
   * warning when editing linked Group used in multiple Workspaces
   * detach copy action
   * explain effect before edit

4. Improve menu bar proxy library:

   * Pro unavailable state
   * Accessibility missing state
   * stale scan state
   * no automatic permission prompt

5. Improve draft handling:

   * dirty indicator
   * commit confirmation if major changes
   * revert action
   * autosave draft status if implemented

## Tests

Add or update:

* Set Builder UI tests.
* linked/detached group tests.
* draft commit/revert tests.
* proxy library unavailable tests.
* missing reference cleanup tests.

## Acceptance Criteria

* Set Builder is understandable.
* Linked vs detached behavior is clear.
* No raw menu bar identities leak.
* Tests pass.

---

# Workstream 22.9 — Find & Rescue Polish

## Goal

Make Find & Rescue the daily tool for finding, assigning, and rescuing items.

## Tasks

1. Finalize Find Icon filters:

   * All
   * Current Workspace
   * Any Workspace
   * Unassigned
   * New Items
   * Groups
   * Hidden
   * Always Hidden
   * Stale

2. Polish result badges:

   * New
   * Current Workspace
   * Used in N Workspaces
   * Unassigned
   * Linked Group
   * Detached Group
   * Stale
   * Missing
   * Protected

3. Polish item actions:

   * reveal/highlight
   * open owning app
   * show in Second Bar
   * add to Workspace
   * add to Group
   * create Group
   * arrange manually
   * dry-run Assisted Move, Experimental

4. Polish New Item Inbox:

   * assign to Workspace
   * assign to Group
   * create Group
   * dismiss
   * reset inbox
   * no spam

5. Polish Second Bar handoff:

   * show item in Second Bar
   * open Second Bar from crowded rescue
   * explain metadata/icon limitation

## Tests

Add or update:

* filter tests.
* ranking tests.
* badge tests.
* assignment tests.
* New Item Inbox tests.
* diagnostics redaction tests.

## Acceptance Criteria

* Find & Rescue feels connected to Workspaces.
* New items can be organized easily.
* No broad activation overclaim.
* Tests pass.

---

# Workstream 22.10 — Arrange and Placement Planner Polish

## Goal

Make physical arrangement guidance coherent with Workspaces.

## Tasks

1. Polish manual Arrange:

   * command-drag guide
   * control/separator diagram
   * test collapse/reveal
   * reset layout
   * common mistakes

2. Polish Workspace-aware Placement Planner:

   * used in current Workspace
   * used in N Workspaces
   * unassigned
   * linked Group usage
   * keep hidden but expose in Function Bar
   * add to Workspace
   * open Set Builder
   * dry-run Assisted Move

3. Polish Assisted Move boundaries:

   * Experimental
   * single-item only
   * dry-run first
   * per-move confirmation
   * failure recovery
   * no bulk

4. Polish physical profile binding:

   * dry-run only by default
   * safe Basic apply explicit
   * no icon moves
   * no Spacing Labs
   * no Launch at Login
   * no triggers

## Tests

Add or update:

* Arrange UI tests.
* placement recommendation tests.
* no physical mutation tests.
* assisted move dry-run tests.
* profile binding safe apply tests.

## Acceptance Criteria

* Users understand physical arrangement versus virtual Workspaces.
* No physical mutation occurs silently.
* Tests pass.

---

# Workstream 22.11 — Visual Design System Pass

## Goal

Make the app feel cohesive and native.

## Tasks

1. Review `DesignSystem/`.

2. Create or standardize:

   * page header
   * status card
   * action card
   * feature badge
   * preview banner
   * unavailable state
   * empty state
   * inline warning
   * destructive confirmation
   * help footer
   * permission explainer
   * panel chrome

3. Apply consistently to:

   * General
   * Hide & Reveal
   * Arrange
   * Find & Rescue
   * Workspaces
   * Privacy
   * Recovery
   * Advanced
   * Function Bar
   * Info Strip
   * Set Builder

4. Visual rules:

   * no theme engine
   * no decorative overbuild
   * native macOS controls where possible
   * support light/dark mode
   * reduce toggle walls
   * group settings logically
   * use clear actions instead of giant option lists

5. Add accessibility labels:

   * major buttons
   * toggles
   * badges
   * panels
   * warnings
   * destructive actions

## Tests

Add or update:

* visual component unit tests if existing.
* UI smoke tests for main sections.
* accessibility label checks where feasible.

## Acceptance Criteria

* UI is consistent.
* Pages look like one app.
* Preview/Labs/Experimental statuses are visually consistent.
* No theme engine added.
* Tests pass.

---

# Workstream 22.12 — Panel Placement and Display QA Hardening

## Goal

Harden panel behavior before v0.2.

Panels include:

* Function Bar
* Info Strip
* Second Bar
* Find Icon
* Set Switcher
* Group Panel

## Tasks

1. Audit placement services:

   * FunctionBarPlacementService
   * InfoStripPlacementService
   * SecondBarPlacementService
   * Search panel placement
   * Group panel placement

2. Standardize placement decisions:

   * below menu bar icon
   * below menu bar
   * near mouse
   * last position
   * centered below menu bar
   * clamp visible frame
   * external display change
   * notch estimate
   * auto-hide menu bar
   * sleep/wake
   * active Space changes

3. Add common placement diagnostics:

   * mode
   * clamped
   * display count
   * failure reason
   * no screen content

4. Add recovery:

   * reset panel positions
   * close all workspace panels
   * disable Function Bar/Info Strip preview
   * open Settings

## Tests

Add or update:

* placement math tests.
* display-change tests.
* invalid last position fallback tests.
* Safe Mode panel suppression tests.
* recovery reset panel positions tests.

## Acceptance Criteria

* Panels do not run offscreen in simulated cases.
* Display change does not break panel placement.
* Safe Mode suppresses workspace panels.
* Tests pass.

---

# Workstream 22.13 — Keyboard Navigation and Accessibility Polish

## Goal

Improve keyboard and accessibility before v0.2.

## Required Keyboard Flows

### Function Bar

* Left/Right selection
* Enter activate
* Escape close
* Down opens Set Switcher if focused on Workspace button
* Tab through items

### Info Strip

* Escape close
* Enter action if tile has action
* optional Right/Left next/previous tile

### Set Builder

* keyboard selection in Workspace list
* add selected library item
* reorder selected item with buttons or keyboard shortcuts
* commit/revert accessible

### Find Icon

* search field focus
* Up/Down result navigation
* Enter default action
* Command+Enter show in Second Bar
* Escape close

## Accessibility Labels

Add or verify:

* feature status badges
* protected badges
* missing/stale badges
* Workspaces cards
* Function Bar items
* Info Strip tiles
* Set Builder controls
* destructive actions

## Tests

Add UI tests where feasible:

* keyboard close panels.
* major controls have labels.
* Set Builder actions accessible.
* Find Icon keyboard flow preserved.

## Acceptance Criteria

* Core UI can be used with keyboard.
* Accessibility labels exist for important controls.
* Tests pass where feasible.

---

# Workstream 22.14 — Performance and Idle Behavior

## Goal

Ensure Workspaces / Function Bar / Info Strip do not make the app feel heavy.

## Tasks

1. Add privacy-safe performance diagnostics:

   * Function Bar open time bucket
   * Info Strip rotation status
   * Search index rebuild time bucket
   * Workspace usage index rebuild time bucket
   * Set Builder draft commit time bucket
   * panel placement failure count
   * no raw query or item identity

2. Avoid:

   * high-frequency timers
   * repeated full index rebuild on every keystroke
   * repeated file writes on every hover
   * expensive scanning while Safe Mode
   * keeping panels alive when disabled

3. Ensure:

   * Info Strip rotation interval minimum is enforced
   * idle timers stop on close
   * panels deallocate or hide cleanly
   * no unnecessary Pro scan caused by Workspaces UI
   * no permission prompt from UI inspection

## Tests

Add or update:

* idle timer stop tests.
* rotation minimum interval tests.
* no runtime start from editing tests.
* workspace index rebuild tests.
* diagnostics redaction tests.

## Acceptance Criteria

* App remains light while idle.
* Preview features do not run unless enabled.
* No high-frequency polling is introduced.
* Tests pass.

---

# Workstream 22.15 — Privacy Boundary Re-Audit

## Goal

Re-audit privacy after the Workspace MVP expansion.

## Tasks

1. Update privacy docs:

```text
docs/privacy/v0.1.9-privacy-claims.md
docs/privacy/v0.1.9-workspaces-privacy.md
```

2. Confirm Basic Mode still does not require:

   * Accessibility
   * Screen Recording
   * ScreenCaptureKit
   * Apple Events
   * Input Monitoring
   * network

3. Confirm Preview features:

   * Workspaces local only
   * Function Bar app-owned panel
   * Info Strip local tiles only
   * Calendar/Reminder optional explicit permission only, if implemented
   * diagnostics redacted

4. Update privacy verification script if needed to catch:

   * ScreenCaptureKit linkage
   * screen capture usage strings
   * Apple Events usage strings
   * network APIs
   * telemetry SDK names
   * suspicious remote config/update checks

5. Check Info.plist:

   * no unnecessary sensitive usage strings
   * if Calendar/Reminder usage strings exist, docs explain why and permission is explicit only

6. Run:

```bash
scripts/verify_privacy_boundary.sh
```

## Acceptance Criteria

* Privacy boundary script passes.
* Privacy docs are current.
* No accidental sensitive permission added.
* No network/telemetry introduced.
* Diagnostics redaction covers Workspace/Info Strip/Set Builder data.

---

# Workstream 22.16 — Recovery and Safe Mode Final Polish

## Goal

Make recovery strong enough before v0.2.

## Recovery Must Cover

* Basic layout reset
* reveal all
* recreate status items
* disable hover/auto-rehide temporarily
* disable Pro temporarily
* hide Function Bar
* hide Info Strip
* close Second Bar
* close Find Icon
* reset panel positions
* reset Workspaces
* clean missing references
* clear builder drafts
* disable Preview features
* disable Labs
* export diagnostics
* Safe Mode one-shot

## Safe Mode Must Suppress

* Pro scanning
* Function Bar runtime
* Info Strip runtime
* Set Builder live preview
* Smart Triggers
* App Intents broad automation
* URL automation beyond safe manual basics
* dynamic hotkeys if risky
* Assisted Move
* Spacing Labs
* optional group status items

## Tests

Add or update:

* Safe Mode start expanded.
* workspace panels suppressed.
* recovery actions available.
* reset Workspaces works.
* clean missing references works.
* diagnostics export redacted.
* Safe Mode does not remove user data unless explicitly reset.

## Acceptance Criteria

* Recovery can undo Preview feature confusion.
* Safe Mode remains simple and reliable.
* Tests pass.

---

# Workstream 22.17 — Backup / Restore Freeze

## Goal

Freeze local backup/restore behavior before v0.2.

## Backup Must Include

For complete local backup:

* settings
* profiles
* groups
* workspaces
* linked/detached group references
* function bar config
* info strip config
* workspace integration preferences
* hotkeys
* spacer items
* safe layout preferences
* schema metadata

## Safe Support Export Must Redact

* raw menu bar item names
* raw bundle IDs
* protected workspace names
* protected group names
* protected hotkey targets
* live search text
* selected item identity
* calendar/reminder titles
* full file paths unless user explicitly selected file

## Import Must Not Automatically Enable

* Launch at Login system state
* Icon Moving
* Smart Triggers
* Spacing Labs
* Function Bar primary click
* Info Strip auto-show
* physical profile apply
* Assisted Move
* broad automation

## Tests

Add or update:

* complete backup round-trip.
* support export redaction.
* import dry-run.
* import apply selected sections.
* rollback on failure.
* imported Preview features remain off unless selected.
* linked/detached references preserved.

## Acceptance Criteria

* Backup/restore is reliable for v0.2 preparation.
* Import is conservative.
* Tests pass.

---

# Workstream 22.18 — Manual QA Freeze

## Goal

Produce the manual QA evidence needed before v0.2.

## Create

```text
docs/testing/manual-v0.1.9-system-qa.md
docs/testing/manual-v0.1.9-workspaces-qa.md
docs/testing/manual-v0.1.9-panels-display-qa.md
docs/testing/manual-v0.1.9-privacy-qa.md
docs/testing/manual-v0.1.9-results.md
```

## Manual QA Matrix

### Basic

* command-drag setup
* collapse
* expand
* reveal all
* always-hidden
* auto-rehide
* hover reveal
* Basic hotkey
* reset layout

### Arrange

* guided manual arrange
* placement planner
* workspace-aware recommendations
* assisted move dry-run
* assisted move actual execution only if experimental test allowed

### Find & Rescue

* Find Icon
* Second Bar
* New Item Inbox
* Workspace filters
* assign to Workspace
* assign to Group
* create Group

### Workspaces

* create Workspace
* duplicate Workspace
* switch Workspace
* Function Bar
* Set Switcher
* Set Builder
* Linked Groups
* Detached Copy
* Info Strip
* profile binding dry-run
* crowded rescue Function Bar fallback

### Panels / Display

* notch MacBook
* external display
* mirror mode
* switch main display
* menu bar auto-hide
* sleep/wake
* active Space change
* dark/light mode

### Permissions

* Pro off
* Accessibility Discovery off
* Accessibility granted
* Accessibility revoked
* Calendar/Reminder permission if implemented
* no silent prompt

### Safe Mode / Recovery

* Option launch
* one-shot Safe Mode
* crash marker recovery
* reset panel positions
* reset Workspaces
* clear missing references
* export diagnostics

### Release Install

* dry-run install
* `/Applications` installed app
* Launch at Login
* logout/login if possible
* restart if possible
* URL scheme smoke
* Shortcuts basic actions if feasible
* no-network watch

## Acceptance Criteria

* Manual QA docs exist.
* Results are recorded.
* Blockers are categorized.
* Stable claims pass or are downgraded.
* Preview failures are documented honestly.
* Release checklist links to QA docs.

---

# Workstream 22.19 — Developer ID / Notarization Readiness

## Goal

Keep public release path ready.

## Tasks

1. Inspect:

```text
Config/ExportOptions.plist
scripts/build_release.sh
scripts/release_archive.sh
scripts/release_export_app.sh
scripts/release_notarize.sh
scripts/release_staple.sh
scripts/release_validate_gatekeeper.sh
scripts/verify_release_artifact.sh
scripts/verify_installed_app.sh
```

2. Run dry-run:

```bash
scripts/build_release.sh --dry-run --install --verify-installed
```

3. If Developer ID credentials are available, run:

```bash
scripts/build_release.sh --notarize --staple --install --verify-installed
```

4. If credentials are unavailable:

   * do not fake success
   * document external blocker
   * verify dry-run still passes

5. Validate:

   * code signature
   * hardened runtime
   * sandbox
   * LSUIElement
   * app category
   * URL scheme
   * no network entitlement
   * no sensitive usage strings unless justified
   * no ScreenCaptureKit linkage
   * spctl if notarized
   * stapler if stapled

## Docs

Update:

```text
docs/release/v0.1.9-release-runbook.md
docs/release/v0.1.9-local-dry-run.md
docs/release/v0.1.9-notarization-status.md
```

## Acceptance Criteria

* Dry-run release passes.
* Installed-app verification passes.
* Real notarization either passes or is clearly blocked by missing credentials.
* No secrets committed.

---

# Workstream 22.20 — v0.2 Draft Scope and Claims Freeze

## Goal

Prepare, but do not execute, the future v0.2 release scope.

## Create Draft Docs

```text
docs/release/v0.2-scope-freeze-draft.md
docs/release/v0.2-public-claims-draft.md
docs/release/v0.2-known-limitations-draft.md
docs/release/v0.2-manual-qa-required-draft.md
docs/release/v0.2-release-readiness-draft.md
```

Every file must begin with:

```markdown
# Draft / Future Scope

This is a draft for a future v0.2 release. It is not the current shipped release. The current active release line is v0.1.9.
```

## Future v0.2 Stable Candidate Claims

Can be drafted as future candidates only if implemented and tested:

* Basic hide/show/reveal
* Guided Manual Arrange
* Find Icon
* Second Bar
* New Item Inbox
* Workspaces
* Function Bar
* Set Switcher
* Linked Groups
* Info Strip local tiles
* Safe Mode / Recovery
* privacy-safe diagnostics
* local backup

## Future v0.2 Preview Candidate Claims

* Set Builder
* Detached Group Copy
* Workspace-aware Placement Planner
* Workspace-aware Crowded Rescue
* Workspace physical profile dry-run
* basic Shortcuts actions
* Calendar/Reminder tiles if implemented

## Future v0.2 Experimental Candidate Claims

* Assisted Move actual execution
* broad item activation if present
* physical layout movement

## Not in Future v0.2

* Screen Recording
* ScreenCaptureKit
* online widgets
* media controls
* notification scraping
* cloud sync
* telemetry
* stable competitor import
* stable bulk icon moving
* stable physical workspace switching

## Acceptance Criteria

* v0.2 draft docs exist.
* v0.2 docs are clearly draft/future.
* They do not change app version.
* They do not create release artifacts.
* They match v0.1.9 implementation status.

---

# Workstream 22.21 — Documentation Finalization

## Goal

Update v0.1.9 docs to match the actual app.

## Create or Update

```text
README.md
docs/release/v0.1.9-release-notes.md
docs/release/v0.1.9-release-checklist.md
docs/release/v0.1.9-known-limitations.md
docs/release/v0.1.9-feature-status-audit.md
docs/features/workspaces-v0.1.9-preview.md
docs/features/function-bar-v0.1.9-preview.md
docs/features/set-builder-v0.1.9-preview.md
docs/features/linked-groups-v0.1.9-preview.md
docs/features/info-strip-v0.1.9-preview.md
docs/features/workspace-integration-v0.1.9-preview.md
docs/features/find-rescue-v0.1.9.md
docs/features/arrange-v0.1.9.md
docs/privacy/v0.1.9-privacy-claims.md
docs/support/workspaces.md
docs/support/function-bar.md
docs/support/info-strip.md
docs/support/set-builder.md
docs/support/linked-groups.md
docs/support/troubleshooting.md
docs/support/safe-mode.md
docs/support/backup-restore.md
docs/progress/phase-22-v0.1.9-workspace-mvp-design-rc.md
```

## Required Wording

Use this product message:

> MenuBarDeclutter is a privacy-first menu bar declutter and workspace tool. Hide clutter without sensitive permissions, arrange icons safely, find hidden items when needed, create menu bar workspaces with reusable groups, show a lightweight Function Bar or Info Strip, and recover if layout breaks.

## Forbidden Claims

Do not claim:

* v0.2 shipped
* stable physical workspace switching
* system menu bar replacement
* Dynamic Island clone
* Screen Recording support
* ScreenCaptureKit support
* online widgets
* media controls
* notification scraping
* stable bulk icon moving
* stable broad third-party menu item activation
* competitor import stable

## Acceptance Criteria

* Docs match implementation.
* Docs separate current v0.1.9 from future v0.2 draft.
* No overclaims.
* Privacy claims are current.

---

# Workstream 22.22 — Tests

## Goal

Add or update tests for design RC behavior.

## Suggested Test Files

Create or update:

```text
MenuBar-ManagerTests/FeatureStatusAuditTests.swift
MenuBar-ManagerTests/WorkspaceLandingPageModelTests.swift
MenuBar-ManagerTests/OnboardingV2Tests.swift
MenuBar-ManagerTests/PanelPlacementRegressionTests.swift
MenuBar-ManagerTests/WorkspaceRecoveryTests.swift
MenuBar-ManagerTests/WorkspaceBackupRestoreFreezeTests.swift
MenuBar-ManagerTests/PrivacyBoundaryRegressionTests.swift
MenuBar-ManagerUITests/SettingsInformationArchitectureUITests.swift
MenuBar-ManagerUITests/WorkspacesLandingUITests.swift
MenuBar-ManagerUITests/OnboardingV2UITests.swift
MenuBar-ManagerUITests/WorkspaceMVPFlowUITests.swift
MenuBar-ManagerUITests/RecoveryUITests.swift
```

## Required Unit Tests

Cover:

1. Version is 0.1.9.
2. Feature statuses are consistent.
3. Workspaces top-level route exists.
4. Advanced contains Labs/Experimental surfaces.
5. Onboarding sample Workspace uses safe commands only.
6. Function Bar disabled by Safe Mode.
7. Info Strip disabled by Safe Mode.
8. Set Builder live preview disabled by Safe Mode.
9. Panel placement invalid last position fallback.
10. Recovery resets panel positions.
11. Recovery resets Workspaces.
12. Backup includes Workspaces/Groups/Info Strip.
13. Support export redacts identities.
14. Import does not enable risky features.
15. Privacy boundary still excludes screen/network APIs.
16. v0.2 draft docs are not current release docs if docs tests exist.

## Required UI Tests

Cover:

1. Settings sidebar route order.
2. Workspaces page renders.
3. Workspaces Preview badge visible.
4. Show Function Bar action visible.
5. Show Info Strip action visible.
6. Open Set Builder from Workspaces.
7. Find & Rescue route renders Workspace filters.
8. Arrange route renders workspace-aware placement section.
9. Recovery route renders Workspace recovery actions.
10. Onboarding v2 renders Workspaces step.
11. Privacy page renders no Screen Recording / no ScreenCaptureKit copy.
12. No Accessibility prompt on launch/settings/onboarding.

If UI tests are brittle, keep smoke-level UI tests and cover logic with unit tests.

## Acceptance Criteria

* New tests pass.
* Existing tests pass.
* UI smoke coverage reflects final IA.
* Privacy verification remains passing.

---

# Workstream 22.23 — Release and Privacy Verification

## Required Commands

After implementation, run:

```bash
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
```

If Developer ID credentials are available:

```bash
scripts/build_release.sh --notarize --staple --install --verify-installed
```

If credentials are unavailable, document external blocker.

## Targeted Searches

Run:

```bash
rg -n "MARKETING_VERSION|CURRENT_PROJECT_VERSION|CFBundleShortVersionString|CFBundleVersion" Config MenuBar-Manager MenuBar-Manager.xcodeproj || true

rg -n "v0\.2|0\.2\.0" README.md docs MenuBar-Manager scripts Config || true

rg -n "ScreenCaptureKit|NSScreenCaptureUsageDescription|NSAppleEventsUsageDescription|InputMonitoring|URLSession|NWConnection|analytics|telemetry|Sentry|Firebase|remote config|crash upload|update check|license check" MenuBar-Manager Config scripts docs || true

rg -n "stable Workspace|stable Workspaces|stable Function Bar|stable Info Strip|stable Set Builder|stable physical workspace|replace.*macOS.*menu bar|system menu bar replacement|Dynamic Island|live.*menu bar.*clone|pixel capture|live icon capture|Screen Recording" README.md docs MenuBar-Manager || true

rg -n "Workspace.*move.*icon|Workspace.*bulk|Workspace.*apply.*profile|Workspace.*physical.*layout|Workspace.*physical.*switch|bulk move" README.md docs MenuBar-Manager || true

rg -n "Function Bar.*all hidden items|Function Bar.*system menu bar|Info Strip.*online|media control|weather|stocks|news|RSS|notification scraping|file shelf" README.md docs MenuBar-Manager || true
```

Inspect results manually.

Acceptable:

* v0.2 draft/future docs clearly marked as not current release.
* Historical/future notes if clearly labeled.
* Docs that explicitly state deferred/future behavior.
* Mentions saying online/media widgets are not implemented.

Not acceptable:

* Current shipped-release v0.2 claim.
* Current-facing claim that Workspaces replace system menu bar.
* Current-facing claim that Workspace switching moves real menu bar icons.
* Current-facing claim that Function Bar captures live pixels or shows all hidden items.
* Current-facing claim that Info Strip is Dynamic Island or online widget system.
* Any new privacy-sensitive API usage.

## Acceptance Criteria

* Full test suite passes.
* Privacy boundary script passes.
* Release dry-run passes.
* Installed-app verification passes.
* Notarized flow either passes or is clearly blocked by credentials.
* Targeted searches do not reveal current-facing overclaims.
* Phase progress file records final validation results.

---

# Phase 22 Definition of Done

Phase 22 is complete when:

1. App version is `0.1.9`.
2. Build number is incremented to `10` or documented next build.
3. No shipped-release docs/UI call this v0.2.
4. Any v0.2 docs are clearly marked draft/future.
5. Main Settings sidebar is finalized:

   * General
   * Hide & Reveal
   * Arrange
   * Find & Rescue
   * Workspaces
   * Privacy
   * Recovery
   * Advanced
6. Workspaces is a polished top-level Preview section.
7. Workspaces landing page exists.
8. Onboarding v2 explains Basic, Arrange, Find & Rescue, Workspaces, privacy, and recovery.
9. Function Bar is polished and remains Preview.
10. Info Strip is polished and remains Preview.
11. Set Builder and Linked Groups are polished and remain Preview.
12. Find & Rescue has Workspace-aware filters and actions.
13. Arrange / Placement Planner explains virtual Workspace versus physical arrangement.
14. Crowded Rescue Function Bar fallback is understandable and conservatively configured.
15. Physical profile binding remains dry-run/safe-apply only.
16. Assisted Move remains Experimental.
17. Spacing Labs remains Advanced/Labs.
18. Smart Triggers remain Advanced/Preview.
19. No physical workspace switching is stable.
20. No bulk icon moving exists.
21. No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network, telemetry, analytics, cloud sync, private APIs, media private APIs, or notification scraping are introduced.
22. Privacy boundary is verified.
23. Manual QA docs and results exist.
24. Backup/restore behavior is frozen and tested.
25. Recovery/Safe Mode covers Workspace/Function Bar/Info Strip/Set Builder failure modes.
26. Release dry-run and installed-app verification pass.
27. Developer ID notarization path is either completed or clearly blocked by missing external credentials.
28. v0.2 draft scope and public claims are prepared but not shipped.
29. Full tests pass.
30. `docs/progress/phase-22-v0.1.9-workspace-mvp-design-rc.md` includes:

    * summary
    * changed files
    * test results
    * manual QA results
    * release verification results
    * privacy verification results
    * notarization status
    * v0.2 draft readiness status
    * known limitations
    * recommended scope for Phase 23 / future v0.2

---

# Recommended Codex Subtask Breakdown

Do not ask Codex to execute all Phase 22 in one huge pass. Use these slices.

## Phase 22A — Version + Scope Freeze

```markdown
Implement Phase 22A only:
- bump app version to 0.1.9 build 10
- add v0.1.9 release notes/checklist placeholders
- add feature status audit
- add v0.2 draft scope/public claims docs, clearly marked future/draft
- do not create v0.2 shipped artifacts
- do not add new runtime features
```

## Phase 22B — Information Architecture + Workspaces Landing

```markdown
Implement Phase 22B only:
- finalize Settings sidebar:
  General, Hide & Reveal, Arrange, Find & Rescue, Workspaces, Privacy, Recovery, Advanced
- move Workspaces to top-level Preview section
- build polished Workspaces landing page
- add route redirects if needed
- add UI smoke tests
```

## Phase 22C — Onboarding v2

```markdown
Implement Phase 22C only:
- rewrite onboarding flow around native cleanup, Basic, Arrange, Find & Rescue, Workspaces, privacy, recovery
- optional sample Workspace with safe command items only
- no automatic permission prompts
- no Preview/Labs auto-enable
- add UI tests
```

## Phase 22D — Workspace UI Polish

```markdown
Implement Phase 22D only:
- polish Function Bar
- polish Info Strip
- polish Set Builder and Linked Groups
- polish Find & Rescue Workspace filters
- polish Arrange/Placement Planner Workspace copy
- no new major features
- add tests for UI states
```

## Phase 22E — Design System + Panels + Accessibility

```markdown
Implement Phase 22E only:
- standardize DesignSystem components
- apply consistent page/card/badge/unavailable states
- harden panel placement for Function Bar, Info Strip, Second Bar, Find Icon, Group Panel
- improve keyboard navigation and accessibility labels
- add tests
```

## Phase 22F — Recovery + Backup + Privacy Freeze

```markdown
Implement Phase 22F only:
- polish Safe Mode and Recovery for Workspace-related failures
- freeze backup/restore behavior
- update privacy docs and privacy verification
- ensure diagnostics redact Workspaces/Info Strip/Set Builder data
- add tests
```

## Phase 22G — Manual QA + Release Readiness

```markdown
Implement Phase 22G only:
- create v0.1.9 manual QA docs and results templates
- run release dry-run and installed-app verification
- rehearse notarization only if credentials are available
- document external credential blocker if missing
- update release runbook/checklist
```

## Phase 22H — Docs + Final Validation

```markdown
Implement Phase 22H only:
- finalize v0.1.9 docs
- finalize v0.2 draft scope docs clearly marked future/draft
- run full validation commands
- run targeted privacy/overclaim searches
- record final results in phase progress doc
```
