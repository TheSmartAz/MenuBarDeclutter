
# Phase 21 — v0.1.8 Workspace Integration Pack

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar decluttering utility written in Swift, AppKit, and SwiftUI.

This phase follows:

- Phase 17 / v0.1.4 Workspaces Foundation
- Phase 18 / v0.1.5 Set Switcher + Virtual Function Bar MVP
- Phase 19 / v0.1.6 Linked Groups + Set Builder MVP
- Phase 20 / v0.1.7 Info Strip MVP

The active release line for this phase is:

`v0.1.8`

This phase is **not v0.2**. Do not create v0.2 docs, v0.2 release notes, v0.2 public claims, v0.2 artifact names, or current-facing v0.2 roadmap language.

## Phase Mission

Phase 21 turns the Workspace system into an integrated app workflow.

The goal is:

> Workspaces should no longer feel like a separate Advanced experiment. Existing features should understand Workspaces: New Item Inbox, Find Icon, Placement Planner, Crowded Rescue, Function Bar, Info Strip, Set Builder, Groups, Profiles, backup/restore, diagnostics, and recovery.

By the end of Phase 21:

1. New Menu Bar Item Inbox can assign new items to:
   - current Workspace
   - selected Workspace
   - existing Group
   - new Group
   - hidden/manual arrangement recommendation
   - assisted move dry-run, still Experimental

2. Find Icon can filter and act by Workspace:
   - current Workspace
   - all Workspaces
   - unassigned items
   - used in other Workspaces
   - group members
   - new items

3. Placement Planner becomes Workspace-aware:
   - item is used in Workspace A/B/C
   - item is unassigned
   - group is used in multiple Workspaces
   - recommendation can say “keep hidden physically but expose in Function Bar”
   - manual arrange guidance can reference Workspace usage

4. Crowded Reveal Rescue can choose Function Bar as a fallback:
   - inline reveal
   - Second Bar
   - current Workspace Function Bar
   - Full Menu Bar Mode
   - ask user
   - show layout suggestions

5. Workspace physical profile binding becomes usable as Preview:
   - dry-run only by default
   - safe Basic settings apply only if explicitly enabled
   - no silent icon moving
   - no bulk move
   - no Spacing Labs mutation
   - no Launch at Login system-state mutation

6. Function Bar and Info Strip can use Workspace-aware item status:
   - new item badge
   - unassigned badge
   - group usage badge
   - stale/missing proxy warning
   - physical profile binding status

7. Import/export/backup includes new Workspace integration metadata safely.

8. Diagnostics and health can detect Workspace integration issues without leaking raw item identities.

9. Basic Mode remains stable and permission-free.

Phase 21 must **not** implement physical workspace switching as stable, bulk icon moving, ScreenCaptureKit, Screen Recording, online widgets, media controls, notification scraping, cloud sync, or competitor import.

## Product Boundary

Workspaces in v0.1.8 are still Preview.

They configure MenuBarDeclutter’s app-owned Workspace / Function Bar / Info Strip layer and can provide dry-run physical layout guidance.

They do not:
- replace the macOS system menu bar
- control the notch/right-side system area directly
- capture live menu bar pixels
- require Screen Recording
- use ScreenCaptureKit
- use private Apple menu bar APIs
- silently apply physical profiles
- silently move third-party menu bar icons
- perform bulk icon moving
- activate arbitrary third-party menu bar items as a stable claim
- use network widgets or telemetry

## Version Target

Set active app version to:

- Marketing version: `0.1.8`
- Build number: increment from `8` to `9`, unless the project has already advanced build numbering.

Release artifacts should use:

- `MenuBarDeclutter-v0.1.8.zip`
- `MenuBarDeclutter-v0.1.8-alpha.zip` only if alpha/dogfood packaging still exists.

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
- Workspaces are Preview/Foundation from v0.1.4.
- Function Bar is Preview from v0.1.5.
- Set Builder and Linked Groups are Preview from v0.1.6.
- Info Strip is Preview from v0.1.7.
- Basic Mode remains the stable product core.

## Hard Rules

1. Do not call this phase v0.2.
2. Do not add Screen Recording.
3. Do not add ScreenCaptureKit.
4. Do not add Apple Events scripting/control.
5. Do not add Input Monitoring.
6. Do not add network access, telemetry, analytics, crash upload, cloud sync, remote config, update checks, or license checks.
7. Do not add weather/news/stocks/online widgets.
8. Do not add media controls that require private APIs.
9. Do not scrape Notification Center.
10. Do not use private Apple menu bar APIs.
11. Do not silently prompt for Accessibility, Calendar, Reminders, or any other permission.
12. Do not make Workspaces stable public claims in v0.1.8.
13. Do not claim Workspaces replace the macOS menu bar.
14. Do not implement stable physical workspace switching.
15. Do not automatically apply physical profiles when switching Workspace.
16. Do not implement bulk icon moving.
17. Do not make assisted icon moving stable.
18. Do not expose broad third-party menu item activation as stable.
19. Do not mutate real menu bar layout from New Item Inbox, Find Icon, Placement Planner, Crowded Rescue, Function Bar, Info Strip, or Set Builder.
20. Keep Workspaces / Function Bar / Set Builder / Info Strip under Preview / Advanced in v0.1.8.
21. Diagnostics must not export raw workspace names, raw workspace item names, raw menu bar item identities, protected group names, protected workspace names, calendar event titles, reminder titles, live search text, drag payload values, or file paths by default.

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

`docs/progress/phase-21-v0.1.8-workspace-integration.md`

Record:

* baseline git status
* baseline version/build
* baseline test results
* baseline privacy verification result
* baseline release dry-run result
* baseline installed-app verification result
* known limitations from Phase 20
* exact date
* short phase goal

---

# Workstream 21.1 — Version and Release Identity

## Goal

Move the active release line from `0.1.7` to `0.1.8`.

## Tasks

1. Search version references:

```bash
rg -n "0\.1\.7|v0\.1\.7|0\.1\.8|v0\.1\.8|0\.2|v0\.2|MARKETING_VERSION|CURRENT_PROJECT_VERSION|CFBundleShortVersionString|CFBundleVersion" .
```

2. Update active version/build values to:

* `0.1.8`
* build `9`

3. Update release artifact naming.

4. Add release notes placeholder:

