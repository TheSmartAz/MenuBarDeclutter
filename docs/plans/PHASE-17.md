
# Phase 17 — v0.1.4 Workspaces Foundation

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar decluttering utility written in Swift, AppKit, and SwiftUI.

This phase follows v0.1.3. The active release line for this phase is:

`v0.1.4`

This phase is **not v0.2**. Do not create v0.2 execution docs, v0.2 release notes, v0.2 public claims, v0.2 artifact names, or current-facing v0.2 roadmap copy.

## Phase Mission

Phase 17 introduces the foundation for a future Workspaces / Sets system.

The long-term product idea is:

> A user can define different menu bar workspaces. Each workspace can later have its own Function Bar, reusable groups, optional Info Strip, and optional physical profile binding.

But Phase 17 is only the foundation.

By the end of Phase 17:

1. The app has a stable Workspace data model.
2. Workspaces are persisted locally under Application Support.
3. Workspaces have schema versioning, validation, corruption backup, and safe defaults.
4. A current active workspace can be selected and persisted.
5. Command Center can route basic workspace commands.
6. Groups can be referenced by workspace items in preparation for linked reusable groups.
7. Profiles can be optionally referenced by workspace as a future physical layout binding.
8. Diagnostics report privacy-safe workspace status.
9. Advanced Settings has a small Workspaces Preview page.
10. Basic Mode, Find & Rescue, Arrange, Recovery, privacy boundary, and release scripts remain stable.

Phase 17 must **not** implement the full Function Bar, Info Strip, Set Builder, workspace drag/drop, physical menu bar set switching, or bulk icon movement.

## Product Boundary

Workspaces in this phase are a local app-owned configuration layer.

They do not replace the macOS system menu bar.
They do not take ownership of third-party menu bar icons.
They do not capture menu bar pixels.
They do not require Screen Recording.
They do not use ScreenCaptureKit.
They do not use private Apple menu bar APIs.

Future phases may use Workspace data to power Function Bar and Info Strip, but Phase 17 only creates the foundation.

## Version Target

Set active app version to:

- Marketing version: `0.1.4`
- Build number: increment from `4` to `5`, unless the project has already advanced build numbering.

Release artifacts should use:

- `MenuBarDeclutter-v0.1.4.zip`
- `MenuBarDeclutter-v0.1.4-alpha.zip` only if alpha/dogfood packaging still exists.

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
- Product should remain privacy-first and local-first.

## Hard Rules

1. Do not call this phase v0.2.
2. Do not add Screen Recording.
3. Do not add ScreenCaptureKit.
4. Do not add Apple Events scripting/control.
5. Do not add Input Monitoring.
6. Do not add network access, telemetry, analytics, crash upload, cloud sync, remote config, update checks, or license checks.
7. Do not use private Apple menu bar APIs.
8. Do not silently prompt for Accessibility.
9. Do not make Workspaces a stable public claim in v0.1.4.
10. Do not implement full Function Bar UI in this phase.
11. Do not implement Info Strip rotation in this phase.
12. Do not implement drag/drop Set Builder in this phase.
13. Do not implement bulk icon moving.
14. Do not make assisted icon moving stable.
15. Do not enable physical workspace switching by default.
16. Do not mutate real menu bar layout when switching Workspace.
17. Do not break Basic Mode, Safe Mode, diagnostics export, privacy verification, or release dry-run.
18. Do not move advanced Preview/Labs/Experimental features back into the main Settings sidebar.
19. Keep Workspace UI under Advanced / Preview only.
20. Diagnostics must not export raw workspace item names, raw menu bar item identities, protected group names, live search text, or file paths by default.

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

`docs/progress/phase-17-v0.1.4-workspaces-foundation.md`

Record:

* baseline git status
* baseline version/build
* baseline test results
* baseline privacy verification result
* baseline release dry-run result
* baseline installed-app verification result
* current known limitations
* exact date
* short phase goal

---

# Workstream 17.1 — Version and Release Identity

## Goal

Move the active release line from `0.1.3` to `0.1.4`.

## Tasks

1. Search version references:

```bash
rg -n "0\.1\.3|v0\.1\.3|0\.1\.4|v0\.1\.4|0\.2|v0\.2|MARKETING_VERSION|CURRENT_PROJECT_VERSION|CFBundleShortVersionString|CFBundleVersion" .
```

2. Update active version/build values to:

* `0.1.4`
* build `5`

3. Update release artifact naming.

4. Add release notes placeholder:

`docs/release/v0.1.4-release-notes.md`

5. Add release checklist:

`docs/release/v0.1.4-release-checklist.md`

6. Update current docs that list latest release line.

7. Do not create v0.2 docs.

8. If historical docs mention v0.2, leave them only if clearly historical/future. Do not convert current-facing language to v0.2.

## Acceptance Criteria

* App bundle reports `0.1.4`.
* Build number is `5` or documented next build number.
* Release artifacts use `v0.1.4`.
* Current-facing docs/UI do not call this v0.2.
* Release dry-run still works.

---

# Workstream 17.2 — Workspaces Source Area and Module Boundaries

## Goal

Create a focused Workspaces source area without spreading workspace logic across unrelated modules.

## New Source Area

Create:

```text
MenuBar-Manager/Workspaces/
  Models/
  Store/
  Switching/
  Diagnostics/
  Settings/
```

Suggested files:

