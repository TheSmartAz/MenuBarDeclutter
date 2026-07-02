
# Phase 20 — v0.1.7 Info Strip MVP

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar decluttering utility written in Swift, AppKit, and SwiftUI.

This phase follows:

- Phase 17 / v0.1.4 Workspaces Foundation
- Phase 18 / v0.1.5 Set Switcher + Virtual Function Bar MVP
- Phase 19 / v0.1.6 Linked Groups + Set Builder MVP

The active release line for this phase is:

`v0.1.7`

This phase is **not v0.2**. Do not create v0.2 docs, v0.2 release notes, v0.2 public claims, v0.2 artifact names, or current-facing v0.2 roadmap language.

## Phase Mission

Phase 20 introduces the first Info Strip MVP.

The goal is:

> A Workspace can show a lightweight, app-owned information strip while idle. The Info Strip rotates through local, privacy-safe tiles. When the user hovers over the strip or chooses to interact, it switches back to the active Workspace’s Function Bar.

By the end of Phase 20:

1. An app-owned Info Strip panel exists.
2. Info Strip is configured per Workspace.
3. Info Strip rotates through safe local info tiles.
4. Function Bar and Info Strip share one Workspace display state machine.
5. Idle behavior can switch from Function Bar to Info Strip.
6. Hover behavior can switch from Info Strip back to Function Bar.
7. Info Strip supports local, no-network tiles:
   - current Workspace
   - clock
   - battery
   - hidden item count
   - new item inbox count
   - recovery warning
   - stale scan warning
8. Optional permission-gated Calendar/Reminder tiles may be added only if implemented with explicit user permission and safe degraded states.
9. Info Strip is Preview, off by default, and lives under Advanced / Workspaces Preview.
10. Safe Mode suppresses Info Strip runtime.
11. Diagnostics and exports remain privacy-safe.
12. Basic Mode remains stable and permission-free.

Phase 20 must **not** implement online widgets, media controls, notification scraping, file shelf, ScreenCaptureKit visual capture, Screen Recording, or private APIs.

## Product Boundary

Info Strip is an app-owned floating panel connected to MenuBarDeclutter Workspaces.

It does not:
- replace the macOS system menu bar
- capture screen pixels
- read screen contents
- use Screen Recording
- use ScreenCaptureKit
- use private Apple media/control APIs
- scrape notifications
- use network widgets
- use telemetry/cloud sync
- directly control third-party menu bar items
- move real menu bar icons
- apply physical menu bar layouts

Info Strip in v0.1.7 is a Preview feature. It should be useful, but not advertised as a stable public product pillar yet.

## Version Target

Set active app version to:

- Marketing version: `0.1.7`
- Build number: increment from `7` to `8`, unless the project has already advanced build numbering.

Release artifacts should use:

- `MenuBarDeclutter-v0.1.7.zip`
- `MenuBarDeclutter-v0.1.7-alpha.zip` only if alpha/dogfood packaging still exists.

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
11. Do not silently prompt for Calendar, Reminders, Accessibility, or any other permission.
12. Do not make Info Strip a stable public claim in v0.1.7.
13. Do not claim Info Strip replaces the macOS menu bar.
14. Do not claim Info Strip is a Dynamic Island clone.
15. Do not implement physical workspace switching.
16. Do not automatically apply physical profiles.
17. Do not implement bulk icon moving.
18. Do not make assisted icon moving stable.
19. Do not move real menu bar icons from Info Strip.
20. Keep Info Strip under Preview / Advanced in v0.1.7.
21. Diagnostics must not export raw workspace item names, raw menu bar item identities, protected group names, protected workspace names, calendar event titles, reminder titles, live search text, or file paths by default.

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

`docs/progress/phase-20-v0.1.7-info-strip-mvp.md`

Record:

* baseline git status
* baseline version/build
* baseline test results
* baseline privacy verification result
* baseline release dry-run result
* baseline installed-app verification result
* known limitations from Phase 19
* exact date
* short phase goal

---

# Workstream 20.1 — Version and Release Identity

## Goal

Move the active release line from `0.1.6` to `0.1.7`.

## Tasks

1. Search version references:

```bash
rg -n "0\.1\.6|v0\.1\.6|0\.1\.7|v0\.1\.7|0\.2|v0\.2|MARKETING_VERSION|CURRENT_PROJECT_VERSION|CFBundleShortVersionString|CFBundleVersion" .
```

2. Update active version/build values to:

* `0.1.7`
* build `8`

3. Update release artifact naming.

4. Add release notes placeholder:

`docs/release/v0.1.7-release-notes.md`

5. Add release checklist:

`docs/release/v0.1.7-release-checklist.md`

6. Update latest-progress docs that list current release line.

7. Do not create v0.2 docs.

8. If historical docs mention v0.2, leave them only if clearly historical/future. Do not add current-facing v0.2 language.

## Acceptance Criteria

* App bundle reports `0.1.7`.
* Build number is `8` or documented next build number.
* Release artifacts use `v0.1.7`.
* Current-facing docs/UI do not call this v0.2.
* Release dry-run still works.

---

# Workstream 20.2 — InfoStrip Source Area and Boundaries

## Goal

Create a focused InfoStrip source area for the app-owned idle information strip.

## New Source Area

Create:

```text
MenuBar-Manager/InfoStrip/
  Models/
  Providers/
  Runtime/
  Placement/
  Views/
  Settings/
  Diagnostics/
```

Suggested files:

```text
MenuBar-Manager/InfoStrip/Models/InfoTile.swift
MenuBar-Manager/InfoStrip/Models/InfoTileSnapshot.swift
MenuBar-Manager/InfoStrip/Models/InfoTileProviderID.swift
MenuBar-Manager/InfoStrip/Models/InfoTileAvailability.swift
MenuBar-Manager/InfoStrip/Models/InfoTileConfiguration.swift
MenuBar-Manager/InfoStrip/Models/InfoStripDisplayState.swift
MenuBar-Manager/InfoStrip/Models/InfoStripRotationPolicy.swift
MenuBar-Manager/InfoStrip/Models/InfoStripInteractionMode.swift
MenuBar-Manager/InfoStrip/Providers/InfoTileProvider.swift
MenuBar-Manager/InfoStrip/Providers/InfoTileProviderRegistry.swift
MenuBar-Manager/InfoStrip/Providers/WorkspaceNameTileProvider.swift
MenuBar-Manager/InfoStrip/Providers/ClockTileProvider.swift
MenuBar-Manager/InfoStrip/Providers/BatteryTileProvider.swift
MenuBar-Manager/InfoStrip/Providers/HiddenCountTileProvider.swift
MenuBar-Manager/InfoStrip/Providers/NewItemCountTileProvider.swift
MenuBar-Manager/InfoStrip/Providers/RecoveryWarningTileProvider.swift
MenuBar-Manager/InfoStrip/Providers/StaleScanWarningTileProvider.swift
MenuBar-Manager/InfoStrip/Runtime/InfoStripController.swift
MenuBar-Manager/InfoStrip/Runtime/InfoStripStateMachine.swift
MenuBar-Manager/InfoStrip/Runtime/InfoStripRotationService.swift
MenuBar-Manager/InfoStrip/Runtime/InfoStripViewModel.swift
MenuBar-Manager/InfoStrip/Runtime/WorkspaceDisplayCoordinator.swift
MenuBar-Manager/InfoStrip/Placement/InfoStripPlacementService.swift
MenuBar-Manager/InfoStrip/Views/InfoStripPanelHost.swift
MenuBar-Manager/InfoStrip/Views/InfoStripView.swift
MenuBar-Manager/InfoStrip/Views/InfoTileView.swift
MenuBar-Manager/InfoStrip/Views/InfoStripUnavailableView.swift
MenuBar-Manager/InfoStrip/Views/InfoStripPreviewView.swift
MenuBar-Manager/InfoStrip/Settings/InfoStripPreviewSettingsView.swift
MenuBar-Manager/InfoStrip/Settings/InfoStripTilePickerView.swift
MenuBar-Manager/InfoStrip/Settings/InfoStripPreviewSettingsViewModel.swift
MenuBar-Manager/InfoStrip/Diagnostics/InfoStripDiagnosticsSnapshot.swift
MenuBar-Manager/InfoStrip/Diagnostics/InfoStripDiagnosticsRedactor.swift
```

If the repo already has equivalent files after earlier phases, extend those instead of duplicating.

## Module Boundaries

InfoStrip may depend on:

* Workspaces models/store/switching
* FunctionBar controller/state
* CommandCenter for safe actions
* Hiding/Layout status summaries
* New Item Inbox count provider if existing
* Health/recovery snapshot
* Accessibility scan staleness status through safe diagnostics/status models
* DesignSystem
* Settings route model
* Diagnostics redaction helpers

InfoStrip must not directly depend on:

* ScreenCaptureKit
* Screen Recording
* network APIs
* private Apple APIs
* Notification Center scraping
* media private APIs
* CGEvent moving execution services
* SetBuilder drag/drop internals
* low-level Accessibility scanner internals
* App Intents execution service
* URL automation router

## Acceptance Criteria

* `MenuBar-Manager/InfoStrip/` exists.
* Files are target-membered correctly.
* InfoStrip has clear boundaries.
* Build succeeds.
* No privacy-sensitive APIs are introduced.

---

# Workstream 20.3 — Info Strip Feature Gate and Workspace Settings

## Goal

Add Info Strip Preview settings and per-Workspace configuration.

## Global Settings

Add settings if not already present:

```swift
infoStripPreviewEnabled: Bool
infoStripAutoShowEnabled: Bool
infoStripHoverToFunctionBarEnabled: Bool
infoStripCloseOnOutsideClick: Bool
infoStripPauseWhenFunctionBarPinned: Bool
infoStripKeyboardNavigationEnabled: Bool
infoStripShowPreviewBadge: Bool
```

Recommended defaults:

```text
infoStripPreviewEnabled: false
infoStripAutoShowEnabled: false
infoStripHoverToFunctionBarEnabled: true
infoStripCloseOnOutsideClick: true
infoStripPauseWhenFunctionBarPinned: true
infoStripKeyboardNavigationEnabled: true
infoStripShowPreviewBadge: true
```

## Per-Workspace Config

Use or extend Phase 17 `WorkspaceInfoStripConfig`:

```swift
struct WorkspaceInfoStripConfig: Codable, Equatable {
    var isEnabled: Bool
    var idleDelaySeconds: Int
    var rotationIntervalSeconds: Int
    var selectedTileProviderIDs: [String]
    var showTileLabels: Bool
    var compactMode: Bool
    var hoverBehavior: WorkspaceInfoStripHoverBehavior
}
```

Suggested hover behavior:

```swift
enum WorkspaceInfoStripHoverBehavior: String, Codable, Equatable {
    case showFunctionBar
    case keepInfoStrip
    case pinInfoStrip
}
```

Default per Workspace:

```text
isEnabled: false
idleDelaySeconds: 5
rotationIntervalSeconds: 8
selectedTileProviderIDs:
  - workspace.current
  - clock.local
  - battery.status
  - hidden.count
  - newItems.count
  - health.warning
  - scan.stale
showTileLabels: true
compactMode: true
hoverBehavior: showFunctionBar
```

## Validation

Clamp values:

```text
idleDelaySeconds: 1...120
rotationIntervalSeconds: 3...300
selectedTileProviderIDs max: 20
```

Unknown provider IDs should be tolerated and shown as unavailable.

## Settings UI

Add under:

```text
Settings → Advanced → Workspaces Preview → Info Strip Preview
```

Do not add Info Strip as a top-level sidebar section in v0.1.7.

UI should include:

* Preview badge
* Enable Info Strip Preview toggle
* Enable Info Strip for active Workspace toggle
* Idle delay control
* Rotation interval control
* Tile picker
* Hover behavior picker
* Compact mode toggle
* Show preview badge toggle
* Open Info Strip preview button
* “Info Strip is app-owned UI, not a system menu bar replacement” copy

## Tests

Add tests:

* global Info Strip preview off by default
* workspace Info Strip off by default
* hover-to-function-bar enabled by default
* invalid idle delay clamped
* invalid rotation interval clamped
* unknown provider tolerated
* settings page renders
* no Accessibility prompt
* no network permission/path

## Acceptance Criteria

* Info Strip is Preview-gated.
* Info Strip is off by default.
* Per-Workspace config exists and validates.
* Settings UI is clear and honest.
* Tests pass.

