
# Phase 13 Codex Execution Pack

```markdown
# Codex Execution Pack
# Phase 13 — v0.1.1 Pro Workflow Completion & Competitive UX Pack

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar utility written in Swift, AppKit, and SwiftUI.

This phase continues the `v0.1.1` line. It is **not v0.2**. Do not use `v0.2`, `0.2`, or `v0.2.0` in current docs, UI, release notes, or roadmap.

Phase 12 should already have hardened release claims, privacy boundaries, Basic Mode, feature gates, and release tooling. Phase 13 now turns the Phase 10/11 Pro scaffolding into cohesive, gated, testable user workflows, still under the `v0.1.1` version line.

## Phase Mission

Build the v0.1.1 Pro Workflow Completion Pack.

The goal is to make advanced features feel like one coherent product instead of disconnected Settings surfaces.

Primary v0.1.1 Pro workflows:

1. Command Center:
   - unified Find Icon + Second Bar + Groups action routing

2. Second Bar / Icon Panel:
   - browse, search, filter, and act on discovered menu bar items

3. Crowded Menu Rescue:
   - real decision engine and reveal fallback flow

4. Groups:
   - create, edit, search, protect, hotkey, import/export

5. Private Access:
   - protect app-owned actions, groups, hotkeys, profiles, and automation commands

6. Profiles:
   - Work/Home/Presentation style workflows with dry-run, apply, conflict handling, and explanation

7. Dynamic Hotkeys:
   - bind hotkeys to commands, groups, profiles, and reveal/highlight actions

8. App Intents / URL Automation:
   - complete unified gates and predictable results

9. Import / Export:
   - real local backup/export/import flow, not placeholder scaffolding

10. Spacing Labs:
   - either complete Labs 1.0 safely, or keep it dry-run/hidden. Do not expose half-complete global defaults mutation.

## Hard Rules

1. This is still `v0.1.1`.
2. Do not call anything `v0.2`.
3. Do not introduce ScreenCaptureKit.
4. Do not introduce Screen Recording permission.
5. Do not introduce Apple Events.
6. Do not introduce Input Monitoring.
7. Do not introduce network telemetry, cloud sync, analytics, crash upload, or remote config.
8. Do not silently prompt for Accessibility.
9. Do not use private Apple menu bar APIs.
10. Do not make Icon Moving stable.
11. Do not claim to visually capture real menu bar pixels.
12. Do not claim Private Access encrypts or hides third-party menu bar items already visible in the system menu bar.
13. Do not expose Spacing Labs apply/restore/reset unless backup/restore semantics are reliable and tested.
14. All Pro actions must degrade clearly when Pro Mode, Accessibility Discovery, or Accessibility permission is unavailable.
15. All protected app-owned actions must go through the same Private Access gate.
16. App Intents and URL automation must not bypass app gates.

## Initial Repository Checks

Run:

```bash
git status --short
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
````

Create:

`docs/progress/phase-13-v0.1.1-pro-workflow-completion.md`

Document baseline results before making changes.

---

# Workstream 13.1 — Menu Bar Command Center Core

## Goal

Create one shared command model and command router used by Find Icon, Second Bar, Groups, Hotkeys, Profiles, App Intents, and URL automation.

Currently these surfaces exist but are not fully unified. Phase 13 should prevent each UI from reinventing action routing and gate checks.

## Suggested New Source Area

Create if appropriate:

`MenuBar-Manager/CommandCenter/`

Suggested files:

* `MenuBarCommand.swift`
* `MenuBarCommandTarget.swift`
* `MenuBarCommandContext.swift`
* `MenuBarCommandResult.swift`
* `MenuBarCommandAvailability.swift`
* `MenuBarCommandGate.swift`
* `MenuBarCommandRouter.swift`
* `MenuBarCommandDiagnostics.swift`
* `MenuBarCommandCenterViewModel.swift`

Use existing project style and naming conventions. If the repo already has equivalent types, extend those instead of duplicating.

## Command Targets

Support targets such as:

