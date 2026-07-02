
# Phase 18 — v0.1.5 Set Switcher + Virtual Function Bar MVP

You are working on `MenuBarDeclutter`, a native macOS 26.0+ menu bar decluttering utility written in Swift, AppKit, and SwiftUI.

This phase follows Phase 17 / v0.1.4 Workspaces Foundation.

The active release line for this phase is:

`v0.1.5`

This phase is **not v0.2**. Do not create v0.2 docs, v0.2 release notes, v0.2 public claims, v0.2 artifact names, or current-facing v0.2 roadmap language.

## Phase Mission

Phase 18 introduces the first visible Workspace experience:

> A user can open a virtual Function Bar, switch between Workspaces/Sets, and see each Workspace’s configured commands, menu bar item proxies, groups, spacers, and dividers.

The Function Bar is an **app-owned floating panel**. It does not replace the macOS system menu bar. It does not capture real menu bar pixels. It does not require Screen Recording. It does not take ownership of third-party menu bar items.

By the end of Phase 18:

1. The app can show a Virtual Function Bar for the active Workspace.
2. The Function Bar renders workspace items from the Phase 17 Workspace model.
3. A Set Switcher lets users switch active Workspace from the Function Bar.
4. Function Bar actions route through Command Center.
5. Workspace command items execute safely.
6. Menu bar item proxy items support safe actions:
   - reveal/highlight if Pro gates are satisfied
   - open owning app when metadata supports it
   - show in Find Icon / Second Bar where available
7. Group items open existing group panels or show unavailable/missing states.
8. Spacers/dividers render visually in the app-owned Function Bar.
9. Status menu and Advanced Settings can open the Function Bar.
10. Optional primary-click behavior can show the Function Bar, but must be off by default.
11. Safe Mode suppresses Function Bar runtime while preserving Basic Mode recovery.
12. Basic Mode remains stable and permission-free.

Phase 18 must **not** implement Info Strip, hover idle ticker, drag/drop Set Builder, bulk physical layout movement, or stable third-party menu item activation.

## Product Boundary

The Function Bar is a virtual workspace action strip.

It may contain:
- command items
- menu bar item proxy references
- group references
- spacer items
- divider items

It does not:
- replace the macOS system menu bar
- duplicate live menu bar pixels
- guarantee that third-party menu extras can be clicked or controlled
- require Screen Recording
- use ScreenCaptureKit
- use private Apple menu bar APIs
- silently request Accessibility
- move icons automatically
- apply physical workspace profiles automatically

## Version Target

Set active app version to:

- Marketing version: `0.1.5`
- Build number: increment from `5` to `6`, unless the project has already advanced build numbering.

Release artifacts should use:

- `MenuBarDeclutter-v0.1.5.zip`
- `MenuBarDeclutter-v0.1.5-alpha.zip` only if alpha/dogfood packaging still exists.

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
- Phase 17 should have added:
  - `MenuBar-Manager/Workspaces/`
  - Workspace models
  - Workspace store
  - active workspace switching
  - workspace Command Center actions
  - Advanced Workspaces Preview
  - workspace diagnostics / health / backup integration

## Hard Rules

1. Do not call this phase v0.2.
2. Do not add Screen Recording.
3. Do not add ScreenCaptureKit.
4. Do not add Apple Events scripting/control.
5. Do not add Input Monitoring.
6. Do not add network access, telemetry, analytics, crash upload, cloud sync, remote config, update checks, or license checks.
7. Do not use private Apple menu bar APIs.
8. Do not silently prompt for Accessibility.
9. Do not make Workspaces a stable public claim in v0.1.5.
10. Do not claim Function Bar replaces the macOS system menu bar.
11. Do not claim Function Bar is a live clone of system menu bar icons.
12. Do not implement Info Strip runtime in this phase.
13. Do not implement hover idle ticker in this phase.
14. Do not implement full drag/drop Set Builder in this phase.
15. Do not implement bulk icon moving.
16. Do not make assisted icon moving stable.
17. Do not apply physical workspace profiles automatically.
18. Do not mutate real menu bar layout when switching Workspace.
19. Do not expose Workspaces as a stable top-level Settings pillar yet unless explicitly behind Preview labeling.
20. Keep Function Bar behind Preview/Advanced gates in v0.1.5.
21. Diagnostics must not export raw workspace item names, raw menu bar item identities, protected group names, protected workspace names, live search text, or file paths by default.

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

`docs/progress/phase-18-v0.1.5-set-switcher-function-bar.md`

Record:

* baseline git status
* baseline version/build
* baseline test results
* baseline privacy verification result
* baseline release dry-run result
* baseline installed-app verification result
* known limitations from Phase 17
* exact date
* short phase goal

---

# Workstream 18.1 — Version and Release Identity

## Goal

Move the active release line from `0.1.4` to `0.1.5`.

## Tasks

1. Search version references:

```bash
rg -n "0\.1\.4|v0\.1\.4|0\.1\.5|v0\.1\.5|0\.2|v0\.2|MARKETING_VERSION|CURRENT_PROJECT_VERSION|CFBundleShortVersionString|CFBundleVersion" .
```

2. Update active version/build values to:

* `0.1.5`
* build `6`

3. Update release artifact naming.

4. Add release notes placeholder:

`docs/release/v0.1.5-release-notes.md`

5. Add release checklist:

`docs/release/v0.1.5-release-checklist.md`

6. Update latest-progress docs that list current release line.

7. Do not create v0.2 docs.

8. If historical docs mention v0.2, leave them only if clearly historical/future. Do not add current-facing v0.2 language.

## Acceptance Criteria

* App bundle reports `0.1.5`.
* Build number is `6` or documented next build number.
* Release artifacts use `v0.1.5`.
* Current-facing docs/UI do not call this v0.2.
* Release dry-run still works.