---

# Workstream 20.4 — Info Tile Provider Protocol and Registry

## Goal

Create a provider system for local, privacy-safe tiles.

## Protocol

Implement:

```swift
protocol InfoTileProvider {
    var id: InfoTileProviderID { get }
    var displayName: String { get }
    var category: InfoTileCategory { get }
    var requiredPermission: InfoTilePermission { get }
    var defaultPriority: Int { get }
    func availability(context: InfoTileContext) -> InfoTileAvailability
    func snapshot(context: InfoTileContext) async -> InfoTileSnapshot?
}
```

If async complicates tests/runtime, provide sync providers first:

```swift
func snapshot(context: InfoTileContext) -> InfoTileSnapshot?
```

Use existing project async conventions.

## Core Types

```swift
struct InfoTileSnapshot: Identifiable, Codable, Equatable {
    var id: UUID
    var providerID: String
    var title: String
    var subtitle: String?
    var iconName: String
    var severity: InfoTileSeverity
    var timestamp: Date
    var action: InfoTileAction?
    var privacyLevel: InfoTilePrivacyLevel
}
```

Severity:

```swift
enum InfoTileSeverity: String, Codable, Equatable {
    case normal
    case info
    case warning
    case critical
}
```

Permission:

```swift
enum InfoTilePermission: String, Codable, Equatable {
    case none
    case proDiscovery
    case calendar
    case reminders
    case localAuthentication
    case unavailable
}
```

Privacy level:

```swift
enum InfoTilePrivacyLevel: String, Codable, Equatable {
    case safeForDiagnostics
    case redactedInDiagnostics
    case localOnly
}
```

Action:

```swift
struct InfoTileAction: Codable, Equatable {
    var commandID: String
    var label: String
}
```

Actions should route through Command Center.

## Registry

Implement:

```swift
final class InfoTileProviderRegistry {
    func register(_ provider: InfoTileProvider)
    func provider(id: String) -> InfoTileProvider?
    func availableProviders(context: InfoTileContext) -> [InfoTileProvider]
    func snapshots(for providerIDs: [String], context: InfoTileContext) -> [InfoTileSnapshot]
}
```

Register default local providers.

## Context

Implement:

```swift
struct InfoTileContext {
    var activeWorkspace: MenuBarWorkspace?
    var functionBarVisible: Bool
    var hiddenItemCount: Int?
    var alwaysHiddenItemCount: Int?
    var newItemCount: Int?
    var healthWarningCount: Int
    var latestScanAgeSeconds: Int?
    var proDiscoveryAvailable: Bool
    var safeModeActive: Bool
    var currentDate: Date
}
```

Do not include raw item identities.

## Tests

Add tests:

* registry registers providers
* provider lookup works
* unknown provider returns nil
* provider availability filters correctly
* snapshot privacy levels preserved
* no raw identities in context
* selected provider order preserved
* unavailable providers produce unavailable state, not crash

## Acceptance Criteria

* Provider system exists.
* Default local providers can be registered.
* No network providers.
* No private API providers.
* Tests pass.

---

# Workstream 20.5 — Local Tile Providers MVP

## Goal

Implement safe local tiles for the first Info Strip MVP.

## Required Providers

### 1. Current Workspace

ID:

```text
workspace.current
```

Displays:

* active Workspace name, unless protected/redacted
* icon
* optional “Preview” subtitle

Action:

* open Set Switcher or Workspaces Preview

Diagnostics:

* do not export protected workspace names

### 2. Clock

ID:

```text
clock.local
```

Displays:

* local time
* optional date

No network.

### 3. Battery

ID:

```text
battery.status
```

Displays:

* battery percentage if available
* charging state if available
* unavailable on desktops if battery status missing

Use public macOS APIs only. Do not use private APIs.

### 4. Hidden Count

ID:

```text
hidden.count
```

Displays:

* hidden item count
* always-hidden count if available
* Basic-only fallback if Pro data unavailable

No raw item identities.

### 5. New Item Count

ID:

```text
newItems.count
```

Displays:

* number of new menu bar items in inbox
* unavailable if New Item Inbox / Pro Discovery unavailable

Action:

* open New Item Inbox / Find & Rescue if existing

No raw item names.

### 6. Recovery Warning

ID:

```text
health.warning
```

Displays:

* warning count or “All clear”
* critical if Safe Mode/recovery issue

Action:

* open Recovery

No raw diagnostic details in tile unless safe.

### 7. Stale Scan Warning

ID:

```text
scan.stale
```

Displays:

* “Scan up to date”
* “Menu bar scan may be stale”
* unavailable if Pro Discovery off

No raw item identities.

## Optional Providers

Do not implement unless straightforward and explicitly permission gated:

### Calendar Next Event

ID:

```text
calendar.nextEvent
```

Rules:

* explicit user permission only
* no silent prompt
* event titles redacted in diagnostics
* tile can display local title in UI after permission
* Safe support export excludes event title

### Reminder Count

ID:

```text
reminders.count
```

Rules:

* explicit permission only
* no silent prompt
* reminder titles not exported
* count only is safe

## Do Not Implement

* weather
* stocks
* news
* RSS
* online widgets
* media controls
* now playing controls via private API
* notification scraping
* file shelf
* clipboard viewer
* screen content tiles

## Tests

Add tests:

* each required provider availability
* each required provider snapshot
* battery unavailable path
* Pro unavailable path for New Item and Stale Scan
* protected workspace name redaction
* health warning severity
* no raw item identities
* optional permission providers do not prompt automatically

## Acceptance Criteria

* Required local tiles work.
* Optional permission tiles are gated or deferred.
* No network/private APIs.
* Tests pass.

---

# Workstream 20.6 — Info Strip Rotation Service

## Goal

Rotate selected Info Tiles at a configurable interval.

## Runtime Behavior

Implement:

```swift
final class InfoStripRotationService {
    func start(configuration: WorkspaceInfoStripConfig, contextProvider: InfoTileContextProvider)
    func stop()
    func pause(reason: InfoStripPauseReason)
    func resume(reason: InfoStripResumeReason)
    func currentSnapshot() -> InfoTileSnapshot?
    func advanceManually()
}
```

## Rules

