
# Phase 19 — v0.1.6 Linked Groups + Set Builder MVP

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar decluttering utility written in Swift, AppKit, and SwiftUI.

This phase follows:

- Phase 17 / v0.1.4 Workspaces Foundation
- Phase 18 / v0.1.5 Set Switcher + Virtual Function Bar MVP

The active release line for this phase is:

`v0.1.6`

This phase is **not v0.2**. Do not create v0.2 docs, v0.2 release notes, v0.2 public claims, v0.2 artifact names, or current-facing v0.2 roadmap language.

## Phase Mission

Phase 19 introduces the first real Set Builder MVP.

The goal is:

> A user can build different Workspaces/Sets by arranging command items, menu bar item proxies, spacers, dividers, and reusable Groups. A Group can be inserted into multiple Workspaces as a linked reference, so editing the Group updates all Workspaces that use it.

By the end of Phase 19:

1. A Set Builder UI exists under Workspaces Preview / Advanced.
2. Users can create, rename, duplicate, archive, and switch Workspaces.
3. Users can add, remove, and reorder function items inside a Workspace.
4. Users can add command items to a Workspace.
5. Users can add spacers and dividers to a Workspace.
6. Users can add menu bar item proxy references when Pro Discovery is available.
7. Users can add Groups to a Workspace.
8. Group insertion supports:
   - linked reference
   - detached copy
9. Linked Groups update across all Workspaces that reference them.
10. Detached Group copies do not update when the source Group changes.
11. Function Bar preview reflects Set Builder changes.
12. Function Bar uses updated Workspace data without requiring restart.
13. Import/export/backup includes Workspaces and linked Group references safely.
14. Diagnostics remain privacy-safe.
15. Basic Mode remains stable and permission-free.

Phase 19 must **not** implement Info Strip runtime, hover ticker, physical workspace switching, bulk icon moving, ScreenCaptureKit, Screen Recording, network widgets, or media widgets.

## Product Boundary

Set Builder and Linked Groups are still **Preview** in v0.1.6.

They configure MenuBarDeclutter’s app-owned Workspace / Function Bar layer.

They do not:
- replace the macOS system menu bar
- capture live menu bar pixels
- take ownership of third-party menu bar items
- guarantee activation of arbitrary third-party menu extras
- automatically move real menu bar icons
- apply physical menu bar layouts silently
- require Screen Recording
- use ScreenCaptureKit
- use private Apple menu bar APIs
- use network access

## Version Target

Set active app version to:

- Marketing version: `0.1.6`
- Build number: increment from `6` to `7`, unless the project has already advanced build numbering.

Release artifacts should use:

- `MenuBarDeclutter-v0.1.6.zip`
- `MenuBarDeclutter-v0.1.6-alpha.zip` only if alpha/dogfood packaging still exists.

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
- Basic Mode remains the stable product core.

## Hard Rules

1. Do not call this phase v0.2.
2. Do not add Screen Recording.
3. Do not add ScreenCaptureKit.
4. Do not add Apple Events scripting/control.
5. Do not add Input Monitoring.
6. Do not add network access, telemetry, analytics, crash upload, cloud sync, remote config, update checks, or license checks.
7. Do not use private Apple menu bar APIs.
8. Do not silently prompt for Accessibility.
9. Do not make Workspaces stable public claims yet.
10. Do not make Set Builder stable public claims yet.
11. Do not claim Function Bar replaces macOS menu bar.
12. Do not claim Function Bar is a live clone of system menu bar icons.
13. Do not implement Info Strip runtime in this phase.
14. Do not implement hover idle ticker in this phase.
15. Do not implement physical workspace switching.
16. Do not automatically apply physical profiles when switching Workspace.
17. Do not implement bulk icon moving.
18. Do not make assisted icon moving stable.
19. Do not expose broad third-party menu item activation as stable.
20. Do not mutate real menu bar layout from Set Builder.
21. Keep Set Builder under Preview/Advanced in v0.1.6.
22. Diagnostics must not export raw workspace item names, raw menu bar item identities, protected group names, protected workspace names, live search text, drag payload values, or file paths by default.

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

`docs/progress/phase-19-v0.1.6-linked-groups-set-builder.md`

Record:

* baseline git status
* baseline version/build
* baseline test results
* baseline privacy verification result
* baseline release dry-run result
* baseline installed-app verification result
* known limitations from Phase 18
* exact date
* short phase goal

---

# Workstream 19.1 — Version and Release Identity

## Goal

Move the active release line from `0.1.5` to `0.1.6`.

## Tasks

1. Search version references:

```bash
rg -n "0\.1\.5|v0\.1\.5|0\.1\.6|v0\.1\.6|0\.2|v0\.2|MARKETING_VERSION|CURRENT_PROJECT_VERSION|CFBundleShortVersionString|CFBundleVersion" .
```

2. Update active version/build values to:

* `0.1.6`
* build `7`

3. Update release artifact naming.

4. Add release notes placeholder:

`docs/release/v0.1.6-release-notes.md`

5. Add release checklist:

`docs/release/v0.1.6-release-checklist.md`

6. Update latest-progress docs that list current release line.

7. Do not create v0.2 docs.

8. If historical docs mention v0.2, leave them only if clearly historical/future. Do not add current-facing v0.2 language.

## Acceptance Criteria

* App bundle reports `0.1.6`.
* Build number is `7` or documented next build number.
* Release artifacts use `v0.1.6`.
* Current-facing docs/UI do not call this v0.2.
* Release dry-run still works.

---

# Workstream 19.2 — SetBuilder Source Area and Boundaries

## Goal

Create a focused Set Builder source area that edits Workspace function item layouts without mixing UI logic into Workspaces store or Function Bar runtime.

## New Source Area

Create:

```text
MenuBar-Manager/SetBuilder/
  Models/
  Runtime/
  Views/
  Library/
  DragDrop/
  Diagnostics/
  Settings/
```

Suggested files:

