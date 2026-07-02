
# Phase 14 — v0.1.1 Product Diet + Guided Icon Placement

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar decluttering utility written in Swift with AppKit and SwiftUI.

This phase continues the `v0.1.1` release line. It is not v0.2. Do not introduce `v0.2`, `0.2`, or `v0.2.0` in current-facing docs, release notes, UI, roadmap, package names, or code comments.

## Phase 14 Mission

The app currently feels too heavy because many Preview/Labs/Experimental surfaces are visible as product pillars. Phase 14 must make the app feel lighter without removing important power.

The core product should become:

> Hide clutter. Arrange icons safely. Find hidden icons. Recover if something goes wrong.

Phase 14 has two main goals:

1. **Product Diet**
   - Collapse the user-facing Settings surface.
   - Move heavy Preview/Labs/Experimental features out of the main sidebar.
   - Make the everyday product understandable in about 60 seconds.

2. **Guided Icon Placement**
   - Keep icon moving important to normal user flow.
   - Replace the current “icon moving is an experimental feature island” feeling with a guided arrange workflow.
   - Make manual `⌘`-drag placement the stable path.
   - Make Pro placement planning a Preview feature.
   - Keep automated CGEvent-based Assisted Move explicitly Experimental and per-action confirmed.

## Current Product Line

- Active release line: `v0.1.1`
- Version/build: `0.1.1 (2)` unless separately changed later.
- Product name: `MenuBarDeclutter`
- Xcode project: `MenuBar-Manager.xcodeproj`
- Canonical scheme: `MenuBarDeclutter`
- Deployment target: macOS `26.0`
- Swift: `6.0`
- Runtime style: `LSUIElement`
- Bundle ID: `Yongjun-Zhang.MenuBarDeclutter`

## Hard Rules

1. Do not call this v0.2.
2. Do not add Screen Recording.
3. Do not add ScreenCaptureKit.
4. Do not add Apple Events scripting/control.
5. Do not add Input Monitoring.
6. Do not add network access, telemetry, analytics, crash upload, cloud sync, or remote config.
7. Do not use private Apple menu bar APIs.
8. Do not automatically prompt for Accessibility.
9. Do not make broad third-party menu bar activation stable.
10. Do not make fully automated icon moving stable.
11. Do not expose Spacing Labs global defaults mutation in normal user flow.
12. Do not remove the existing Basic Mode reliability guarantees.
13. Do not remove Safe Mode, recovery, diagnostics, or privacy verification.
14. Do not hide icon placement entirely. Icon arrangement is important to normal user flow.
15. All Pro, Preview, Labs, and Experimental actions must degrade clearly.

## Important Product Decision

Do not remove Icon Moving. Reframe it.

Phase 14 should create this product model:

### Stable: Guided Manual Arrange

This is the normal user flow.

- No Accessibility required.
- No automation.
- No CGEvent.
- No attempt to control third-party menu extras.
- Teach the user to hold `⌘` and drag menu bar items.
- Show where MenuBarDeclutter’s control item and separators should go.
- Provide a test step: collapse, reveal, reset.
- Provide recovery if layout looks wrong.

### Preview: Placement Planner

This is Pro-assisted but non-mutating.

- Requires Pro Mode, Accessibility Discovery, and Accessibility permission.
- Reads metadata only.
- Does not move anything.
- Shows discovered items and zones.
- Suggests which items should remain visible, hidden, or always hidden.
- Produces manual step-by-step instructions.

### Experimental: Assisted Move

This uses the existing icon moving machinery.

- Requires Pro Mode.
- Requires Accessibility.
- Requires explicit Icon Moving setting.
- Requires first-use confirmation.
- Requires per-move confirmation.
- Must support dry-run.
- Must never bulk move silently.
- Must verify after move.
- Must restore safe visibility/reveal state on failure.
- Must remain labeled Experimental.

---

# Initial Repository Checks

Run:

```bash
git status --short
xcodebuild -list -project MenuBar-Manager.xcodeproj
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
````

Create the Phase 14 progress file immediately:

`docs/progress/phase-14-v0.1.1-product-diet-guided-placement.md`

Record:

* baseline git status
* baseline test results
* current known failures, if any
* exact date
* short phase goal

---

# Workstream 14.1 — Product Diet Taxonomy

## Goal

Define a simpler product taxonomy that all Settings, docs, onboarding, and status menu surfaces follow.

## New Product Pillars

The user-facing app should have only these top-level ideas:

1. **General**

   * app startup
   * Launch at Login
   * basic app behavior

2. **Hide & Reveal**

   * collapse
   * expand
   * reveal all
   * auto-rehide
   * hover reveal
   * always-hidden zone
   * Basic hotkey

3. **Arrange**

   * command-drag guide
   * control/separator placement
   * placement test
   * Pro placement planner
   * Experimental assisted move

4. **Find & Rescue**

   * Find Icon
   * Second Bar
   * crowded reveal fallback
   * new item inbox
   * lightweight groups/tags inside this workflow only

5. **Privacy**

   * Basic privacy boundary
   * Pro permission boundary
   * diagnostics redaction
   * no Screen Recording
   * no ScreenCaptureKit
   * no network

6. **Recovery**

   * Safe Mode
   * reset layout
   * repair
   * diagnostics export
   * health report

7. **Advanced**

   * Profiles
   * Smart Triggers
   * Dynamic Hotkeys
   * Private Access
   * App Intents
   * URL automation
   * Import / Export
   * Spacing Labs
   * Dogfood/internal surfaces, if visible at all
   * experimental settings

## Feature Statuses

Keep or standardize these statuses:

* Stable
* Preview
* Labs
* Experimental
* Deferred
* Internal

## Tasks

1. Search current Settings sidebar and feature sections.

   Inspect:

   * `MenuBar-Manager/Settings/`
   * `MenuBar-Manager/DesignSystem/`
   * `MenuBar-Manager/App/`
   * `docs/release/v0.1.1-feature-gates.md`
   * `docs/release/v0.1.1-public-claims.md`

2. Add or update a central product taxonomy doc:

   `docs/product/v0.1.1-product-taxonomy.md`

3. Add or update a central feature visibility model.

   Suggested file:

   `MenuBar-Manager/Core/FeatureVisibility.swift`

   Or extend existing feature gate/status model if present.

4. Classify every current feature:

   Stable main:

   * Basic hide/reveal
   * auto-rehide
   * hover reveal
   * Basic hotkey
   * always-hidden zone
   * Launch at Login
   * Safe Mode/recovery
   * diagnostics export
   * privacy boundary
   * guided manual arrange

   Preview main:

   * Find Icon
   * Second Bar
   * crowded reveal rescue
   * new item inbox
   * placement planner

   Advanced Preview:

   * groups beyond lightweight tags
   * profiles
   * dynamic hotkeys beyond 2-3 basic commands
   * Smart Triggers
   * App Intents
   * URL automation
   * import/export migration assistant
   * Private Access

   Labs:

   * Spacing Labs

   Experimental:

   * Assisted Move / CGEvent icon moving
   * broad third-party menu item activation
   * group status items if still present

   Deferred:

   * ScreenCaptureKit visual capture
   * Screen Recording
   * Apple Events
   * Input Monitoring
   * cloud sync
   * stable competitor migration
   * stable bulk icon moving

5. Make this taxonomy available to Settings UI so feature sections can show/hide consistently.

## Acceptance Criteria

* There is one documented product taxonomy.
* Settings and docs use the same vocabulary.
* Icon placement is a main product concept, not hidden away.
* Fully automated icon moving remains Experimental.
* Preview/Labs/Experimental features are not shown as stable product pillars.

---

# Workstream 14.2 — Settings Sidebar Simplification

## Goal

Make the Settings app feel lighter.

Current Settings has many sections:

* General
* Menu Bar Items
* Behavior
* Layout
* Search
* Second Bar
* Private Access
* Groups
* Hotkeys
* Profiles
* Automation
* Import / Export
* Privacy
* Diagnostics
* Advanced

Phase 14 should collapse this into a smaller user-facing navigation.

## New Top-Level Sidebar

Implement the main sidebar as:

1. General
2. Hide & Reveal
3. Arrange
4. Find & Rescue
5. Privacy
6. Recovery
7. Advanced

## Mapping

### General

Move here:

* Launch at Login
* start collapsed
* onboarding reset
* app version
* basic app startup state

### Hide & Reveal

Move here:

* collapse/expand/reveal behavior
* auto-rehide
* hover reveal
* always-hidden zone
* Basic global hotkey
* status menu behavior

### Arrange

Move here:

* command-drag guide
* control item placement
* separator placement
* always-hidden separator placement
* placement test
* Pro placement planner
* Assisted Move, clearly Experimental
* icon moving safety explanation

### Find & Rescue

Move here:

* Pro discovery requirement summary
* Find Icon
* Second Bar
* crowded reveal fallback
* new item inbox
* lightweight group/tag actions
* reveal/highlight/open owning app

### Privacy

Move here:

* Basic privacy boundary
* Pro permission explainer
* diagnostics redaction
* data storage
* no network
* no Screen Recording
* no ScreenCaptureKit

### Recovery

Move here:

* health
* diagnostics export
* Safe Mode
* reset layout
* reset all settings
* repair actions
* crash marker recovery

### Advanced

Nest these subsections inside Advanced:

* Profiles
* Smart Triggers
* Dynamic Hotkeys
* Private Access
* Groups advanced
* App Intents
* URL Automation
* Import / Export
* Spacing Labs
* Icon Moving advanced logs
* Dogfood/internal, if visible
* Developer/debug tools, if present

## Tasks

1. Refactor Settings route model.

   Inspect:

   * `MenuBar-Manager/Settings/`
   * native Settings shell route definitions
   * UI tests that refer to sidebar items
   * docs/design route inventory

2. Preserve old feature views, but move them behind Advanced where appropriate.

3. Add lightweight summary cards for moved features.

   Example:

   * In Find & Rescue, show “Groups are available as lightweight collections. Advanced group status items are in Advanced.”
   * In Arrange, show “Assisted Move is Experimental and requires Pro + Accessibility.”

4. Add search or quick jump inside Advanced if existing settings search supports it.

5. Make Preview/Labs/Experimental badges highly visible.

6. Update UI tests to reflect new sidebar.

7. Update docs:

   * `docs/design/phase-14-settings-simplification.md`
   * `docs/support/settings-overview.md`
   * `docs/release/v0.1.1-public-claims.md`

## Acceptance Criteria

* Main Settings sidebar has no more than 7 top-level sections.
* Icon placement has a visible normal user flow under Arrange.
* Heavy features are not top-level sidebar items.
* Existing views remain accessible through Advanced unless intentionally hidden.
* UI smoke tests pass.
* Docs match new Settings layout.

---

# Workstream 14.3 — Guided Manual Arrange Flow

## Goal

Make icon placement part of the normal user flow without requiring Pro or Accessibility.

This is the stable replacement for treating “icon moving” as only a risky experimental feature.

## User Story

A new user should be able to open Arrange and understand:

1. Why MenuBarDeclutter uses a control item and separators.
2. Where to place the control item.
3. Where to place the primary separator.
4. How to place items to hide.
5. How to place always-hidden items, if enabled.
6. How to test collapse/reveal.
7. How to reset if something looks wrong.

## Tasks

1. Create an Arrange view.

   Suggested files:

   * `MenuBar-Manager/Settings/ArrangeSettingsView.swift`
   * `MenuBar-Manager/Arrange/ArrangeGuideView.swift`
   * `MenuBar-Manager/Arrange/ArrangeStep.swift`
   * `MenuBar-Manager/Arrange/ArrangeGuideViewModel.swift`

   Use existing source conventions if there is already a better place.

2. Add step-by-step guided flow:

   Suggested steps:

   * Step 1: “Show MenuBarDeclutter controls”
   * Step 2: “Hold Command and drag the control item”
   * Step 3: “Hold Command and drag the separator”
   * Step 4: “Put hidden items to the left of the separator”
   * Step 5: “Test collapse”
   * Step 6: “Test reveal”
   * Step 7: “Enable always-hidden area”, optional
   * Step 8: “Reset layout if needed”

3. Add visual diagrams using app-owned SwiftUI drawings.

   Do not use screenshots.
   Do not capture the user’s screen.
   Do not use ScreenCaptureKit.

4. Add status menu entry:

   * “Arrange Menu Bar Items…”

   This should open Settings directly to Arrange.

5. Add onboarding connection.

   Onboarding should include:

   * native Apple cleanup step
   * command-drag arrangement step
   * test collapse/reveal step

6. Add placement test commands:

   * expand
   * collapse
   * reveal all
   * reset layout
   * show drag hint popover

7. Add “I can’t find the control item” recovery link.

   It should offer:

   * expand/reveal
   * reset layout
   * Safe Mode instructions
   * diagnostics export

8. Add tests:

   * Arrange view renders
   * status menu opens Arrange route
   * onboarding can navigate through arrange step
   * test commands call existing Basic actions
   * no Pro required
   * no Accessibility prompt
   * no ScreenCaptureKit usage

## Acceptance Criteria

* A user can learn manual icon placement from the app.
* No sensitive permission is requested.
* Arrange is visible in normal Settings.
* Icon moving feels important but safe.
* Basic placement test is available.
* UI tests cover the route.

---

# Workstream 14.4 — Pro Placement Planner

## Goal

Add a non-mutating placement planner powered by Accessibility metadata.

This should help normal users arrange icons without immediately using automated CGEvent moving.

## User Story

A Pro user enables Accessibility Discovery. The app shows discovered menu bar items and suggests:

* keep visible
* move to hidden
* move to always hidden
* recently added item needs decision
* item may be stale or unknown
* item is likely system item and should be handled carefully

The planner should produce manual instructions, not auto-move by default.

## Tasks

1. Add placement planning model.

   Suggested files:

   * `MenuBar-Manager/Arrange/PlacementPlan.swift`
   * `MenuBar-Manager/Arrange/PlacementPlanItem.swift`
   * `MenuBar-Manager/Arrange/PlacementRecommendation.swift`
   * `MenuBar-Manager/Arrange/PlacementPlanner.swift`
   * `MenuBar-Manager/Arrange/PlacementPlannerViewModel.swift`

2. Inputs:

   * latest Accessibility item snapshots
   * zone classification
   * separator frames
   * always-hidden separator state
   * item recents/favorites memory
   * new item inbox state
   * group/tag assignments
   * user preferences

3. Recommendation types:

   * keepVisible
   * moveToHidden
   * moveToAlwaysHidden
   * reviewNewItem
   * staleMetadata
   * likelySystemItem
   * noRecommendation
   * needsManualPlacement

4. Add planner UI in Arrange:

   * list discovered items
   * current zone
   * recommended zone
   * reason
   * manual instruction
   * action buttons:

     * mark as visible
     * mark as hidden
     * mark as always hidden
     * add to group/tag
     * show in Find Icon
     * show in Second Bar
     * dry-run assisted move
     * try assisted move, Experimental

5. Do not mutate menu bar item order from planner unless user explicitly chooses Assisted Move.

6. Degraded states:

   * Pro off
   * Accessibility Discovery off
   * permission missing
   * Safe Mode
   * no scan yet
   * stale scan

7. Diagnostics:

   * count recommendations by type
   * do not log item titles, bundle IDs, live item identities, or protected names by default

8. Tests:

   * recommendations based on zone
   * no mutation
   * Pro/AX gates
   * stale scan handling
   * system item caution
   * diagnostics redaction

## Acceptance Criteria

* Pro Placement Planner gives actionable manual guidance.
* It does not move items automatically.
* It integrates with Find Icon, Second Bar, groups/tags, and Assisted Move dry-run.
* It uses existing Accessibility privacy boundary.
* Tests cover recommendation logic.

---

# Workstream 14.5 — Assisted Move as a Normal but Experimental Subflow

## Goal

Keep icon moving accessible from normal Arrange / Find & Rescue flows, but make the automated part explicitly Experimental and safe.

The user should see Assisted Move as:

> “MenuBarDeclutter can try to move this item for you, but macOS menu bar movement is fragile. We will show a dry-run first, ask for confirmation, try one item, verify, and recover if it fails.”

## Tasks

1. Audit existing moving code.

   Inspect:

   * `MenuBar-Manager/Moving/`
   * `MenuBar-Manager/Search/`
   * `MenuBar-Manager/SecondBar/`
   * `MenuBar-Manager/Groups/`
   * `MenuBar-Manager/CommandCenter/`
   * `MenuBar-Manager/App/MenuBarItemSurfaceCoordinator.swift`
   * tests under `MenuBar-ManagerTests/` related to moving

2. Create a user-facing assisted move flow.

   Suggested files:

   * `MenuBar-Manager/Arrange/AssistedMoveIntroView.swift`
   * `MenuBar-Manager/Arrange/AssistedMoveDryRunView.swift`
   * `MenuBar-Manager/Arrange/AssistedMoveConfirmationView.swift`
   * `MenuBar-Manager/Arrange/AssistedMoveResultView.swift`
   * `MenuBar-Manager/Arrange/AssistedMoveViewModel.swift`

3. Entry points:

   * Arrange planner item row
   * Find Icon item action
   * Second Bar item action
   * Group item action
   * Advanced → Icon Moving

4. Required gates:

   * Pro Mode enabled
   * Accessibility Discovery enabled
   * Accessibility permission granted
   * Icon Moving enabled
   * Safe Mode inactive
   * valid item frame
   * valid target zone
   * not MenuBarDeclutter’s own status items
   * not likely system item unless explicit advanced override is enabled
   * first-use confirmation accepted
   * per-move confirmation accepted

5. Required flow:

   * user selects one item
   * user selects target:

     * visible
     * hidden
     * always hidden
   * dry-run plan appears
   * app explains risk
   * user confirms
   * app expands/reveals as needed
   * app suspends conflicting behaviors:

     * auto-rehide
     * hover reveal
     * dynamic hotkeys if needed
     * automation if needed
   * app attempts command-drag using existing moving service
   * app rescans
   * app verifies target zone
   * app restores previous safe visibility behavior
   * app shows result

6. Failure recovery:

   On failure, app must offer:

   * reveal all
   * reset layout
   * retry dry-run
   * open manual arrange guide
   * export diagnostics

7. Do not implement bulk assisted moving.

   Bulk movement must remain deferred.

8. Do not mark Assisted Move stable.

   The stable feature is Guided Manual Arrange.
   The Preview feature is Placement Planner.
   The Experimental feature is Assisted Move.

9. Add command router integration.

   Add or update command actions:

   * `dryRunMoveItem`
   * `tryAssistedMoveItem`
   * `cancelAssistedMove`
   * `showAssistedMoveGuide`

10. Add tests:

* gate unavailable states
* dry-run does not execute CGEvent
* own app item blocked
* likely system item blocked by default
* missing frame blocked
* Safe Mode blocked
* first-use confirmation required
* per-move confirmation required
* failure restores visibility state
* successful verification result
* diagnostics redaction

## Acceptance Criteria

* Icon moving is visible as part of Arrange.
* Manual placement remains the recommended stable path.
* Assisted Move is available but clearly Experimental.
* Assisted Move is single-item only.
* All entry points use shared command gates.
* Failure cannot strand the app in an unsafe hidden state.
* Tests cover moving gate and recovery logic.

---

# Workstream 14.6 — New Menu Bar Item Inbox

## Goal

Add a lightweight Pro feature that solves a real user problem:

When a new app adds a menu bar item, the user should not lose it or wonder where it went.

This is especially important for separator-based hiding because new items may appear on the hidden side depending on placement.

## User Story

When Pro Discovery sees a previously unknown menu bar item, the app shows it in a “New Items” inbox.

The user can choose:

* Keep visible
* Move to hidden, manual instruction
* Move to always hidden, manual instruction
* Add to group/tag
* Show in Find Icon
* Show in Second Bar
* Dismiss

Assisted Move can be offered, but only as Experimental and gated.

## Tasks

1. Add new item detection.

   Use existing hashed item memory if possible:

   * `menu-bar-item-memory.json`
   * Search/Second Bar recents/favorites memory
   * Accessibility item identity model

2. Add model:

   Suggested files:

   * `MenuBar-Manager/Arrange/NewMenuBarItem.swift`
   * `MenuBar-Manager/Arrange/NewMenuBarItemInbox.swift`
   * `MenuBar-Manager/Arrange/NewMenuBarItemInboxStore.swift`
   * `MenuBar-Manager/Arrange/NewMenuBarItemInboxViewModel.swift`

3. Store only privacy-safe identity.

   Do not store raw titles/bundle IDs in diagnostics export by default.
   If raw metadata is required for local display, ensure it stays local and is excluded from diagnostics/support export by default.

4. Add UI in Find & Rescue or Arrange:

   * “New Items”
   * count badge
   * review list
   * suggested action
   * dismiss
   * reset inbox

5. Add status menu notification only if non-intrusive.

   Suggested:

   * status menu row: “Open New Items…”
   * no push notification unless user opts in later

6. Add onboarding note:

   “When Pro Discovery is enabled, MenuBarDeclutter can help you notice new menu bar items before they get lost in a hidden area.”

7. Add tests:

   * new item detected
   * known item not repeated
   * dismissed item not repeated
   * reset inbox works
   * diagnostics redaction
   * Pro gates respected
   * Safe Mode suppresses scanning/inbox updates

## Acceptance Criteria

* New Item Inbox exists behind Pro Discovery.
* It does not require Screen Recording.
* It helps users arrange new icons.
* It integrates with Arrange and Find & Rescue.
* It does not spam users.
* Privacy-safe export still passes.

---

# Workstream 14.7 — Find & Rescue Consolidation

## Goal

Simplify advanced item access around one user-facing concept:

> Find & Rescue

This replaces the feeling of many separate advanced surfaces.

## Find & Rescue Should Include

* Find Icon
* Second Bar
* Crowded Reveal Rescue
* New Item Inbox
* lightweight groups/tags
* reveal/highlight
* open owning app
* arrange item
* show manual move instruction
* assisted move dry-run
* assisted move experimental action

## Tasks

1. Create or update `FindAndRescueSettingsView`.

   Suggested file:

   `MenuBar-Manager/Settings/FindAndRescueSettingsView.swift`

2. Move Search and Second Bar settings into this page as cards.

3. Add cards:

   * Find Icon
   * Second Bar
   * Crowded Reveal Rescue
   * New Items
   * Lightweight Groups/Tags
   * Pro Discovery Requirements

4. Remove top-level Search and Second Bar routes from main sidebar.

   Keep deep links or Advanced links if tests/docs need compatibility.

5. Item action model:

   Ensure item actions from Find Icon and Second Bar include:

   * reveal
   * highlight
   * open owning app
   * show in Second Bar
   * arrange manually
   * add to group/tag
   * dry-run assisted move
   * try assisted move, Experimental

6. Crowded Rescue simplification:

   In the main UI, show only:

   * “When reveal does not fit, open Second Bar”
   * “Ask before switching”
   * “Prefer inline reveal”
   * “Use Full Menu Bar Mode”

   Move advanced capacity details to Advanced.

7. Groups simplification:

   In main UI, use language like:

   * “Collections”
   * “Tags”
   * “Saved groups”

   Avoid implying native merger of third-party menu bar items.

8. Tests:

   * Find & Rescue page renders
   * Search controls still reachable
   * Second Bar controls still reachable
   * item actions use Command Center
   * crowded rescue preference persists
   * groups/tags actions are available but not overclaimed

## Acceptance Criteria

* Find Icon, Second Bar, New Items, Crowded Rescue, and lightweight groups feel like one workflow.
* Search and Second Bar are no longer separate top-level product pillars.
* The main UI is lighter.
* Existing functionality remains accessible.
* Tests are updated.

---

# Workstream 14.8 — Advanced Feature Diet

## Goal

Move non-core features out of the normal flow without deleting useful code.

## Features To Move Under Advanced

Move these out of the main sidebar:

* Profiles
* Smart Triggers
* Dynamic Hotkeys beyond basic hotkeys
* Private Access
* Advanced Groups
* App Intents
* URL automation
* Import / Export migration assistant
* Spacing Labs
* Dogfood/internal
* Advanced Icon Moving logs/settings

## Stable Features That Stay Outside Advanced

* Basic hotkey
* Launch at Login
* diagnostics export
* Safe Mode
* reset layout
* guided manual arrange
* Find Icon
* Second Bar
* New Item Inbox
* crowded rescue fallback

## Tasks

1. Add Advanced landing page.

   It should explain:

   * “These features are Preview, Labs, Experimental, or for power users.”
   * “Basic hiding and guided arrangement do not require these features.”

2. For each advanced feature, add card:

   * feature name
   * status badge
   * short description
   * required permissions/gates
   * link to detailed page
   * reset/disable quick action if relevant

3. Add “Show Preview Features” preference if useful.

   Optional design:

   * Main UI can hide Preview/Labs/Experimental cards unless Advanced is opened.
   * Existing power users can still access them.

4. Ensure default settings do not enable advanced features.

5. Ensure Safe Mode suppresses advanced features.

6. Add tests:

   * Advanced page renders
   * advanced feature links work
   * status badges correct
   * default settings keep advanced off
   * Safe Mode unavailable states render

## Acceptance Criteria

* Main Settings feels lighter.
* No major existing feature is accidentally deleted.
* Heavy features are clearly labeled and nested.
* Advanced features are off by default.
* UI tests pass.

---

# Workstream 14.9 — Status Menu Simplification

## Goal

Make the menu bar status menu support the focused product story.

## Recommended Status Menu

Primary actions:

* Hide Menu Bar Items
* Show Menu Bar Items
* Reveal All
* Arrange Items…
* Find Icon…
* Show Second Bar
* Full Menu Bar Mode
* Open New Items, only if Pro Discovery enabled and inbox has items
* Settings…
* Recovery
* Diagnostics
* Quit

Advanced submenu:

* Apply Profile, if profiles enabled
* Pause Automation, if automation enabled
* Spacing Labs, only if Labs enabled
* Experimental Assisted Move tools, only if enabled
* Developer/Dogfood, only internal/debug

## Tasks

1. Inspect status menu presenter:

   * `MenuBar-Manager/StatusBar/`
   * status menu tests
   * `AppEnvironment` callbacks

2. Add “Arrange Items…” route.

3. Add “Open New Items…” conditional route.

4. Move advanced actions into an Advanced submenu.

5. Make disabled/unavailable items explain why:

   * Pro off
   * Accessibility missing
   * Safe Mode active
   * feature disabled
   * Labs off
   * Experimental disabled

6. Add tests:

   * default status menu contains focused actions
   * advanced submenu hides unavailable features
   * Arrange route works
   * New Items row appears only with inbox count
   * Safe Mode status menu remains recovery-first

## Acceptance Criteria

* Status menu is not overloaded.
* Arrange is first-class.
* Find & Rescue is easy to reach.
* Advanced actions do not clutter normal use.
* Safe Mode menu remains simple and useful.

---

# Workstream 14.10 — Automation Surface Diet

## Goal

Reduce automation complexity in the normal product.

Automation should exist, but not dominate the app.

## Keep Visible

Keep these basic automation surfaces visible or documented:

* App Intent: expand
* App Intent: collapse
* App Intent: toggle/reveal all
* App Intent: show Find Icon
* App Intent: show Second Bar
* URL routes for basic manual commands

## Move To Advanced

* profile apply by name
* group by UUID
* reveal group by UUID
* spacing preview
* Labs automation
* protected automation
* Smart Triggers
* external workflow automation

## Tasks

1. Audit App Intents and URL automation UI.

   Inspect:

   * `MenuBar-Manager/Shortcuts/`
   * `MenuBar-Manager/Profiles/`
   * `MenuBar-Manager/CommandCenter/`
   * `Settings/Automation`

2. Keep command router/gates intact.

3. Do not delete advanced automation unless clearly unused.

4. Simplify user-facing Automation page:

   * Basic Shortcuts
   * Advanced Automation
   * Gated/Labs actions

5. Ensure automation still fails closed:

   * Safe Mode
   * automation paused
   * Pro gates
   * Accessibility gates
   * Private Access gates
   * Labs gates

6. Update docs:

   * `docs/features/automation-v0.1.1.md`
   * `docs/support/shortcuts.md`, if present

7. Add tests:

   * basic automation visible
   * advanced automation hidden/nested
   * gates still apply
   * no URL bypass
   * no App Intent bypass

## Acceptance Criteria

* Automation is still present but not a main product pillar.
* Basic commands are easy to understand.
* Advanced automation is nested.
* Gates still work.

---

# Workstream 14.11 — Import / Export Diet

## Goal

Keep the useful parts of Import/Export and hide migration-heavy parts.

## Keep Visible

* Export Diagnostics
* Export Health Report
* Backup Settings
* Restore from MenuBarDeclutter backup, if implemented safely

## Move To Advanced

* Migration Assistant
* competitor import
* profile packs
* group packs
* selective import
* redaction details
* full schema explorer

## Tasks

1. Inspect:

   * `MenuBar-Manager/Migration/`
   * `MenuBar-Manager/Core/`
   * `Settings/ImportExport`
   * diagnostics export code
   * docs

2. Move Import / Export out of main sidebar.

3. Add Recovery page actions:

   * Export Diagnostics
   * Backup Settings
   * Restore Backup, if safe
   * Open Application Support folder, if already supported safely

4. Add Advanced → Import / Export page for full flows.

5. Do not expose competitor import as stable.

6. Tests:

   * diagnostics export still accessible
   * backup settings still accessible
   * migration assistant only Advanced/Preview
   * export redaction remains safe
   * import does not enable risky features by default

## Acceptance Criteria

* Normal users see backup/diagnostics, not migration complexity.
* Migration assistant no longer makes the app feel heavy.
* Privacy-safe export remains stable.
* Import/export tests pass.

---

# Workstream 14.12 — Spacing Labs Diet

## Goal

Keep Spacing Labs from making the normal app feel dangerous or heavy.

## Tasks

1. Move Spacing Labs fully under:

   `Advanced → Labs`

2. In normal Arrange/Find & Rescue UI, only show:

   * spacing suggestion text
   * “Advanced spacing experiments are available in Labs”

3. Hide or disable apply/restore/reset unless the code has proven backup/restore semantics.

4. Ensure App Intents and URL automation cannot apply spacing unless:

   * Labs enabled
   * explicit user setting enabled
   * command gate allows
   * Safe Mode inactive

5. Add tests:

   * Labs off blocks apply
   * Safe Mode blocks apply
   * normal UI does not expose apply
   * dry-run does not mutate global defaults

## Acceptance Criteria

* Spacing Labs is not part of normal user flow.
* No accidental global defaults mutation.
* Labs docs are honest.
* Privacy boundary remains intact.

---

# Workstream 14.13 — Documentation Rewrite for Focused Product

## Goal

Rewrite current-facing docs around the lighter product shape.

## Create or Update

* `README.md`
* `docs/product/v0.1.1-product-taxonomy.md`
* `docs/product/v0.1.1-product-diet.md`
* `docs/features/arrange-v0.1.1.md`
* `docs/features/guided-manual-arrange-v0.1.1.md`
* `docs/features/placement-planner-v0.1.1.md`
* `docs/features/assisted-move-v0.1.1-experimental.md`
* `docs/features/find-rescue-v0.1.1.md`
* `docs/features/new-item-inbox-v0.1.1.md`
* `docs/support/arrange-menu-bar-items.md`
* `docs/support/icon-moving-boundary.md`
* `docs/release/v0.1.1-public-claims.md`
* `docs/release/v0.1.1-known-limitations.md`
* `docs/progress/phase-14-v0.1.1-product-diet-guided-placement.md`

## Public Message

Use this product message:

> MenuBarDeclutter is a privacy-first menu bar declutter tool. Hide clutter without sensitive permissions, arrange icons safely, find hidden items when needed, and recover if layout breaks.

## Explain Icon Moving Clearly

Docs must distinguish:

### Stable

Guided Manual Arrange:

* user uses normal macOS `⌘`-drag
* no Pro required
* no Accessibility required
* no automation

### Preview

Placement Planner:

* requires Pro Discovery
* reads Accessibility metadata only
* suggests manual placement
* does not move items

### Experimental

Assisted Move:

* tries a single move
* requires Pro + Accessibility
* requires explicit confirmation
* may fail
* can be disabled
* is not stable

## Do Not Claim

* Do not claim stable automated moving.
* Do not claim broad activation of third-party menu items.
* Do not claim to capture real menu bar pixels.
* Do not claim Private Access hides already-visible system menu content.
* Do not call this v0.2.

## Acceptance Criteria

* Docs match new Settings structure.
* Docs explain Arrange as a core product pillar.
* Docs reduce emphasis on automation, triggers, labs, migration, and Private Access.
* Docs use v0.1.1 language only.
* No overclaiming.

---

# Workstream 14.14 — Tests, QA, and Release Verification

## Goal

Validate that Phase 14 simplified the product without breaking core behavior.

## Required Tests

Run after implementation:

```bash
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
```

## Targeted Searches

Run:

```bash
rg -n "v0\.2|0\.2\.0" README.md docs MenuBar-Manager scripts Config || true
rg -n "ScreenCaptureKit|NSScreenCaptureUsageDescription|NSAppleEventsUsageDescription|InputMonitoring|URLSession|NWConnection|analytics|telemetry|Sentry|Firebase" MenuBar-Manager Config scripts docs || true
rg -n "stable icon moving|stable automated move|bulk move|Screen Recording|screen capture|pixel capture" README.md docs MenuBar-Manager || true
rg -n "Private Access.*encrypt|Private Access.*hide.*third-party|Touch ID.*hide.*visible" README.md docs MenuBar-Manager || true
```

Inspect results manually. Fix only current-facing overclaims. Historical docs may remain if clearly historical.

## New Test Coverage Required

Add or update tests for:

1. Settings sidebar simplification.
2. Arrange route rendering.
3. Guided Manual Arrange no-permission behavior.
4. Placement Planner Pro/AX gates.
5. Placement recommendation logic.
6. Assisted Move gate matrix.
7. Assisted Move dry-run no-CGEvent behavior.
8. Assisted Move failure recovery.
9. New Item Inbox detection/dismiss/reset.
10. Find & Rescue consolidated page.
11. Status menu simplified actions.
12. Advanced page feature status badges.
13. Automation nested behavior.
14. Import/export still accessible through Recovery/Advanced.
15. Spacing Labs hidden from normal UI.
16. Privacy verification remains passing.
17. Diagnostics redaction for new placement/inbox features.

## Manual QA Additions

Update:

`docs/testing/manual-v0.1.1-system-qa.md`

Add a Phase 14 section:

### Arrange Manual QA

* Open Arrange.
* Follow command-drag guide.
* Move control item manually.
* Move separator manually.
* Test collapse.
* Test reveal.
* Test reset.
* Enable always-hidden zone and test placement.
* Confirm no permission prompt appears.

### Placement Planner Manual QA

* Enable Pro Mode.
* Enable Accessibility Discovery.
* Grant Accessibility manually.
* Confirm item list appears.
* Confirm recommendations appear.
* Confirm planner does not move anything.
* Confirm diagnostics do not include raw item names by default.

### Assisted Move Manual QA

* Enable experimental Icon Moving.
* Select one non-system third-party item.
* Run dry-run.
* Cancel confirmation.
* Confirm no move happened.
* Run confirmed move.
* Verify result or failure recovery.
* Confirm failed move offers reveal/reset/diagnostics.
* Confirm system item is blocked by default.

### New Item Inbox Manual QA

* Launch fixture app with a new item.
* Confirm New Items count appears.
* Review item.
* Dismiss item.
* Relaunch fixture.
* Confirm dismissed item does not repeat.
* Reset inbox.
* Confirm item can appear again.

## Acceptance Criteria

* All required automated tests pass.
* Privacy boundary script passes.
* Release dry-run still works.
* Settings UI is visibly lighter.
* Arrange is visible and useful.
* Icon moving is integrated but correctly tiered.
* Assisted Move remains Experimental.
* No current-facing v0.2 language.

````

---

# Recommended Phase 14 Definition of Done

```markdown
# Phase 14 Definition of Done