* Do not start automatically unless Info Strip Preview and workspace config are enabled.
* Do not rotate in Safe Mode.
* Do not rotate when Function Bar is visible and `pauseWhenFunctionBarPinned` is true.
* Do not rotate when app is terminating.
* Skip unavailable providers.
* Preserve provider order.
* Loop through selected providers.
* If no available tiles, show unavailable/empty state.
* Rotation interval should use validated config.
* Manual advance should be available from UI if feasible.

## Timer

Use project-safe timer pattern.

Avoid high-frequency polling. Rotation intervals should not be less than 3 seconds.

## Tests

Add tests:

* start with selected providers
* no providers -> empty state
* unavailable provider skipped
* rotation advances by interval
* manual advance works
* pause/resume works
* Safe Mode blocks start
* stop cancels timer
* interval clamped
* no CPU-heavy loop

## Acceptance Criteria

* Info Strip rotates tiles predictably.
* No excessive polling.
* Safe Mode blocks rotation.
* Tests pass.

---

# Workstream 20.7 — Workspace Display State Machine

## Goal

Coordinate Function Bar and Info Strip behavior.

This is the core UX of this phase:

```text
Function Bar visible -> idle delay -> Info Strip visible
Info Strip visible -> hover -> Function Bar visible
```

## State Machine

Implement or extend:

```swift
enum WorkspaceDisplayState: Equatable {
    case closed
    case functionBarVisible(workspaceID: UUID)
    case infoStripVisible(workspaceID: UUID, tileID: String?)
    case transitioningToFunctionBar(workspaceID: UUID)
    case transitioningToInfoStrip(workspaceID: UUID)
    case pinnedFunctionBar(workspaceID: UUID)
    case suspendedBySafeMode
    case unavailable(WorkspaceDisplayUnavailableReason)
}
```

If Function Bar already has its own state machine, add a coordinating layer:

```swift
WorkspaceDisplayCoordinator
```

Responsibilities:

* show Function Bar
* show Info Strip
* switch active Workspace
* start idle countdown after Function Bar interaction ends
* switch to Info Strip after idle delay
* switch back to Function Bar on hover
* pause Info Strip when Function Bar pinned
* close both panels on Safe Mode
* hide Info Strip when Function Bar opens
* hide Function Bar when Info Strip opens, unless design uses same panel host

## Hover Behavior

Use safe event handling:

* app-owned panel hover tracking
* no global event tap
* no Input Monitoring
* no private APIs

Hover transitions:

```text
mouse enters Info Strip -> show FunctionBar
mouse enters FunctionBar -> keep FunctionBar visible
mouse exits FunctionBar -> start idle countdown if enabled
```

Do not track arbitrary system-wide mouse events beyond current allowed patterns. If existing hover reveal uses `NSEvent.mouseLocation` polling, reuse safe approach only if low-cost and no event tap.

## Tests

Add tests:

* Function Bar visible -> idle countdown -> Info Strip visible
* Info Strip hover -> Function Bar visible
* pinned Function Bar prevents Info Strip
* Safe Mode closes/suspends both
* active workspace switch updates state
* disabled Info Strip leaves Function Bar behavior unchanged
* no Input Monitoring/event tap dependency

## Acceptance Criteria

* Function Bar and Info Strip coordinate cleanly.
* Hover returns to Function Bar.
* Idle can switch to Info Strip.
* Safe Mode suppresses all workspace panels.
* Tests pass.

---

# Workstream 20.8 — Info Strip Panel and Views

## Goal

Build a compact native SwiftUI Info Strip panel.

## Visual Direction

Info Strip should be:

* small
* app-owned
* compact
* readable
* not a full dashboard
* not visually pretending to be the real system menu bar
* clear enough in light/dark mode
* consistent with Function Bar placement/style

## Panel

Implement:

```swift
InfoStripPanelHost
InfoStripView
InfoTileView
InfoStripUnavailableView
InfoStripPreviewView
```

The panel should support:

* current tile icon
* title
* subtitle
* optional severity styling
* optional action button
* rotation progress indicator, if simple
* hover tracking
* click to show Function Bar or open tile action, based on config
* manual next tile control, optional
* close/pin control, optional

## Layout

Suggested compact layout:

```text
[icon] Title — Subtitle   [small progress dots]
```

or:

```text
[Workspace icon] Work · 4 hidden · 2 new
```

Do not build a full widget dashboard.

## Empty State

If no tiles available:

```text
Info Strip has no available tiles.
```

Offer:

* open Info Strip settings
* show Function Bar

## Accessibility

Add labels for:

* tile title
* tile subtitle
* severity
* action
* show Function Bar
* close

## Tests

Add UI/unit tests:

* renders tile
* renders subtitle
* renders severity
* renders empty state
* action button routes command
* hover event calls state transition if testable
* accessibility labels present
* protected/redacted tile display

## Acceptance Criteria

* Info Strip panel renders.
* It is compact and native-feeling.
* It does not look like a system menu bar replacement.
* Hover/click interactions work.
* Tests pass.

---

# Workstream 20.9 — Info Strip Placement Service

## Goal

Place Info Strip consistently with Function Bar.

## Placement Modes

Use or mirror Function Bar placement preferences:

```swift
enum InfoStripPlacementPreference: String, Codable, Equatable {
    case alignWithFunctionBar
    case belowMenuBarIcon
    case belowMenuBar
    case nearMouse
    case lastPosition
    case centeredBelowMenuBar
}
```

Default:

```text
alignWithFunctionBar
```

## Placement Rules

* Prefer same anchor as Function Bar.
* Clamp to visible frame.
* Avoid menu bar overlap unless intentionally designed.
* Handle notch estimates if existing Layout service supports this safely.
* Handle external display changes.
* Handle last position invalid fallback.
* Handle auto-hide menu bar variants as best effort.
* No screen capture.
* No private APIs.

## Tests

Add tests:

* align with Function Bar placement
* below menu bar icon fallback
* near mouse placement
* clamping to visible frame
* last position invalid fallback
* display change reposition
* same display as active Function Bar
* no ScreenCaptureKit dependency

## Acceptance Criteria

* Info Strip placement is predictable.
* It reuses Function Bar placement logic where possible.
* It is display-safe.
* Tests pass.

---

# Workstream 20.10 — Info Strip Actions and Command Center Integration

## Goal

Tile actions should route through Command Center and existing safe coordinators.

## Tile Actions