`docs/release/v0.1.8-release-notes.md`

5. Add release checklist:

`docs/release/v0.1.8-release-checklist.md`

6. Update latest-progress docs that list current release line.

7. Do not create v0.2 docs.

8. If historical docs mention v0.2, leave them only if clearly historical/future. Do not add current-facing v0.2 language.

## Acceptance Criteria

* App bundle reports `0.1.8`.
* Build number is `9` or documented next build number.
* Release artifacts use `v0.1.8`.
* Current-facing docs/UI do not call this v0.2.
* Release dry-run still works.

---

# Workstream 21.2 — Workspace Integration Source Area

## Goal

Create a focused integration layer so Workspace-related cross-feature logic does not spread into Search, New Item Inbox, Placement Planner, Crowded Rescue, and Function Bar one by one.

## New Source Area

Create:

```text
MenuBar-Manager/WorkspaceIntegration/
  Models/
  Runtime/
  Indexing/
  Assignment/
  Suggestions/
  Diagnostics/
```

Suggested files:

```text
MenuBar-Manager/WorkspaceIntegration/Models/WorkspaceItemUsage.swift
MenuBar-Manager/WorkspaceIntegration/Models/WorkspaceAssignment.swift
MenuBar-Manager/WorkspaceIntegration/Models/WorkspaceAssignmentTarget.swift
MenuBar-Manager/WorkspaceIntegration/Models/WorkspaceAssignmentResult.swift
MenuBar-Manager/WorkspaceIntegration/Models/WorkspaceReferenceStatus.swift
MenuBar-Manager/WorkspaceIntegration/Models/WorkspacePhysicalPlan.swift
MenuBar-Manager/WorkspaceIntegration/Models/WorkspaceIntegrationFeatureStatus.swift

MenuBar-Manager/WorkspaceIntegration/Indexing/WorkspaceUsageIndex.swift
MenuBar-Manager/WorkspaceIntegration/Indexing/WorkspaceItemReferenceIndex.swift
MenuBar-Manager/WorkspaceIntegration/Indexing/WorkspaceGroupUsageIndex.swift
MenuBar-Manager/WorkspaceIntegration/Indexing/WorkspaceUnassignedItemIndex.swift

MenuBar-Manager/WorkspaceIntegration/Assignment/WorkspaceAssignmentService.swift
MenuBar-Manager/WorkspaceIntegration/Assignment/WorkspaceAssignmentValidator.swift
MenuBar-Manager/WorkspaceIntegration/Assignment/WorkspaceAssignmentCommandAdapter.swift

MenuBar-Manager/WorkspaceIntegration/Suggestions/WorkspaceRecommendationEngine.swift
MenuBar-Manager/WorkspaceIntegration/Suggestions/WorkspacePlacementRecommendationAdapter.swift
MenuBar-Manager/WorkspaceIntegration/Suggestions/WorkspaceCrowdedRescueAdapter.swift

MenuBar-Manager/WorkspaceIntegration/Runtime/WorkspaceIntegrationCoordinator.swift
MenuBar-Manager/WorkspaceIntegration/Diagnostics/WorkspaceIntegrationDiagnosticsSnapshot.swift
MenuBar-Manager/WorkspaceIntegration/Diagnostics/WorkspaceIntegrationDiagnosticsRedactor.swift
```

If existing equivalent files exist after prior phases, extend them instead of duplicating.

## Module Boundaries

WorkspaceIntegration may depend on:

* Workspaces store/models/switching
* FunctionBar controller
* InfoStrip controller/config
* SetBuilder commit service/library models
* Groups store/resolver
* New Item Inbox store/models
* Search / Find Icon item references
* Placement Planner models
* Layout / Crowded Rescue decision engine
* Profiles dry-run/apply-safe services
* CommandCenter
* Diagnostics redaction helpers

WorkspaceIntegration must not directly depend on:

* ScreenCaptureKit
* Screen Recording
* network APIs
* private Apple APIs
* CGEvent moving execution internals
* InfoStrip provider internals beyond tile status
* low-level Accessibility scanner internals
* App Intents execution service
* URL automation router

## Acceptance Criteria

* `MenuBar-Manager/WorkspaceIntegration/` exists.
* Cross-feature Workspace logic is centralized.
* Existing modules call integration services instead of duplicating logic where feasible.
* Build succeeds.
* No privacy-sensitive APIs are introduced.

---

# Workstream 21.3 — Workspace Usage Index

## Goal

Build a privacy-safe index that answers:

* Which Workspaces use this menu bar item reference?
* Which Workspaces use this Group?
* Which Groups contain this item?
* Is this item unassigned?
* Is this item new?
* Is this item only used in inactive Workspaces?
* Is this item referenced by linked or detached Groups?

## Core Types

Implement:

```swift
struct WorkspaceItemUsage: Equatable {
    var itemHash: String
    var workspaceIDs: [UUID]
    var groupIDs: [UUID]
    var directWorkspaceCount: Int
    var groupReferenceCount: Int
    var linkedGroupReferenceCount: Int
    var detachedGroupReferenceCount: Int
    var isUsedInActiveWorkspace: Bool
    var isUnassigned: Bool
}
```

Do not store raw item name or bundle ID in the usage model.

Implement:

```swift
final class WorkspaceUsageIndex {
    func rebuild(snapshot: WorkspaceStoreSnapshot, groups: [IconGroup]) -> WorkspaceUsageIndexSnapshot
    func usage(for itemHash: String) -> WorkspaceItemUsage
    func workspacesUsingItemHash(_ itemHash: String) -> [UUID]
    func workspacesUsingGroup(_ groupID: UUID) -> [UUID]
    func groupsContainingItemHash(_ itemHash: String) -> [UUID]
    func unassignedItemHashes(from discovered: [MenuBarItemReference]) -> [String]
}
```

Use existing group model name instead of `IconGroup` if different.

## Privacy Rules

Diagnostics can report:

* total indexed items
* direct workspace assignment count
* group assignment count
* unassigned count
* missing reference count

Diagnostics must not report:

* raw item names
* bundle IDs
* workspace names if protected
* group names if protected

## Tests

Add tests:

* item directly used in one Workspace
* item used through linked Group
* item used through detached Group
* item used in multiple Workspaces
* group used by multiple Workspaces
* unassigned item detected
* archived Workspace ignored
* missing Group tolerated
* protected names redacted
* diagnostics only counts