```text
MenuBar-Manager/Workspaces/Models/MenuBarWorkspace.swift
MenuBar-Manager/Workspaces/Models/WorkspaceItem.swift
MenuBar-Manager/Workspaces/Models/WorkspaceItemKind.swift
MenuBar-Manager/Workspaces/Models/WorkspaceDisplayMode.swift
MenuBar-Manager/Workspaces/Models/WorkspaceBehavior.swift
MenuBar-Manager/Workspaces/Models/WorkspaceInfoStripConfig.swift
MenuBar-Manager/Workspaces/Models/WorkspaceFunctionBarConfig.swift
MenuBar-Manager/Workspaces/Models/WorkspaceGroupReference.swift
MenuBar-Manager/Workspaces/Models/WorkspacePhysicalProfileBinding.swift
MenuBar-Manager/Workspaces/Models/WorkspaceValidation.swift
MenuBar-Manager/Workspaces/Store/WorkspaceStore.swift
MenuBar-Manager/Workspaces/Store/WorkspaceStoreSnapshot.swift
MenuBar-Manager/Workspaces/Store/WorkspaceStoreError.swift
MenuBar-Manager/Workspaces/Store/WorkspaceStoreMigration.swift
MenuBar-Manager/Workspaces/Store/WorkspaceBackupService.swift
MenuBar-Manager/Workspaces/Switching/WorkspaceSwitchingService.swift
MenuBar-Manager/Workspaces/Switching/WorkspaceSwitchResult.swift
MenuBar-Manager/Workspaces/Diagnostics/WorkspaceDiagnosticsSnapshot.swift
MenuBar-Manager/Workspaces/Diagnostics/WorkspaceDiagnosticsRedactor.swift
MenuBar-Manager/Workspaces/Settings/WorkspacePreviewSettingsView.swift
MenuBar-Manager/Workspaces/Settings/WorkspacePreviewViewModel.swift
```

If the repo already has equivalent types after previous work, extend them instead of duplicating.

## Project Membership

Add all new Swift files to:

* `MenuBarDeclutter` target
* relevant test target if test helpers are created

Do not add local fixture-only code to shipping target unless required.

## Module Boundaries

Workspaces may depend on:

* CommandCenter model types
* Groups identity/reference types
* Profiles identity/reference types
* SettingsStore
* AppSupportPaths
* Diagnostics
* Privacy redaction helpers
* DesignSystem
* Settings route model

Workspaces must not directly depend on:

* ScreenCaptureKit
* Screen Recording
* network APIs
* Icon Moving execution services
* CGEvent moving implementation
* low-level Accessibility scanner internals beyond stable menu bar item references
* UI-only Search panel logic
* UI-only Second Bar panel logic

## Acceptance Criteria

* Workspaces source area exists.
* New files are target-membered correctly.
* Build succeeds.
* Workspace logic has clear boundaries.
* No privacy-sensitive APIs are introduced.

---

# Workstream 17.3 — Core Workspace Data Model

## Goal

Define the data model for future menu bar Workspaces / Sets.

## Required Types

Implement a Codable, Equatable, Identifiable workspace model.

Suggested shape:

```swift
struct MenuBarWorkspace: Identifiable, Codable, Equatable {
    var id: UUID
    var schemaVersion: Int
    var name: String
    var iconName: String
    var functionItems: [WorkspaceItem]
    var infoItems: [InfoTileConfiguration]
    var functionBarConfig: WorkspaceFunctionBarConfig
    var infoStripConfig: WorkspaceInfoStripConfig
    var displayMode: WorkspaceDisplayMode
    var hoverBehavior: WorkspaceHoverBehavior
    var clickBehavior: WorkspaceClickBehavior
    var physicalProfileBinding: WorkspacePhysicalProfileBinding?
    var isProtected: Bool
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
}
```

Use project style for dates and Codable strategies. If existing stores avoid raw `Date`, follow the existing convention.

## Workspace Item Types

Implement:

```swift
struct WorkspaceItem: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: WorkspaceItemKind
    var displayNameOverride: String?
    var iconOverride: String?
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
}
```

Suggested enum:

```swift
enum WorkspaceItemKind: Codable, Equatable {
    case menuBarItem(MenuBarItemReference)
    case group(WorkspaceGroupReference)
    case command(WorkspaceCommandReference)
    case infoTile(InfoTileReference)
    case spacer
    case divider
}
```

If `MenuBarItemReference` or equivalent identity type already exists, use it. If not, create a lightweight reference that can represent discovered menu bar items without storing raw names by default:

```swift
struct MenuBarItemReference: Codable, Equatable, Hashable {
    var stableHash: String
    var source: MenuBarItemReferenceSource
    var lastKnownDisplayName: String?
    var lastKnownBundleIdentifier: String?
    var redactionPolicy: ItemReferenceRedactionPolicy
}
```

Do not include raw display names in diagnostics export by default.

## Command Reference

Implement a command reference that points into Command Center without copying execution logic:

```swift
struct WorkspaceCommandReference: Codable, Equatable, Hashable {
    var actionID: String
    var targetKind: String?
    var targetID: String?
}
```

Prefer using existing `MenuBarCommand.Action` if it is Codable and stable. If it is not stable enough for persisted schema, create a versioned string reference.

## Info Tile Reference

Phase 17 does not implement Info Strip, but it should define a placeholder reference:

```swift
struct InfoTileReference: Codable, Equatable, Hashable {
    var providerID: String
    var configurationID: UUID?
}
```

No Info Strip runtime should be implemented yet.

## Group Reference

Implement:

```swift
struct WorkspaceGroupReference: Codable, Equatable, Hashable {
    var groupID: UUID
    var referenceMode: WorkspaceGroupReferenceMode
}

enum WorkspaceGroupReferenceMode: String, Codable, Equatable {
    case linked
    case detached
}
```