Supported action examples:

| Tile               | Action                                 |
| ------------------ | -------------------------------------- |
| Current Workspace  | show Set Switcher / Workspaces Preview |
| Hidden Count       | reveal all / show Function Bar         |
| New Item Count     | open New Item Inbox                    |
| Recovery Warning   | open Recovery                          |
| Stale Scan Warning | open Pro setup / rescan                |
| Clock              | no action                              |
| Battery            | no action                              |

## Rules

* Views should not directly execute low-level behavior.
* Tile actions route:

  * InfoStripView
  * InfoStripViewModel
  * CommandCenter / AppEnvironment coordinator
* Actions respect:

  * Safe Mode
  * Pro gates
  * Accessibility gates
  * Automation pause if action source counts as automation
  * Private Access if relevant
  * Preview/Labs/Experimental gates

## New Commands

Add internal/Preview command IDs if needed:

```text
infoStrip.show
infoStrip.hide
infoStrip.nextTile
infoStrip.openSettings
infoStrip.showFunctionBar
workspace.display.showFunctionBar
workspace.display.showInfoStrip
```

Do not expose public App Intents or URL routes for Info Strip in this phase.

## Tests

Add tests:

* tile action routes command
* hidden count action reveal all
* new item action opens inbox route
* recovery action opens recovery route
* Safe Mode blocks inappropriate action
* unavailable action returns clear result
* diagnostics redacted

## Acceptance Criteria

* Info Strip actions are useful but safe.
* Actions use shared routing.
* No bypass of gates.
* Tests pass.

---

# Workstream 20.11 — Workspace / Set Builder Integration

## Goal

Let users configure Info Strip tiles from the existing Workspaces Preview / Set Builder UI.

## UI Location

In:

```text
Settings → Advanced → Workspaces Preview → Set Builder
```

Add a section:

```text
Info Strip
```

It should show:

* Info Strip enabled for this Workspace
* selected tile list
* available tile library
* reorder tiles
* remove tile
* rotation interval
* idle delay
* hover behavior
* preview tile

## Library

Add Info Tiles tab/section in Set Builder library:

* Current Workspace
* Clock
* Battery
* Hidden Count
* New Items Count
* Recovery Warning
* Stale Scan Warning
* Calendar Next Event, disabled/Preview if implemented
* Reminder Count, disabled/Preview if implemented

## Drag/Add Behavior

If Set Builder drag/drop exists:

* allow dragging tile into Info Strip config list

If drag/drop is brittle:

* add buttons are acceptable
* up/down reorder controls required

## Important Boundary

Do not put InfoTile items into `functionItems` as real Function Bar items, except as deferred placeholders from previous phases. Info Strip should use `workspace.infoItems` or `WorkspaceInfoStripConfig.selectedTileProviderIDs`.

If previous model only has `infoItems`, use that. If previous model used provider IDs in config, keep one source of truth and migrate old placeholders.

## Tests

Add tests:

* tile library appears
* add tile to Workspace Info Strip
* remove tile
* reorder tile
* invalid provider shown unavailable
* Function Bar unchanged by Info Strip tile changes
* Info Strip preview updates after commit
* no runtime starts from editing alone

## Acceptance Criteria

* Users can configure Info Strip tiles per Workspace.
* Set Builder integrates Info Strip config without becoming a full dashboard.
* Editing config does not start runtime automatically.
* Tests pass.

---

# Workstream 20.12 — Status Menu Integration

## Goal

Let users access Info Strip preview from the status menu without cluttering Basic Mode.

## Status Menu Changes

Add conditional action under Advanced/Preview:

```text
Show Info Strip…
```

or:

```text
Show Workspace Info Strip…
```

Show it only when:

* Workspaces Preview is enabled, and
* Info Strip Preview is enabled

Alternatively place under:

```text
Advanced → Workspaces Preview → Show Info Strip
```

Default status menu should remain focused on Basic use.

## Required Actions

* Show Info Strip
* Hide Info Strip
* Show Function Bar
* Open Info Strip Settings

## Safe Mode

In Safe Mode:

* Info Strip actions should be hidden or disabled.
* Status menu remains recovery-first.

## Tests

Add tests:

* Info Strip status menu action hidden by default
* appears when preview enabled
* show action calls controller
* hide action calls controller
* Safe Mode hides/disables action
* default Basic menu remains uncluttered

## Acceptance Criteria

* Info Strip is discoverable but not intrusive.
* Basic status menu remains simple.
* Safe Mode remains recovery-first.
* Tests pass.

---

# Workstream 20.13 — Diagnostics, Health, and Recovery

## Goal

Add privacy-safe Info Strip diagnostics and recovery support.

## Diagnostics Snapshot

Add:

```swift
struct InfoStripDiagnosticsSnapshot: Codable, Equatable {
    var previewEnabled: Bool
    var autoShowEnabled: Bool
    var isVisible: Bool
    var displayState: String
    var activeWorkspacePresent: Bool
    var activeWorkspaceIDHash: String?
    var selectedTileProviderCount: Int
    var availableTileProviderCount: Int
    var unavailableTileProviderCount: Int
    var currentTileProviderID: String?
    var rotationIntervalSeconds: Int
    var idleDelaySeconds: Int
    var lastRotationResult: String?
    var lastPlacementMode: String?
    var lastPlacementClamped: Bool
    var lastShowResult: String?
}
```

Do not include:

* workspace names
* raw item names
* raw bundle IDs
* group names
* protected names
* calendar event titles
* reminder titles
* live search text
* file paths
* screen contents

## Health Checks

Add non-invasive checks:

* Info Strip visible while preview disabled
* Info Strip visible in Safe Mode
* no available providers selected
* rotation repeatedly failing
* placement repeatedly failing
* invalid interval repaired
* invalid provider IDs found

Health should not mark Basic Mode unhealthy unless Info Strip interferes with Basic controls.

## Recovery Actions

Add recovery actions:

* hide Info Strip
* disable Info Strip Preview
* reset Info Strip settings for current Workspace
* reset Info Strip placement
* clear invalid provider IDs
* show Function Bar instead

Keep under Recovery/Advanced.

## Tests

Add tests:

* diagnostics redaction
* visible state reported
* no available provider health issue
* invalid provider recovery
* Safe Mode hides/suppresses Info Strip
* disabling preview hides panel
* Basic Mode health unaffected