## Acceptance Criteria

* Workspace usage can be queried by item hash/group/workspace.
* Unassigned items can be detected.
* Linked/detached references are represented.
* Diagnostics are privacy-safe.
* Tests pass.

---

# Workstream 21.4 — New Item Inbox → Workspace Assignment

## Goal

Turn New Item Inbox into a Workspace assignment entry point.

## User Story

When Pro Discovery sees a new menu bar item, the user can review it and choose:

* Add to current Workspace
* Add to selected Workspace
* Add to existing Group
* Create new Group with this item
* Keep visible physically, no Workspace assignment
* Hide manually
* Always hide manually
* Show in Find Icon
* Show in Second Bar
* Open Arrange guide
* Run Assisted Move dry-run, still Experimental

## Required Service

Implement:

```swift
final class WorkspaceAssignmentService {
    func assignNewItem(_ item: NewMenuBarItem, to target: WorkspaceAssignmentTarget) -> WorkspaceAssignmentResult
    func assignItemReference(_ reference: MenuBarItemReference, to target: WorkspaceAssignmentTarget) -> WorkspaceAssignmentResult
}
```

Targets:

```swift
enum WorkspaceAssignmentTarget: Equatable {
    case currentWorkspace
    case workspace(UUID)
    case group(UUID)
    case newGroup(name: String, workspaceID: UUID?)
    case visibleOnly
    case manualHidden
    case manualAlwaysHidden
    case noAssignment
}
```

Result:

```swift
struct WorkspaceAssignmentResult: Equatable {
    var status: WorkspaceAssignmentStatus
    var message: String
    var workspaceID: UUID?
    var groupID: UUID?
    var diagnosticReason: String?
}
```

Statuses:

```swift
enum WorkspaceAssignmentStatus: Equatable {
    case success
    case noChange
    case unavailable
    case requiresPro
    case missingWorkspace
    case missingGroup
    case validationFailed
    case blockedBySafeMode
    case failed
}
```

## Rules

* Assignment to Workspace adds a `WorkspaceItem.kind.menuBarItem`.
* Assignment to Group adds the item to Group if group editing is available.
* Creating new Group should create a Group with this item and optionally add that Group to selected Workspace as linked.
* Manual hidden/always-hidden actions should not move icons automatically. They should create an Arrange/Placement recommendation.
* Assisted Move dry-run remains Experimental and should only call existing dry-run planning, not execute movement.
* New Item Inbox dismissed state should be updated only after successful user decision.
* No raw item identities in diagnostics.

## UI Updates

Update New Item Inbox UI:

* Add “Assign to Workspace” action.
* Add Workspace picker.
* Add “Add to Group” action.
* Add “Create Group” action.
* Add “Arrange manually” action.
* Add “Dry-run Assisted Move” action, Experimental badge.
* Show if item is already assigned to one or more Workspaces.
* Show if item is unassigned.

## Tests

Add tests:

* assign new item to current Workspace
* assign new item to selected Workspace
* assign new item to existing Group
* create new Group with item
* create new Group and link to Workspace
* visibleOnly does not mutate Workspace
* manualHidden produces recommendation/no physical movement
* assisted move dry-run does not execute move
* missing Workspace blocked
* missing Group blocked
* Safe Mode behavior conservative
* diagnostics redaction
* dismissed state updates after success

## Acceptance Criteria

* New Item Inbox can assign items into Workspace/Group.
* New items are not silently lost.
* No automatic physical movement occurs.
* Assisted Move remains dry-run/Experimental.
* Tests pass.

---

# Workstream 21.5 — Workspace-Aware Find Icon

## Goal

Make Find Icon understand Workspaces.

## New Filters

Add filters:

* All Items
* Current Workspace
* Any Workspace
* Unassigned
* Used in Other Workspace
* Groups
* New Items
* Hidden / Always Hidden / Visible, if already supported

## Search Ranking Changes

Boost:

* current Workspace items
* new items when filter is New Items
* unassigned items when filter is Unassigned
* recently used in Function Bar
* group members from active Workspace

Deprioritize:

* stale/missing references
* archived Workspace references
* unavailable Pro-only references when Pro unavailable

## Result Badges

Add badges:

* Current Workspace
* Used in N Workspaces
* Unassigned
* New
* Linked Group
* Detached Group
* Missing Reference
* Stale

## Actions

From result:

* Add to current Workspace
* Add to selected Workspace
* Add to Group
* Create Group with item
* Remove from Workspace, if item is directly assigned
* Show in Function Bar
* Show in Second Bar
* Reveal / highlight
* Open owner app
* Arrange manually
* Assisted Move dry-run, Experimental

All actions must route through Command Center or WorkspaceAssignmentService.

## Privacy

Search diagnostics must not include:

* live query
* raw item title
* raw bundle ID
* raw workspace name if protected
* raw group name if protected

## Tests

Add tests:

* current Workspace filter
* any Workspace filter
* unassigned filter
* used in other Workspace filter
* new item filter
* ranking boost for current Workspace
* badges computed correctly
* add to Workspace action
* remove from Workspace action
* diagnostics redaction

## Acceptance Criteria

* Find Icon is Workspace-aware.
* Result actions can assign items.
* Filters are useful and tested.
* Privacy boundary remains intact.

---

# Workstream 21.6 — Workspace-Aware Placement Planner

## Goal

Make Placement Planner understand Workspace usage and provide smarter arrangement recommendations.

## New Recommendation Concepts

Placement Planner should be able to say:

* “This item is used in the current Workspace.”
* “This item is used in 3 Workspaces.”
* “This item is only used in Meeting Workspace.”
* “This item is not assigned to any Workspace.”
* “This item is in a linked Group used by 4 Workspaces.”
* “Recommendation: keep this physically hidden but expose it through Function Bar.”
* “Recommendation: keep this visible because it is used often and belongs to active Workspace.”
* “Recommendation: move to Always Hidden and keep in Workspace Function Bar.”

## Required Adapter

Implement:

```swift
final class WorkspacePlacementRecommendationAdapter {
    func enrich(_ recommendation: PlacementRecommendation, usage: WorkspaceItemUsage) -> WorkspaceAwarePlacementRecommendation
}
```

Model:

```swift
struct WorkspaceAwarePlacementRecommendation: Equatable {
    var baseRecommendation: PlacementRecommendation
    var usage: WorkspaceItemUsage
    var workspaceReason: WorkspacePlacementReason
    var suggestedWorkspaceAction: WorkspaceSuggestedAction?
}
```

Suggested actions:

```swift
enum WorkspaceSuggestedAction: Equatable {
    case addToCurrentWorkspace
    case addToGroup(UUID)
    case keepHiddenExposeInFunctionBar
    case removeFromInactiveWorkspace
    case reviewUnassigned
    case noWorkspaceAction
}
```

## UI Updates

Placement Planner item row should show:

* Workspace usage badge
* “Used in current Workspace”
* “Unassigned”
* “Linked Group”
* suggested Workspace action
* Add to Workspace button
* Keep physically hidden, expose in Function Bar button
* Manual arrange instruction

## Rules

* Planner never mutates physical menu bar layout automatically.
* “Keep hidden but expose in Function Bar” means add item to Workspace and recommend manual hidden physical placement.
* Assisted Move remains dry-run/Experimental.
* Missing Workspace/Group references should not crash.

## Tests

Add tests:

* unassigned recommendation
* current Workspace usage recommendation
* multi-Workspace usage recommendation
* linked Group usage recommendation
* keep hidden expose in Function Bar suggestion
* add to Workspace action from planner
* no physical mutation
* diagnostics redaction

## Acceptance Criteria

* Placement Planner understands Workspaces.
* Recommendations are more actionable.
* Physical movement remains manual/dry-run.
* Tests pass.

---

# Workstream 21.7 — Crowded Reveal Rescue → Function Bar Fallback

## Goal

Let Crowded Rescue choose current Workspace Function Bar as a fallback when inline reveal may not fit.

## Decision Engine Updates

Update Crowded Reveal decision outputs to include:

```swift
case functionBar
case functionBarThenSecondBar
case askFunctionBarOrSecondBar
```

Or equivalent model.

Inputs should include:

* Function Bar Preview enabled
* active Workspace exists
* active Workspace item count
* Function Bar controller available
* Safe Mode
* user preference
* Second Bar availability
* Full Menu Bar Mode availability
* current display capacity
* notch/crowded risk estimate

## User Preference

Add setting:

```swift
crowdedRescueWorkspaceFallbackPreference
```

Suggested enum:

```swift
enum CrowdedRescueWorkspaceFallbackPreference: String, Codable {
    case preferSecondBar
    case preferFunctionBar
    case askEveryTime
    case preferInlineOnly
    case preferFullMenuBarMode
}
```

Default:

```text
preferSecondBar
```

Because Second Bar is more directly tied to hidden items. Function Bar is a workspace layer and should not surprise users by default.

## Behavior

When crowded:

* if prefer Second Bar: current behavior
* if prefer Function Bar and Function Bar available: open Function Bar
* if Function Bar unavailable: fallback to Second Bar
* if ask: show small choice prompt or status feedback
* Safe Mode: no automatic Function Bar opening

## UI Copy

Examples:

* “Opened Function Bar because inline reveal may not fit.”
* “Function Bar shows the active Workspace’s shortcuts; it may not include every hidden menu bar item.”
* “Use Second Bar to browse hidden items directly.”
* “Use Arrange to change physical placement.”

## Tests

Add tests:

* crowded + prefer Function Bar -> Function Bar decision
* crowded + Function Bar unavailable -> Second Bar fallback
* crowded + prefer Second Bar -> Second Bar
* askEveryTime returns ask decision
* Safe Mode blocks Function Bar fallback
* Pro off behavior correct
* diagnostics redaction

## Acceptance Criteria

* Crowded Rescue can open Function Bar as fallback.
* Default remains conservative.
* User understands Function Bar is not all hidden items.
* Tests pass.

---

# Workstream 21.8 — Workspace Physical Profile Binding Preview

## Goal

Make Workspace ↔ Profile binding useful but safe.

A Workspace may reference a physical Profile, but v0.1.8 must not silently move icons or bulk-apply risky settings.

## Supported Modes

Use existing or implement:

```swift
enum WorkspacePhysicalProfileApplyMode: String, Codable, Equatable {
    case none
    case dryRunOnly
    case applySafeBasicSettings
}
```

Default:

```text
dryRunOnly
```

or `none` if safer.

## Dry-Run Preview

When a Workspace has a profile binding:

* show bound Profile name, redacted if protected
* show safe Basic settings that would change
* show risky parts that are ignored:

  * icon moving
  * target zones
  * Smart Triggers
  * Launch at Login system state
  * Spacing Labs
  * Private Access sessions
  * broad automation
* show “Open Arrange” / “Open Placement Planner” for physical layout guidance

## Safe Apply

If user explicitly enables `applySafeBasicSettings`:

Allowed to apply:

* Basic collapsed preference if safe
* auto-rehide preference if part of profile and not Safe Mode
* hover reveal preference if safe
* always-hidden preference if safe
* Function Bar/Info Strip preference if workspace-related and explicit

Not allowed:

* icon moving
* target-zone moves
* bulk movement
* Launch at Login system state
* Spacing Labs apply
* Labs settings
* Smart Triggers
* external automation
* App Intents side effects
* URL automation
* physical layout movement

## UI

In Workspace editor / Set Builder inspector:

* Profile Binding section
* select profile
* mode picker:

  * none
  * dry-run only
  * apply safe Basic settings
* preview changes
* run dry-run
* apply safe settings, explicit confirmation
* remove binding

## Tests

Add tests:

* bind profile
* missing profile unresolved
* dry-run does not mutate settings
* safe apply mutates only allowed settings
* icon move fields ignored
* Spacing Labs ignored
* Launch at Login ignored
* Smart Triggers ignored
* Safe Mode blocks apply
* diagnostics redacted

## Acceptance Criteria

* Workspace can bind physical Profile safely.
* Dry-run is useful.
* Safe apply is explicit and limited.
* No physical layout movement occurs.
* Tests pass.

---

# Workstream 21.9 — Function Bar / Info Strip Workspace Status Badges

## Goal

Show Workspace integration status directly in Function Bar and Info Strip.

## Function Bar Badges

Add badges where useful:

* New
* Unassigned
* Used in N Workspaces
* Linked Group
* Detached
* Missing
* Stale
* Protected
* Profile-bound Workspace

Do not overload UI. Use subtle badges/tooltips.

## Info Strip Tile Enhancements

Existing Info Strip tiles can become Workspace-aware:

### Current Workspace tile

Show:

* active Workspace
* profile binding status if safe
* item count
* group count

### New Items tile

Show:

* new item count
* unassigned new item count

### Hidden Count tile

Show:

* hidden count
* items exposed through active Function Bar count, if available

### Stale Scan tile

Show:

* stale scan warning
* workspace proxy references may need refresh

## Tests

Add tests:

* Function Bar item badges computed
* Info Strip current workspace tile includes safe counts
* New Items tile includes unassigned count
* protected names redacted
* badges do not leak raw identities
* UI renders badges

## Acceptance Criteria

* Function Bar and Info Strip reflect Workspace integration.
* Users can understand new/unassigned/linked/stale states.
* UI remains compact.
* Tests pass.

---

# Workstream 21.10 — Set Builder Integration Updates

## Goal

Update Set Builder to use new Workspace integration services.

## Tasks

1. Add “Unassigned Items” library section.

Shows discovered items not assigned to any Workspace/Group.

2. Add “New Items” library section.

Shows New Item Inbox items.

3. Add “Used in Workspaces” inspector section.

For selected item/group:

* current Workspace use
* other Workspace use
* linked group use
* detached group use

4. Add “Assign to Workspace” actions.

* add to current Workspace
* add to another Workspace
* add to linked Group
* create Group

5. Add “Keep physically hidden but expose in Function Bar” action.

This should:

* add item to Workspace
* create placement recommendation
* not move real icon

6. Add missing reference cleanup.

* remove missing item references
* remove missing group references
* keep backup before destructive cleanup

## Tests

Add tests:

* Unassigned section contents
* New Items section contents
* item usage inspector
* assign to another Workspace
* assign to Group
* keep hidden expose action
* missing reference cleanup
* diagnostics redaction

## Acceptance Criteria

* Set Builder is Workspace-aware.
* New/unassigned items can be organized from builder.
* Missing references are easier to clean up.
* Tests pass.

---

# Workstream 21.11 — Command Center Integration

## Goal

Add or update shared commands for Workspace integration.

## New/Internal Commands

Add internal Preview command IDs if needed:

```text
workspace.assign.current
workspace.assign.selected
workspace.assign.group
workspace.assign.newGroup
workspace.item.removeFromWorkspace
workspace.item.showUsage
workspace.item.markUnassignedReviewed
workspace.profileBinding.dryRun
workspace.profileBinding.applySafe
crowdedRescue.openFunctionBar
findIcon.filter.workspace
placementPlanner.workspaceRecommendation
```

These are not public App Intents by default.

## Gates

Evaluate:

* Safe Mode
* Workspaces Preview enabled
* Function Bar Preview enabled
* Set Builder Preview enabled
* Info Strip Preview enabled
* Pro Mode for menu bar proxy references
* Accessibility Discovery for live metadata
* Accessibility permission for live metadata
* target Workspace exists
* target Group exists
* target Profile exists
* protected Workspace/Group/Profile if Private Access safely supports it
* automation pause for automation sources
* Labs gate for Labs actions
* Experimental gate for Assisted Move dry-run/try move

## Tests

Add tests:

* assign current Workspace command
* assign selected Workspace command
* assign Group command
* profile dry-run command
* profile safe apply command
* crowded rescue Function Bar command
* Safe Mode blocks runtime actions
* Pro off blocks live metadata actions
* protected names redacted
* no App Intent exposure unless explicitly intended

## Acceptance Criteria

* Integration actions route through Command Center.
* No ad-hoc bypass paths.
* Tests pass.

---

# Workstream 21.12 — App Intents / URL Automation Boundary

## Goal

Keep Workspace integration internal/Preview and do not accidentally expose broad automation.

## Rules

In v0.1.8:

* Do not add public App Intents for assignment workflows.
* Do not add public URL routes for Set Builder mutation.
* Do not add public routes for physical profile binding apply.
* Do not add public routes for Assisted Move.
* Existing basic App Intents remain stable.

Optional internal testing routes are allowed only if:

* disabled by default
* Preview/Advanced only
* gated by automation pause
* Safe Mode blocks them
* no physical mutation
* no raw item identity in URL

## Tests

Add tests if any routes/intents change:

* workspace assignment not exposed publicly
* unsafe URL route unavailable
* Safe Mode blocks internal route
* automation pause blocks route
* URL cannot include raw item identity in logs
* App Intent list remains basic

## Acceptance Criteria

* Basic automation remains intact.
* Workspace integration does not become broad automation yet.
* No URL/App Intent bypass.
* Tests pass.

---

# Workstream 21.13 — Diagnostics, Health, and Recovery

## Goal

Add integration-level health without compromising privacy or Basic Mode.

## Diagnostics Snapshot

Add:

```swift
struct WorkspaceIntegrationDiagnosticsSnapshot: Codable, Equatable {
    var integrationEnabled: Bool
    var workspaceCount: Int
    var activeWorkspacePresent: Bool
    var indexedItemReferenceCount: Int
    var assignedItemReferenceCount: Int
    var unassignedItemReferenceCount: Int
    var linkedGroupReferenceCount: Int
    var detachedGroupReferenceCount: Int
    var newItemAssignableCount: Int
    var missingWorkspaceReferenceCount: Int
    var missingGroupReferenceCount: Int
    var missingProfileBindingCount: Int
    var functionBarFallbackEnabled: Bool
    var physicalProfileBindingCount: Int
    var lastAssignmentResult: String?
    var lastCrowdedRescueWorkspaceDecision: String?
}
```

Do not include:

* workspace names
* raw item names
* raw bundle IDs
* group names
* profile names
* protected names
* calendar/reminder titles
* live search text
* file paths

## Health Checks

Add checks:

* unassigned new item count above threshold
* missing Workspace references
* missing Group references
* missing Profile bindings
* active Workspace has zero items and Function Bar fallback preferred
* Function Bar fallback preferred but Function Bar disabled
* Workspace-bound profile has risky fields ignored
* too many stale menu bar proxy references

## Recovery Actions

Add:

* clear assignment cache/index
* remove missing Workspace item references
* remove missing Group references, confirmation required
* remove missing profile binding
* disable Function Bar fallback
* reset Workspace integration preferences
* open Set Builder
* open New Item Inbox
* open Placement Planner

All recovery actions must be safe and not move real icons.

## Tests

Add tests:

* diagnostics redaction
* health issue for unassigned new items
* health issue for missing group/profile
* recovery removes missing references
* recovery disables Function Bar fallback
* Basic Mode unaffected
* support export safe

## Acceptance Criteria

* Workspace integration diagnostics are useful and redacted.
* Recovery can clean common integration issues.
* Basic Mode remains unaffected.
* Tests pass.

---

# Workstream 21.14 — Import / Export / Backup Integration

## Goal

Include Workspace integration metadata safely in local backup/export.

## Include in Complete Local Backup

* workspace assignments
* active workspace
* workspace item references
* linked/detached group references
* profile bindings
* Function Bar fallback preference
* Workspace-aware Find Icon filter preferences
* Placement Planner workspace preference flags
* New Item Inbox assignment decisions, if safe and local

## Safe Support Export

Only include counts/status:

* workspace count
* assigned/unassigned count
* linked/detached group reference count
* missing reference counts
* profile binding count
* Function Bar fallback enabled
* no raw names/identities

## Import Safety

Import must not:

* enable Function Bar fallback automatically unless selected
* enable Function Bar Preview automatically unless selected
* enable Info Strip Preview automatically unless selected
* enable profile safe apply automatically unless selected
* enable physical profile apply
* enable icon moving
* enable Smart Triggers
* enable Spacing Labs
* enable Launch at Login system state
* expose raw identities in dry-run result

## Tests

Add tests:

* backup includes integration settings
* support export redacts identities
* import dry-run validates assignments
* import missing Workspace references repaired
* import missing Group references tolerated
* import missing Profile binding unresolved
* import does not enable risky features
* imported assignment decisions do not dismiss live new items incorrectly unless explicitly selected

## Acceptance Criteria

* Backup/export includes integration metadata safely.
* Import is conservative.
* Privacy-safe export remains safe.
* Tests pass.

---

# Workstream 21.15 — UI Polish for Workspace Integration

## Goal

Make integration visible without making the app heavy.

## Settings UI Locations

Keep Workspaces under Advanced/Preview, but improve cross-links from:

### Find & Rescue

Add:

* “Use Workspaces to organize found icons”
* current Workspace filter summary
* New Items assignment shortcut
* open Set Builder link

### Arrange / Placement Planner

Add:

* “Workspace usage” section
* “Keep hidden but expose in Function Bar” action
* open Set Builder link

### Recovery

Add:

* Workspace integration health card
* open New Item Inbox
* open Set Builder
* clean missing references

### Advanced → Workspaces Preview

Add integration dashboard:

* active Workspace
* assigned item count
* unassigned item count
* new items count
* linked groups count
* profile binding status
* crowded rescue fallback status

## Avoid UI Bloat

Do not add new top-level sidebar sections in v0.1.8.

Do not expose every integration detail on main pages. Use compact cards and links.

## Tests

Add UI tests:

* Find & Rescue shows Workspace filter entry
* Placement Planner shows Workspace usage card
* Advanced Workspaces dashboard renders
* Recovery shows Workspace health card
* no top-level Workspaces if policy remains Advanced-only
* no Accessibility prompt from viewing integration UI

## Acceptance Criteria

* Workspace integration is discoverable.
* UI remains lightweight.
* Main product still feels focused.
* Tests pass.

---

# Workstream 21.16 — Manual QA Matrix

## Goal

Add manual QA for Workspace integration behavior.

## Create

```text
docs/testing/manual-v0.1.8-workspace-integration-qa.md
docs/testing/manual-v0.1.8-new-item-assignment-qa.md
docs/testing/manual-v0.1.8-crowded-function-bar-fallback-qa.md
docs/testing/manual-v0.1.8-results.md
```

## Manual QA Areas

### New Item Assignment

* Launch fixture app with new item.
* Confirm New Item Inbox sees item.
* Assign to current Workspace.
* Confirm Function Bar shows item proxy.
* Assign another new item to selected Workspace.
* Assign item to existing Group.
* Create new Group with item.
* Dismiss item after assignment.
* Confirm diagnostics export redacts item name.

### Find Icon Workspace Filters

* Create multiple Workspaces.
* Add different items to each.
* Open Find Icon.
* Filter current Workspace.
* Filter unassigned.
* Filter new items.
* Filter used in other Workspace.
* Confirm result badges.

### Placement Planner

* Open Placement Planner.
* Confirm Workspace usage appears.
* Add unassigned item to Workspace from planner.
* Use “keep hidden but expose in Function Bar.”
* Confirm no physical movement occurs.

### Crowded Rescue

* Enable Function Bar Preview.
* Set crowded fallback preference to Function Bar.
* Create crowded scenario if possible.
* Trigger reveal.
* Confirm Function Bar fallback opens.
* Set preference back to Second Bar.
* Confirm Second Bar fallback opens.

### Physical Profile Binding

* Bind profile to Workspace.
* Run dry-run.
* Confirm no settings mutate.
* Enable safe Basic apply, if implemented.
* Confirm only allowed Basic settings change.
* Confirm no icon movement, no Spacing Labs, no Launch at Login mutation.

### Safe Mode

* Enter Safe Mode.
* Confirm assignment/runtime actions disabled.
* Confirm Basic recovery works.
* Confirm Workspaces integration health can be viewed safely.

### Privacy

* Export diagnostics.
* Confirm no raw workspace names if protected.
* Confirm no raw item names.
* Confirm no raw bundle IDs.
* Run no-network watch.

## Acceptance Criteria

* Manual QA docs exist.
* Results are recorded.
* Preview failures are documented honestly.
* Stable Basic claims remain unaffected.
* Release checklist links to QA docs.

---

# Workstream 21.17 — Documentation

## Goal

Document Workspace integration accurately without overclaiming.

## Create or Update