---

# Workstream 18.2 — FunctionBar Source Area and Boundaries

## Goal

Create a focused FunctionBar source area for the virtual app-owned workspace bar.

## New Source Area

Create:

```text
MenuBar-Manager/FunctionBar/
  Models/
  Runtime/
  Placement/
  Views/
  Settings/
  Diagnostics/
```

Suggested files:

```text
MenuBar-Manager/FunctionBar/Models/FunctionBarItemModel.swift
MenuBar-Manager/FunctionBar/Models/FunctionBarDisplayState.swift
MenuBar-Manager/FunctionBar/Models/FunctionBarActionAvailability.swift
MenuBar-Manager/FunctionBar/Runtime/FunctionBarController.swift
MenuBar-Manager/FunctionBar/Runtime/FunctionBarStateMachine.swift
MenuBar-Manager/FunctionBar/Runtime/FunctionBarViewModel.swift
MenuBar-Manager/FunctionBar/Runtime/FunctionBarItemResolver.swift
MenuBar-Manager/FunctionBar/Runtime/FunctionBarActionDispatcher.swift
MenuBar-Manager/FunctionBar/Placement/FunctionBarPlacementService.swift
MenuBar-Manager/FunctionBar/Placement/FunctionBarPlacementPreference.swift
MenuBar-Manager/FunctionBar/Views/FunctionBarPanelHost.swift
MenuBar-Manager/FunctionBar/Views/FunctionBarView.swift
MenuBar-Manager/FunctionBar/Views/FunctionBarItemView.swift
MenuBar-Manager/FunctionBar/Views/FunctionBarGroupItemView.swift
MenuBar-Manager/FunctionBar/Views/FunctionBarCommandItemView.swift
MenuBar-Manager/FunctionBar/Views/FunctionBarProxyItemView.swift
MenuBar-Manager/FunctionBar/Views/FunctionBarSpacerView.swift
MenuBar-Manager/FunctionBar/Views/SetSwitcherView.swift
MenuBar-Manager/FunctionBar/Views/SetSwitcherButton.swift
MenuBar-Manager/FunctionBar/Settings/FunctionBarPreviewSettingsView.swift
MenuBar-Manager/FunctionBar/Settings/FunctionBarPreviewSettingsViewModel.swift
MenuBar-Manager/FunctionBar/Diagnostics/FunctionBarDiagnosticsSnapshot.swift
MenuBar-Manager/FunctionBar/Diagnostics/FunctionBarDiagnosticsRedactor.swift
```

If the repo already has equivalent types after previous work, extend those instead of duplicating.

## Project Membership

Add all new Swift files to:

* `MenuBarDeclutter` target
* relevant test target if test helpers are created

## Module Boundaries

FunctionBar may depend on:

* Workspaces models/store/switching
* CommandCenter
* Groups resolver/panels
* Search / Find Icon open action
* SecondBar show action
* Accessibility item references only through stable app-level reference types
* DesignSystem
* Settings route model
* Diagnostics redaction helpers

FunctionBar must not directly depend on:

* ScreenCaptureKit
* Screen Recording
* network APIs
* private Apple APIs
* CGEvent moving internals
* low-level Accessibility scanner internals beyond stable menu bar item references
* InfoStrip runtime
* SetBuilder drag/drop runtime

## Acceptance Criteria

* FunctionBar source area exists.
* New files are target-membered correctly.
* Build succeeds.
* FunctionBar has clear boundaries.
* No privacy-sensitive APIs are introduced.

---

# Workstream 18.3 — Function Bar Feature Gate and Settings

## Goal

Introduce a Preview-gated Function Bar runtime setting without making it a stable product pillar.

## Required Settings

Add settings if not already present:

```swift
workspacesPreviewEnabled: Bool
functionBarPreviewEnabled: Bool
functionBarPrimaryClickEnabled: Bool
functionBarPlacementPreference: FunctionBarPlacementPreference
functionBarShowSetSwitcher: Bool
functionBarShowLabels: Bool
functionBarDensity: FunctionBarDensity
functionBarCloseOnOutsideClick: Bool
functionBarKeyboardNavigationEnabled: Bool
```

Default values:

```text
workspacesPreviewEnabled: false or existing Phase 17 default
functionBarPreviewEnabled: false
functionBarPrimaryClickEnabled: false
functionBarPlacementPreference: belowMenuBarIcon
functionBarShowSetSwitcher: true
functionBarShowLabels: false or true based on visual clarity
functionBarDensity: regular
functionBarCloseOnOutsideClick: true
functionBarKeyboardNavigationEnabled: true
```

Important:

* Function Bar must be off by default in v0.1.5.
* Status menu can show an “Open Workspace Bar…” action only if Workspaces Preview or Function Bar Preview is enabled, or under Advanced.
* Primary click should not replace the existing status menu by default.

## Settings UI

Add under:

```text
Settings → Advanced → Workspaces Preview → Function Bar Preview
```

Do not add Function Bar as a main sidebar pillar yet.

The page should include:

* Preview badge
* “Function Bar is app-owned UI”
* “It does not replace the macOS menu bar”
* “It does not capture screen pixels”
* Enable Function Bar Preview toggle
* Open Function Bar button
* Placement preference
* Show Set Switcher toggle
* Show labels toggle
* Density selector
* Primary click behavior toggle, off by default
* Close on outside click toggle
* Keyboard navigation toggle

## Tests

Add tests:

* default Function Bar off
* enabling setting persists
* primary click off by default
* Safe Mode forces Function Bar unavailable
* Settings page renders
* no Accessibility prompt
* no Screen Recording usage string

## Acceptance Criteria

* Function Bar is Preview-gated.
* Function Bar does not alter default Basic status menu behavior.
* UI clearly explains boundaries.
* Tests pass.