```text
MenuBar-Manager/SetBuilder/Models/SetBuilderDraft.swift
MenuBar-Manager/SetBuilder/Models/SetBuilderItemDraft.swift
MenuBar-Manager/SetBuilder/Models/SetBuilderLibraryItem.swift
MenuBar-Manager/SetBuilder/Models/SetBuilderSelection.swift
MenuBar-Manager/SetBuilder/Models/SetBuilderChange.swift
MenuBar-Manager/SetBuilder/Runtime/SetBuilderViewModel.swift
MenuBar-Manager/SetBuilder/Runtime/SetBuilderDraftStore.swift
MenuBar-Manager/SetBuilder/Runtime/SetBuilderCommitService.swift
MenuBar-Manager/SetBuilder/Runtime/SetBuilderValidationService.swift
MenuBar-Manager/SetBuilder/Library/SetBuilderLibraryProvider.swift
MenuBar-Manager/SetBuilder/Library/CommandLibraryProvider.swift
MenuBar-Manager/SetBuilder/Library/MenuBarItemLibraryProvider.swift
MenuBar-Manager/SetBuilder/Library/GroupLibraryProvider.swift
MenuBar-Manager/SetBuilder/Library/SpacerLibraryProvider.swift
MenuBar-Manager/SetBuilder/DragDrop/SetBuilderDragPayload.swift
MenuBar-Manager/SetBuilder/DragDrop/SetBuilderDropTarget.swift
MenuBar-Manager/SetBuilder/DragDrop/SetBuilderDropValidator.swift
MenuBar-Manager/SetBuilder/Views/SetBuilderView.swift
MenuBar-Manager/SetBuilder/Views/WorkspaceListPane.swift
MenuBar-Manager/SetBuilder/Views/WorkspaceCanvasPane.swift
MenuBar-Manager/SetBuilder/Views/WorkspaceItemRow.swift
MenuBar-Manager/SetBuilder/Views/WorkspaceItemPreview.swift
MenuBar-Manager/SetBuilder/Views/SetBuilderLibraryPane.swift
MenuBar-Manager/SetBuilder/Views/SetBuilderInspectorPane.swift
MenuBar-Manager/SetBuilder/Views/GroupReferenceModePicker.swift
MenuBar-Manager/SetBuilder/Views/LinkedGroupBadge.swift
MenuBar-Manager/SetBuilder/Views/DetachedGroupBadge.swift
MenuBar-Manager/SetBuilder/Settings/SetBuilderPreviewSettingsView.swift
MenuBar-Manager/SetBuilder/Diagnostics/SetBuilderDiagnosticsSnapshot.swift
```

If existing equivalent files exist after earlier phases, extend them instead of duplicating.

## Module Boundaries

SetBuilder may depend on:

* Workspaces models/store/switching
* FunctionBar item resolver / preview models
* Groups store/resolver/editor models
* CommandCenter action references
* Accessibility item references through stable item identity models
* Search / Find Icon item memory, only through stable providers
* DesignSystem
* Settings route model
* Diagnostics redaction helpers

SetBuilder must not directly depend on:

* ScreenCaptureKit
* Screen Recording
* network APIs
* private Apple APIs
* CGEvent moving execution services
* InfoStrip runtime
* low-level Accessibility scanner internals
* App Intents execution service
* URL automation router

## Acceptance Criteria

* `MenuBar-Manager/SetBuilder/` exists.
* Files are target-membered correctly.
* SetBuilder has clear boundaries.
* Build succeeds.
* No privacy-sensitive APIs are introduced.

---

# Workstream 19.3 — Set Builder Feature Gate and Settings

## Goal

Expose Set Builder as a Preview feature under Workspaces Preview / Advanced.

## Required Settings

Add settings if not already present:

```swift
setBuilderPreviewEnabled: Bool
setBuilderDragDropEnabled: Bool
setBuilderShowAdvancedLibraryItems: Bool
setBuilderDefaultGroupReferenceMode: WorkspaceGroupReferenceMode
setBuilderShowFunctionBarPreview: Bool
setBuilderAutosaveDrafts: Bool
setBuilderWarnBeforeLinkedGroupEdits: Bool
```

Recommended defaults:

```text
setBuilderPreviewEnabled: false
setBuilderDragDropEnabled: true once Set Builder Preview is enabled
setBuilderShowAdvancedLibraryItems: false
setBuilderDefaultGroupReferenceMode: linked
setBuilderShowFunctionBarPreview: true
setBuilderAutosaveDrafts: true
setBuilderWarnBeforeLinkedGroupEdits: true
```

## UI Location

Add under:

```text
Settings → Advanced → Workspaces Preview → Set Builder Preview
```

Do not add Set Builder as a top-level sidebar section in v0.1.6.

## UI Copy

Must say:

> Set Builder is Preview. It edits MenuBarDeclutter’s app-owned Workspace and Function Bar configuration. It does not move real macOS menu bar icons.

## Tests

Add tests:

* Set Builder preview off by default
* enabling setting persists
* default group reference mode is linked
* no Accessibility prompt when opening Set Builder
* Safe Mode disables drag/drop commit actions if needed
* Function Bar Preview not required to edit Workspaces, but useful for preview

## Acceptance Criteria

* Set Builder is Preview-gated.
* Settings are safe by default.
* UI copy is honest.
* Tests pass.

---

# Workstream 19.4 — Set Builder Draft Model

## Goal

Edit Workspaces through drafts so the user can preview changes before committing.

## Model

Implement:

```swift
struct SetBuilderDraft: Identifiable, Equatable {
    var workspaceID: UUID
    var originalWorkspace: MenuBarWorkspace
    var editedWorkspace: MenuBarWorkspace
    var pendingChanges: [SetBuilderChange]
    var validationIssues: [SetBuilderValidationIssue]
    var isDirty: Bool
    var lastAutosavedAt: Date?
}
```

Implement item draft:

```swift
struct SetBuilderItemDraft: Identifiable, Equatable {
    var id: UUID
    var workspaceItem: WorkspaceItem
    var resolvedTitle: String
    var resolvedSubtitle: String?
    var resolvedIcon: SetBuilderItemIcon
    var status: SetBuilderItemStatus
    var source: SetBuilderItemSource
}
```

Statuses:

```swift
enum SetBuilderItemStatus: Equatable {
    case valid
    case missingReference
    case requiresPro
    case requiresAccessibility
    case stale
    case protected
    case deferred
    case invalid
}
```

Change types:

```swift
enum SetBuilderChange: Equatable {
    case addItem(WorkspaceItem)
    case removeItem(UUID)
    case moveItem(itemID: UUID, from: Int, to: Int)
    case updateItem(WorkspaceItem)
    case renameWorkspace(String)
    case changeWorkspaceIcon(String)
    case addGroupReference(WorkspaceGroupReference)
    case detachGroupReference(groupID: UUID, newGroupID: UUID)
}
```

## Draft Behavior

* Opening a Workspace in Set Builder creates a draft.
* Draft can be edited without immediately saving.
* Autosave draft can save temporary state if project convention supports this.
* Commit writes to WorkspaceStore.
* Cancel reverts to original Workspace.
* Commit validates Workspace before save.
* Commit never applies physical profile.
* Commit never moves real menu bar icons.
* Commit never starts Info Strip.

## Tests

Add tests:

* draft created from workspace
* add item makes draft dirty
* remove item makes draft dirty
* reorder item makes draft dirty
* cancel reverts
* commit writes edited workspace
* invalid draft blocked
* commit does not mutate physical layout
* commit does not enable risky runtime

## Acceptance Criteria

* Set Builder edits through safe drafts.
* User can cancel or commit.
* Invalid workspace data is blocked or repaired.
* No physical menu bar side effects.
* Tests pass.

---

# Workstream 19.5 — Set Builder UI Layout

## Goal

Build a usable MVP Set Builder UI.

## Layout

Implement a three-pane layout:

```text
┌──────────────────┬──────────────────────────┬────────────────────┐
│ Workspace List   │ Function Bar Layout      │ Library / Inspector │
│                  │ Preview Canvas           │                    │
│ Work             │ [Find] [Second] [Group]  │ Commands           │
│ Meeting          │ [Spacer] [Reveal]        │ Groups             │
│ Focus            │                          │ Menu Bar Items     │
│ Personal         │                          │ Spacers            │
└──────────────────┴──────────────────────────┴────────────────────┘
```

## Left Pane: Workspace List

Required:

* list non-archived workspaces
* active workspace indicator
* dirty draft indicator
* create workspace
* duplicate workspace
* archive workspace
* switch workspace
* open workspace in builder

## Center Pane: Workspace Canvas

Required:

* shows current draft’s function items
* supports reorder
* supports remove
* supports item selection
* shows group item as one icon/card
* shows linked/detached badge
* shows missing/unavailable states
* shows spacer/divider
* shows Function Bar preview if enabled

## Right Pane: Library / Inspector

Tabs or sections:

* Commands
* Groups
* Menu Bar Items, Pro gated
* Layout Items: spacer/divider
* Info Tiles, disabled placeholder for v0.1.7
* Inspector for selected item

## Required Actions

* Add command item.
* Add group item.
* Add spacer.
* Add divider.
* Add menu bar item proxy if available.
* Remove selected item.
* Move item left/right or up/down.
* Commit changes.
* Revert changes.
* Preview Function Bar.

## Drag/Drop

If SwiftUI drag/drop is straightforward:

* implement drag from Library to Canvas
* implement reorder inside Canvas

If drag/drop is too brittle:

* implement add buttons and up/down reorder first
* keep drag/drop behind `setBuilderDragDropEnabled`
* document partial drag/drop status

But Phase 19 should make a reasonable best effort to support drag/drop because reusable Group drag is central to the product direction.

## Tests

Add UI tests:

* Set Builder route renders
* workspace list appears
* command library appears
* group library appears
* add command item
* add spacer/divider
* reorder item via accessible controls
* commit changes
* revert changes
* preview Function Bar opens
* no Accessibility prompt on basic builder

## Acceptance Criteria

* Set Builder MVP is usable.
* User can edit workspace items without raw JSON.
* User can add Groups to Workspaces.
* Function Bar preview reflects edits.
* UI tests pass.

---

# Workstream 19.6 — Library Providers

## Goal

Provide a clear library of items that can be added to a Workspace.

## Library Sections

### Commands

Include safe commands:

* Find Icon
* Show Second Bar
* Reveal All
* Expand
* Collapse
* Toggle
* Open Settings
* Open Recovery
* Show Function Bar
* Hide Function Bar
* Switch Workspace, target selected later
* Full Menu Bar Mode if existing and safe

Do not include Labs/Experimental commands by default.

Advanced commands can appear only if:

* `setBuilderShowAdvancedLibraryItems` is enabled
* feature gate is available
* status badge is shown

### Groups

List existing Groups:

* group name, redacted if protected
* item count
* linked insertion default
* detached insertion option

### Menu Bar Items

Available only when:

* Pro Mode enabled
* Accessibility Discovery enabled
* Accessibility permission granted
* latest snapshot available

Show degraded states if unavailable.

Use only stable references; do not require raw live metadata in persistence.

### Layout Items

* Spacer
* Divider

### Info Tiles

Show disabled placeholder:

* Current Workspace, coming v0.1.7
* Clock, coming v0.1.7
* Battery, coming v0.1.7
* New Item Count, coming v0.1.7

Do not implement Info Strip runtime.

## Tests

Add tests:

* command library builds
* advanced commands hidden by default
* groups library redacts protected groups
* menu bar items library unavailable with Pro off
* menu bar items library available with fixture/pro snapshot
* layout items available
* info tiles deferred
* library diagnostics redacted

## Acceptance Criteria

* Library is useful and not overwhelming.
* Pro-gated items degrade clearly.
* Advanced/Experimental items are hidden by default.
* Tests pass.

---

# Workstream 19.7 — Drag and Drop / Reorder Engine

## Goal

Support intuitive item placement while keeping privacy and reliability.

## Drag Payload

Implement a privacy-safe drag payload:

```swift
struct SetBuilderDragPayload: Codable, Equatable {
    var payloadID: UUID
    var payloadKind: SetBuilderDragPayloadKind
    var sourceKind: SetBuilderDragSourceKind
}
```

Payload kinds:

```swift
enum SetBuilderDragPayloadKind: Codable, Equatable {
    case command(String)
    case group(UUID)
    case menuBarItemHash(String)
    case spacer
    case divider
    case existingWorkspaceItem(UUID)
}
```

Do not include raw menu bar item names, raw bundle IDs, protected group names, or workspace names in drag payload logs/diagnostics.

## Drop Targets

Implement:

```swift
enum SetBuilderDropTarget: Equatable {
    case workspaceCanvas(workspaceID: UUID, index: Int)
    case groupEditor(groupID: UUID, index: Int)
    case library
    case trash
}
```

For Phase 19:

* workspace canvas is required
* group editor is optional if group editing UI is implemented
* trash/remove target is optional

## Drop Validation

Validate:

* target workspace exists
* target index valid
* item count limit not exceeded
* group exists
* menu bar item reference valid enough
* command supported
* protected group needs appropriate handling
* Safe Mode restrictions
* no duplicate if duplicate policy disallows

## Reorder

Support reorder within the same Workspace.

If drag/drop reorder is difficult, implement accessible up/down buttons.

## Tests

Add tests:

* command payload accepted
* group payload accepted
* missing group rejected or unresolved placeholder created
* menu bar item payload requires Pro metadata
* item count limit enforced
* reorder valid
* reorder invalid index rejected
* payload redaction
* drag/drop disabled setting blocks drag commit

## Acceptance Criteria

* Drag/drop works for key MVP paths or has accessible fallback.
* Group drag into Workspace works.
* Reorder works.
* No sensitive data in drag diagnostics.
* Tests pass.

---

# Workstream 19.8 — Linked Group Semantics

## Goal

Make linked reusable Groups the core productivity feature.

## Product Behavior

When a user drags a Group into a Workspace, default insertion mode is:

```text
Linked Group
```

Meaning:

* Workspace stores a reference to the existing Group.
* Function Bar displays the Group as one item.
* Clicking the Group opens the Group panel.
* Editing the Group changes what appears in every Workspace that references it.
* The Workspace does not copy individual member items.

## Required Data

If Phase 17 only added:

```swift
struct WorkspaceGroupReference {
    var groupID: UUID
    var referenceMode: WorkspaceGroupReferenceMode
}
```

Extend backward-compatibly:

```swift
struct WorkspaceGroupReference: Codable, Equatable, Hashable {
    var groupID: UUID
    var referenceMode: WorkspaceGroupReferenceMode
    var sourceGroupID: UUID?
    var createdAt: Date?
}
```

For linked:

```text
groupID = original group ID
referenceMode = linked
sourceGroupID = nil
```

For detached:

```text
groupID = copied group ID
referenceMode = detached
sourceGroupID = original group ID
```

If adding dates breaks migration style, omit dates and follow existing schema conventions.

## Linked Group Update

Implement resolution:

```text
Workspace -> WorkspaceGroupReference(groupID: X, linked)
GroupStore -> Group X
Function Bar -> render latest Group X
```

No duplicated item list should be stored in the Workspace for linked mode.

## Reverse Reference Index

Implement helper:

```swift
struct WorkspaceGroupUsageIndex {
    func workspacesReferencing(groupID: UUID) -> [UUID]
    func referenceCount(groupID: UUID) -> Int
}
```

Use in UI:

* “Used in 3 Workspaces”
* “Editing this Group updates 3 Workspaces”

## Linked Edit Warning

If `setBuilderWarnBeforeLinkedGroupEdits` is true:

* show warning when editing a Group that is used by multiple Workspaces
* allow user to continue
* allow user to create detached copy instead

## Tests

Add tests:

* linked group reference resolves latest group items
* editing group updates multiple workspaces’ resolved Function Bar representation
* workspace does not duplicate linked group items
* group usage index counts references
* protected group name redacted in usage diagnostics
* warning condition when reference count > 1

## Acceptance Criteria

* Linked Groups work.
* Editing a linked Group affects all referencing Workspaces.
* UI warns when editing a widely used Group.
* No privacy leaks.
* Tests pass.

---

# Workstream 19.9 — Detached Group Copy Semantics

## Goal

Support a user choosing to insert a Group as a detached copy.

## Product Behavior

When adding a Group to a Workspace, user can choose:

* **Linked Group**: updates everywhere
* **Detached Copy**: copies the Group for this Workspace only

Recommended UI:

* default button: “Add Linked”
* secondary option: “Add Detached Copy”
* Option-drag can mean detached copy if drag/drop modifier detection is available
* context menu: “Convert to Detached Copy”

## Detached Copy Implementation

Recommended implementation:

1. Copy the source Group into GroupStore as a new Group.
2. Give it a new UUID.
3. Name it:

```text
<Original Name> Copy
```

or:

```text
<Original Name> for <Workspace Name>
```

Use safe redaction rules if original is protected.

4. Workspace stores:

```swift
WorkspaceGroupReference(
    groupID: copiedGroupID,
    referenceMode: .detached,
    sourceGroupID: originalGroupID
)
```

5. Future edits to original Group do not affect detached copy.

6. Future edits to detached copy do not affect original Group.

## Convert Existing Linked to Detached

Implement if feasible:

* select linked group item in Set Builder
* choose “Detach Copy”
* create copied group
* update workspace item reference to copied group
* mark as detached

If too large, defer convert action but implement direct detached insertion.

## Tests

Add tests:

* detached insertion creates new group ID
* detached copy has copied members
* detached copy stores sourceGroupID
* editing original does not affect detached copy
* editing detached copy does not affect original
* linked-to-detached conversion if implemented
* protected group copy uses redacted/safe naming
* import/export preserves sourceGroupID

## Acceptance Criteria

* User can insert detached Group copy.
* Detached copy is independent.
* Linked remains default.
* Tests pass.

---

# Workstream 19.10 — Group Editor MVP

## Goal

Allow editing Groups enough to support linked Workspaces without turning this into a huge separate product.

## UI Location

Keep under:

```text
Set Builder → Library → Groups
```

and/or:

```text
Advanced → Groups
```

Do not add Groups back as a main Settings top-level section.

## Group Editor MVP

Required:

* create group
* rename group
* choose icon
* add command item
* add menu bar item proxy if Pro available
* add spacer/divider if group supports layout items
* remove item
* reorder items
* show workspaces using this group
* warning if group is linked in multiple workspaces
* duplicate group
* archive/delete group if safe

Optional:

* protect group with Private Access if existing service is stable enough

## Group Item Types

Group can contain:

* menu bar item proxy
* command
* spacer/divider if already supported
* nested group should be deferred unless existing model already supports it safely

Avoid recursive/nested groups in Phase 19 unless already robust.

## Tests

Add tests:

* create group
* edit group
* add command
* add menu bar proxy
* reorder group items
* warning for linked usage
* duplicate group
* archive group with workspace references creates missing reference state or blocks archive with warning
* protected group redaction

## Acceptance Criteria

* Groups can be edited for linked reuse.
* Editing linked Group updates Function Bar resolved output.
* UI warns about multi-workspace usage.
* Nested groups remain deferred unless already safe.
* Tests pass.

---

# Workstream 19.11 — Workspace Item Inspector

## Goal

Let users understand and edit selected Workspace items.

## Inspector Fields

For selected item:

### Command

* command name
* command description
* status badge
* remove item
* replace command

### Menu Bar Item Proxy

* safe display name
* source
* current zone if available
* Pro requirement
* actions:

  * show in Find Icon
  * show in Second Bar
  * open owning app
  * arrange manually
  * remove from Workspace
* no broad activation claim

### Group

* group name, redacted if protected
* reference mode:

  * linked
  * detached
* used-in count
* edit group
* detach copy
* replace group
* remove from Workspace

### Spacer / Divider

* type
* remove
* move

### Info Tile Placeholder

* deferred status
* “Info Strip arrives in a later v0.1.x release”
* remove

## Tests

Add UI/unit tests:

* command inspector
* proxy inspector Pro unavailable
* linked group inspector
* detached group inspector
* missing group inspector
* spacer/divider inspector
* remove action
* detach action if implemented

## Acceptance Criteria

* User can inspect items.
* User understands linked vs detached group.
* User can remove/replace items.
* No overclaims.
* Tests pass.

---

# Workstream 19.12 — Function Bar Preview Integration

## Goal

Make Set Builder changes visible in Function Bar Preview.

## Required Behavior

When editing a Workspace draft:

* preview canvas updates immediately
* optional live Function Bar preview can update from draft
* committed changes update real Function Bar runtime
* active workspace switch updates Function Bar
* if Function Bar is visible and active workspace draft commits, refresh visible items

## Important Boundary

Draft preview must not:

* save until commit, unless autosave draft is explicitly implemented
* mutate real menu bar
* apply profile
* move icons
* start Info Strip

## Preview Modes

Support two preview levels:

1. **Canvas Preview**

   * pure SwiftUI inside Set Builder
   * always available

2. **Live Function Bar Preview**

   * opens actual Function Bar panel
   * Preview gated
   * optional
   * disabled in Safe Mode

## Tests

Add tests:

* canvas preview updates after add item
* canvas preview updates after reorder
* live Function Bar refreshes after commit
* function bar does not refresh from uncommitted draft unless explicit preview mode
* Safe Mode blocks live preview
* no physical mutation

## Acceptance Criteria

* Set Builder and Function Bar feel connected.
* User can preview before commit.
* Live Function Bar updates after commit.
* No unsafe side effects.
* Tests pass.

---

# Workstream 19.13 — Menu Bar Item Proxy Selection

## Goal

Allow adding discovered menu bar item proxies to Workspaces when Pro Discovery is available.

## Requirements

Menu bar item library section should:

* show unavailable state when Pro off
* show unavailable state when Accessibility Discovery off
* show unavailable state when Accessibility permission missing
* show stale scan state
* show discovered items when available
* allow search/filter if existing Search index can be reused safely
* allow adding item proxy to Workspace

## Privacy

Persistence can store stable reference/hash and optional local display info, but diagnostics/export must redact raw identities by default.

Do not store live query text.

## Actions

From library item:

* add to current Workspace
* add to existing Group
* create new Group with this item
* show in Find Icon
* show in Second Bar

Adding to Group can be Preview if group editor supports it.

## Tests

Add tests:

* Pro off unavailable
* Accessibility missing unavailable
* stale scan unavailable
* fixture snapshot provides items
* add proxy item to Workspace
* add proxy item to Group if implemented
* diagnostics redacts item identity

## Acceptance Criteria

* Users can add real menu bar item proxies when Pro Discovery is available.
* Degraded states are clear.
* No automatic permission prompt.
* Tests pass.

---

# Workstream 19.14 — Command Center Integration

## Goal

Route Set Builder and Group editing actions through consistent command/gate logic where appropriate.

## New or Updated Commands

Add stable internal command IDs if needed:

```text
workspace.builder.open
workspace.item.add
workspace.item.remove
workspace.item.reorder
workspace.item.commitDraft
workspace.item.revertDraft
workspace.group.addLinked
workspace.group.addDetached
workspace.group.detachCopy
workspace.group.edit
workspace.group.openPanel
workspace.preview.functionBar
```

These are internal/Preview actions, not public App Intents.

## Gates

Evaluate:

* Safe Mode
* Workspaces Preview enabled
* Set Builder Preview enabled
* Function Bar Preview enabled for live preview
* Pro/AX for menu bar item proxy selection
* group exists
* workspace exists
* protected group/workspace gate if Private Access is safely supported
* item count limit
* command supported

## No Public Automation Yet

Do not expose Set Builder actions through:

* App Intents
* URL automation
* external scripts

unless strictly internal/testing and disabled by default.

## Tests

Add tests:

* add item command success
* add item command blocked when builder disabled
* add menu bar proxy blocked when Pro off
* add linked group success
* add detached group creates copy
* Safe Mode blocks live preview but may allow non-runtime draft editing if safe
* diagnostics redacted

## Acceptance Criteria

* Set Builder actions use consistent gate logic.
* No automation bypass.
* Tests pass.

---

# Workstream 19.15 — Persistence, Schema Migration, and Import/Export

## Goal

Persist Set Builder changes and upgrade Workspace/Group schemas safely.