For Phase 17, detached references can exist in the model but do not need full clone semantics yet. Full linked-group editing arrives in v0.1.6.

## Physical Profile Binding

Implement:

```swift
struct WorkspacePhysicalProfileBinding: Codable, Equatable {
    var profileID: UUID
    var applyMode: WorkspacePhysicalProfileApplyMode
}

enum WorkspacePhysicalProfileApplyMode: String, Codable, Equatable {
    case none
    case dryRunOnly
    case applySafeBasicSettings
}
```

Do not implement icon moving or bulk physical layout switching.

## Display / Behavior Types

Implement:

```swift
enum WorkspaceDisplayMode: String, Codable, Equatable {
    case functionBar
    case infoStrip
    case lastUsed
}

enum WorkspaceHoverBehavior: String, Codable, Equatable {
    case noChange
    case showFunctionBar
    case pinFunctionBar
}

enum WorkspaceClickBehavior: String, Codable, Equatable {
    case openWorkspacePreview
    case showFunctionBar
    case showSetSwitcher
    case openSettings
}
```

## Config Types

Implement minimal configs:

```swift
struct WorkspaceFunctionBarConfig: Codable, Equatable {
    var isEnabled: Bool
    var density: WorkspaceFunctionBarDensity
    var showLabels: Bool
}

enum WorkspaceFunctionBarDensity: String, Codable, Equatable {
    case compact
    case regular
}

struct WorkspaceInfoStripConfig: Codable, Equatable {
    var isEnabled: Bool
    var rotationIntervalSeconds: Int
    var idleDelaySeconds: Int
}
```

Clamp numeric values during validation.

## Acceptance Criteria

* Workspace data model compiles.
* Workspace item model supports menu bar item proxy, group reference, command, info tile placeholder, spacer, and divider.
* Models are Codable, Equatable, and test-covered.
* Physical profile binding exists but cannot mutate real layout.
* Info Strip config exists but no runtime Info Strip is implemented.
* Model names and cases are stable enough for future migration.

---

# Workstream 17.4 — Workspace Validation and Safe Defaults

## Goal

Make workspace data robust before it powers UI.

## Default Workspaces

Create a default workspace set.

Suggested defaults:

1. `Default`

   * command: Find Icon
   * command: Show Second Bar
   * command: Reveal All
   * spacer/divider if useful

2. `Focus`

   * command: Find Icon
   * command: Show Second Bar
   * command: Collapse

3. `Meeting`

   * command: Reveal All
   * command: Show Second Bar
   * placeholder for future group

Do not add raw third-party item references by default.

## Validation Rules

Implement validation logic:

* Workspace name cannot be empty.
* Workspace name length should be clamped.
* Workspace icon name should be sanitized or defaulted.
* Workspace must have valid UUID.
* Workspace schema version must be supported or migrated.
* `functionItems` count should be clamped to a safe maximum.
* `infoItems` count should be clamped to a safe maximum.
* Duplicate item IDs within one workspace should be repaired.
* Disabled items are allowed.
* Unknown command references should be marked unavailable, not crash.
* Missing group references should remain but show unresolved state.
* Missing physical profile references should remain but show unresolved state.
* Rotation interval and idle delay should be clamped.
* Archived workspaces should not be active.
* Active workspace ID must point to a non-archived workspace.
* If active workspace is missing, fall back to Default.
* If all workspaces are invalid, recreate safe default workspace.

Suggested limits:

```text
max workspaces: 50
max function items per workspace: 64
max info items per workspace: 32
workspace name max length: 80
rotation interval: 3s to 120s
idle delay: 1s to 120s
```

Use project conventions for constants.

## Validation Result

Add a structured validation result:

```swift
struct WorkspaceValidationResult {
    var repairedWorkspaces: [MenuBarWorkspace]
    var issues: [WorkspaceValidationIssue]
    var selectedActiveWorkspaceID: UUID
    var didRepair: Bool
}
```

Diagnostic issues should be privacy-safe.

## Tests

Add tests for:

* empty name repair
* duplicate item IDs repair
* invalid active workspace fallback
* archived active workspace fallback
* too many workspaces clamped
* too many function items clamped
* unsupported command reference does not crash
* missing group reference becomes unresolved
* missing profile binding becomes unresolved
* corrupted config values clamped
* all-invalid store falls back to default

## Acceptance Criteria

* Workspace validation is deterministic.
* Invalid workspace data cannot crash app startup.
* Safe default workspace is recreated when needed.
* Active workspace always resolves to a valid non-archived workspace.
* Tests cover validation.

---

# Workstream 17.5 — Workspace Store and Application Support Paths

## Goal

Persist Workspaces locally and safely under Application Support.

## App Support Path

Extend `AppSupportPaths` or equivalent central path manager.

Add:

```text
Application Support/MenuBarDeclutter/workspaces/
Application Support/MenuBarDeclutter/workspaces/workspaces.json
Application Support/MenuBarDeclutter/workspaces/backups/
```

If the project already centralizes backups under `backups/`, follow existing convention.

## Store Format

Use one versioned JSON file:

```json
{
  "schemaVersion": 1,
  "activeWorkspaceID": "...",
  "workspaces": [],
  "createdAt": "...",
  "updatedAt": "..."
}
```

Implement:

```swift
struct WorkspaceStoreSnapshot: Codable, Equatable {
    var schemaVersion: Int
    var activeWorkspaceID: UUID?
    var workspaces: [MenuBarWorkspace]
    var createdAt: Date
    var updatedAt: Date
}
```

## Store API

Implement:

```swift
protocol WorkspaceStoreProtocol {
    func load() throws -> WorkspaceStoreSnapshot
    func save(_ snapshot: WorkspaceStoreSnapshot) throws
    func resetToDefaults() throws -> WorkspaceStoreSnapshot
    func backupCurrentStore(reason: WorkspaceBackupReason) throws -> URL?
}
```

Concrete store:

```swift
final class WorkspaceStore: WorkspaceStoreProtocol
```

## Required Behavior

On load:

1. Ensure directory exists.
2. If file missing, create default snapshot.
3. If file exists, decode.
4. If decode fails, back up corrupted file.
5. Recreate default snapshot if corrupted.
6. Validate and repair snapshot.
7. Save repaired snapshot if needed.
8. Return validated snapshot.

On save:

1. Validate before writing.
2. Write atomically.
3. Do not save raw diagnostics.
4. Do not write outside app support path.
5. Handle errors gracefully.

## Backup

Backup corrupted or pre-repair store to:

```text
workspaces/backups/workspaces-corrupt-YYYYMMDD-HHMMSS.json
workspaces/backups/workspaces-repaired-YYYYMMDD-HHMMSS.json
```

Use existing backup naming conventions if present.

## Tests

Add tests for:

* missing file creates defaults
* valid file loads
* corrupted file backup and reset
* invalid data repairs
* save is atomic or uses project’s safe write pattern
* backup path stays inside app support tree
* load failure does not affect Basic Mode
* active workspace persists
* resetToDefaults works

## Acceptance Criteria

* Workspaces persist locally.
* Corrupted workspace file cannot break app startup.
* Backup is created before destructive reset.
* Store uses Application Support paths.
* Tests pass.

---

# Workstream 17.6 — Workspace Switching Service

## Goal

Support active workspace selection without changing real menu bar layout.

## Tasks

Implement:

```swift
final class WorkspaceSwitchingService {
    func activeWorkspace() -> MenuBarWorkspace
    func switchWorkspace(id: UUID, source: WorkspaceSwitchSource) -> WorkspaceSwitchResult
    func createWorkspace(_ draft: WorkspaceDraft) -> WorkspaceSwitchResult
    func duplicateWorkspace(id: UUID) -> WorkspaceSwitchResult
    func archiveWorkspace(id: UUID) -> WorkspaceSwitchResult
    func deleteWorkspace(id: UUID) -> WorkspaceSwitchResult
    func resetWorkspacesToDefaults() -> WorkspaceSwitchResult
}
```

Use `archive` by default instead of destructive delete if that matches project convention. If delete is implemented, it must not allow deleting the last valid workspace.

## Switch Result

Implement structured result:

```swift
struct WorkspaceSwitchResult: Equatable {
    var status: WorkspaceSwitchStatus
    var activeWorkspaceID: UUID?
    var message: String
    var diagnosticReason: WorkspaceSwitchDiagnosticReason?
}

enum WorkspaceSwitchStatus: Equatable {
    case success
    case notFound
    case archived
    case blockedBySafeMode
    case invalidWorkspace
    case failed
    case noChange
}
```

## Safe Mode

Switching active workspace may be allowed in Safe Mode only if it does not start Function Bar / Info Strip / automation.

Recommended behavior:

* allow viewing workspace list in Advanced
* allow switching active workspace state
* do not launch workspace UI panels
* do not apply physical profile binding
* do not trigger automation
* diagnostics should note Safe Mode restrictions

## No Physical Mutation

Switching workspace in Phase 17 must not:

* collapse/expand Basic Mode
* move icons
* apply physical profile
* start Function Bar
* start Info Strip
* change global spacing
* trigger App Intents/URL automation

It only changes active workspace state.

## Tests

Add tests:

* switch existing workspace
* switch missing workspace
* switch archived workspace
* cannot delete last workspace
* duplicate workspace creates new ID
* archive active workspace falls back to another valid workspace
* Safe Mode switch does not start optional services
* no physical profile mutation is called
* result is privacy-safe

## Acceptance Criteria

* Active workspace can be changed and persisted.
* Switching workspace is non-mutating in Phase 17.
* Safe Mode behavior is conservative.
* Tests cover switching.

---

# Workstream 17.7 — Command Center Integration

## Goal

Add workspace commands to existing Command Center without creating one-off routing paths.

## Tasks

Inspect:

```text
MenuBar-Manager/CommandCenter/
MenuBar-Manager/App/
MenuBar-Manager/Profiles/
MenuBar-Manager/Shortcuts/
MenuBar-Manager/Settings/
```

Add workspace command target and actions.

Suggested actions:

```swift
switchWorkspace
createWorkspace
duplicateWorkspace
archiveWorkspace
resetWorkspaces
showWorkspacePreview
```

If Command Center uses string-backed actions, add versioned stable IDs:

```text
workspace.switch
workspace.create
workspace.duplicate
workspace.archive
workspace.reset
workspace.preview.open
```

## Gates

Workspace commands must evaluate:

* Safe Mode
* feature enabled setting
* workspace preview enabled
* target workspace exists
* target workspace not archived
* command source allowed
* Private Access if workspace is protected, but only if existing Private Access wiring is safe
* automation pause for URL/App Intent sources

For Phase 17, workspace commands should be allowed from:

* Settings
* Advanced preview UI
* internal tests
* status menu only if a preview action is explicitly added

Do not expose App Intents or URL routes for workspaces in Phase 17 unless an internal route already exists and is clearly Preview/Advanced.

## Command Result

Return structured result:

* success
* noChange
* unavailable
* blocked
* failed
* requiresUnlock, only if protected workspace gating is implemented
* previewOnly

Diagnostics must not include raw workspace name if workspace is protected.