## Acceptance Criteria

* Diagnostics are useful and redacted.
* Health detects Info Strip issues.
* Recovery can hide/disable/reset Info Strip.
* Basic Mode remains unaffected.
* Tests pass.

---

# Workstream 20.14 — Import / Export / Backup Integration

## Goal

Include Info Strip settings in local backup/export safely.

## Tasks

Inspect:

```text
MenuBar-Manager/Migration/
MenuBar-Manager/Workspaces/
MenuBar-Manager/InfoStrip/
MenuBar-Manager/Core/SettingsStore
```

Update local backup schema to include:

* global Info Strip preview setting
* per-Workspace Info Strip config
* selected tile provider IDs
* idle delay
* rotation interval
* hover behavior
* placement preference

## Import Safety

Import must not:

* enable Info Strip Preview by default unless user explicitly selects settings import
* enable Calendar/Reminder providers without permission
* start Info Strip runtime after import
* enable Function Bar primary click
* enable physical profile apply
* enable assisted move
* enable automation
* enable Labs

Safe support export should include only:

* enabled state
* provider counts
* invalid provider count
* interval values
* no workspace names if protected
* no calendar/reminder titles
* no raw menu bar item identities

## Tests

Add tests:

* backup includes Info Strip settings
* support export redacts tile content
* import dry-run validates Info Strip settings
* import apply does not start runtime
* imported invalid interval clamped
* imported unknown provider tolerated
* imported permission-gated providers do not prompt

## Acceptance Criteria

* Backup/export handles Info Strip settings.
* Safe support export remains redacted.
* Import cannot enable risky runtime behavior accidentally.
* Tests pass.

---

# Workstream 20.15 — Optional Permission-Gated Calendar / Reminder Tiles

## Goal

Optionally add Calendar/Reminder tile groundwork only if it can be implemented safely and explicitly.

This workstream is optional. Skip if it risks scope creep.

## Rules

Calendar/Reminder tiles must:

* be off by default
* be Preview
* require explicit user enablement
* never prompt automatically
* show permission explanation before request
* use public EventKit APIs only
* not export event/reminder titles in diagnostics/support exports
* degrade clearly when permission is denied
* not use network

## Required Usage Strings

If adding EventKit/Reminders permission, update Info.plist usage descriptions as required by macOS.

Text should be clear:

```text
MenuBarDeclutter can show your next calendar event in the local Info Strip. Event titles stay on this Mac and are excluded from diagnostics exports by default.
```

Adjust to project style.

## Calendar Tile

Provider ID:

```text
calendar.nextEvent
```

Display:

* next event title locally in UI after permission
* start time
* redacted diagnostics

No event location unless user explicitly enables later. Defer location.

## Reminder Tile

Provider ID:

```text
reminders.count
```

Display:

* reminder count
* maybe next due time
* no reminder titles in diagnostics

## Tests

Add tests with mocked EventKit provider:

* unavailable before permission
* no prompt on settings open
* permission request only explicit
* granted returns snapshot
* denied returns unavailable
* diagnostics redacts titles
* support export excludes titles

## Acceptance Criteria

* Optional permission tiles are safe or skipped.
* No silent prompt.
* No event/reminder title leakage.
* Tests pass.

---

# Workstream 20.16 — UI Polish and Interaction Details

## Goal

Make Function Bar + Info Strip interaction feel coherent rather than two disconnected panels.

## Tasks

1. Align visual style:

   * similar panel width/height logic
   * similar corner radius/materials using existing DesignSystem
   * consistent typography
   * consistent Preview badge
   * consistent unavailable state

2. Transition behavior:

   * Info Strip to Function Bar should be quick and not jarring
   * Function Bar to Info Strip should wait for idle delay
   * repeated hover should not flicker

3. Pin behavior:

   * allow pin Function Bar if existing
   * pinned Function Bar stops Info Strip auto-switch

4. Close behavior:

   * Escape closes visible panel
   * outside click closes if enabled
   * status menu hide action closes both

5. Keyboard:

   * Tab focus through tile action buttons
   * Escape close
   * optional arrow to next tile if simple

6. Empty states:

   * no tile available
   * preview disabled
   * workspace disabled
   * Safe Mode
   * invalid provider

## Tests

Add UI tests:

* Info Strip appears
* hover/interaction switches to Function Bar if testable
* Escape closes panel
* pinned Function Bar prevents Info Strip if modeled
* unavailable state visible
* dark/light mode snapshots if project supports them

## Acceptance Criteria

* Interaction feels coherent.
* No flicker from repeated hover/idle transitions.
* Basic panel controls work.
* UI tests or model tests cover transitions.

---

# Workstream 20.17 — Manual QA Matrix

## Goal

Add manual QA for Info Strip MVP.

## Create

```text
docs/testing/manual-v0.1.7-info-strip-qa.md
docs/testing/manual-v0.1.7-workspace-display-qa.md
docs/testing/manual-v0.1.7-results.md
```

## Manual QA Areas

### Enable / Disable

* Launch app with Info Strip disabled.
* Confirm no Info Strip appears automatically.
* Enable Workspaces Preview.
* Enable Function Bar Preview.
* Enable Info Strip Preview.
* Enable Info Strip for one Workspace.
* Open Info Strip from Settings.
* Disable Info Strip Preview and confirm panel closes.

### Rotation

* Select 3 local tiles.
* Confirm Info Strip rotates.
* Change rotation interval.
* Confirm new interval applies.
* Manual advance if implemented.
* Empty tile list shows clear state.

### Hover Behavior

* Show Function Bar.
* Wait idle delay.
* Confirm Info Strip appears.
* Hover Info Strip.
* Confirm Function Bar appears.
* Leave Function Bar.
* Confirm idle delay returns to Info Strip.
* Pin Function Bar if supported.
* Confirm Info Strip pauses.

### Workspace Switching

* Create two Workspaces with different Info Strip config.
* Switch Workspace.
* Confirm Info Strip tile selection changes.
* Confirm Function Bar contents still match active Workspace.

### Tiles

* Current Workspace tile.
* Clock tile.
* Battery tile.
* Hidden Count tile.
* New Item Count tile.
* Recovery Warning tile.
* Stale Scan tile.
* Calendar/Reminder tiles only if implemented and permission granted.