* global app visibility
* specific discovered menu bar item identity
* group
* profile
* Second Bar / Icon Panel
* Full Menu Bar Mode
* layout suggestion
* automation pause/resume
* spacing preset request
* protected resource
* experimental icon activation

## Command Actions

Support at least:

* expand
* collapse
* toggle
* reveal all
* reveal hidden zone
* reveal always-hidden zone
* show Find Icon
* show Second Bar
* show Icon Panel
* show item in Second Bar
* reveal item
* highlight item
* open owning app
* add item to group
* remove item from group
* assign hotkey
* protect resource
* unlock protected action
* apply profile
* dry-run profile
* pause automation
* resume automation
* show layout suggestions
* enter Full Menu Bar Mode
* exit Full Menu Bar Mode
* spacing preset dry-run
* spacing preset apply, Labs only if completed
* experimental activate item, Pro/AX/confirmation required

## Gates

Every command must evaluate:

* Safe Mode
* Basic availability
* Pro Mode
* Accessibility Discovery
* Accessibility permission
* feature enabled setting
* Labs setting
* Private Access requirement
* Automation pause/global enable
* item identity availability
* stale scan
* experimental feature confirmation
* unsupported target

## Result Model

Every command should return a structured result:

* success
* unavailable
* blocked
* requiresPermission
* requiresUnlock
* requiresPro
* requiresLabs
* dryRunOnly
* failed
* noOp

Include a user-facing message and a privacy-safe diagnostic reason.

Do not include live search query, selected item identity, protected names, or full file paths in diagnostics.

## Integration

Refactor the following to use the command router:

* Find Icon selection actions
* Second Bar item action menu
* Group panel actions
* Dynamic hotkey execution
* Profile apply/dry-run
* URL automation
* App Intents
* status menu advanced actions where appropriate

## Acceptance Criteria

* One command path handles gates consistently.
* Search, Second Bar, Groups, Hotkeys, URL automation, and App Intents do not bypass gates.
* Unit tests cover gate combinations.
* Diagnostics are privacy-safe.
* UI can explain why an action is unavailable.

---

# Workstream 13.2 — Find Icon 2.0

## Goal

Turn Find Icon from search + reveal/highlight into a command-oriented workflow.

## Tasks

1. Keep existing privacy boundary:

   * no screenshots
   * no pixels
   * Accessibility metadata only when Pro/Discovery/Permission are enabled
   * live query text excluded from diagnostics/export

2. Add result filters:

   * All
   * Visible
   * Hidden
   * Always Hidden
   * Groups
   * Recent
   * Favorites
   * Protected
   * Stale/Needs Rescan if useful

3. Add result actions through `MenuBarCommandRouter`:

   * Reveal
   * Highlight
   * Show in Second Bar
   * Add to Group
   * Assign Hotkey
   * Protect
   * Open Owning App
   * Experimental Activate, gated

4. Add recents/favorites storage.

   Storage must be privacy-safe:

   * store stable internal identity hashes if possible
   * avoid exporting selected item identities by default
   * provide reset recents/favorites

5. Keyboard behavior:

   * Up/Down selection
   * Enter default action
   * Command+Enter show in Second Bar/Icon Panel
   * Option+Enter open owning app
   * Escape close
   * Tab between search/results/actions if applicable

6. Add empty/unavailable states:

   * Pro off
   * Discovery off
   * Accessibility not granted
   * no scan yet
   * scan stale
   * Safe Mode
   * no results

7. Update Search Settings:

   * default action preference
   * include/exclude Always Hidden
   * show recents
   * show favorites
   * enable protected results display

## Files to Inspect

* `Search/`
* `Accessibility/`
* `MenuBarItemSurfaceCoordinator`
* `Settings/Search`
* `Diagnostics`
* `Tests` related to search ranking and panels

## Acceptance Criteria

* Find Icon can route item actions without duplicating logic.
* No result action bypasses Pro/AX/Private Access gates.
* Recents/favorites do not leak into diagnostics/export.
* Search panel remains useful even when degraded.
* Unit tests cover ranking, filters, command availability, and redaction.

---

# Workstream 13.3 — Second Bar 2.0 / Icon Panel