```text
docs/features/workspace-integration-v0.1.8-preview.md
docs/features/new-item-workspace-assignment-v0.1.8-preview.md
docs/features/find-icon-workspace-filters-v0.1.8-preview.md
docs/features/workspace-aware-placement-planner-v0.1.8-preview.md
docs/features/crowded-rescue-function-bar-fallback-v0.1.8-preview.md
docs/features/workspace-profile-binding-v0.1.8-preview.md
docs/architecture/workspace-integration-architecture.md
docs/privacy/v0.1.8-workspace-integration-privacy.md
docs/release/v0.1.8-release-notes.md
docs/release/v0.1.8-release-checklist.md
docs/release/v0.1.8-known-limitations.md
docs/progress/phase-21-v0.1.8-workspace-integration.md
README.md
docs/support/workspaces-preview.md
docs/support/new-item-assignment.md
docs/support/workspace-filters.md
docs/support/workspace-profile-binding.md
```

## Required Wording

Use this wording or equivalent:

> Workspace integration in v0.1.8 is Preview. It connects Workspaces with New Item Inbox, Find Icon, Placement Planner, Crowded Rescue, Function Bar, Info Strip, and local backup/restore. It does not replace the macOS menu bar, does not capture screen pixels, and does not move real menu bar icons automatically.

Use this wording or equivalent:

> Workspace physical profile binding is conservative. Dry-run is the default. Safe Basic settings can be applied only after explicit user action. Icon movement, Spacing Labs, Launch at Login system state, and bulk layout changes are not applied by workspace switching.

## Docs Must Explain

* What Workspace integration means.
* New Item Inbox assignment.
* Workspace-aware Find Icon filters.
* Workspace-aware Placement Planner recommendations.
* Function Bar fallback from Crowded Rescue.
* Physical Profile binding limitations.
* What is safe to apply.
* What is ignored.
* What remains Experimental.
* How to recover missing references.
* What data is exported and redacted.

## Forbidden Claims

Do not claim:

* stable Workspaces
* stable physical workspace switching
* system menu bar replacement
* live menu bar pixel clone
* automatic real icon movement
* bulk icon moving
* stable third-party menu activation
* Screen Recording support
* ScreenCaptureKit support
* online widgets
* media controls
* competitor import
* v0.2 release

## Acceptance Criteria

* Docs match implementation.
* Docs clearly call Workspace integration Preview.
* Docs explain dry-run and safe apply boundaries.
* Privacy claims remain intact.
* Current-facing docs use v0.1.8.

---

# Workstream 21.18 — Tests

## Goal

Add meaningful coverage for Workspace integration.

## Suggested Test Files

Create or update:

```text
MenuBar-ManagerTests/WorkspaceUsageIndexTests.swift
MenuBar-ManagerTests/WorkspaceAssignmentServiceTests.swift
MenuBar-ManagerTests/NewItemWorkspaceAssignmentTests.swift
MenuBar-ManagerTests/FindIconWorkspaceFilterTests.swift
MenuBar-ManagerTests/WorkspacePlacementPlannerTests.swift
MenuBar-ManagerTests/CrowdedRescueFunctionBarFallbackTests.swift
MenuBar-ManagerTests/WorkspacePhysicalProfileBindingTests.swift
MenuBar-ManagerTests/WorkspaceIntegrationDiagnosticsTests.swift
MenuBar-ManagerTests/WorkspaceIntegrationImportExportTests.swift
MenuBar-ManagerUITests/WorkspaceIntegrationUITests.swift
MenuBar-ManagerUITests/NewItemAssignmentUITests.swift
```

Follow existing test style.

## Required Unit Tests

Cover:

1. Usage index direct Workspace assignment.
2. Usage index linked Group assignment.
3. Usage index detached Group assignment.
4. Unassigned item detection.
5. New item assigned to current Workspace.
6. New item assigned to selected Workspace.
7. New item assigned to Group.
8. New Group created with item.
9. Assignment does not move real icon.
10. Assignment diagnostics redacted.
11. Find Icon current Workspace filter.
12. Find Icon unassigned filter.
13. Find Icon new item filter.
14. Find Icon used in other Workspace filter.
15. Workspace-aware ranking boosts.
16. Placement Planner unassigned recommendation.
17. Placement Planner current Workspace recommendation.
18. Placement Planner linked Group recommendation.
19. Keep hidden expose in Function Bar recommendation.
20. Crowded rescue prefers Function Bar when configured.
21. Crowded rescue falls back to Second Bar when Function Bar unavailable.
22. Crowded rescue Safe Mode blocks Function Bar.
23. Profile binding dry-run no mutation.
24. Safe Basic apply only mutates allowed settings.
25. Profile binding ignores icon moves.
26. Profile binding ignores Spacing Labs.
27. Profile binding ignores Launch at Login.
28. Function Bar badges computed.
29. Info Strip tile enhancements redacted.
30. Import/export integration metadata.
31. Import does not enable risky features.
32. Health detects missing references.
33. Recovery removes missing references safely.
34. Basic Mode unaffected.

## Required UI Tests

Cover:

1. New Item Inbox assignment UI renders.
2. Assign to current Workspace.
3. Assign to selected Workspace.
4. Create Group from new item.
5. Find Icon Workspace filter visible.
6. Placement Planner Workspace usage card visible.
7. Crowded Rescue Function Bar preference visible.
8. Workspace profile binding UI visible.
9. Advanced Workspace integration dashboard visible.
10. Recovery Workspace health card visible.
11. No Accessibility prompt from simply viewing integration UI.
12. Safe Mode unavailable state renders.

If UI tests are too brittle, cover core behavior with unit tests and add smoke-level UI tests.

## Acceptance Criteria

* Integration model/service tests pass.
* UI smoke coverage exists.
* Existing tests still pass.
* Privacy verification still passes.

---

# Workstream 21.19 — Release and Privacy Verification

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

## Targeted Searches

Run:

```bash
rg -n "v0\.2|0\.2\.0" README.md docs MenuBar-Manager scripts Config || true
rg -n "ScreenCaptureKit|NSScreenCaptureUsageDescription|NSAppleEventsUsageDescription|InputMonitoring|URLSession|NWConnection|analytics|telemetry|Sentry|Firebase|remote config|crash upload" MenuBar-Manager Config scripts docs || true
rg -n "stable Workspace|stable Workspaces|stable physical workspace|replace.*macOS.*menu bar|system menu bar replacement|live.*menu bar.*clone|pixel capture|live icon capture|Screen Recording" README.md docs MenuBar-Manager || true
rg -n "Workspace.*move.*icon|Workspace.*bulk|Workspace.*apply.*profile|Workspace.*physical.*layout|Workspace.*physical.*switch|bulk move" README.md docs MenuBar-Manager || true
rg -n "Function Bar.*all hidden items|Function Bar.*system menu bar|Info Strip.*Dynamic Island|Info Strip.*online|media control|weather|stocks|news" README.md docs MenuBar-Manager || true
```