### Display / Placement

Current v0.1.7 QA gate is single-screen UI QA on the built-in display. External multi-display movement and expanded notch/edge hardware checks are deferred follow-up when suitable hardware is available.

* Place below menu bar icon.
* Confirm placement remains visible and clamped on the built-in display.
* Sleep/wake.
* Toggle menu bar auto-hide.
* Confirm panel stays visible and clamped.

### Safe Mode

* Enter Safe Mode.
* Confirm Info Strip does not open.
* Confirm Function Bar does not auto-open.
* Confirm status menu remains recovery-first.
* Confirm Recovery page explains Info Strip suppression.

### Privacy

* Export diagnostics.
* Confirm no raw menu bar item names.
* Confirm no protected group/workspace names.
* Confirm no calendar/reminder titles if optional tiles exist.
* Run no-network watch.
* Confirm no sockets.

## Acceptance Criteria

* Manual QA docs exist.
* Results are recorded.
* Preview failures are documented honestly.
* Stable Basic claims remain unaffected.
* Release checklist links to QA docs.

---

# Workstream 20.18 — Documentation

## Goal

Document Info Strip accurately without overclaiming.

## Create or Update

```text
docs/features/info-strip-v0.1.7-preview.md
docs/features/workspaces-v0.1.7-preview.md
docs/features/function-bar-v0.1.7-preview.md
docs/architecture/info-strip-architecture.md
docs/architecture/workspace-display-state-machine.md
docs/privacy/v0.1.7-info-strip-privacy.md
docs/release/v0.1.7-release-notes.md
docs/release/v0.1.7-release-checklist.md
docs/release/v0.1.7-known-limitations.md
docs/progress/phase-20-v0.1.7-info-strip-mvp.md
README.md
docs/support/workspaces-preview.md
docs/support/info-strip-preview.md
```

## Required Wording

Use this wording or equivalent:

> Info Strip in v0.1.7 is a Preview app-owned panel that can show lightweight local status tiles for the active Workspace while idle. Hovering the strip can return to the Function Bar. It does not replace the macOS menu bar, does not capture screen pixels, does not use Screen Recording, and does not use network widgets.

Use this wording or equivalent:

> Info Strip tiles are local and privacy-safe by default. Calendar or Reminder tiles, if enabled, require explicit user permission and are redacted from diagnostics exports by default.

## Docs Must Explain

* What Info Strip is.
* What Info Strip is not.
* How it relates to Workspaces.
* How it relates to Function Bar.
* How idle-to-info and hover-to-function behavior works.
* Which local tiles exist.
* Which tiles require Pro Discovery.
* Which optional tiles require explicit permission.
* Why network widgets are not included.
* Why media controls are not included.
* Why Screen Recording is not used.
* How Safe Mode handles Info Strip.
* How to recover if Info Strip behaves badly.

## Forbidden Claims

Do not claim:

* stable Info Strip
* Dynamic Island replacement
* system menu bar replacement
* live widget dashboard
* media controls
* notification scraping
* weather/news/stocks
* online widgets
* live screen content
* Screen Recording support
* ScreenCaptureKit support
* stable physical Workspace switching
* broad third-party menu item activation
* v0.2 release

## Acceptance Criteria

* Docs match implementation.
* Docs clearly label Info Strip Preview.
* Docs explain local-only privacy boundary.
* Current-facing docs use v0.1.7.
* No overclaims.

---

# Workstream 20.19 — Tests

## Goal

Add meaningful coverage for Info Strip MVP.

## Suggested Test Files

Create or update:

```text
MenuBar-ManagerTests/InfoTileProviderRegistryTests.swift
MenuBar-ManagerTests/InfoTileProviderTests.swift
MenuBar-ManagerTests/InfoStripRotationServiceTests.swift
MenuBar-ManagerTests/InfoStripStateMachineTests.swift
MenuBar-ManagerTests/InfoStripControllerTests.swift
MenuBar-ManagerTests/InfoStripPlacementTests.swift
MenuBar-ManagerTests/InfoStripDiagnosticsTests.swift
MenuBar-ManagerTests/InfoStripImportExportTests.swift
MenuBar-ManagerTests/WorkspaceDisplayCoordinatorTests.swift
MenuBar-ManagerUITests/InfoStripPreviewUITests.swift
MenuBar-ManagerUITests/WorkspaceDisplayUITests.swift
```

Follow existing test style.

## Required Unit Tests

Cover:

1. Info Strip disabled by default.
2. Workspace Info Strip disabled by default.
3. Settings validation clamps idle delay.
4. Settings validation clamps rotation interval.
5. Registry registers required providers.
6. Unknown provider tolerated.
7. Current Workspace tile snapshot.
8. Clock tile snapshot.
9. Battery tile available/unavailable.
10. Hidden Count tile snapshot.
11. New Item Count tile unavailable when Pro/New Inbox unavailable.
12. Recovery Warning tile severity.
13. Stale Scan tile unavailable when Pro Discovery off.
14. Provider snapshots do not contain raw item identities.
15. Rotation skips unavailable provider.
16. Rotation loops selected providers.
17. Manual advance works.
18. Pause/resume works.
19. Safe Mode blocks rotation.
20. Function Bar visible -> idle -> Info Strip visible.
21. Info Strip hover -> Function Bar visible.
22. Pinned Function Bar blocks Info Strip.
23. Active Workspace switch updates Info Strip config.
24. Info Strip placement clamps to visible frame.
25. Info Strip action routes through Command Center.
26. Diagnostics redacts tile content.
27. Import/export includes Info Strip settings safely.
28. Import does not start runtime.
29. Safe Mode suppresses Info Strip panel.
30. Basic Mode unaffected by Info Strip corruption.

## Required UI Tests

Cover:

1. Info Strip Preview Settings page renders.
2. Enable Info Strip Preview.
3. Enable Info Strip for active Workspace.
4. Select tile providers.
5. Open Info Strip.
6. Info Strip displays a tile.
7. Empty state renders when no tile selected.
8. Hover/click shows Function Bar if testable.
9. Hide Info Strip.
10. Safe Mode unavailable state renders.
11. No Accessibility prompt appears.
12. No Calendar/Reminder prompt appears unless explicit permission action is clicked.

If UI hover simulation is brittle, cover hover state machine in unit tests and keep UI tests smoke-level.

