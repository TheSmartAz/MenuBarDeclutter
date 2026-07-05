# Architecture Overview

Last reviewed: 2026-07-05

MenuBarDeclutter is a native macOS 26.0+ menu bar utility built with Swift, AppKit, and SwiftUI. The app has no remote backend. Runtime behavior is local and is composed inside `AppEnvironment`.

## Project Identity

- Xcode project: `MenuBar-Manager.xcodeproj`
- Canonical scheme: `MenuBarDeclutter`
- Compatibility scheme: `MenuBar-Manager`
- App target, product, executable, wrapper, and display name: `MenuBarDeclutter`
- Fixture target: `MenuBarFixtureApp`, used only for local QA
- Current release line: `v0.1.10`, build `11`
- Deployment target: macOS 26.0+

## Lifecycle

- `MenuBarDeclutterApp` is the SwiftUI `@main` entry point.
- `AppDelegate` attaches through `@NSApplicationDelegateAdaptor`, sets accessory activation, owns the `AppEnvironment`, handles reopen/termination, and installs UI-test fixtures when launch arguments request them.
- `AppEnvironment` is the composition root. It owns long-lived services, AppKit controllers, SwiftUI window hosts, command handlers, diagnostics, and startup/shutdown ordering.
- Startup is recovery-first: Safe Mode/crash markers are checked, status items are installed, health runs, recovery may repair state, and only then can a collapsed launch preference be honored.

## Coordinator Split

`AppEnvironment` remains the dependency graph owner. Behavior is split into focused `@MainActor` coordinators:

- `SettingsRuntimeCoordinator` applies settings-driven side effects to live services.
- `MenuBarItemSurfaceCoordinator` owns Find Icon, Second Bar, menu item refresh, Accurate Icons refresh handoff, and explicit icon move dispatch.
- `ProfileAutomationCoordinator` owns profiles, smart triggers, URL automation, and local automation lifecycle.
- `AppHealthCoordinator` owns health snapshots, recovery actions, Safe Mode requests, and optional-feature suppression.
- `AppEnvironmentLiveStatusSynchronizer` keeps shared live diagnostics fields current.
- `AppEnvironmentSystemRecoveryCoordinator` observes display, wake, and active-Space changes and calls recovery hooks.
- `WorkspaceDisplayCoordinator` coordinates app-owned Workspace preview surfaces such as Function Bar and Info Strip.

## Basic Mode

Basic Mode is the stable product core and uses public AppKit menu bar primitives only.

- `StatusBarController` owns the square control `NSStatusItem` and menu presentation.
- `SeparatorController` owns primary and optional always-hidden separator `NSStatusItem` instances.
- `StatusItemFactory` creates and updates status items, symbols, labels, and lengths.
- `HidingService` owns `collapsed`, `expanded`, and `revealAll` visibility state and persists the collapsed state through `SettingsStore`.
- `ScreenGeometryService` computes menu bar geometry and safe separator lengths.
- `RehideController`, `HoverRevealController`, and `GlobalHotkeyManager` provide permission-free behavior polish.

Basic Mode does not require Accessibility, Screen Recording, Apple Events, Input Monitoring, network access, telemetry, cloud sync, or ScreenCaptureKit.

## Optional Pro Discovery

Pro discovery is a separate opt-in metadata capability.

- `AccessibilityPermissionService` checks Accessibility trust without prompting by default. The prompt is requested only from explicit user action.
- `MenuBarScanCoordinator` scans only when Pro Mode, Accessibility Discovery, and Accessibility permission are all enabled.
- `AXMenuBarScanner` and `AXElementReader` use bounded public Accessibility traversal and defensive attribute reads.
- `MenuBarItemSnapshot` values hold local metadata such as owner, title, frame, zone, and timestamp.

Find Icon, Second Bar, placement helpers, groups, workspace assignment, and diagnostics can consume the snapshot index. When requirements are missing, they show unavailable or degraded states and Basic Mode continues working.

## Accurate Icons

Accurate Icons is a separate Preview capture path for visual thumbnail accuracy.

- `ScreenCapturePermissionService` checks and requests Screen Recording only from explicit Accurate Icons controls.
- `MenuBarIconCaptureCoordinator` runs capture only when the user setting and permission allow it.
- `MenuBarVisibleIconCapturer` uses public ScreenCaptureKit visible-region capture.
- `MenuBarRenderedIconCache` stores cropped thumbnails locally.