---

# Workstream 18.4 — Function Bar State Machine and Runtime Controller

## Goal

Implement a controlled runtime for showing, hiding, and updating the virtual Function Bar.

## State Machine

Implement states:

```swift
enum FunctionBarDisplayState: Equatable {
    case closed
    case opening
    case visible(workspaceID: UUID)
    case switching(from: UUID?, to: UUID)
    case unavailable(FunctionBarUnavailableReason)
    case suspendedBySafeMode
}
```

Unavailable reasons:

```swift
enum FunctionBarUnavailableReason: Equatable {
    case previewDisabled
    case noActiveWorkspace
    case workspaceStoreUnavailable
    case safeModeActive
    case noDisplayAvailable
    case settingsDisabled
}
```

## Controller

Implement:

```swift
final class FunctionBarController {
    func start()
    func stop()
    func show(source: FunctionBarShowSource)
    func hide(source: FunctionBarHideSource)
    func toggle(source: FunctionBarShowSource)
    func refresh(reason: FunctionBarRefreshReason)
    func activeState() -> FunctionBarDisplayState
}
```

The controller should:

* not start automatically on app launch
* not show panel if preview disabled
* not show panel in Safe Mode
* observe active workspace changes
* refresh visible items when active workspace changes
* hide on app termination
* hide when Safe Mode is requested
* not mutate Basic Mode
* not request Accessibility
* not apply profiles
* not move icons

## Start/Stop Integration

Wire into `AppEnvironment`:

* create FunctionBarController
* do not auto-show
* stop on termination
* expose callbacks for status menu / Settings / Command Center

## Tests

Add tests:

* initial state closed
* show blocked when preview disabled
* show blocked in Safe Mode
* show succeeds when enabled and active workspace exists
* toggle opens/closes
* switch active workspace refreshes visible state
* stop closes panel
* no Basic state mutation
* no Accessibility prompt path

## Acceptance Criteria

* FunctionBarController exists and is lifecycle-safe.
* Function Bar never opens automatically on launch.
* Safe Mode suppresses it.
* Active workspace switching updates runtime if visible.
* Tests pass.

---

# Workstream 18.5 — Function Bar Placement Service

## Goal

Place the app-owned Function Bar near the menu bar in a safe, notch-aware, display-aware way.

## Placement Modes

Implement:

```swift
enum FunctionBarPlacementPreference: String, Codable, Equatable {
    case belowMenuBarIcon
    case belowMenuBar
    case nearMouse
    case lastPosition
    case centeredBelowMenuBar
}
```

Default:

```text
belowMenuBarIcon
```

## Placement Input

Use only safe inputs:

* current mouse location
* active display visible frame
* menu bar height estimate
* status item approximate anchor if available from app-owned status item
* last saved position
* panel size
* notch avoidance estimate if existing Layout services expose one

Do not capture screen.
Do not use ScreenCaptureKit.
Do not use private APIs.

## Placement Output

Implement:

```swift
struct FunctionBarPlacement {
    var origin: CGPoint
    var displayID: String?
    var placementMode: FunctionBarPlacementPreference
    var didClampToVisibleFrame: Bool
    var reason: FunctionBarPlacementReason
}
```

## Behavior

* Clamp to visible frame.
* Avoid going under menu bar.
* Avoid going offscreen.
* Recover if last position is invalid.
* Reposition after display change.
* Reposition after sleep/wake if controller is visible.
* Reposition after active Space changes if existing system recovery hooks expose this.
* If anchor is unavailable, fall back to belowMenuBar or nearMouse.

## Tests

Add tests:

* below menu bar icon placement
* near mouse placement
* last position valid
* last position invalid fallback
* narrow display clamps
* notch estimate avoids unsafe area if service exists
* display change repositions
* no screen capture dependency

## Acceptance Criteria

* Function Bar panel placement is deterministic and tested.
* Placement is safe on simulated displays.
* No ScreenCaptureKit or Screen Recording is introduced.
* Display-change refresh works.

---

# Workstream 18.6 — Function Bar Item Resolution

## Goal

Resolve `WorkspaceItem` values into renderable Function Bar item view models.

## Input

Use active `MenuBarWorkspace.functionItems`.

Supported Phase 18 item kinds:

1. `command`
2. `menuBarItem`
3. `group`
4. `spacer`
5. `divider`

Info tile items should show placeholder/unavailable because Info Strip is deferred.

## Output

Implement:

```swift
struct FunctionBarItemModel: Identifiable, Equatable {
    var id: UUID
    var kind: FunctionBarItemKind
    var title: String
    var subtitle: String?
    var icon: FunctionBarIcon
    var status: FunctionBarItemStatus
    var availability: FunctionBarActionAvailability
    var badge: FunctionBarItemBadge?
}
```

Item statuses:

```swift
enum FunctionBarItemStatus: Equatable {
    case available
    case unavailable
    case missingReference
    case requiresPro
    case requiresAccessibility
    case stale
    case protected
    case previewOnly
    case deferred
}
```

## Command Items

Resolve command items for:

* Find Icon
* Show Second Bar
* Reveal All
* Expand
* Collapse
* Open Settings
* Open Recovery
* Switch Workspace, if target exists
* Show Workspace Preview

Unknown command:

* render as unavailable
* do not crash

## Menu Bar Item Proxy Items

Resolve proxy item if possible using existing item memory / Accessibility snapshot reference.

Action availability:

* Pro off: show requiresPro for metadata-dependent actions
* Discovery off: show requiresAccessibilityDiscovery or unavailable
* Accessibility missing: show requiresAccessibility
* snapshot stale: show stale
* item missing: show missingReference
* item available: allow reveal/highlight/open owning app where supported

Do not expose broad “click actual menu item” as stable.

## Group Items

Resolve group reference using existing Groups store/resolver.