## Workspace Schema

If Phase 19 adds fields such as `sourceGroupID`, `builderMetadata`, or item preferences, update schema version.

Required:

* migration from v0.1.4/v0.1.5 workspace snapshot
* old group references still decode
* missing sourceGroupID allowed
* default referenceMode = linked when absent
* item IDs repaired if duplicated
* invalid groups tolerated

## Group Schema

If needed, update Group schema for:

* usage metadata
* sourceGroupID for detached copies
* archived flag
* workspace usage index cache, if persisted

Prefer deriving usage index instead of persisting it unless performance requires persistence.

## Import/Export

Update local backup to include:

* workspaces
* workspace function item lists
* linked group references
* detached group copies
* group records
* schema version
* redaction mode

Import safety:

* imported linked group references must resolve or be marked missing
* imported detached groups must preserve independence
* imported Set Builder settings should not enable risky features by default
* imported workspace should not apply physical profile
* imported workspace should not enable assisted move
* imported workspace should not start Function Bar automatically
* imported workspace should not enable Info Strip

## Tests

Add tests:

* migrate v0.1.4 workspace data
* migrate v0.1.5 workspace data
* decode old group references
* detached group sourceGroupID preserved
* export includes linked/detached references
* import missing group reference safe
* import detached copy remains independent
* support export redacts item identities
* import does not enable runtime features

## Acceptance Criteria

* Workspace/Group schema migration is safe.
* Backup/export supports Set Builder data.
* Import is non-destructive and privacy-safe.
* Tests pass.

---

# Workstream 19.16 — Diagnostics, Health, and Recovery

## Goal

Add Set Builder and linked group health without making Basic Mode fragile.

## Diagnostics Snapshot

Add privacy-safe snapshot:

```swift
struct SetBuilderDiagnosticsSnapshot: Codable, Equatable {
    var previewEnabled: Bool
    var workspaceCount: Int
    var workspaceWithItemsCount: Int
    var totalWorkspaceItemCount: Int
    var linkedGroupReferenceCount: Int
    var detachedGroupReferenceCount: Int
    var missingGroupReferenceCount: Int
    var menuBarProxyReferenceCount: Int
    var commandItemCount: Int
    var spacerDividerCount: Int
    var lastCommitResult: String?
    var lastValidationIssueCount: Int
}
```

Do not include:

* workspace names
* group names
* protected names
* raw menu bar item names
* raw bundle IDs
* drag payload values
* file paths
* live search text

## Health Checks

Add checks:

* workspace item count too high
* missing group references
* detached source group missing
* too many unresolved menu bar proxy references
* builder draft corruption
* group used by workspaces but archived/deleted
* Function Bar visible with invalid active workspace

Health should not mark Basic Mode unhealthy unless Function Bar/Set Builder interferes with Basic controls.

## Recovery Actions

Add recovery actions:

* discard builder draft
* reset current workspace layout to defaults
* reset all Workspaces
* remove missing group references from Workspace, confirmation required
* hide Function Bar
* disable Set Builder Preview
* disable Function Bar Preview

Keep these under Recovery/Advanced.

## Tests

Add tests:

* diagnostics redaction
* missing group health issue
* unresolved proxy health issue
* reset workspace layout recovery
* discard draft recovery
* disable builder preview recovery
* Basic Mode health unaffected by builder corruption

## Acceptance Criteria

* Diagnostics are useful and redacted.
* Health detects Set Builder issues.
* Recovery can fix workspace/group reference problems.
* Basic Mode remains protected.
* Tests pass.

---

# Workstream 19.17 — Advanced Settings Integration

## Goal

Integrate Set Builder into existing Advanced Workspaces Preview UI without making the app heavy again.

## UI Location

Recommended:

```text
Settings
  Advanced
    Workspaces Preview
      Overview
      Workspaces
      Set Builder
      Groups
      Function Bar Preview
      Diagnostics
```

Do not add top-level `Set Builder` sidebar item.

## Page Requirements

Add a Set Builder tab/section:

* Preview badge
* active workspace selector
* builder three-pane UI
* Function Bar preview button
* commit/revert controls
* group mode explanation:

  * linked group
  * detached copy
* no Info Strip runtime
* no physical layout switching

## User Education

Add a short explanation:

> Groups can be reused across multiple Workspaces. By default, dragging a Group into a Workspace creates a linked reference. Editing the Group updates every Workspace that uses it. Use Detached Copy when you want a one-off version for a single Workspace.

## Tests

Add UI tests:

* Workspaces Preview page has Set Builder section
* Set Builder is gated by Preview toggle
* linked/detached explanation visible
* builder route does not prompt Accessibility
* Function Bar preview route works
* Info Strip copy says deferred

## Acceptance Criteria

* Set Builder is discoverable but not overexposed.
* UI explains linked vs detached.
* Advanced remains the home for Preview features.
* Tests pass.

---

# Workstream 19.18 — Manual QA Matrix

## Goal

Add manual QA for Set Builder and Linked Groups.

## Create

```text
docs/testing/manual-v0.1.6-set-builder-qa.md
docs/testing/manual-v0.1.6-linked-groups-qa.md
docs/testing/manual-v0.1.6-results.md
```

## Manual QA Areas

### Enable/Disable

* Launch app with Set Builder disabled.
* Confirm no Set Builder appears in main sidebar.
* Enable Workspaces Preview.
* Enable Set Builder Preview.
* Open Set Builder.

### Workspace Editing

* Create Workspace.
* Rename Workspace.
* Duplicate Workspace.
* Archive Workspace.
* Switch Workspace.
* Add command items.
* Add spacer/divider.
* Reorder items.
* Commit changes.
* Revert changes.
* Confirm Function Bar preview updates.

### Linked Group

* Create Group.
* Add items to Group.
* Drag/Add Group to Workspace A as linked.
* Drag/Add same Group to Workspace B as linked.
* Edit Group.
* Confirm Workspace A and B both reflect update.
* Confirm UI says Group is used in multiple Workspaces.

### Detached Group

* Add Group to Workspace C as detached copy.
* Edit original Group.
* Confirm Workspace C does not update.
* Edit detached copy.
* Confirm original Group does not update.
* Confirm detached badge appears.