## Tests

Add tests:

* switch workspace command success
* missing target command result
* archived target blocked
* Safe Mode restrictions
* automation source blocked if automation paused
* protected workspace name redacted
* command result does not leak item identities

## Acceptance Criteria

* Workspace actions route through Command Center.
* No separate ad-hoc workspace command path.
* Command results are privacy-safe.
* Tests pass.

---

# Workstream 17.8 — Settings Integration: Advanced Workspaces Preview

## Goal

Expose a small Workspaces Preview under Advanced without making Workspaces a main product pillar yet.

## UI Location

Add under:

```text
Settings → Advanced → Workspaces Preview
```

Do not add Workspaces as a top-level sidebar section in v0.1.4.

## Preview Page Content

The page should include:

1. Status header:

   * Workspaces Preview
   * Preview badge
   * “Foundation only in v0.1.4”
   * active workspace name, redacted if protected

2. Explanation:

   * Workspaces are app-owned configurations.
   * They do not replace the macOS menu bar.
   * Future Function Bar / Info Strip support will use this data.
   * Switching a workspace in v0.1.4 does not move menu bar icons.

3. Workspace list:

   * name
   * icon
   * item counts
   * active indicator
   * archived indicator if relevant

4. Actions:

   * create workspace
   * duplicate workspace
   * switch active workspace
   * archive workspace
   * reset to defaults

5. Basic editor:

   * rename workspace
   * choose icon from safe SF Symbol list or existing app-safe icon list
   * toggle protected flag only if Private Access exists safely
   * select display mode placeholder
   * add basic command items from a small command library

6. Placeholder sections:

   * Function Bar: “Coming in later v0.1.x”
   * Info Strip: “Coming in later v0.1.x”
   * Set Builder: “Coming in later v0.1.x”

Do not expose drag/drop builder yet.

## Command Library

Allow adding a few safe command items:

* Find Icon
* Show Second Bar
* Reveal All
* Expand
* Collapse
* Open Settings
* Open Recovery

Each command item is a `WorkspaceItem.kind.command`.

## Degraded States

Show:

* Safe Mode active
* workspace store failed and reset
* workspace feature disabled
* no workspaces
* protected name redacted

## Tests

Add UI/unit tests:

* Workspaces Preview route renders
* list shows defaults
* create workspace works
* duplicate workspace works
* switch active workspace works
* archive workspace works
* reset defaults works
* adding command item works
* no drag/drop builder visible
* placeholders shown for Function Bar / Info Strip
* Safe Mode copy renders
* no Accessibility prompt

## Acceptance Criteria

* Advanced Workspaces Preview exists.
* Users can manage basic workspace records.
* UI clearly says this is Preview/Foundation.
* UI does not imply full Function Bar/Info Strip is implemented.
* No Pro or Accessibility permission is required for this preview.
* Tests pass.

---

# Workstream 17.9 — Group Reference Groundwork

## Goal

Prepare existing Groups module for future linked reusable groups inside Workspaces.

## Tasks

Inspect:

```text
MenuBar-Manager/Groups/
MenuBar-Manager/Workspaces/
MenuBar-Manager/Migration/
MenuBar-Manager/Diagnostics/
```

Add:

1. Workspace group reference type:

   * linked
   * detached

2. Group resolver service or helper:

```swift
struct WorkspaceGroupResolution {
    var groupID: UUID
    var status: WorkspaceGroupResolutionStatus
    var itemCount: Int
}

enum WorkspaceGroupResolutionStatus {
    case resolved
    case missing
    case protected
    case unavailable
}
```

3. A way for Workspace validation to detect missing group references.

4. A way for diagnostics to count:

   * number of group references
   * missing group references
   * protected group references
   * linked references
   * detached references

5. Do not implement drag/drop group insertion yet.

6. Do not implement full linked group UI yet.

7. If Group store corruption occurs, Workspace validation must not crash. Missing group references should show unresolved.

## Tests

Add tests:

* workspace references existing group
* workspace references missing group
* linked reference persists
* detached reference persists
* group diagnostics redacts protected group name
* missing group does not invalidate entire workspace
* workspace store survives group store reset

## Acceptance Criteria

* Workspaces can reference existing groups.
* Missing groups are tolerated.
* Linked/detached reference modes are persisted.
* Diagnostics remain redacted.
* No full Set Builder is exposed yet.

---

# Workstream 17.10 — Profile Binding Groundwork

## Goal

Allow a Workspace to optionally reference an existing Profile as a future physical layout binding, without applying it automatically.

## Tasks

Inspect:

```text
MenuBar-Manager/Profiles/
MenuBar-Manager/Workspaces/
MenuBar-Manager/CommandCenter/
MenuBar-Manager/Diagnostics/
```

Implement:

```swift
WorkspacePhysicalProfileBinding
WorkspacePhysicalProfileApplyMode
```

Supported apply modes in v0.1.4:

* `none`
* `dryRunOnly`
* `applySafeBasicSettings`

But in Phase 17, UI should default to `none` or `dryRunOnly`.

## Critical Rule

Switching workspace must not automatically apply physical profile in Phase 17.

If any dry-run preview is shown, it must be clearly labeled Preview and must not mutate settings.

## Validation

* Missing profile ID should mark binding unresolved.
* Archived/deleted profile should not crash workspace.
* Binding should be removable.
* Binding should not enable Smart Triggers.
* Binding should not enable Icon Moving.
* Binding should not apply Launch at Login system state.
* Binding should not apply Spacing Labs.

## Tests

Add tests:

* valid profile binding persists
* missing profile binding is unresolved
* switching workspace does not apply profile
* dryRunOnly does not mutate Basic settings
* binding is redacted in diagnostics if profile protected/private fields exist
* import/export handles binding safely

## Acceptance Criteria

* Workspace can store optional profile binding.
* No automatic physical layout changes occur.
* Tests confirm non-mutation.
* UI clearly describes this as future/Preview groundwork.

---

# Workstream 17.11 — Import / Export / Backup Integration

## Goal

Include Workspace data in local backup/export infrastructure safely.

## Tasks

Inspect:

```text
MenuBar-Manager/Migration/
MenuBar-Manager/Core/
MenuBar-Manager/Diagnostics/
MenuBar-Manager/Workspaces/
```

Update export schemas to optionally include:

```json
"workspaces": {
  "schemaVersion": 1,
  "activeWorkspaceID": "...",
  "workspaces": []
}
```

## Export Kinds

For safe support export:

* include workspace count
* include active workspace status
* include validation issue counts
* do not include workspace item names
* do not include raw menu bar item identities
* do not include protected workspace names
* do not include protected group names

For complete local backup:

* include full workspace JSON
* still exclude active unlock sessions
* include redaction mode metadata
* do not enable risky features on import by default

## Import Behavior

For Phase 17:

* dry-run import can validate workspace package.
* apply import can restore workspace data only if current migration system already supports safe selected-section apply.
* if apply support is not safe, keep workspace import dry-run only and document it.

Import must:

* validate schema
* create backup before apply
* clamp unsafe values
* repair invalid active workspace
* not enable physical profile apply
* not enable assisted move
* not enable Info Strip runtime
* not enable Function Bar runtime

## Tests

Add tests:

* backup includes workspace section
* safe support export redacts workspace item identities
* complete backup includes workspace records
* import dry-run validates workspace data
* import apply, if implemented, creates backup first
* imported workspace cannot enable risky behavior
* corrupted workspace import fails safely

## Acceptance Criteria

* Workspace data participates in local backup/export.
* Safe support export remains redacted.
* Import cannot turn on risky features.
* Tests pass.

---

# Workstream 17.12 — Diagnostics, Health, and Safe Mode

## Goal

Add workspace health/diagnostic awareness without creating privacy leaks.

## Diagnostics Snapshot

Add:

```swift
struct WorkspaceDiagnosticsSnapshot: Codable, Equatable {
    var workspaceFeatureEnabled: Bool
    var workspaceCount: Int
    var archivedWorkspaceCount: Int
    var activeWorkspacePresent: Bool
    var activeWorkspaceIDHash: String?
    var validationIssueCount: Int
    var missingGroupReferenceCount: Int
    var missingProfileBindingCount: Int
    var commandItemCount: Int
    var menuBarItemReferenceCount: Int
    var infoTileReferenceCount: Int
    var lastLoadStatus: WorkspaceStoreLoadStatus
}
```

Do not include:

* raw workspace names
* raw menu bar item names
* raw bundle IDs
* raw group names
* protected group names
* protected workspace names
* raw file paths
* live search text
* selected item identity

## Health Checks

Add non-invasive health checks:

* workspace store missing, default recreated
* workspace store corrupted, backup created
* active workspace missing, fallback applied
* missing group references
* missing profile bindings
* too many workspaces/items repaired
* unsupported schema

Health should not mark the whole app unhealthy if workspace preview data is damaged. Basic Mode must remain healthy.

## Safe Mode

Safe Mode should:

* not start future Function Bar / Info Strip runtimes
* not apply workspace physical profile binding
* allow reset workspace data from Advanced if Settings is available
* show workspace diagnostics only if safe

## Recovery Actions

Add optional recovery action:

* reset workspaces to defaults
* backup and reset corrupted workspace store

Keep it under Advanced/Recovery, not normal flow.

## Tests

Add tests:

* diagnostics redaction
* health issue creation
* corrupted store recovery
* active workspace fallback
* Safe Mode prevents workspace runtime side effects
* reset workspaces recovery action

## Acceptance Criteria

* Workspace diagnostics are privacy-safe.
* Workspace corruption cannot break Basic Mode.
* Health reports workspace issues without overreacting.
* Safe Mode suppresses workspace runtime effects.
* Recovery can reset workspace store.

---

# Workstream 17.13 — AppEnvironment Integration

## Goal

Wire Workspace services into the app lifecycle cleanly, without starting future runtime UI.

## Tasks

Inspect:

```text
MenuBar-Manager/App/AppEnvironment.swift
MenuBar-Manager/App/AppDelegate.swift
MenuBar-Manager/App/SettingsRuntimeCoordinator.swift
MenuBar-Manager/App/AppHealthCoordinator.swift
MenuBar-Manager/App/AppEnvironmentLiveStatusSynchronizer.swift
MenuBar-Manager/CommandCenter/
```

Add to composition root:

* WorkspaceStore
* WorkspaceSwitchingService
* WorkspaceDiagnostics provider
* Workspace settings view model factory if needed

Lifecycle behavior:

On app start:

1. Initialize AppSupportPaths.
2. Initialize WorkspaceStore.
3. Load and validate workspace snapshot.
4. Backup/repair if needed.
5. Register workspace diagnostics.
6. Do not open Function Bar.
7. Do not open Info Strip.
8. Do not apply physical profile.
9. Do not prompt for permissions.

On app termination:

* Save any pending workspace state if needed.
* No network.
* No asynchronous external sync.

On settings changes:

* Workspace preview settings can update store.
* Do not restart Basic runtime.

## UI-Test Isolation