Phase 14 is complete when:

1. The app still identifies as `v0.1.1`, not v0.2.
2. Main Settings sidebar is reduced to:
   - General
   - Hide & Reveal
   - Arrange
   - Find & Rescue
   - Privacy
   - Recovery
   - Advanced
3. Icon placement is a first-class normal workflow under Arrange.
4. Guided Manual Arrange is Stable and permission-free.
5. Placement Planner is Preview and Pro/Accessibility gated.
6. Assisted Move remains Experimental and explicitly confirmed per move.
7. Assisted Move is single-item only.
8. Assisted Move has dry-run, verification, and failure recovery.
9. Icon Moving is no longer a disconnected hidden feature island.
10. Find Icon, Second Bar, New Item Inbox, and Crowded Rescue are consolidated into Find & Rescue.
11. New Menu Bar Item Inbox exists behind Pro Discovery.
12. Heavy features are moved under Advanced:
    - Profiles
    - Smart Triggers
    - Dynamic Hotkeys
    - Private Access
    - advanced Groups
    - App Intents
    - URL automation
    - Import / Export
    - Spacing Labs
    - Dogfood/internal
13. Spacing Labs apply/restore/reset is not exposed in normal flow.
14. Automation is not a main product pillar.
15. Import/export complexity is not a main product pillar.
16. Status menu is simplified and includes Arrange.
17. Docs explain the three icon-placement layers:
    - Stable manual arrange
    - Preview placement planner
    - Experimental assisted move