* resolved group: show group icon/title/item count
* missing group: show missingReference
* protected group: show protected badge and route through Private Access only if already safely supported
* detached reference: show detached badge if model supports it

## Spacers/Dividers

Render visually, no action.

## Info Tile Placeholder

If a workspace contains `infoTile` item in `functionItems`, render as deferred/unavailable:

* “Info Strip item”
* “Coming in later v0.1.x”

## Tests

Add tests:

* command item resolved
* unknown command unavailable
* menu bar item proxy requires Pro when Pro off
* menu bar item proxy missing reference
* group resolved
* missing group unresolved
* protected group redacted
* spacer/divider no action
* info tile deferred
* resolver redacts diagnostics

## Acceptance Criteria

* Function Bar can render active workspace items.
* Missing references are handled gracefully.
* No crash on unknown commands.
* No raw protected names leak into diagnostics.
* Tests pass.

---

# Workstream 18.7 — Function Bar Views

## Goal

Build a minimal native SwiftUI Function Bar panel.

## Visual Requirements

The Function Bar should be:

* compact
* native-feeling
* app-owned floating panel
* visually distinct from the real macOS menu bar
* clear that it is Preview
* usable in light/dark mode
* keyboard navigable
* not overloaded

## Views

Implement:

```swift
FunctionBarPanelHost
FunctionBarView
FunctionBarItemView
FunctionBarCommandItemView
FunctionBarProxyItemView
FunctionBarGroupItemView
FunctionBarSpacerView
SetSwitcherView
```

## Layout

The first version can be:

```text
[Set Switcher] [item] [item] [group] [divider] [item]
```

or a compact horizontal strip:

```text
Workspace Name ▾ | Find | Second Bar | Reveal | Group | ...
```

Support:

* horizontal layout
* compact mode
* labels optional
* icon + tooltip/title
* disabled state
* Preview badge in an unobtrusive way
* overflow handling if too many items

Overflow behavior:

* if too many items, show “More…” button
* “More…” opens a simple menu/list
* do not let panel exceed visible frame

## Keyboard Navigation

Support if feasible:

* Left/Right selection
* Enter activate selected item
* Escape close
* Command+K or configured search hotkey opens Find Icon, if already supported
* Down arrow opens Set Switcher when focus on workspace button

If full keyboard nav is too large, implement focusable buttons and document remaining work.

## Tooltips / Help

Each item should have a tooltip or accessible label:

* command name
* group name or redacted protected label
* proxy item safe label
* unavailable reason

## Tests

Add UI or unit tests:

* FunctionBarView renders command items
* renders group item
* renders missing item state
* renders empty workspace state
* More/overflow state if item count high
* Escape close if UI tests can simulate
* accessibility labels exist

## Acceptance Criteria

* Function Bar panel renders active workspace items.
* It handles empty/missing/unavailable states.
* It does not look like it replaces the system menu bar.
* It supports basic keyboard/mouse interaction.
* Tests pass.

---

# Workstream 18.8 — Set Switcher MVP

## Goal

Allow users to switch Workspace from the Function Bar.

## UI

Set Switcher should show:

* active workspace
* list of non-archived workspaces
* workspace name/icon
* Preview badge or subtle Workspaces label
* create/duplicate actions can link to Advanced Workspaces Preview
* manage workspaces action opens Advanced Workspaces Preview

## Required Actions

* switch to workspace
* open manage workspaces
* duplicate active workspace, optional if already supported
* create workspace, optional if already supported

## Behavior

When user switches workspace:

1. Call WorkspaceSwitchingService or Command Center `workspace.switch`.
2. Persist active workspace.
3. Refresh Function Bar items.
4. Do not move real menu bar icons.
5. Do not apply physical profile.
6. Do not start Info Strip.
7. Show short feedback if needed.

## Protected Workspace

If `isProtected` exists:

* protected workspace names should be redacted unless unlocked
* switching protected workspace should go through Private Access only if existing service supports this safely
* otherwise show “Protected workspace switching is deferred”

Do not overbuild Private Access in this phase.

## Tests

Add tests:

* switcher lists active/non-archived workspaces
* archived workspaces hidden or marked
* switching updates active workspace
* switching refreshes Function Bar model
* missing workspace handled
* protected workspace redacted
* manage action opens Advanced preview route

## Acceptance Criteria

* User can switch sets from Function Bar.
* Function Bar changes content after switch.
* Switching workspace does not mutate physical layout.
* Tests pass.

---

# Workstream 18.9 — Function Bar Action Dispatch

## Goal

Route all Function Bar item actions through Command Center or existing safe coordinators.

## Rule

No Function Bar view should directly execute low-level behavior.

Actions must flow through:

```text
FunctionBarView
 -> FunctionBarViewModel
 -> FunctionBarActionDispatcher
 -> CommandCenter / AppEnvironment coordinator
 -> result
```

## Supported Actions in Phase 18

### Command Item

Route to Command Center.

Allowed stable/preview commands:

* expand
* collapse
* toggle
* reveal all
* show Find Icon
* show Second Bar
* open Settings
* open Recovery
* show Workspace Preview
* switch Workspace

### Menu Bar Item Proxy

Route to safe existing item action flow.

Allowed:

* reveal item
* highlight item
* show in Find Icon
* show in Second Bar
* open owning app

Do not mark actual menu item activation stable.

If experimental activation exists:

* keep it hidden or behind Advanced/Experimental
* do not expose as default Function Bar action

### Group Item

Allowed:

* open group panel
* reveal group if existing safe action exists
* show group in Find Icon/Second Bar if existing
* protected group must respect Private Access gate if available

### Spacer/Divider

No action.

## Result Feedback

Show lightweight feedback:

* success
* unavailable
* requires Pro
* requires Accessibility
* Safe Mode active
* missing reference
* stale scan
* protected/locked
* failed