Make sure UI tests use isolated app support paths and isolated defaults. Workspace store should respect existing UI-test isolation.

## Tests

Add tests:

* environment creates workspace services
* startup with missing store creates defaults
* startup with corrupted store recovers
* UI-test isolation uses temp workspace path
* Safe Mode does not start workspace runtime
* no Accessibility prompt on workspace preview open

## Acceptance Criteria

* Workspace services are wired.
* App startup remains stable.
* Basic Mode startup order is not broken.
* UI-test isolation works.
* Tests pass.

---

# Workstream 17.14 — URL / App Intents Boundary

## Goal

Do not expose full Workspace automation yet. Add internal command readiness only.

## Tasks

Inspect:

```text
MenuBar-Manager/Shortcuts/
MenuBar-Manager/Profiles/
MenuBar-Manager/CommandCenter/
MenuBar-Manager/App/
```

Phase 17 recommended behavior:

* Do not add public App Intents for Workspaces yet.
* Do not add public URL routes for Workspaces yet.
* If internal routes are added for tests, they must be disabled by default and Preview/Advanced only.
* Existing App Intent and URL automation gates must continue to pass.

If you do add a hidden/internal workspace URL route, it must:

* respect Safe Mode
* respect automation pause
* respect workspace feature gate
* not apply physical profile
* not start Function Bar / Info Strip
* not bypass Private Access
* return privacy-safe result

## Tests

Add tests only if routes/intents are changed:

* no public workspace App Intent appears
* workspace URL route unavailable by default
* Safe Mode blocks route
* automation pause blocks route
* command result privacy-safe

## Acceptance Criteria

* Existing Shortcuts/App Intents remain stable.
* Workspace automation is not public in v0.1.4.
* No bypass is introduced.
* Tests pass.

---

# Workstream 17.15 — Documentation

## Goal

Document Workspaces Foundation clearly without overclaiming.

## Create or Update

```text
docs/features/workspaces-v0.1.4-foundation.md
docs/architecture/workspaces-architecture.md
docs/release/v0.1.4-release-notes.md
docs/release/v0.1.4-release-checklist.md
docs/release/v0.1.4-known-limitations.md
docs/privacy/v0.1.4-workspaces-privacy.md
docs/progress/phase-17-v0.1.4-workspaces-foundation.md
```

Update if current docs have latest release references:

```text
README.md
docs/roadmap/
docs/features/
docs/support/settings-overview.md
docs/release/v0.1.3-public-claims.md or latest public claims doc
```

## Required Wording

Use this wording or equivalent:

> Workspaces in v0.1.4 are Preview/Foundation only. They store local app-owned configurations that future Function Bar and Info Strip features can use. Switching a workspace in v0.1.4 does not move third-party menu bar icons, replace the macOS menu bar, apply physical layouts, or start automation.

## Docs Must Explain

* What a Workspace is.
* What a Workspace is not.
* Where workspace data is stored.
* What is included in diagnostics.
* What is redacted.
* Why Workspaces do not require Screen Recording.
* Why Workspaces do not use ScreenCaptureKit.
* Why switching a Workspace does not change the real menu bar yet.
* How Workspaces will later connect to Function Bar, Info Strip, linked groups, and placement planner.
* Current limitations.

## Forbidden Claims

Do not claim:

* stable Function Bar
* stable Info Strip
* stable Set Builder
* stable workspace drag/drop
* complete system menu bar replacement
* stable physical menu bar set switching
* bulk icon moving
* broad third-party icon activation
* live icon pixel capture
* media widget support
* online widgets
* competitor import
* cloud sync
* v0.2 release

## Acceptance Criteria

* Docs are accurate.
* Docs do not overclaim.
* Current-facing docs use v0.1.4.
* Workspaces are clearly Preview/Foundation.
* Privacy claims remain intact.

---

# Workstream 17.16 — Tests

## Goal

Add meaningful coverage for the new foundation.

## Suggested Test Files

Create or update:

```text
MenuBar-ManagerTests/WorkspaceModelTests.swift
MenuBar-ManagerTests/WorkspaceValidationTests.swift
MenuBar-ManagerTests/WorkspaceStoreTests.swift
MenuBar-ManagerTests/WorkspaceSwitchingServiceTests.swift
MenuBar-ManagerTests/WorkspaceCommandCenterTests.swift
MenuBar-ManagerTests/WorkspaceDiagnosticsTests.swift
MenuBar-ManagerTests/WorkspaceImportExportTests.swift
MenuBar-ManagerTests/WorkspaceHealthTests.swift
MenuBar-ManagerUITests/WorkspacePreviewUITests.swift
```

Follow existing test naming/style conventions.

## Required Unit Tests

Cover:

1. Model Codable round-trip.
2. Default workspace creation.
3. Workspace validation repairs invalid names.
4. Duplicate item IDs repaired.
5. Invalid active workspace fallback.
6. Archived active workspace fallback.
7. Too many workspaces clamped.
8. Too many function items clamped.
9. Missing group reference tolerated.
10. Missing profile binding tolerated.
11. Corrupted store backup and reset.
12. Missing store creates defaults.
13. Save/load persists active workspace.
14. Switching workspace success.
15. Switching archived workspace blocked.
16. Duplicate workspace creates new ID.
17. Deleting/archiving last workspace blocked or repaired.
18. Command Center switch workspace success.
19. Command Center missing target blocked.
20. Safe Mode prevents workspace runtime side effects.
21. Diagnostics redacts names and item identities.
22. Export includes workspace section in complete backup.
23. Safe support export redacts workspace item identities.
24. Import dry-run validates workspace.
25. Import cannot enable risky workspace runtime behavior.