Accurate Icons captures only currently visible rendered menu bar pixels. It does not use private menu bar APIs, offscreen capture, Apple Events, Input Monitoring, or network access. Surfaces fall back to stale thumbnails or app icons when capture is unavailable.

## Layout And Rescue

Layout behavior is local and conservative.

- `LayoutCoordinator` connects capacity estimates, layout suggestions, crowded reveal fallback, Full Menu Bar Mode, app-owned spacers, and Menu Bar Spacing Labs.
- Basic capacity estimates are geometry-only.
- Pro estimates can incorporate Accessibility snapshots when already available.
- Spacing Labs can apply macOS spacing defaults with backups, but remains Labs and user-triggered.

## Workspaces And App-Owned Panels

Workspaces are Preview configuration for MenuBarDeclutter-owned UI. They do not replace or control the macOS system menu bar.

- `WorkspaceStore` persists local workspace JSON.
- `WorkspaceSwitchingService` switches active workspaces and repairs invalid state.
- `WorkspaceValidation` enforces model limits.
- `WorkspaceIntegrationCoordinator` builds local usage/assignment context.
- `FunctionBarController`, `InfoStripController`, `SetBuilderViewModel`, and group panel controllers host app-owned preview UI.

Function Bar, Info Strip, Set Builder, and group panels are SwiftUI surfaces hosted by AppKit controllers. They can route commands back into the shared command system, but they do not physically move third-party menu bar items.

## Commands And Automation

`MenuBarCommandRouter` centralizes command availability and execution.

Callers include:

- Status menu actions
- Settings actions
- Find Icon and Second Bar selections
- Groups, Function Bar, Info Strip, and Workspaces actions
- Dynamic hotkeys
- App Intents
- `menubardeclutter://` URL automation
- Smart triggers

The router applies shared gates for Safe Mode, automation pause, Pro Mode, Accessibility Discovery, permission state, Labs/Experimental flags, target validity, and Private Access. Profiles and URL automation use conservative Basic settings and do not run background icon moving.

## Settings And UI

AppKit owns system integration: `NSStatusItem`, `NSMenu`, `NSPanel`, `NSWindow`, `NSPopover`, hotkeys, Accessibility checks, and app lifecycle.

SwiftUI owns user-facing content:

- Settings and command palette
- Onboarding
- Diagnostics and dogfood notes
- Find Icon, Second Bar, Function Bar, Info Strip, Set Builder, and Groups
- Workspaces, profiles, private access, import/export, and recovery

Current top-level Settings sections are General, Hide & Reveal, Arrange, Find & Rescue, Workspaces, Privacy, Recovery, and Advanced. Deeper or less frequent surfaces live under More or are opened from contextual buttons.

## Local Data

`SettingsStore` is a UserDefaults-backed `@Observable` settings model with conservative defaults and clamping for unsafe values.

`AppSupportPaths` centralizes local files under `Application Support/MenuBarDeclutter/`, including diagnostics, profiles, backups, workspaces, groups, hotkeys, dogfood runs, and rendered icon cache files.

Diagnostics are local and explicit:

- `DiagnosticsLogger` keeps structured in-memory events.
- `LiveDiagnosticsStatus` exposes runtime state to SwiftUI.
- `DiagnosticsExporter` writes `.txt` or `.json` exports only after user action.
- Exports exclude screenshots, screen contents, rendered icon thumbnails, live search text, selected item identity, network data, and sensitive personal file paths by default.

## Testing And QA

Pure logic is covered by unit tests for settings migration, hiding state, rehide/hover logic, scans, search ranking, second bar placement, profiles, triggers, command routing, groups, private access, layout, workspaces, diagnostics, import/export, and recovery.

System behavior is documented through manual QA because real menu bar ordering, display changes, Launch at Login, physical notch/external display behavior, and system permission prompts cannot be fully asserted in unit tests.

Current QA entry points:

- `docs/testing/qa-process.md`
- `docs/testing/manual-qa.md`
- `docs/testing/macos26-test-matrix.md`
- `docs/testing/manual-v0.1.10-results.md`
- `docs/release/v0.1.10-release-runbook.md`