## Acceptance Criteria

* InfoStrip model/controller/rotation/state tests pass.
* UI smoke coverage exists.
* Existing tests still pass.
* Privacy verification still passes.

---

# Workstream 20.20 — Release and Privacy Verification

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
rg -n "stable Info Strip|stable Function Bar|replace.*macOS.*menu bar|system menu bar replacement|Dynamic Island|live.*menu bar.*clone|pixel capture|live icon capture|Screen Recording" README.md docs MenuBar-Manager || true
rg -n "weather|stocks|news|RSS|media control|Now Playing|notification scraping|file shelf|online widget|cloud widget" README.md docs MenuBar-Manager || true
rg -n "Info Strip.*move.*icon|Info Strip.*apply.*profile|Workspace.*physical.*layout|Workspace.*physical.*switch|bulk move" README.md docs MenuBar-Manager || true
```

Inspect results manually.

Acceptable:

* Historical/future notes if clearly labeled.
* Internal type names that do not claim current stability.
* Docs that explicitly state deferred/future behavior.
* Mentions saying online/media widgets are not implemented.

Not acceptable:

* Current-facing v0.2 claim.
* Current-facing claim that Info Strip replaces system menu bar.
* Current-facing claim that Info Strip is a Dynamic Island clone.
* Current-facing claim that Info Strip captures screen pixels.
* Current-facing claim that Info Strip includes online/media widgets.
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

# Phase 20 Definition of Done

Phase 20 is complete when:

1. App version is `0.1.7`.
2. Build number is incremented to `8` or documented next build.
3. No current-facing docs/UI call this v0.2.
4. `MenuBar-Manager/InfoStrip/` source area exists.
5. Info Strip Preview setting exists and defaults off.
6. Per-Workspace Info Strip config exists and defaults off.
7. Required local tile providers exist:

   * Current Workspace
   * Clock
   * Battery
   * Hidden Count
   * New Items Count
   * Recovery Warning
   * Stale Scan Warning
8. No online/media/news/weather/stocks widgets are implemented.
9. Info Strip rotation service exists.
10. Info Strip controller can show/hide/toggle an app-owned panel.
11. Info Strip does not open automatically at launch.
12. Info Strip is suppressed in Safe Mode.
13. Workspace display state machine coordinates Function Bar and Info Strip.
14. Function Bar can transition to Info Strip after idle delay.
15. Info Strip hover can return to Function Bar.
16. Info Strip placement is display-aware and clamps to visible frame.
17. Info Strip actions route through Command Center or safe existing coordinators.
18. Set Builder can configure selected Info Strip tiles per Workspace.
19. Status menu can open Info Strip only under Preview/Advanced conditions.
20. Diagnostics are privacy-safe and redacted.
21. Health/recovery can hide/disable/reset Info Strip.
22. Import/export handles Info Strip settings safely.
23. Optional Calendar/Reminder tiles, if implemented, are explicit-permission gated and diagnostics-redacted.
24. Info Strip does not replace or claim to control the macOS system menu bar.
25. No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network, telemetry, analytics, cloud sync, private APIs, media private APIs, or notification scraping are introduced.
26. Full tests pass.
27. Release dry-run and installed-app verification pass.
28. `docs/progress/phase-20-v0.1.7-info-strip-mvp.md` includes:

    * summary
    * changed files
    * test results
    * release verification results
    * privacy verification results
    * manual QA status
    * known limitations
    * deferred work for v0.1.8

---

# Recommended Codex Subtask Breakdown

Do not ask Codex to execute all Phase 20 in one huge pass. Use these slices.

## Phase 20A — Version + InfoStrip Skeleton

```markdown
Implement Phase 20A only:
- bump app version to 0.1.7 build 8
- create InfoStrip source area
- add Info Strip Preview settings with safe defaults
- extend WorkspaceInfoStripConfig
- add InfoStripDisplayState and unavailable reasons
- add basic controller skeleton
- add tests for defaults and validation
- do not add tile providers yet beyond stubs
- do not mention v0.2
```

## Phase 20B — Tile Provider Registry + Local Providers

```markdown
Implement Phase 20B only:
- add InfoTileProvider protocol and registry
- implement local providers: workspace, clock, battery, hidden count, new items count, recovery warning, stale scan warning
- no network providers
- no media controls
- no Calendar/Reminder unless explicitly mocked/deferred
- add provider tests and diagnostics redaction tests
```

## Phase 20C — Rotation Service + State Machine

```markdown
Implement Phase 20C only:
- implement InfoStripRotationService
- implement WorkspaceDisplayCoordinator / state machine between Function Bar and Info Strip
- support idle delay and hover-to-Function-Bar transitions
- Safe Mode suppresses runtime
- add tests for rotation and state transitions
```

## Phase 20D — Info Strip Panel + Placement

```markdown
Implement Phase 20D only:
- implement InfoStripPanelHost and SwiftUI views
- implement InfoStripPlacementService
- render tile, empty, unavailable states
- add accessibility labels
- add UI smoke tests
- do not build full dashboard or widgets
```

## Phase 20E — Settings + Set Builder Integration

```markdown
Implement Phase 20E only:
- add Info Strip Preview settings page under Advanced → Workspaces Preview
- add Info Strip config section to Set Builder
- allow selecting/reordering tile providers per Workspace
- add preview button
- no runtime auto-start from editing alone
- add tests
```

## Phase 20F — Actions + Status Menu + Recovery

```markdown
Implement Phase 20F only:
- route tile actions through Command Center
- add conditional status menu Show Info Strip action under Preview/Advanced
- add diagnostics, health checks, and recovery actions
- update import/export for Info Strip settings
- add tests
```

## Phase 20G — Optional Calendar/Reminder Tiles

```markdown
Implement Phase 20G only if safe:
- add explicit-permission Calendar/Reminder tile providers using public APIs
- no silent prompt
- event/reminder titles redacted from diagnostics/support exports
- add permission explanation and tests
- skip this slice if it risks scope creep
```

## Phase 20H — Docs + Manual QA + Final Validation

```markdown
Implement Phase 20H only:
- add v0.1.7 Info Strip docs
- update release notes/checklist
- add manual QA docs
- run full validation commands
- run targeted privacy/overclaim searches
- record final results in phase progress doc
```