## Goal

Productize Second Bar as the main crowded-menu-bar fallback and add an Icon Panel mode.

## Tasks

1. Add two presentation modes:

   * Second Bar: horizontal, menu-bar-like strip
   * Icon Panel: compact grid/list panel

2. Shared capabilities:

   * search
   * keyboard navigation
   * zone badges
   * group filters
   * protected badges
   * recents/favorites
   * compact/detailed density
   * labels on/off
   * app/bundle icon display
   * no screenshots

3. Placement:

   * below menu bar
   * near mouse
   * last position
   * current display
   * notch-aware estimate
   * clamp to visible frame
   * recover after display changes
   * recover after sleep/wake

4. Actions:

   * reveal item
   * highlight item
   * show owning app
   * add to group
   * assign hotkey
   * protect item/action
   * experimental activate item, gated

5. Behavior:

   * outside-click close
   * pinned mode
   * reopen last mode
   * default mode setting
   * show from status menu
   * show from Find Icon
   * show from hotkey
   * show from App Intent / URL command

6. Diagnostics:

   * placement mode
   * placement failure reason
   * item count by zone
   * no item identities in normal export
   * no live search text

## Files to Inspect

* `SecondBar/`
* `Layout/`
* `Search/`
* `Groups/`
* `MenuBarItemSurfaceCoordinator`
* `Settings/SecondBar`
* `Settings/Layout`
* `Diagnostics`

## Acceptance Criteria

* Second Bar and Icon Panel share command actions.
* Both modes degrade clearly without Pro/AX.
* Placement survives display changes.
* Crowded Rescue can open Second Bar/Icon Panel as fallback.
* Tests cover placement, availability, filters, and command routing.

---

# Workstream 13.4 — Crowded Menu Rescue 2.0

## Goal

Make crowded reveal handling real, not just a service/suggestion scaffold.

When the user expands/reveals and estimated inline menu bar capacity is insufficient, the app should choose a safe fallback.

## Tasks

1. Create or complete:

`CrowdedRevealDecisionEngine`

Inputs:

* current collapsed/expanded state
* hidden item count
* always-hidden item count
* estimated menu bar capacity
* notch risk estimate
* external display state
* active layout mode
* user preference
* Second Bar availability
* Full Menu Bar Mode availability
* Safe Mode state
* Pro/AX availability

Outputs:

* inlineReveal
* fullMenuBarMode
* secondBar
* iconPanel
* showLayoutSuggestion
* askUser
* blocked
* noOp

2. User preferences:

   * Always try inline first
   * Prefer Second Bar when crowded
   * Prefer Full Menu Bar Mode
   * Ask every time
   * Disable rescue automation

3. Wire decision engine into:

   * normal expand path
   * reveal all path
   * status menu reveal commands
   * Find Icon reveal action
   * group reveal action

4. Add user-facing explanation:

   * “Inline reveal may not fit”
   * “Opened Second Bar instead”
   * “Full Menu Bar Mode entered temporarily”
   * “Use Apple Menu Bar settings to reduce system items”
   * “Spacing Labs suggestion available”

5. Diagnostics:

   * decision kind
   * blocked reason
   * fallback used
   * no app identities

6. Tests:

   * enough capacity -> inline reveal
   * low capacity -> Second Bar
   * low capacity + Second Bar unavailable -> Full Menu Bar Mode
   * Safe Mode -> no automation
   * Pro off -> Basic fallback only
   * user asks every time -> no silent switch
   * diagnostics redaction

## Files to Inspect

* `Layout/`
* `Hiding/`
* `StatusBar/`
* `SecondBar/`
* `Search/`
* `Groups/`
* `Settings/Layout`
* `Diagnostics`

## Acceptance Criteria

* Crowded reveal path is actually wired.
* Low-capacity reveal no longer silently fails.
* User can choose rescue preference.
* Rescue uses Second Bar/Icon Panel when appropriate.
* Safe Mode disables automatic rescue.
* Tests cover decision engine.

---

# Workstream 13.5 — Groups 1.0 Workflow Completion