Do not log raw item identity.

## Tests

Add tests:

* command route called
* proxy reveal route called
* proxy open owner route called
* group open route called
* spacer no-op
* missing reference returns unavailable
* Pro missing returns requiresPro
* Safe Mode blocks runtime action
* result diagnostics redacted

## Acceptance Criteria

* Function Bar actions use shared routing.
* No low-level behavior is duplicated in views.
* Gates are respected.
* Results are user-visible and privacy-safe.
* Tests pass.

---

# Workstream 18.10 — Status Menu Integration

## Goal

Let users open Function Bar from the everyday status menu without cluttering Basic Mode.

## Status Menu Changes

Add conditional action:

```text
Open Workspace Bar…
```

or:

```text
Show Function Bar…
```

Recommended placement:

```text
Hide Menu Bar Items
Show Menu Bar Items
Reveal All
Arrange Items…
Find Icon…
Show Second Bar
Show Function Bar…    [Preview]
Settings…
Recovery
Diagnostics
Quit
```

But only show this action if:

* Workspaces Preview is enabled, or
* Function Bar Preview is enabled, or
* Advanced Preview Features are shown

Alternative:

* place it under Advanced submenu until user enables Function Bar Preview.

## Primary Click Behavior

Add optional setting:

```text
Primary click on MenuBarDeclutter icon opens Function Bar
```

Default: off.

If enabled:

* click opens Function Bar instead of status menu or alongside current behavior only if project supports alternate click behavior safely
* right click or modified click should still open status menu
* Safe Mode should force normal recovery/status menu behavior

Do not break existing Basic Mode interactions.

## Option/Modifier Behavior

If existing status item supports modifier clicks:

* Option-click reveal-all must remain working.
* Any new Function Bar click behavior must not override important recovery gestures.

## Tests

Add tests:

* status menu includes Function Bar action only under correct conditions
* Function Bar action calls controller show
* primary click setting defaults off
* Safe Mode status menu remains recovery-first
* Option-click reveal-all still available if previously tested

## Acceptance Criteria

* Function Bar is discoverable but not intrusive.
* Default click behavior is unchanged.
* Safe Mode preserves recovery-first menu.
* Tests pass.

---

# Workstream 18.11 — Advanced Workspaces Preview Update

## Goal

Update the Phase 17 Advanced Workspaces Preview page to include Function Bar MVP controls.

## UI Additions

In:

```text
Settings → Advanced → Workspaces Preview
```

Add:

1. Active workspace summary.
2. Button: `Show Function Bar`.
3. Button: `Hide Function Bar`.
4. Function Bar availability state.
5. Function Bar Preview settings card.
6. Workspace item list preview.
7. Add basic command item controls, if not already implemented in Phase 17.
8. Explanation that full drag/drop builder arrives later.
9. Placeholder for Set Builder:

   * “Drag-and-drop Set Builder is coming in a later v0.1.x release.”

## Editing Scope

Phase 18 can allow limited workspace editing from Advanced Preview:

* rename workspace
* duplicate workspace
* switch active workspace
* add/remove command items
* add/remove spacer/divider
* reorder items using simple up/down buttons

Do not implement full drag/drop builder.

## Tests

Add tests:

* Show Function Bar button visible when preview enabled
* Hide Function Bar button works
* workspace item preview updates after active workspace change
* add command item works
* reorder via up/down works if implemented
* drag/drop builder not visible
* Function Bar placeholder replaced by MVP controls

## Acceptance Criteria

* Advanced preview can open Function Bar.
* Users can configure simple Function Bar command items.
* No drag/drop builder yet.
* UI copy is clear and honest.

---

# Workstream 18.12 — Group Item Integration

## Goal

Make Function Bar able to display existing Groups as reusable group items, without implementing full linked group builder yet.

## Tasks

Inspect:

```text
MenuBar-Manager/Groups/
MenuBar-Manager/Workspaces/
MenuBar-Manager/FunctionBar/
MenuBar-Manager/CommandCenter/
```

Implement:

1. Resolve `WorkspaceItem.kind.group`.
2. Display group item in Function Bar.
3. On click:

   * open existing group panel if available
   * otherwise show unavailable message
4. Show item count if safe.
5. Missing group:

   * render missing state
   * allow remove from workspace item list if simple editing exists
6. Protected group:

   * redacted label unless unlocked
   * use Private Access gate only if already safely wired
7. Detached group mode:

   * display detached badge if applicable
   * full detached clone semantics deferred to v0.1.6

## Tests

Add tests:

* resolved group renders
* group click opens group panel command
* missing group renders missing
* protected group redacted
* detached reference badge
* diagnostics count group item without names

## Acceptance Criteria

* Function Bar can include group icons.
* Group click is useful.
* Missing/protected groups are safe.
* Full Set Builder remains deferred.

---

# Workstream 18.13 — Menu Bar Item Proxy Integration

## Goal

Allow Function Bar to display menu bar item proxy references from Workspace items.

## Tasks

Inspect:

```text
MenuBar-Manager/Search/
MenuBar-Manager/SecondBar/
MenuBar-Manager/Accessibility/
MenuBar-Manager/Core/menu-bar-item-memory related code
MenuBar-Manager/Workspaces/
MenuBar-Manager/CommandCenter/
```

## Proxy Display

For a menu bar item reference:

* display app/bundle icon if available
* display safe title if not protected/redacted
* show zone badge if available:

  * visible
  * hidden
  * always hidden
  * unknown
* show stale/missing badge if snapshot unavailable

## Proxy Actions

Primary action:

* reveal/highlight item if available

Secondary actions:

* show in Find Icon
* show in Second Bar
* open owning app
* arrange manually
* assisted move dry-run, only if existing and still Experimental/Advanced