### Menu Bar Proxy

* With Pro off, confirm library unavailable.
* Enable Pro Discovery manually.
* Grant Accessibility manually.
* Add menu bar item proxy to Workspace.
* Confirm Function Bar displays proxy.
* Confirm reveal/highlight action works or degrades honestly.

### Missing References

* Delete/archive group used by Workspace if allowed.
* Confirm Workspace shows missing group state.
* Confirm recovery can remove missing reference.

### Privacy

* Export diagnostics.
* Confirm no raw menu bar item names or protected group names in safe export.
* Run no-network watch.

### Safe Mode

* Enter Safe Mode.
* Confirm Function Bar/Set Builder runtime actions are suppressed.
* Confirm Recovery remains available.
* Confirm Basic Mode works.

## Acceptance Criteria

* Manual QA docs exist.
* Results are recorded.
* Preview failures are documented honestly.
* Stable Basic claims remain unaffected.
* Release checklist links to QA docs.

---

# Workstream 19.19 — Documentation

## Goal

Document Set Builder and Linked Groups accurately without overclaiming.

## Create or Update

```text
docs/features/set-builder-v0.1.6-preview.md
docs/features/linked-groups-v0.1.6-preview.md
docs/features/workspaces-v0.1.6-preview.md
docs/features/function-bar-v0.1.6-preview.md
docs/architecture/set-builder-architecture.md
docs/architecture/linked-groups-architecture.md
docs/privacy/v0.1.6-set-builder-privacy.md
docs/release/v0.1.6-release-notes.md
docs/release/v0.1.6-release-checklist.md
docs/release/v0.1.6-known-limitations.md
docs/progress/phase-19-v0.1.6-linked-groups-set-builder.md
README.md
docs/support/workspaces-preview.md
docs/support/set-builder.md
docs/support/linked-groups.md
```

## Required Wording

Use this wording or equivalent:

> Set Builder in v0.1.6 is a Preview tool for arranging MenuBarDeclutter’s app-owned Workspace and Function Bar items. It does not move real macOS menu bar icons or replace the system menu bar.

Use this wording or equivalent:

> Linked Groups let multiple Workspaces reference the same Group. Editing a linked Group updates every Workspace that uses it. Use Detached Copy when you want a one-off version for a single Workspace.

## Docs Must Explain

* What Set Builder is.
* What Set Builder is not.
* What Linked Group means.
* What Detached Copy means.
* How Function Bar preview relates to Set Builder.
* How menu bar item proxies work.
* Why Pro Discovery may be needed.
* Why Screen Recording is not used.
* Why Info Strip is deferred.
* Why physical workspace switching is deferred.
* How to recover missing references.
* How imports/exports handle Workspaces and Groups.

## Forbidden Claims

Do not claim:

* stable Set Builder
* stable Function Bar
* stable Info Strip
* complete system menu bar replacement
* drag/drop physical menu bar control
* stable physical workspace switching
* bulk icon moving
* stable broad third-party item activation
* live icon pixel capture
* media widgets
* online widgets
* v0.2 release

## Acceptance Criteria

* Docs match implementation.
* Docs clearly call Set Builder Preview.
* Docs explain linked/detached groups.
* Privacy claims remain intact.
* Current-facing docs use v0.1.6.

---

# Workstream 19.20 — Tests

## Goal

Add meaningful coverage for Set Builder and Linked Groups.

## Suggested Test Files

Create or update:

```text
MenuBar-ManagerTests/SetBuilderDraftTests.swift
MenuBar-ManagerTests/SetBuilderValidationTests.swift
MenuBar-ManagerTests/SetBuilderLibraryTests.swift
MenuBar-ManagerTests/SetBuilderDragDropTests.swift
MenuBar-ManagerTests/LinkedGroupReferenceTests.swift
MenuBar-ManagerTests/DetachedGroupCopyTests.swift
MenuBar-ManagerTests/SetBuilderCommitTests.swift
MenuBar-ManagerTests/SetBuilderDiagnosticsTests.swift
MenuBar-ManagerTests/SetBuilderImportExportTests.swift
MenuBar-ManagerUITests/SetBuilderPreviewUITests.swift
MenuBar-ManagerUITests/LinkedGroupsUITests.swift
```

Follow existing test style.

## Required Unit Tests

Cover:

1. Set Builder disabled by default.
2. Draft created from Workspace.
3. Add command item.
4. Add spacer.
5. Add divider.
6. Add linked Group.
7. Add detached Group copy.
8. Reorder items.
9. Remove item.
10. Commit draft.
11. Revert draft.
12. Invalid draft blocked.
13. Linked Group resolves latest group data.
14. Editing linked Group updates multiple Workspaces’ resolved output.
15. Detached Group copy creates new Group ID.
16. Editing original does not update detached copy.
17. Editing detached copy does not update original.
18. Group usage index counts references.
19. Missing group reference tolerated.
20. Protected group name redacted.
21. Menu bar item library Pro-off unavailable.
22. Menu bar proxy added when Pro snapshot available.
23. Drag payload redacts sensitive values.
24. Drop validation enforces item count limit.
25. Import/export preserves linked/detached references.
26. Import does not enable risky features.
27. Diagnostics redacts workspace/item/group names.
28. Safe Mode suppresses runtime actions.
29. Function Bar preview updates after commit.
30. Basic Mode unaffected by builder corruption.

## Required UI Tests

Cover:

1. Set Builder Preview route renders.
2. Workspace list appears.
3. Command library appears.
4. Group library appears.
5. Add command item.
6. Add spacer/divider.
7. Add linked Group.
8. Add detached Group if UI supports it.
9. Reorder item via accessible controls.
10. Commit changes.
11. Revert changes.
12. Function Bar preview opens.
13. Linked/detached explanation visible.
14. Missing group state renders if fixture/setup supports it.
15. No Accessibility prompt for basic builder.

If UI drag/drop is brittle, use button-based accessible controls for UI tests and keep drag/drop covered in unit tests.

## Acceptance Criteria

