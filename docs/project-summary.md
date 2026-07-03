# MenuBarDeclutter Project Summary

Last reviewed: 2026-07-03

MenuBarDeclutter is a native macOS 26.0+ menu bar decluttering utility built with Swift, AppKit, and SwiftUI. The current Xcode project is `MenuBar-Manager.xcodeproj`; the canonical scheme, app target, product, executable, and display identity are `MenuBarDeclutter`. The older `MenuBar-Manager` scheme is retained as a compatibility fallback, and `MenuBarFixtureApp` is a separate local QA fixture target.

The current documented release line is `v0.1.10`. It is a release-hardening checkpoint for the `v0.1.9` source/docs baseline, not a new feature promotion. Basic Mode is the stable product core. Workspaces and most power-user surfaces remain Preview, Menu Bar Spacing is Labs, and Assisted Move / Icon Moving is Experimental.

## Product Status

Stable Basic Mode features:

- Expand, collapse, toggle, reveal all, and always-hidden reveal for menu bar items.
- Permission-free menu bar hiding through app-owned `NSStatusItem` control and separator items.
- Auto-rehide, hover reveal, Option-click reveal-all, separator visuals, and a global Basic visibility hotkey.
- Launch at Login through `SMAppService.mainApp`, only after user opt-in.
- Guided Manual Arrange that teaches normal macOS Command-drag placement instead of controlling other apps by default.
- Privacy-safe diagnostics export, local backup/restore mechanics, health checks, recovery actions, Safe Mode, reset layout, and reset settings.

Preview features:

- Pro Accessibility Discovery, Find Icon search, Second Bar, Placement Planner, New Item Inbox, Crowded Reveal Rescue, Workspaces, Workspace Integration, Function Bar, Set Builder, linked/detached Groups, Info Strip, Profiles, Smart Triggers, Dynamic Hotkeys, Private Access, App Intents, URL automation, and broader import/export workflows.

Labs and Experimental features:

- Menu Bar Spacing Labs can preview/apply spacing presets and stores backups.
- Assisted Move / Icon Moving can attempt explicit, user-triggered single-item movement, but remains Experimental and off by default.

Deferred or not claimed:

- ScreenCaptureKit visual capture, Screen Recording, Apple Events scripting/control, Input Monitoring, network/cloud sync, telemetry, analytics, remote config, and stable automated physical menu bar item moving.
- Developer ID signing, notarization, stapling, and public distribution are out of scope until explicitly requested.

## How Features Are Implemented

Basic hiding uses public AppKit menu bar primitives. `StatusBarController` owns the control item plus primary and optional always-hidden separators. `SeparatorController` and `StatusItemFactory` create and update the `NSStatusItem` instances. `HidingService` stores the visibility state (`collapsed`, `expanded`, `revealAll`) and persists collapsed state through `SettingsStore`. `ScreenGeometryService` computes safe separator lengths and menu bar bands.

Behavior polish is local and permission-free. `RehideController` handles one-shot auto-rehide timers; `HoverRevealController` polls `NSEvent.mouseLocation` without event taps; `GlobalHotkeyManager` registers Carbon hotkeys. These services update `LiveDiagnosticsStatus` and are refreshed by `SettingsRuntimeCoordinator`.

Pro discovery is explicitly gated. `AccessibilityPermissionService` checks Accessibility trust without prompting unless the user clicks the request action. `MenuBarScanCoordinator` scans only when Pro Mode, Accessibility Discovery, and Accessibility permission are all enabled. `AXMenuBarScanner` uses bounded public Accessibility traversal to create `MenuBarItemSnapshot` values and classify them into visible, hidden, always-hidden, or unknown zones.

Find Icon and Second Bar reuse the Pro discovery index. `SearchService` provides pure ranking/filtering, while `SearchWindowController` hosts `SearchRootView` in a floating `NSPanel`. `SecondBarWindowController` hosts `SecondBarRootView` and uses `SecondBarPositioningService` for display-aware placement. Selection reveals or highlights items; it does not click third-party menu bar items.