Do not make “click actual menu item” stable.

## Pro Gate

If Pro Discovery is off:

* show item as unavailable/requires Pro if it needs live metadata
* do not prompt automatically
* provide “Open Pro setup” if existing

If Accessibility missing:

* show clear unavailable state
* no prompt unless explicit permission action

## Tests

Add tests:

* proxy item displays from reference
* proxy unavailable when Pro off
* proxy requires Accessibility when permission missing
* proxy missing snapshot renders stale/missing
* proxy reveal/highlight routes through command
* proxy open owning app routes safely
* no raw title in diagnostics export

## Acceptance Criteria

* Function Bar can show menu bar item proxies.
* Pro unavailable states are clear.
* No broad stable activation claim.
* Diagnostics remain redacted.

---

# Workstream 18.14 — Empty, Missing, and Degraded States

## Goal

Make Function Bar understandable even when Workspaces are empty, Pro is off, references are missing, or Safe Mode is active.

## Required States

Implement clear states for:

1. Function Bar Preview disabled.
2. No active workspace.
3. Active workspace has no items.
4. Workspace store unavailable.
5. Safe Mode active.
6. Group reference missing.
7. Menu bar item reference missing/stale.
8. Pro off for proxy metadata.
9. Accessibility missing.
10. Protected workspace/group locked.
11. Info Strip item deferred.
12. Function Bar hidden due to display placement failure.

## User-Facing Copy

Examples:

* “Function Bar is Preview and currently disabled.”
* “This workspace has no function items yet.”
* “This item references a group that no longer exists.”
* “This menu bar item needs Pro Discovery to resolve.”
* “Info Strip items are coming in a later v0.1.x release.”
* “Safe Mode disables Function Bar so recovery stays simple.”

## Tests

Add tests:

* each unavailable state maps to copy
* safe mode state blocks opening
* empty workspace renders helpful action
* missing references do not crash
* deferred info tile state visible

## Acceptance Criteria

* No blank panels.
* No crashes from missing references.
* Users understand why something is unavailable.
* Tests pass.

---

# Workstream 18.15 — Diagnostics and Health Integration

## Goal

Add privacy-safe Function Bar diagnostics and health checks.

## Diagnostics Snapshot

Add:

```swift
struct FunctionBarDiagnosticsSnapshot: Codable, Equatable {
    var previewEnabled: Bool
    var isVisible: Bool
    var displayState: String
    var activeWorkspacePresent: Bool
    var activeWorkspaceIDHash: String?
    var visibleItemCount: Int
    var commandItemCount: Int
    var proxyItemCount: Int
    var groupItemCount: Int
    var missingReferenceCount: Int
    var unavailableItemCount: Int
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
* live search text
* file paths
* screen contents

## Health Checks

Add non-invasive checks:

* Function Bar visible while preview disabled
* Function Bar visible in Safe Mode
* active workspace missing
* too many items causing layout overflow
* placement failure repeated
* stale proxy references count over threshold

Health should not mark Basic Mode unhealthy unless the Function Bar interferes with Basic controls.

## Recovery

Add recovery actions if useful:

* hide Function Bar
* disable Function Bar Preview
* reset Function Bar placement
* reset Workspaces to defaults

Keep under Recovery/Advanced.

## Tests

Add tests:

* diagnostics redaction
* visible state reported
* missing refs count
* Safe Mode hides/suppresses Function Bar
* recovery hide action works
* disabling preview hides panel

## Acceptance Criteria

* Diagnostics include Function Bar status safely.
* Health can detect Function Bar issues.
* Recovery can hide/disable Function Bar.
* Basic Mode remains unaffected.

---

# Workstream 18.16 — Import / Export / Backup Integration

## Goal

Update backup/export to include Function Bar settings and workspace items safely.

## Tasks

Inspect:

```text
MenuBar-Manager/Migration/
MenuBar-Manager/Workspaces/
MenuBar-Manager/FunctionBar/
MenuBar-Manager/Core/SettingsStore
```

Update local backup schema to include:

* Function Bar preview setting
* placement preference
* show labels
* density
* primary click setting
* close on outside click
* workspace function item lists, if not already included in Phase 17

## Important Import Safety

Import must not:

* enable Function Bar Preview by default unless user explicitly selects settings import
* enable primary click behavior without explicit selection
* enable physical profile apply
* enable assisted move
* enable Info Strip runtime
* enable automation
* enable Labs

Safe support export should include only:

* feature enabled state
* item counts
* missing reference counts
* no raw item names
* no raw workspace names if protected
* no raw bundle IDs

## Tests

Add tests:

* backup includes function bar settings
* support export redacts item identities
* import dry-run validates function bar settings
* import apply does not enable primary click unless selected
* imported invalid placement preference repaired
* imported oversized item lists clamped

## Acceptance Criteria

* Backup/export handles Function Bar settings.
* Safe support export remains redacted.
* Import cannot enable risky runtime behavior accidentally.
* Tests pass.

---

# Workstream 18.17 — Manual QA Matrix

## Goal

Add manual QA for Function Bar MVP.

## Create

```text
docs/testing/manual-v0.1.5-function-bar-qa.md
docs/testing/manual-v0.1.5-results.md
```

## Manual QA Areas

### Enable/Disable

* Launch app with Function Bar disabled.
* Confirm no Function Bar appears automatically.
* Enable Workspaces Preview.
* Enable Function Bar Preview.
* Open Function Bar from Settings.
* Open Function Bar from status menu.
* Disable Function Bar Preview and confirm panel closes.

### Set Switcher

* Create multiple Workspaces.
* Add different command items to each workspace.
* Open Function Bar.
* Switch workspace.
* Confirm items update.
* Confirm no real menu bar layout changes.

### Commands

* Add Find Icon command.
* Add Show Second Bar command.
* Add Reveal All command.
* Add Expand/Collapse command.
* Activate commands from Function Bar.
* Confirm results and feedback.

### Groups

* Add a group reference to workspace.
* Open Function Bar.
* Click group item.
* Confirm group panel opens or appropriate unavailable state appears.
* Delete/missing group scenario if feasible.

### Menu Bar Proxy

* Add a menu bar item proxy if UI supports it.
* With Pro off, confirm unavailable state.
* Enable Pro Discovery and Accessibility manually.
* Confirm proxy resolves.
* Click reveal/highlight.
* Confirm no broad activation claim.

### Placement

Current v0.1.7 QA gate is single-screen UI QA on the built-in display. External multi-display movement and expanded notch hardware checks are deferred follow-up when suitable hardware is available.

* Open below menu bar icon.
* Open near mouse.
* Confirm placement remains visible and clamped on the built-in display.
* Sleep/wake if feasible.
* Toggle menu bar auto-hide.

### Safe Mode

* Enter Safe Mode.
* Confirm Function Bar does not open.
* Confirm status menu remains recovery-first.
* Confirm Settings explains Function Bar unavailable.

### Privacy

* Run diagnostics export.
* Confirm no raw item names or protected group names in support export.
* Run no-network watch.
* Confirm no network sockets.

## Acceptance Criteria

* Manual QA docs exist.
* Results are recorded.
* Stable Basic claims remain unaffected.
* Function Bar Preview issues are documented honestly.
* Release checklist links to QA docs.

---

# Workstream 18.18 — Documentation

## Goal

Document Function Bar MVP accurately without overclaiming.

## Create or Update

```text
docs/features/function-bar-v0.1.5-preview.md
docs/features/workspaces-v0.1.5-preview.md
docs/architecture/function-bar-architecture.md
docs/privacy/v0.1.5-function-bar-privacy.md
docs/release/v0.1.5-release-notes.md
docs/release/v0.1.5-release-checklist.md
docs/release/v0.1.5-known-limitations.md
docs/progress/phase-18-v0.1.5-set-switcher-function-bar.md
README.md
docs/support/settings-overview.md
docs/support/workspaces-preview.md
```

## Required Wording

Use this wording or equivalent:

> Function Bar in v0.1.5 is a Preview app-owned panel. It displays actions from the active Workspace. It does not replace the macOS menu bar, does not capture screen pixels, does not use Screen Recording, and does not take ownership of third-party menu bar items.

## Docs Must Explain

* What Function Bar is.
* What Function Bar is not.
* How to enable it.
* How to open it.
* How to switch Workspaces.
* What command items can do.
* What menu bar item proxies can do.
* Why proxy items may require Pro Discovery.
* Why it does not use Screen Recording.
* Why it is not a live clone of system menu bar.
* Why physical workspace switching is deferred.
* Why Info Strip is deferred.
* What Safe Mode does to Function Bar.
* How to recover if Function Bar behaves badly.

## Forbidden Claims

Do not claim:

* stable Function Bar
* stable Info Strip
* full Set Builder
* drag/drop workspace builder
* complete macOS menu bar replacement
* live pixel-accurate icon clone
* stable physical set switching
* stable broad menu item activation
* bulk icon moving
* media widgets
* online widgets
* v0.2 release

## Acceptance Criteria

* Docs match implementation.
* Docs call Function Bar Preview.
* Docs do not overclaim.
* Privacy boundary is clear.
* Current-facing docs use v0.1.5.

---

# Workstream 18.19 — Tests

## Goal

Add meaningful coverage for Function Bar MVP.

## Suggested Test Files

Create or update:

```text
MenuBar-ManagerTests/FunctionBarStateMachineTests.swift
MenuBar-ManagerTests/FunctionBarControllerTests.swift
MenuBar-ManagerTests/FunctionBarPlacementTests.swift
MenuBar-ManagerTests/FunctionBarItemResolverTests.swift
MenuBar-ManagerTests/FunctionBarActionDispatcherTests.swift
MenuBar-ManagerTests/FunctionBarDiagnosticsTests.swift
MenuBar-ManagerTests/FunctionBarImportExportTests.swift
MenuBar-ManagerUITests/FunctionBarPreviewUITests.swift
MenuBar-ManagerUITests/SetSwitcherUITests.swift
```

Follow existing test style.

## Required Unit Tests

Cover:

1. Function Bar disabled by default.
2. Show blocked when preview disabled.
3. Show blocked in Safe Mode.
4. Show succeeds when enabled.
5. Toggle opens/closes.
6. Active workspace change refreshes visible items.
7. Stop closes panel.
8. Placement below menu bar icon.
9. Placement near mouse.
10. Placement fallback when last position invalid.
11. Placement clamps to visible frame.
12. Command item resolves.
13. Unknown command unavailable.
14. Group item resolves.
15. Missing group unavailable.
16. Proxy item requires Pro when Pro off.
17. Proxy item requires Accessibility when permission missing.
18. Proxy item stale/missing snapshot.
19. Spacer/divider no-op.
20. Info tile placeholder deferred.
21. Function Bar action routes through Command Center.
22. Proxy reveal/highlight route uses existing safe action.
23. Group click routes through group panel action.
24. Diagnostics redacts names and item identities.
25. Import/export includes Function Bar settings safely.
26. Primary click remains off by default.

## Required UI Tests

Cover:

1. Function Bar Preview Settings page renders.
2. Enable Function Bar Preview.
3. Open Function Bar from Settings.
4. Function Bar displays active workspace.
5. Set Switcher appears.
6. Switch workspace updates visible label/items.
7. Empty workspace state renders.
8. Missing reference state renders if fixture available.
9. Hide Function Bar.
10. Safe Mode unavailable state renders.
11. No Accessibility prompt appears.

If UI tests are too brittle, add smoke-level tests consistent with the existing suite.

## Acceptance Criteria

* Function Bar model/controller/placement/resolution tests pass.
* UI smoke coverage exists.
* Existing tests still pass.
* Privacy verification still passes.

---

# Workstream 18.20 — Release and Privacy Verification

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
rg -n "stable Function Bar|stable Info Strip|replace.*macOS.*menu bar|system menu bar replacement|live.*menu bar.*clone|pixel capture|live icon capture|Screen Recording" README.md docs MenuBar-Manager || true
rg -n "Function Bar.*move.*icon|Function Bar.*apply.*profile|Function Bar.*physical.*layout|Workspace.*physical.*switch|bulk move" README.md docs MenuBar-Manager || true
```