18. Privacy boundary remains intact.
19. All required tests pass.
20. `docs/progress/phase-14-v0.1.1-product-diet-guided-placement.md` includes:
    - summary
    - changed files
    - test results
    - manual QA notes
    - known limitations
    - deferred work
````

---

# Suggested Codex Subtask Breakdown

Do not ask Codex to do all of Phase 14 in one pass. Run it in slices.

## Phase 14A — Product Taxonomy + Settings Diet

```markdown
Implement Phase 14A only:
- create product taxonomy doc
- add feature visibility model if needed
- reduce Settings sidebar to General, Hide & Reveal, Arrange, Find & Rescue, Privacy, Recovery, Advanced
- move old heavy sections under Advanced
- update UI smoke tests
- do not implement new placement planner yet
- do not change icon moving internals yet
- keep version v0.1.1
```

## Phase 14B — Guided Manual Arrange

```markdown
Implement Phase 14B only:
- add Arrange settings page
- add guided manual command-drag flow
- add diagrams using SwiftUI only, no screenshots
- add status menu “Arrange Items…”
- connect onboarding to Arrange
- add Basic placement test actions
- add tests
- no Pro required
- no Accessibility prompt
```

## Phase 14C — Placement Planner

```markdown
Implement Phase 14C only:
- add Pro Placement Planner models and UI
- use Accessibility metadata only behind existing gates
- generate non-mutating placement recommendations
- integrate with Find Icon / Second Bar / groups where safe
- add diagnostics redaction
- add tests
- no auto move
```

## Phase 14D — Assisted Move Flow

```markdown
Implement Phase 14D only:
- keep Assisted Move Experimental
- add dry-run / confirmation / result UI
- integrate with existing Moving services
- route through Command Center gates
- single-item only
- no bulk moving
- add recovery on failure
- add tests for all gates and dry-run no-CGEvent behavior
```

## Phase 14E — New Item Inbox + Find & Rescue

```markdown
Implement Phase 14E only:
- add New Menu Bar Item Inbox behind Pro Discovery
- consolidate Find Icon, Second Bar, Crowded Rescue, and lightweight groups into Find & Rescue
- update status menu conditional “Open New Items…”
- add privacy-safe storage and tests
```

## Phase 14F — Advanced Diet + Docs + Final Validation

```markdown
Implement Phase 14F only:
- move automation/import-export/spacing/private-access/profile/trigger complexity under Advanced
- rewrite docs for focused v0.1.1 product
- update manual QA matrix
- run full validation commands
- record results in phase progress doc
```

---

The key design decision for Phase 14 is:

> **Do not remove icon moving. Make manual icon arrangement stable, make placement planning helpful, and keep automated assisted moving experimental.**

That gives normal users the icon-moving flow they need, while keeping the app light, safe, and honest.