* Set Builder model/store/commit tests pass.
* Linked/detached group tests pass.
* UI smoke coverage exists.
* Existing tests still pass.
* Privacy verification still passes.

---

# Workstream 19.21 — Release and Privacy Verification

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
rg -n "stable Set Builder|stable Function Bar|stable Info Strip|replace.*macOS.*menu bar|system menu bar replacement|live.*menu bar.*clone|pixel capture|live icon capture|Screen Recording" README.md docs MenuBar-Manager || true
rg -n "Set Builder.*move.*icon|Workspace.*apply.*profile|Workspace.*physical.*layout|Workspace.*physical.*switch|bulk move" README.md docs MenuBar-Manager || true
rg -n "Linked Groups.*system menu bar|Group.*merge.*third-party|Group.*native.*menu bar" README.md docs MenuBar-Manager || true
```

Inspect results manually.

Acceptable:

* Historical/future notes if clearly labeled.
* Internal type names that do not claim current stability.
* Docs that explicitly state deferred/future behavior.

Not acceptable:

* Current-facing v0.2 claim.
* Current-facing claim that Set Builder controls real macOS menu bar icons.
* Current-facing claim that linked Groups merge third-party icons into a native menu bar group.
* Current-facing claim that Function Bar captures live pixels.
* Current-facing claim that switching Workspace moves real menu bar icons.
* Any new privacy-sensitive API usage.

## Acceptance Criteria

* Full test suite passes.
* Privacy boundary script passes.
* Release dry-run passes.
* Installed-app verification passes.
* Targeted searches do not reveal current-facing overclaims.
* Phase progress file records final validation results.

---

# Phase 19 Definition of Done

Phase 19 is complete when:

1. App version is `0.1.6`.
2. Build number is incremented to `7` or documented next build.
3. No current-facing docs/UI call this v0.2.
4. `MenuBar-Manager/SetBuilder/` source area exists.
5. Set Builder Preview setting exists and defaults off.
6. Set Builder is under Advanced / Workspaces Preview, not a stable top-level product pillar.
7. Set Builder can create/edit Workspace drafts.
8. Users can add command items to a Workspace.
9. Users can add spacer/divider items to a Workspace.
10. Users can reorder and remove Workspace items.
11. Users can commit and revert Workspace drafts.
12. Users can add Groups to Workspaces.
13. Group insertion supports linked reference.
14. Group insertion supports detached copy.
15. Linked Groups update across all referencing Workspaces.
16. Detached Group copies remain independent.
17. Group usage index exists or equivalent usage count exists.
18. UI warns when editing a Group used in multiple Workspaces.
19. Function Bar preview reflects committed Workspace changes.
20. Set Builder does not move real menu bar icons.
21. Set Builder does not apply physical profiles.
22. Set Builder does not start Info Strip.
23. Menu bar item proxy library is Pro-gated and degrades clearly.
24. Import/export preserves Workspaces and linked/detached Group references.
25. Diagnostics are privacy-safe and redacted.
26. Health/recovery can handle missing group references and corrupt builder/workspace data.
27. Safe Mode suppresses runtime actions while preserving recovery.
28. No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network, telemetry, analytics, cloud sync, or private APIs are introduced.
29. Full tests pass.
30. Release dry-run and installed-app verification pass.
31. `docs/progress/phase-19-v0.1.6-linked-groups-set-builder.md` includes:

    * summary
    * changed files
    * test results
    * release verification results
    * privacy verification results
    * manual QA status
    * known limitations
    * deferred work for v0.1.7

---

# Recommended Codex Subtask Breakdown

Do not ask Codex to execute all Phase 19 in one huge pass. Use these slices.

## Phase 19A — Version + SetBuilder Skeleton

```markdown
Implement Phase 19A only:
- bump app version to 0.1.6 build 7
- create SetBuilder source area
- add Set Builder Preview settings with safe defaults
- add SetBuilderDraft, item draft, change model, validation shell
- add basic tests
- do not implement drag/drop yet
- do not implement Info Strip
- do not mention v0.2
```

## Phase 19B — Set Builder UI MVP

```markdown
Implement Phase 19B only:
- build three-pane Set Builder UI under Advanced → Workspaces Preview
- workspace list, canvas, library/inspector
- support add command, spacer, divider
- support reorder via accessible up/down controls
- support commit/revert
- add UI tests
- no menu bar proxy or group complexity yet
```

## Phase 19C — Library Providers + Menu Bar Proxy Selection

```markdown
Implement Phase 19C only:
- implement command, group, layout item, and Pro-gated menu bar item library providers
- menu bar proxy library degrades when Pro/AX unavailable
- adding proxy item to Workspace works when references available
- diagnostics redacted
- tests for library providers
```

## Phase 19D — Linked Groups

```markdown
Implement Phase 19D only:
- implement linked Group reference resolution
- implement Group usage index
- add Group to Workspace as linked by default
- Function Bar resolves latest linked Group data
- UI warns when editing Group used by multiple Workspaces
- tests for linked group behavior
```

## Phase 19E — Detached Group Copy

```markdown
Implement Phase 19E only:
- implement detached Group copy insertion
- create copied Group with new UUID
- preserve sourceGroupID if model supports it
- ensure edits to original do not affect detached copy
- ensure edits to detached copy do not affect original
- add tests
```

## Phase 19F — Drag/Drop + Inspector

```markdown
Implement Phase 19F only:
- implement privacy-safe drag payloads
- support drag from Library to Workspace canvas where feasible
- support drag/reorder or accessible fallback
- implement Workspace item inspector
- ensure drag diagnostics do not leak names/IDs
- add tests
```

## Phase 19G — Import/Export + Diagnostics + Recovery

```markdown
Implement Phase 19G only:
- update workspace/group schema migration
- update import/export backup for linked/detached references
- add Set Builder diagnostics snapshot
- add health checks and recovery actions
- add tests
```

## Phase 19H — Docs + Manual QA + Final Validation

```markdown
Implement Phase 19H only:
- add v0.1.6 Set Builder and Linked Groups docs
- update release notes/checklist
- add manual QA docs
- run full validation commands
- run targeted privacy/overclaim searches
- record final results in phase progress doc
```