## Goal

Turn Groups from model/scaffolding into a user workflow.

## Tasks

1. Group creation entry points:

   * Settings → Groups
   * Find Icon result action
   * Second Bar item action
   * Icon Panel item action
   * command palette / Command Center if implemented

2. Group properties:

   * name
   * icon
   * optional color/style for app-owned UI only
   * protected flag
   * preferred zone
   * default action
   * optional hotkey
   * member matching rules

3. Smart suggested groups:

   * Cloud
   * VPN / Network
   * Chat
   * Audio / Media
   * Dev Tools
   * Capture / Meeting
   * Finance / Crypto
   * System Utilities
   * Other

4. Group actions:

   * reveal group
   * show group panel
   * search within group
   * add/remove member
   * protect/unprotect group
   * assign group hotkey
   * apply preferred zone, dry-run unless icon move is explicitly enabled
   * export group
   * import group

5. Protected groups:

   * opening protected group panel can require Private Access
   * revealing protected group can require Private Access
   * group name redacted in diagnostics/export by default

6. Group status items:

   * remain off by default
   * app-owned only
   * no claim that third-party icons are truly merged into a native system group
   * clear Preview/Experimental badge if exposed

7. Validation:

   * duplicate names
   * empty groups
   * stale item identities
   * broken matching rules
   * protected export redaction

## Files to Inspect

* `Groups/`
* `Search/`
* `SecondBar/`
* `PrivateAccess/`
* `Hotkeys/`
* `Migration/`
* `Settings/Groups`
* `Diagnostics`

## Acceptance Criteria

* User can create a group from an item action.
* User can reveal/search/protect/hotkey a group.
* Groups appear in Find Icon / Icon Panel filters.
* Protected groups use Private Access gate.
* Group export/import is schema-versioned and privacy-safe.
* Group status items remain opt-in.

---

# Workstream 13.6 — Private Access 1.0 Coverage

## Goal

Make Private Access a clear, useful, app-owned protection feature.

Private Access must not be described as encryption. It must not claim to hide third-party menu bar items already visible in the system menu bar.

## Protectable Resources

Support protection for:

* Second Bar opening
* Icon Panel opening
* Always Hidden reveal
* protected group panel
* protected group reveal
* protected hotkey target
* protected profile apply
* protected App Intent
* protected URL automation command
* experimental icon activation command

## Tasks

1. Route all protected actions through one gate:

   * `ProtectedActionGate`
   * or existing `PrivateAccess` service if already equivalent

2. Add unlock session policies:

   * once
   * 1 minute
   * 5 minutes
   * until app quit
   * manual lock now

3. Add LocalAuthentication outcomes:

   * success
   * cancel
   * failure
   * unavailable
   * fallback password unavailable
   * locked out

4. Add UI:

   * Private Access Settings
   * protected resource list
   * session status
   * lock now
   * explanation of boundary

5. Add Safe Mode behavior:

   * clear sessions
   * block protected automation
   * keep recovery available

6. Add diagnostics redaction:

   * no protected resource names
   * no protected target IDs
   * no unlock session details beyond safe status

7. Add tests:

   * gate allow
   * gate deny
   * session expiration
   * Safe Mode clears session
   * App Intent cannot bypass gate
   * URL automation cannot bypass gate
   * diagnostics redaction

## Files to Inspect

* `PrivateAccess/`
* `Shortcuts/`
* `Profiles/`
* `Hotkeys/`
* `Groups/`
* `Search/`
* `SecondBar/`
* `Diagnostics`
* `Health/`

## Acceptance Criteria

* Protected actions are uniformly gated.
* Touch ID/password outcomes are handled.
* Protected actions do not run from App Intents/URLs without gate approval.
* Safe Mode clears active unlock sessions.
* UI clearly states Private Access boundaries.

---

# Workstream 13.7 — Profiles 2.0 Within v0.1.1

## Goal

Complete practical local profile workflows while keeping automation conservative.

Do not call this v0.2. This is still v0.1.1 profile completion.

## Built-in Profile Templates

Add optional templates:

* Work
* Home
* Presentation
* Screen Sharing
* Travel
* Meeting Mode
* Developer Mode
* Focus Writing

## Profile Contents

Profiles may include:

* collapsed state preference
* start collapsed preference
* auto-rehide
* hover reveal
* always-hidden zone
* Second Bar/Icon Panel preference
* crowded rescue preference
* group visibility preferences
* protected groups
* dynamic hotkeys
* automation pause preference
* layout suggestion preference
* Full Menu Bar Mode preference
* Labs settings only if Labs is enabled
* icon moving target zones as dry-run plans only unless explicit experimental moving is enabled

## Trigger Providers

Stable or near-stable providers for this phase:

* display count
* external monitor attached
* frontmost app
* launched app
* battery low
* time of day

Keep these inactive unless already safely implemented:

* Focus
* Wi-Fi

Do not introduce location triggers in this phase.

## Tasks

1. Add profile templates.
2. Add dry-run preview.
3. Add apply summary.
4. Add conflict resolver.
5. Add last-applied profile record.
6. Add “why profile applied” explanation.
7. Add manual override cooldown.
8. Add automation pause reason.
9. Add trigger history diagnostics, privacy-safe.
10. Ensure Safe Mode blocks trigger application.
11. Ensure URL automation and App Intents use the same profile apply gate.

## Files to Inspect

* `Profiles/`
* `Settings/Profiles`
* `App/ProfileAutomationCoordinator`
* `Shortcuts/`
* `Layout/`
* `Groups/`
* `Hotkeys/`
* `Diagnostics`

## Acceptance Criteria

* User can create, duplicate, dry-run, and apply Work/Home/Presentation style profiles.
* Trigger application explains why it happened.
* Trigger conflicts are handled deterministically.
* Automation pause blocks trigger apply.
* Safe Mode blocks trigger apply.
* Focus/Wi-Fi remain inactive unless truly implemented and tested.
* Profile export/import uses schema versioning.

---

# Workstream 13.8 — Dynamic Hotkeys 1.0

## Goal

Make dynamic hotkeys useful by binding them to Command Center actions.

## Hotkey Target Types

Support:

* toggle visibility
* expand
* collapse
* reveal all
* show Find Icon
* show Second Bar
* show Icon Panel
* apply profile
* reveal group
* show group panel
* reveal/highlight specific item
* open owning app
* pause/resume automation
* enter/exit Full Menu Bar Mode
* protected command
* experimental activate item, gated

## Tasks

1. Refactor dynamic hotkey execution to use `MenuBarCommandRouter`.

2. Add assignment entry points:

   * Settings → Hotkeys
   * Find Icon result action
   * Second Bar item action
   * Group editor
   * Profile editor

3. Conflict handling:

   * duplicate internal hotkey
   * reserved system-like combos
   * invalid combo
   * Carbon registration failure
   * target unavailable
   * protected target needs Private Access

4. Add UI:

   * hotkey list
   * target type
   * availability
   * conflict reason
   * last registration status
   * reset hotkey
   * disable hotkey

5. Add diagnostics:

   * count
   * registration successes/failures
   * conflict count
   * no protected target names
   * no selected item identity

6. Add tests:

   * conflict detection
   * registration model
   * command routing
   * gate unavailable
   * Private Access protected target
   * Safe Mode disables dynamic hotkeys

## Files to Inspect

* `Hotkeys/`
* `Settings/Hotkeys`
* `Search/`
* `SecondBar/`
* `Groups/`
* `Profiles/`
* `PrivateAccess/`
* `Diagnostics`

## Acceptance Criteria

* Hotkeys execute through command router.
* Hotkeys do not bypass gates.
* Protected hotkeys require Private Access.
* Safe Mode disables dynamic hotkeys.
* Hotkey import/export is schema-versioned.

---

# Workstream 13.9 — App Intents and URL Automation Completion

## Goal

Complete predictable automation behavior for v0.1.1.

App Intents and URL commands must use the same command gate and command router as UI and hotkeys.

## Supported Actions

Stable or Preview actions:

* expand
* collapse
* toggle
* reveal all
* show Find Icon
* show Second Bar
* show Icon Panel
* apply profile
* dry-run profile
* pause automation
* resume automation
* toggle Full Menu Bar Mode
* show layout suggestions
* show group panel
* reveal group
* spacing preset dry-run
* spacing preset apply only if Spacing Labs is fully completed and Labs is enabled

## Tasks

1. Consolidate App Intent execution and URL route execution through:

   * `AutomationCommandGate`
   * `MenuBarCommandRouter`

2. Every automation result must include:

   * success
   * unavailable
   * blocked by Safe Mode
   * blocked by automation pause
   * blocked by Pro gate
   * blocked by Accessibility gate
   * blocked by Private Access
   * blocked by Labs gate
   * dry-run only
   * failed with safe reason

3. Add Settings → Automation availability matrix:

   * action name
   * current status
   * required gate
   * stable/preview/labs/experimental badge

4. Rename misleading spacing preset intent if it does not apply:

   * from “Apply Spacing Preset”
   * to “Preview Spacing Preset”
     unless full safe apply exists.

5. Add tests:

   * Safe Mode blocks
   * automation paused blocks
   * Pro off blocks Pro action
   * AX missing blocks AX action
   * Private Access blocks protected action
   * Labs off blocks Labs action
   * dry-run action does not mutate settings
   * URL and App Intent produce equivalent gate results

## Files to Inspect

* `Shortcuts/`
* `Profiles/`
* `App/ProfileAutomationCoordinator`
* `Settings/Automation`
* URL routing code for `menubardeclutter://`
* `PrivateAccess/`
* `Layout/`
* `Diagnostics`

## Acceptance Criteria

* App Intents appear in Shortcuts with accurate names.
* App Intents do not bypass gates.
* URL automation does not bypass gates.
* Automation pause is respected everywhere.
* Spacing preset action is either real and gated, or honestly preview-only.
* Tests cover gate matrix.

---

# Workstream 13.10 — Import / Export / Backup / Restore 1.0

## Goal

Replace placeholder migration scaffolding with real local backup/export/import behavior.

No cloud sync. No network. No telemetry.

## Export Kinds

Support:

1. Safe Support Export

   * diagnostics
   * health report
   * redacted settings summary
   * no protected names
   * no selected item identity
   * no live query
   * no full paths unless explicitly selected

2. Local Settings Backup

   * settings
   * profiles
   * groups
   * hotkeys
   * layout preferences
   * Labs settings if included
   * protected metadata only if user explicitly chooses complete backup

3. Profile Pack

   * selected profiles
   * optional group references
   * schema version

4. Group Pack

   * selected groups
   * redacted protected fields by default

## Import Flow

Implement:

1. Select file.
2. Validate schema.
3. Parse.
4. Show diff preview.
5. Let user choose sections:

   * settings
   * profiles
   * groups
   * hotkeys
   * layout
   * Labs
6. Create backup.
7. Apply selected sections.
8. Restart affected services.
9. Verify.
10. Roll back on failure.
11. Show result summary.

## Schema Metadata

Every export must include:

* app name
* app version
* schema version
* export kind
* created date
* redaction mode
* included sections

## Migration Assistant

For competitor migration:

* Do not implement aggressive auto-import unless schema is confirmed.
* Provide guided migration checklist only.
* Do not parse competitor private config unless user explicitly chooses a file and the schema is known.
* Do not claim Bartender/Ice/SaneBar auto-import as complete.

## Tasks

1. Replace placeholder settings export with real values.
2. Add schema types.
3. Add validation.
4. Add diff preview.
5. Add apply/commit path.
6. Add backup creation.
7. Add rollback.
8. Add result summary.
9. Add redaction controls.
10. Add tests for each export/import kind.

## Files to Inspect

* `Migration/`
* `Core/SettingsStore`
* `Profiles/`
* `Groups/`
* `Hotkeys/`
* `Layout/`
* `PrivateAccess/`
* `Dogfood/`
* `Diagnostics`
* `Settings/ImportExport`

## Acceptance Criteria