Inspect results manually.

Acceptable:

* Historical/future notes if clearly labeled.
* Internal type names that do not claim current stability.
* Docs that explicitly state deferred/future behavior.
* Mentions saying online/media widgets are not implemented.

Not acceptable:

* Current-facing v0.2 claim.
* Current-facing claim that Workspaces replace system menu bar.
* Current-facing claim that Workspace switching moves real menu bar icons.
* Current-facing claim that physical profile binding applies icon moves.
* Current-facing claim that Function Bar shows all hidden items by default.
* Current-facing claim that Info Strip is a Dynamic Island clone or online widget system.
* Any new privacy-sensitive API usage.

## Acceptance Criteria

* Full test suite passes.
* Privacy boundary script passes.
* Release dry-run passes.
* Installed-app verification passes.
* Targeted searches do not reveal current-facing overclaims.
* Phase progress file records final validation results.

---

# Phase 21 Definition of Done

Phase 21 is complete when:

1. App version is `0.1.8`.
2. Build number is incremented to `9` or documented next build.
3. No current-facing docs/UI call this v0.2.
4. `MenuBar-Manager/WorkspaceIntegration/` source area exists or equivalent integration layer exists.
5. WorkspaceUsageIndex can answer item/group/workspace usage.
6. New Item Inbox can assign new items to Workspaces.
7. New Item Inbox can assign new items to Groups.
8. New Item Inbox can create a new Group with a new item.
9. Assignment does not move real menu bar icons.
10. Find Icon has Workspace-aware filters.
11. Find Icon result badges show Workspace usage safely.
12. Placement Planner has Workspace-aware recommendations.
13. Placement Planner supports “keep hidden but expose in Function Bar” recommendation.
14. Crowded Rescue can choose Function Bar as fallback.
15. Default crowded fallback remains conservative.
16. Workspace physical profile binding supports dry-run.
17. Workspace physical profile binding safe apply, if implemented, only applies explicitly allowed Basic settings.
18. Workspace physical profile binding does not apply icon moving, Spacing Labs, Launch at Login, Smart Triggers, or broad automation.
19. Function Bar shows Workspace integration badges where useful.
20. Info Strip tiles include safe Workspace integration counts where useful.
21. Set Builder has Unassigned/New Items integration.
22. Diagnostics are privacy-safe and redacted.
23. Health/recovery can handle missing Workspace/Group/Profile references.
24. Import/export includes integration metadata safely.
25. App Intents/URL automation do not expose broad Workspace mutation routes.
26. Safe Mode suppresses runtime integration actions while preserving recovery.
27. No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network, telemetry, analytics, cloud sync, private APIs, media private APIs, or notification scraping are introduced.
28. Full tests pass.
29. Release dry-run and installed-app verification pass.
30. `docs/progress/phase-21-v0.1.8-workspace-integration.md` includes:

    * summary
    * changed files
    * test results
    * release verification results
    * privacy verification results
    * manual QA status
    * known limitations
    * deferred work for v0.1.9

---

# Recommended Codex Subtask Breakdown

Do not ask Codex to execute all Phase 21 in one huge pass. Use these slices.

## Phase 21A — Version + Integration Skeleton

```markdown
Implement Phase 21A only:
- bump app version to 0.1.8 build 9
- create WorkspaceIntegration source area
- add WorkspaceUsageIndex and core assignment models
- add diagnostics shell
- add tests for usage index
- do not implement UI changes yet
- do not mention v0.2
```

## Phase 21B — New Item Inbox Assignment

```markdown
Implement Phase 21B only:
- implement WorkspaceAssignmentService
- connect New Item Inbox to assign item to current Workspace, selected Workspace, existing Group, or new Group
- manual hidden/always-hidden actions create recommendations only
- assisted move remains dry-run/Experimental
- add tests and redaction
```

## Phase 21C — Find Icon Workspace Filters

```markdown
Implement Phase 21C only:
- add Workspace-aware filters and badges to Find Icon
- add actions: add to Workspace, add to Group, create Group, remove from Workspace
- update ranking boosts
- add tests
- no broad activation claims
```

## Phase 21D — Placement Planner Integration

```markdown
Implement Phase 21D only:
- enrich Placement Planner recommendations with Workspace usage
- add “keep hidden but expose in Function Bar” recommendation
- add actions to assign from planner
- add tests
- no physical movement
```

## Phase 21E — Crowded Rescue Function Bar Fallback

```markdown
Implement Phase 21E only:
- update CrowdedRevealDecisionEngine to support Function Bar fallback
- add user preference, default conservative
- wire status/reveal paths safely
- Safe Mode blocks Function Bar fallback
- add tests and UI copy
```

## Phase 21F — Physical Profile Binding Preview

```markdown
Implement Phase 21F only:
- make Workspace physical profile binding usable as Preview
- implement dry-run view/result
- implement explicit safe Basic apply only if safe
- ignore icon moves, Spacing Labs, Launch at Login, triggers, automation
- add tests
```

## Phase 21G — Function Bar / Info Strip / Set Builder UI Updates

```markdown
Implement Phase 21G only:
- add Workspace integration badges to Function Bar
- enrich Info Strip tiles with safe counts
- add Unassigned/New Items sections to Set Builder
- add Advanced Workspace integration dashboard
- add UI tests
```

## Phase 21H — Diagnostics + Import/Export + Recovery

```markdown
Implement Phase 21H only:
- add WorkspaceIntegrationDiagnosticsSnapshot
- add health checks and recovery actions for missing references
- update backup/export/import integration metadata
- ensure safe support export redacts identities
- add tests
```

## Phase 21I — Docs + Manual QA + Final Validation

```markdown
Implement Phase 21I only:
- add v0.1.8 Workspace integration docs
- update release notes/checklist
- add manual QA docs
- run full validation commands
- run targeted privacy/overclaim searches
- record final results in phase progress doc
```