Inspect results manually.

Acceptable:

* Historical/future notes if clearly labeled.
* Internal type names that do not claim current stability.
* Docs that explicitly state deferred/future behavior.

Not acceptable:

* Current-facing v0.2 claim.
* Current-facing claim that Function Bar replaces system menu bar.
* Current-facing claim that Function Bar captures live pixels.
* Current-facing claim that switching Function Bar workspace moves real menu bar icons.
* Any new privacy-sensitive API usage.

## Acceptance Criteria

* Full test suite passes.
* Privacy boundary script passes.
* Release dry-run passes.
* Installed-app verification passes.
* Targeted searches do not reveal current-facing overclaims.
* Phase progress file records final validation results.

---

# Phase 18 Definition of Done

Phase 18 is complete when:

1. App version is `0.1.5`.
2. Build number is incremented to `6` or documented next build.
3. No current-facing docs/UI call this v0.2.
4. `MenuBar-Manager/FunctionBar/` source area exists.
5. Function Bar Preview setting exists and defaults off.
6. Function Bar primary-click setting exists and defaults off.
7. FunctionBarController can show/hide/toggle an app-owned panel.
8. Function Bar does not open automatically at launch.
9. Function Bar is suppressed in Safe Mode.
10. Function Bar renders active workspace items.
11. Function Bar supports command items.
12. Function Bar supports group items.
13. Function Bar supports menu bar item proxy items with safe actions.
14. Function Bar supports spacers and dividers.
15. Info tile items are rendered as deferred placeholders only.
16. Set Switcher can switch active Workspace.
17. Switching Workspace updates Function Bar contents.
18. Switching Workspace does not move real menu bar icons.
19. Switching Workspace does not apply physical profiles.
20. Function Bar actions route through Command Center or safe existing coordinators.
21. Function Bar placement is display-aware and clamps to visible frame.
22. Status menu can open Function Bar without disrupting Basic defaults.
23. Advanced Workspaces Preview can open/hide Function Bar.
24. Diagnostics are privacy-safe and redacted.
25. Import/export handles Function Bar settings safely.
26. Docs clearly label Function Bar as Preview.
27. Docs clearly state it does not replace macOS menu bar.
28. No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network, telemetry, analytics, cloud sync, or private APIs are introduced.
29. Full tests pass.
30. Release dry-run and installed-app verification pass.
31. `docs/progress/phase-18-v0.1.5-set-switcher-function-bar.md` includes:

    * summary
    * changed files
    * test results
    * release verification results
    * privacy verification results
    * manual QA status
    * known limitations
    * deferred work for v0.1.6

---

# Recommended Codex Subtask Breakdown

Do not ask Codex to execute all Phase 18 in one huge pass. Use these slices.

## Phase 18A — Version + FunctionBar Skeleton

```markdown
Implement Phase 18A only:
- bump app version to 0.1.5 build 6
- create FunctionBar source area
- add Function Bar settings with safe defaults
- add FunctionBarDisplayState and unavailable reasons
- add basic controller skeleton
- add tests for defaults and Safe Mode blocking
- do not add full views yet
- do not add Info Strip
- do not mention v0.2
```

## Phase 18B — Placement + Controller Runtime

```markdown
Implement Phase 18B only:
- implement FunctionBarController show/hide/toggle
- implement FunctionBarPlacementService
- wire controller into AppEnvironment without auto-showing
- suppress in Safe Mode
- add placement tests and lifecycle tests
- no Function Bar actions yet
```

## Phase 18C — Item Resolution

```markdown
Implement Phase 18C only:
- implement FunctionBarItemResolver
- resolve command, menuBarItem proxy, group, spacer, divider, and deferred infoTile placeholder
- handle missing references and Pro unavailable states
- add tests for each item type
- no drag/drop builder
```

## Phase 18D — Function Bar Views + Set Switcher

```markdown
Implement Phase 18D only:
- implement FunctionBarPanelHost and SwiftUI views
- render active workspace items
- implement SetSwitcherView
- switching workspace refreshes visible items
- add UI smoke tests
- do not add Info Strip or drag/drop builder
```

## Phase 18E — Action Dispatch + Status Menu

```markdown
Implement Phase 18E only:
- route Function Bar actions through Command Center or existing safe coordinators
- support commands, proxy reveal/highlight/open owner, group panel open
- add status menu “Show Function Bar…” under Preview/Advanced conditions
- primary click behavior setting remains off by default
- add tests for dispatch and status menu behavior
```

## Phase 18F — Diagnostics + Import/Export + Recovery

```markdown
Implement Phase 18F only:
- add Function Bar diagnostics snapshot with redaction
- add health checks and recovery actions: hide Function Bar, disable preview, reset placement
- include Function Bar settings in backup/export safely
- add tests
```

## Phase 18G — Docs + Manual QA + Final Validation

```markdown
Implement Phase 18G only:
- add v0.1.5 Function Bar docs
- update release notes/checklist
- add manual QA docs
- run full validation commands
- run targeted privacy/overclaim searches
- record final results in phase progress doc
```