Layout and rescue behavior live in `LayoutCoordinator`. It coordinates layout capacity estimates, suggestions, Full Menu Bar Mode, crowded reveal fallback, app-owned spacers, and spacing labs. Basic estimates are geometry-only; Pro estimates can use Accessibility snapshots when available.

Profiles, triggers, shortcuts, and URL automation are local automation layers. `ProfileStore` and `TriggerService` persist local JSON under Application Support. `ProfileApplicationService` applies conservative Basic settings and dry-runs zone moves instead of silently moving icons. App Intents and URL automation route through `MenuBarCommandRouter`, so Safe Mode, automation pause, Pro, Accessibility, Labs, and Private Access gates are shared.

Workspaces are app-owned Preview configuration, not a replacement for the macOS system menu bar. `WorkspaceStore` persists local workspace JSON, `WorkspaceSwitchingService` switches active workspaces, and `WorkspaceValidation` repairs invalid workspace state. Workspaces feed the Function Bar, Info Strip, Set Builder, workspace assignment helpers, and diagnostics, but do not physically move real menu bar icons.

Groups are lightweight local collections of menu bar item references. `IconGroupStore` persists groups, `IconGroupMatcher` resolves snapshots, `IconGroupPanelWindowController` hosts the group panel, and `IconGroupStatusItemController` can create optional app-owned group status items. Protected groups route through Private Access.

Health and recovery are local safety systems. `HealthService` builds reports for status items, separators, screen geometry, hotkeys, timers, Pro scan health, layout, groups, workspaces, Function Bar, Info Strip, and private-access issues. `RecoveryService` maps those issues to targeted repair actions. `SafeModeService` detects Option-at-launch, crash markers, and next-launch flags, then suppresses optional features while keeping Basic controls and recovery reachable.

## Frontend And Backend Wiring

There is no remote backend. The "backend" of this app is a local native service layer composed inside `AppEnvironment`.

Lifecycle wiring:

- `MenuBarDeclutterApp` is the SwiftUI `@main` shell.
- `AppDelegate` attaches via `@NSApplicationDelegateAdaptor`, sets the app to `.accessory`, creates `AppEnvironment`, starts runtime services, handles reopen/termination, and installs special UI-test fixtures when requested.
- `AppEnvironment` is the composition root. It owns long-lived services, creates AppKit controllers, injects stores and closures into SwiftUI views, starts scanning/automation/health/runtime observers, and coordinates shutdown.

Frontend surfaces:

- AppKit owns system integration: `NSStatusItem`, `NSMenu`, `NSWindow`, `NSPanel`, `NSPopover`, hotkeys, Accessibility checks, and app lifecycle.
- SwiftUI owns user-facing content: Settings, onboarding, diagnostics, Find Icon, Second Bar, Function Bar, Info Strip, Set Builder, group panels, migration/import-export, Private Access, and dogfood notes.
- AppKit controllers host SwiftUI roots with `NSHostingController`: `SettingsWindowController`, `OnboardingWindowController`, `SearchWindowController`, `SecondBarWindowController`, `IconGroupPanelWindowController`, `FunctionBarController`, and `InfoStripController`.

Settings wiring:

- `SettingsRootView` is a `NavigationSplitView` with visible sections for General, Hide & Reveal, Arrange, Find & Rescue, Workspaces, Privacy, Recovery, and Advanced.
- Hidden or deep-linkable settings surfaces include Menu Bar Items, Layout, Search, Second Bar, Private Access, Groups, Hotkeys, Profiles, Automation, Import/Export, and Diagnostics.
- Views bind to `SettingsStore`, `LiveDiagnosticsStatus`, domain stores, and service objects.
- `SettingsActions` passes UI events back to `AppEnvironment`; `SettingsRuntimeCoordinator` then applies side effects to live AppKit services.

Command wiring:

- `StatusBarMenuBuilder`, Settings, Search, Second Bar, Groups, Function Bar, Info Strip, App Intents, URL automation, smart triggers, and dynamic hotkeys all route user or automation requests as `MenuBarCommand` values where practical.
- `MenuBarCommandRouter` centralizes availability checks for Safe Mode, automation pause, Pro Mode, Accessibility Discovery, Accessibility permission, feature gates, Labs access, experimental confirmation, target validity, and Private Access.
- Successful command execution calls handler closures owned by `AppEnvironment`, which in turn invoke domain services such as hiding, search, second bar, layout, workspaces, profiles, groups, or recovery.

Data and diagnostics wiring:

- `SettingsStore` is a `@MainActor @Observable` UserDefaults-backed settings store with conservative defaults and clamping for unsafe values.
- `AppSupportPaths` centralizes local storage under `Application Support/MenuBarDeclutter/` for diagnostics, profiles, backups, workspaces, groups, hotkeys, dogfood runs, and related JSON files.
- `DiagnosticsLogger` keeps structured in-memory events. `LiveDiagnosticsStatus` exposes runtime state to UI. `DiagnosticsExporter` writes privacy-safe `.txt` or `.json` exports on explicit user action.
- `SettingsMigrationService`, import/export services, profile packs, and workspace/group stores keep migration and backup behavior local.

## Privacy Boundary

Basic Mode is usable without Accessibility, Screen Recording, Apple Events, Input Monitoring, network access, telemetry, cloud sync, or ScreenCaptureKit. Pro features are opt-in and degrade to unavailable or explanatory states when Pro Mode, Accessibility Discovery, or Accessibility permission is missing. Diagnostics exclude screenshots, screen contents, live search text, selected item identity, network data, and sensitive file paths by default.

## Tests And QA

The project has unit tests for pure logic such as settings migration, hiding state, rehide/hover logic, scans, search ranking, second bar placement, profiles, triggers, command routing, groups, private access, layout, workspaces, diagnostics, import/export, and recovery. UI tests cover installed surfaces and visual smoke flows.

The v0.1.10 docs record successful local automated gates for build-for-testing, split unit/UI test lanes, privacy verification, dry-run packaging, installed-app verification, and screenshot QA. Direct full `xcodebuild test` is documented as blocked by an Xcode LaunchServices runner issue in this environment, while split unit and UI lanes passed. Hardware-only manual QA for external displays, notch behavior, and some hands-on permission/menu cases remains partial or blocked in the documented local setup.

## Important Source And Doc Entry Points

- App lifecycle and composition: `MenuBar-Manager/App/MenuBarDeclutterApp.swift`, `MenuBar-Manager/App/AppDelegate.swift`, `MenuBar-Manager/App/AppEnvironment.swift`.
- Settings and user surfaces: `MenuBar-Manager/Settings/`, `MenuBar-Manager/Onboarding/`, `MenuBar-Manager/Search/`, `MenuBar-Manager/SecondBar/`, `MenuBar-Manager/FunctionBar/`, `MenuBar-Manager/InfoStrip/`, `MenuBar-Manager/Groups/`, `MenuBar-Manager/SetBuilder/`.
- Runtime services: `MenuBar-Manager/StatusBar/`, `MenuBar-Manager/Hiding/`, `MenuBar-Manager/Layout/`, `MenuBar-Manager/Accessibility/`, `MenuBar-Manager/Health/`, `MenuBar-Manager/CommandCenter/`, `MenuBar-Manager/Profiles/`, `MenuBar-Manager/Workspaces/`.
- Core local state: `MenuBar-Manager/Core/`, `MenuBar-Manager/Migration/`, `MenuBar-Manager/PrivateAccess/`, `MenuBar-Manager/Dogfood/`.
- Current docs: `README.md`, `docs/architecture/architecture-overview.md`, `docs/release/v0.1.10-release-notes.md`, `docs/release/v0.1.10-feature-status-audit.md`, `docs/release/v0.1.10-known-limitations.md`, `docs/privacy/v0.1.10-privacy-claims.md`, and `docs/progress/phase-23-v0.1.10-release-hardening.md`.