* Real settings export contains real settings, not placeholders.
* Import dry-run does not mutate state.
* Import apply mutates only selected sections.
* Backup is created before apply.
* Rollback works on simulated failure.
* Protected metadata redacted by default.
* Export/import tests pass.

---

# Workstream 13.11 — Spacing Labs 1.0 or Safe Defer

## Goal

Resolve the half-complete Spacing Labs state.

Spacing Labs mutates global menu bar spacing defaults, so it must either be fully safe or not exposed as an apply feature.

## Required Decision

Implement one of the following two outcomes:

## Outcome A — Complete Spacing Labs 1.0

Only choose this if reliable backup/restore/reset can be implemented and tested.

Tasks:

1. UI controls:

   * Dry Run
   * Apply Preset
   * Restore Previous
   * Reset to System Default
   * View Backup
   * Explain Logout/Restart Requirement

2. Backup persistence:

   * previous values
   * applied preset
   * timestamp
   * app version
   * schema version
   * restore status

3. Safety:

   * Labs must be enabled
   * strong confirmation before apply
   * never auto-kill or restart SystemUIServer
   * never apply from App Intent unless Labs enabled and command gate allows
   * Safe Mode blocks apply
   * restore blocked when no backup exists
   * reset requires explicit confirmation

4. Tests:

   * dry-run no mutation
   * apply writes expected model
   * backup created
   * restore uses backup
   * missing backup blocks restore
   * reset path
   * Safe Mode blocks
   * Labs off blocks
   * App Intent cannot bypass Labs gate

## Outcome B — Safe Defer

Choose this if reliable backup/restore cannot be implemented safely in this phase.

Tasks:

1. Hide Apply/Restore/Reset UI.
2. Keep Dry Run and Suggestions only.
3. Rename App Intent to Preview only.
4. Add docs:

   * “Spacing Labs apply is deferred”
5. Add tests:

   * no apply path exposed
   * Labs off blocks
   * dry-run no mutation

## Files to Inspect

* `Layout/`
* `Settings/Layout`
* `Shortcuts/`
* `Profiles/`
* `Diagnostics`
* `Health/`

## Acceptance Criteria

* There is no half-complete apply UI.
* App Intents cannot apply spacing unless full Labs 1.0 exists.
* Global defaults mutation never happens accidentally.
* Release docs state the real behavior.

---

# Workstream 13.12 — Icon Moving Guardrail Refresh

## Goal

Keep Icon Moving experimental while making the surrounding workflow safer.

Do not make Icon Moving stable in v0.1.1.

## Tasks

1. Ensure every icon moving entry point is gated:

   * Pro Mode
   * Accessibility permission
   * Icon Moving enabled
   * experimental confirmation
   * item frame available
   * not app-owned protected item
   * not likely system item unless explicitly allowed
   * Safe Mode off

2. Integrate with command router:

   * move command returns unavailable/experimental/failed/success
   * command router does not hide failure details
   * user gets recovery path after failure

3. Add move dry-run:

   * show planned drag
   * show target zone
   * show risk warning
   * no actual CGEvent

4. Add docs:

   * `docs/features/icon-moving-v0.1.1-experimental.md`

5. Tests:

   * system item blocked
   * own app items blocked
   * missing frame blocked
   * Safe Mode blocked
   * dry-run does not execute CGEvent
   * failure restores visibility state

## Files to Inspect

* `Moving/`
* `Search/`
* `SecondBar/`
* `Groups/`
* `CommandCenter/`
* `Health/`
* `Diagnostics`

## Acceptance Criteria

* Icon Moving remains Experimental.
* All entry points require explicit enablement.
* Dry-run is available.
* Failure does not strand the app in hidden/collapsed state.
* Docs are honest.

---

# Workstream 13.13 — v0.1.1 Pro Docs and Product Contract

## Goal

Document the completed v0.1.1 Pro workflows without using v0.2 language.

Create or update:

* `docs/features/command-center-v0.1.1.md`
* `docs/features/find-icon-v0.1.1.md`
* `docs/features/second-bar-icon-panel-v0.1.1.md`
* `docs/features/crowded-rescue-v0.1.1.md`
* `docs/features/groups-v0.1.1.md`
* `docs/features/private-access-v0.1.1.md`
* `docs/features/profiles-v0.1.1.md`
* `docs/features/dynamic-hotkeys-v0.1.1.md`
* `docs/features/automation-v0.1.1.md`
* `docs/features/import-export-v0.1.1.md`
* `docs/features/spacing-labs-v0.1.1.md`
* `docs/release/v0.1.1-pro-workflow-notes.md`
* `docs/progress/phase-13-v0.1.1-pro-workflow-completion.md`

Docs must state:

* Basic Mode remains the default.
* Pro Mode remains opt-in.
* Accessibility remains explicit.
* No Screen Recording.
* No ScreenCaptureKit.
* No cloud.
* No telemetry.
* Private Access protects app-owned actions only.
* Icon Moving is experimental.
* Spacing Labs is Labs or deferred.
* Focus/Wi-Fi triggers remain inactive unless actually completed.
* This is v0.1.1, not v0.2.

## Acceptance Criteria

* Docs match implementation.
* No v0.2 naming.
* Every Pro workflow has a user-facing explanation.
* Every risky feature has clear gate and limitation text.

---

# Required Tests and Commands

After implementation, run:

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
rg -n "ScreenCaptureKit|NSScreenCaptureUsageDescription|NSAppleEventsUsageDescription|URLSession|NWConnection|analytics|telemetry|Sentry|Firebase" MenuBar-Manager Config scripts docs || true
rg -n "placeholder|TODO|FIXME|stub|scaffold" MenuBar-Manager/Migration MenuBar-Manager/Shortcuts MenuBar-Manager/Layout MenuBar-Manager/Search MenuBar-Manager/SecondBar MenuBar-Manager/Groups docs/release docs/features || true
```

Inspect search results manually. Fix current-release misleading items. It is acceptable to keep well-labeled deferred notes.

---

# Phase 13 Definition of Done

Phase 13 is complete when:

1. Current release line remains `v0.1.1`.
2. No current-facing docs/UI refer to `v0.2`.
3. Command Center routing exists or equivalent shared command routing is implemented.
4. Find Icon actions route through the shared command path.
5. Second Bar/Icon Panel actions route through the shared command path.
6. Crowded Reveal Rescue is wired into real reveal decisions.
7. Groups are usable from Find Icon / Second Bar / Icon Panel.
8. Private Access gates all protected app-owned actions.
9. Profiles have templates, dry-run, apply, explanation, and conflict handling.
10. Dynamic Hotkeys execute command-router actions and respect gates.
11. App Intents and URL automation use unified gates.
12. Import/export uses real values, schema versions, backup, apply, and rollback.
13. Spacing Labs is either fully safe or safely deferred.
14. Icon Moving remains experimental and guarded.
15. Privacy boundary remains intact.
16. All required tests pass.
17. `docs/progress/phase-13-v0.1.1-pro-workflow-completion.md` contains:

    * summary
    * changed files
    * test results
    * manual QA notes
    * known limitations
    * remaining deferred work

````

---

# 建议的执行顺序

## Phase 13 分批

1. **13A — Command Center Core**
   - shared command model
   - gate model
   - command router
   - diagnostics

2. **13B — Find Icon + Second Bar / Icon Panel**
   - refactor actions through router
   - filters
   - recents/favorites
   - placement recovery

3. **13C — Crowded Rescue + Groups**
   - decision engine
   - reveal path wiring
   - group workflow completion

4. **13D — Private Access + Dynamic Hotkeys**
   - protected action coverage
   - session behavior
   - hotkey command targets

5. **13E — Profiles + App Intents / URL Automation**
   - profile templates
   - trigger explanation
   - unified automation gate

6. **13F — Import/Export + Spacing Labs Decision**
   - real export/import/backup/rollback
   - Spacing Labs full safe implementation or safe defer

7. **13G — Docs / Tests / Release Validation**
   - v0.1.1 Pro workflow docs
   - privacy verification
   - installed-app validation

---