## Required UI Tests

Cover:

1. Advanced Workspaces Preview renders.
2. Default workspaces appear.
3. Create workspace action works.
4. Switch active workspace action works.
5. Duplicate workspace action works.
6. Archive workspace action works.
7. Reset to defaults action works.
8. Function Bar placeholder is shown.
9. Info Strip placeholder is shown.
10. No Accessibility prompt appears.

If UI tests are too brittle, add smoke-level tests consistent with existing suite.

## Acceptance Criteria

* New model/store/switching tests pass.
* UI smoke coverage exists.
* No privacy-sensitive data appears in diagnostics tests.
* Existing tests still pass.

---

# Workstream 17.17 — Release and Privacy Verification

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
rg -n "stable Function Bar|stable Info Strip|replace.*macOS.*menu bar|system menu bar replacement|bulk move|stable automated move|Screen Recording|pixel capture|live icon capture" README.md docs MenuBar-Manager || true
rg -n "Workspace.*move.*icon|Workspace.*apply.*profile|Workspace.*physical.*layout|Workspace.*automation" README.md docs MenuBar-Manager || true
```

Inspect results manually.

Acceptable:

* Historical/future notes if clearly labeled.
* Internal model names that do not claim current stability.

Not acceptable:

* Current-facing v0.2 claim.
* Current-facing claim that Workspaces replace system menu bar.
* Current-facing claim that Workspaces move real icons in v0.1.4.
* Any new privacy-sensitive API usage.

## Acceptance Criteria

* Full test suite passes.
* Privacy boundary script passes.
* Release dry-run passes.
* Installed-app verification passes.
* Targeted searches do not reveal current-facing overclaims.
* Phase progress file records final validation results.

---

# Phase 17 Definition of Done

Phase 17 is complete when:

1. App version is `0.1.4`.
2. Build number is incremented to `5` or documented next build.
3. No current-facing docs/UI call this v0.2.
4. `MenuBar-Manager/Workspaces/` source area exists.
5. Workspace data model exists and is Codable/Equatable/tested.
6. Workspace item model supports:

   * menu bar item proxy reference
   * group reference
   * command reference
   * info tile placeholder
   * spacer
   * divider
7. Workspace store persists local JSON under Application Support.
8. Store supports schema versioning.
9. Store creates defaults when missing.
10. Store backs up corrupted files before reset.
11. Validation repairs unsafe or invalid workspace data.
12. Active workspace can be switched and persisted.
13. Switching workspace does not mutate real menu bar layout.
14. Switching workspace does not start Function Bar or Info Strip.
15. Workspace actions route through Command Center.
16. Advanced Workspaces Preview UI exists.
17. Workspaces are not top-level stable Settings pillar yet.
18. Workspace group references support linked/detached modes at model level.
19. Workspace profile binding exists but does not auto-apply.
20. Import/export can include or dry-run workspace data safely.
21. Diagnostics are privacy-safe and redacted.
22. Health can report workspace store issues without breaking Basic Mode.
23. Safe Mode suppresses workspace runtime side effects.
24. No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network, telemetry, analytics, cloud sync, or private APIs are introduced.
25. Full tests pass.
26. Release dry-run and installed-app verification pass.
27. `docs/progress/phase-17-v0.1.4-workspaces-foundation.md` includes:

    * summary
    * changed files
    * test results
    * release verification results
    * privacy verification results
    * known limitations
    * deferred work for v0.1.5

---

# Recommended Codex Subtask Breakdown

Do not ask Codex to execute all Phase 17 in one huge pass. Use these slices.

## Phase 17A — Version + Workspace Models

```markdown
Implement Phase 17A only:
- bump app version to 0.1.4 build 5
- create Workspaces source area
- add core Workspace models
- add WorkspaceItem, group reference, command reference, info tile placeholder, physical profile binding
- add model Codable round-trip tests
- do not add UI yet
- do not add Function Bar / Info Strip runtime
- do not mention v0.2
```

## Phase 17B — Validation + Store

```markdown
Implement Phase 17B only:
- add Workspace validation and safe defaults
- add AppSupportPaths workspace directory
- add WorkspaceStore JSON persistence
- add schema versioning
- add corrupted file backup/reset behavior
- add tests for missing/corrupted/invalid store
- no UI yet except if needed for compile
- do not start runtime panels
```

## Phase 17C — Switching Service + Command Center

```markdown
Implement Phase 17C only:
- add WorkspaceSwitchingService
- persist active workspace
- add workspace command actions to Command Center
- ensure switching workspace does not mutate real menu bar layout
- ensure Safe Mode behavior is conservative
- add tests for switching and command routing
```

## Phase 17D — Advanced Workspaces Preview UI

```markdown
Implement Phase 17D only:
- add Advanced → Workspaces Preview page
- show workspace list, active indicator, create/duplicate/switch/archive/reset actions
- allow adding a few safe command items
- show Function Bar / Info Strip placeholders only
- no drag/drop builder
- no Accessibility prompt
- add UI smoke tests
```

## Phase 17E — Groups/Profile/Import/Diagnostics Integration

```markdown
Implement Phase 17E only:
- add linked/detached group reference resolution
- add physical profile binding groundwork with no auto-apply
- include workspace data in backup/export safely
- add diagnostics and health snapshot
- ensure redaction of raw workspace item identities and protected names
- add tests
```

## Phase 17F — Docs + Final Validation

```markdown
Implement Phase 17F only:
- update v0.1.4 release docs
- create Workspaces foundation docs
- update privacy docs
- update progress file
- run full validation commands
- run targeted overclaim/privacy searches
- record results
```
