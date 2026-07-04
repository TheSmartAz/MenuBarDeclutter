# Architecture Overview

MenuBarDeclutter uses Swift, AppKit, and SwiftUI for a native macOS 26.0+ app.

The project also contains a separate local-only `MenuBarFixtureApp` target and scheme used for dogfood QA. The shipping `MenuBarDeclutter` app target has no runtime dependency on that fixture target.

## App Lifecycle

- `MenuBarDeclutterApp` uses the SwiftUI app lifecycle.
- `AppDelegate` is attached through `@NSApplicationDelegateAdaptor`.
- `AppDelegate` sets the app activation policy to `.accessory` and owns `AppEnvironment`.
- `AppEnvironment` is the composition root and lifecycle facade. It wires long-lived services, owns launch/shutdown ordering, and keeps public command methods for `AppDelegate`, Settings callbacks, and status menu commands.
- On launch, `AppEnvironment` detects Safe Mode/crash markers, starts expanded, installs status items, runs a health check, applies recovery when needed, and only then honors a collapsed launch preference if health is OK.
- During runtime, `AppEnvironmentSystemRecoveryCoordinator` observes screen parameter changes, workspace wake, and active Space changes, then calls back into the environment recovery path to pause auto-rehide, reapply geometry, optionally rescan Pro Accessibility snapshots, and log a fresh health report.

## AppEnvironment Coordinator Split

`AppEnvironment` stays intentionally thin around lifecycle ordering and cross-domain wiring. Behavior-heavy runtime domains are split into focused `@MainActor` coordinators:

- `AppHealthCoordinator` owns health snapshot construction, `HealthService` / `RecoveryService` wiring, automatic repair actions, Pro disablement, Safe Mode next-launch requests, and temporary auto-rehide / hover-reveal suppression.
- `SettingsRuntimeCoordinator` owns settings-driven side effects: behavior/search/Second Bar/privacy refreshes, initial behavior application, trigger start/stop decisions, Reset App Layout, Reset All Settings, Pro Mode toggling, and Find Icon hotkey registration.
- `ProfileAutomationCoordinator` owns the local profile store, profile application service, trigger service, and `menubardeclutter://` URL handler lifecycle. It applies profiles through conservative Basic settings and invokes environment refresh callbacks after profile apply.
- `MenuBarItemSurfaceCoordinator` owns Find Icon, Second Bar, menu bar item refresh, Second Bar activation, explicit icon move dispatch, move warning reset, and runtime suspension/resume during icon moves.
- `AppEnvironmentLiveStatusSynchronizer` centralizes the core runtime fields in `LiveDiagnosticsStatus`, including visibility, separator lengths, hotkey state, hover/auto-rehide state, Accessibility status, automation pause, search index count, and Second Bar item count. Domain services still own their domain-specific diagnostics fields, such as scan results, search selections, Second Bar selection state, icon-move outcomes, profiles, triggers, health, and dogfood exports.
- `AppEnvironmentSystemRecoveryCoordinator` owns notification observer installation/removal for display, wake, and active-Space recovery events.

The split keeps `AppEnvironment` as the dependency graph owner while avoiding a single massive app delegate-style object. Cross-domain calls remain explicit closures so Basic Mode can keep working when Pro features are disabled, permission is missing, or Safe Mode suppresses optional services.

## Services

- `StatusBarController` owns the control `NSStatusItem` (square length, left-click toggles hiding, right-click opens the menu, Option-click reveals all) and delegates separator state to two `SeparatorController` instances (primary and always-hidden).
- `SeparatorController` owns a single separator `NSStatusItem` (variable length) and translates `HidingState` into a concrete separator length. The same controller type powers both the primary and the always-hidden separators; the `StatusItemKind` parameter carries symbol/label variants.
- `StatusItemFactory` builds `NSStatusItem` instances and applies SF Symbol images, accessibility labels, length updates, and an optional `showVisualMarker` mode used by the Phase 2 "show separators" toggle.
- `StatusBarMenuBuilder` constructs the menu and bridges menu item selectors to closures. Phase 5 adds "Find Icon...", "Refresh Menu Bar Items", and a dynamic Enable/Disable Pro Mode command. Phase 6 adds Show/Hide/Toggle Second Bar.
- Phase 9.1 adds a dynamic Pause Automation / Resume Automation command. It toggles `SettingsStore.automationPaused`, refreshes trigger runtime state, and gates URL automation without affecting manual Basic Mode commands.
- `HidingService` owns the current `HidingVisibilityState` (`collapsed` / `expanded` / `revealAll`) and derives a binary `currentState` (per primary separator) for Phase 1 callers. Exposes `expand()`, `collapse()`, `toggle()`, `revealAll()`, `toggleRevealAll()`, `setVisibility()`, and `applyState()`; persists `isCollapsed` through `SettingsStore`; notifies observers via closures and two `NotificationCenter` notifications.
- `HidingVisibilityState` describes the three-state menu bar surface introduced in Phase 2 and maps each case to its per-separator `HidingState` (`primarySeparatorState` and `alwaysHiddenSeparatorState`).
- `ScreenGeometryService` computes widest screen width, the recommended collapsed separator length (`max(width * 2, 1200)` capped at `10000`), menu bar band rectangles, and a hit-test helper. Width provider is injectable for unit tests.
- `RehideController` owns the one-shot auto-rehide timer introduced in Phase 2. Postpones when the cursor is in any menu bar band, when the Settings window is key, or (heuristically) when a status item menu is open. Pure logic is split into `processTick` so tests can drive deterministic timelines; the runtime half uses a `Timer.scheduledTimer`.
- `HoverRevealController` polls `NSEvent.mouseLocation` on a configurable timer and calls `ScreenGeometryService.isPointInAnyMenuBarBand` to decide whether to reveal hidden items. Pure logic lives in `processMouseLocation` so tests stay deterministic; no event taps or permissions required.
- `Hotkeys/HotkeyModel` is a pure value type describing a global hotkey (virtual key code + Carbon modifier flags). Includes display-name helpers and `NSEvent` translation. Safe to construct in unit tests.
- `Hotkeys/GlobalHotkeyManager` owns Carbon `RegisterEventHotKey` registrations for named app hotkeys. Phase 5 supports both the Basic visibility toggle and the optional Find Icon hotkey. Failures are logged to Diagnostics and never crash. A shared `Mutex<GlobalHotkeyManager?>` is used by the Carbon C callback to dispatch the pressed hotkey ID back to `MainActor`.
- `SearchService` (Phase 5) is pure ranking logic over the latest `MenuBarItemSnapshot` list. It ranks exact app-name matches, exact title matches, prefix matches, fuzzy contains, bundle identifier matches, and boosts hidden / always-hidden zones because users are likely searching for missing items.
- `SearchWindowController` (Phase 5) owns the floating AppKit `NSPanel` and hosts `SearchRootView`.
- `MenuItemActivator` (Phase 5) handles selection from search results. It expands hidden items or reveals all for always-hidden items when configured, highlights the approximate item frame, and instructs the user to click manually. It never simulates click, drag, or activation events.
- `HighlightOverlayWindow` (Phase 5) shows a transparent borderless overlay around a menu bar item frame for two seconds, ignores mouse events, handles secondary-screen coordinates, and does not capture or inspect screen contents.
- `SecondBarPositioningService` (Phase 6) is pure placement logic for the floating Second Bar. It chooses a screen from mouse/last-position context, supports below-menu-bar / near-mouse / last-position modes, clamps to visible frames, and models notch avoidance for tests.
- `SecondBarViewModel` (Phase 6) filters, searches, and sorts hidden / always-hidden `MenuBarItemSnapshot` values and owns keyboard selection state for the SwiftUI Second Bar.
- `SecondBarWindowController` (Phase 6) owns a floating, non-activating AppKit `NSPanel` hosting `SecondBarRootView`. It closes on Escape, can close on outside click through `hidesOnDeactivate`, follows display changes, and updates live diagnostics. It does not require Screen Recording on its own and does not click original menu bar items.
- `IconMoveService` (Phase 7) coordinates optional explicit icon moves. It gates moves behind the icon-moving setting, Pro Mode, granted Accessibility permission, first-use confirmation, safety rules, and one-at-a-time locking. It reveals required zones, suspends runtime behaviors, asynchronously executes a drag plan, rescans, verifies, retries, and restores visibility on failure.
- `DragPlanFactory`, `DragExecutor`, and `DragVerificationService` (Phase 7) split icon moving into testable planning, nonisolated async runtime `CGEvent` execution, and post-move verification. Unit tests exercise planning, verification, and move-service cleanup only; real drags are manual-QA territory.
- `ProfileStore` (Phase 8) persists local JSON profiles under `Application Support/MenuBarDeclutter/profiles/` and supports create, duplicate, update, delete, import, and export.
- `ProfileApplicationService` (Phase 8) applies conservative profile settings and produces dry-run summaries. It applies Basic settings and visibility immediately, reports zone move requirements, and never silently runs bulk CGEvent moves.
- `TriggerRuleEvaluator` and `TriggerService` (Phase 8) model and run smart triggers. The runtime observes local public signals for display changes, launched apps, frontmost app changes, minute-based evaluation, and public battery capacity when available. Trigger firing is debounced, avoids profile loops, and applies profiles through the conservative profile application service. Phase 9.1 adds global automation pause; paused automation stops observers/evaluation and records skipped evaluations without changing manual Basic commands.
- `AutomationURLHandler` (Phase 8) installs a `kAEGetURL` handler for the registered `menubardeclutter://` scheme. It supports expand, collapse, reveal-all, show second bar, and apply-profile-by-name commands without adding Apple Events scripting dictionaries, network access, or background automation. The global automation pause rejects URL commands while paused.
- `HealthService` (Phase 9) turns a runtime `HealthCheckSnapshot` into a `HealthReport`. Checks cover missing control/separator items, invalid separator lengths, invalid screen geometry, corrupted settings, hotkey registration drift, stuck auto-rehide/hover timers, Pro permission mismatches, repeated AX failures, and stale Pro scans.
- `RecoveryService` (Phase 9) maps health issues to focused repair actions: recreate missing status items, reset separator lengths, expand all, temporarily disable auto-rehide/hover reveal, reset corrupted scan interval / Second Bar position / Accessibility status cache, disable Pro Mode, reset settings as an explicit fallback, and request Safe Mode for the next launch.
- `AppHealthCoordinator` adapts pure health/recovery services to the live AppKit runtime. It builds snapshots from status items, settings, permissions, timers, scans, and Safe Mode state, then runs targeted recovery without requesting new permissions.
- `AppEnvironmentSystemRecoveryCoordinator` owns screen/wake/active-Space observers. `AppEnvironment` still owns the recovery action itself: cancel auto-rehide, reapply status item geometry, refresh Second Bar placement, force Pro rescans when allowed, and rerun health after system changes.
- `SafeModeService` (Phase 9) owns launch-safe flags and crash markers. Holding Option at launch, a one-shot `safe-mode-next-launch.flag`, or a leftover `running.marker` enters Safe Mode; clean termination removes the marker. Safe Mode starts expanded and suppresses auto-rehide, hover reveal, Pro scans, icon moving, hotkeys, and smart triggers while keeping the control item and reset menu available.
- `SettingsWindowController` owns the AppKit settings window and hosts SwiftUI content, including the Behavior section, Profiles, Advanced, and live diagnostics.
- `SettingsRuntimeCoordinator` applies user setting changes to live runtime services and keeps settings refresh ordering consistent across Settings, status menu commands, profile application, and health recovery.
- `SettingsStore` owns typed UserDefaults-backed preferences (Phase 0 through Phase 9.5 fields). It clamps user-entered delay/polling/scan/Second Bar/icon-moving values to documented bounds and exposes helper accessors/mutator methods for the global visibility hotkey, Find Icon hotkey, Second Bar placement, Dogfood Mode, and global automation pause.
- `LiveDiagnosticsStatus` is an `@Observable` snapshot of runtime state (visibility state, separator lengths, hotkey/hover/auto-rehide flags, last rehide reason, Accessibility permission status, latest Pro scan counts, AX failure count, scanned item snapshots, search state, Second Bar state, icon moving state, active profile, trigger logs, automation pause state, profile apply logs, Safe Mode state, and latest health report). It is instantiated by `AppEnvironment`; core runtime fields and derived counts are refreshed by `AppEnvironmentLiveStatusSynchronizer`, while domain services update their own diagnostics fields directly. The snapshot is surfaced in the Diagnostics view.
- `DiagnosticsLogger` owns an in-memory ring buffer of structured diagnostic events. Phase 9.1 events carry timestamp, category, severity, message, and optional privacy-safe metadata. Existing callers can keep using the simple `log(_:level:)` API while category inference provides useful QA filters.
- `AppSupportPaths` centralizes the Application Support directory tree (`MenuBarDeclutter/`, `diagnostics/`, `profiles/`, `backups/`, `rendered-icon-cache/`, `Dogfood/`, `Dogfood/runs/`, and `Dogfood/exports/`) and ensures they exist lazily. Phase 3 writes diagnostics exports only on explicit user action, Phase 8 stores local profile and trigger JSON under `profiles/`, Phase 9.2 stores local dogfood run/notes/export bundles under `Dogfood/`, Phase 9.5 settings migration writes pre-migration backups under `backups/`, and Accurate Icons stores local thumbnail cache files under `rendered-icon-cache/`.
- `LaunchAtLoginService` (Phase 3) wraps the public `SMAppService.mainApp` API. `register()` is called only to honor explicit or persisted user opt-in, including startup reconciliation of the saved Launch at Login setting; `unregister()` runs when the user disables that preference. Failure paths are surfaced through `.lastRegistrationResult` and logged to Diagnostics. Phase 9.1 also exposes live `SMAppService` status and an Open Login Items Settings recovery action. The service never enables Launch at Login without a stored user opt-in. Works inside the App Sandbox.
- `DiagnosticsExporter` (Phase 3+) builds a privacy-safe diagnostics snapshot (app version, macOS version, machine architecture, screen frames only, current settings including Pro opt-in flags, Second Bar settings, icon moving settings, smart trigger enablement, automation pause, Dogfood Mode flags, and recent structured log events) and serializes it to `.txt` or `.json`. The bundle explicitly excludes screenshots, screen contents, personal file paths by default, live query text, selected-item identities, and network data. Phase 9.1 supports filtered diagnostics export through the Diagnostics tab `NSSavePanel`; Phase 9.2 includes optional dogfood run metadata only when Dogfood Mode is enabled.
- `AccessibilityPermissionService` (Phase 4) wraps `AXIsProcessTrustedWithOptions`. It checks permission without prompting by default, shows the system prompt only from the explicit "Request Permission" button, stores the last mapped status in `SettingsStore`, opens the Accessibility privacy pane when requested, and logs permission transitions.
- `AXElementReader` (Phase 4) is the defensive Accessibility attribute adapter. It reads only safe public attributes (role, subrole, title, description, position, size, identifier, process id, children), returns optional/result-style values, logs failed reads, and maintains an AX failure count for diagnostics.
- `AXMenuBarScanner` (Phase 4) creates a system-wide AX element and walks menu bar / menu extra roots where available. It never clicks, drags, activates, records the screen, or uses private APIs. It produces `MenuBarItemSnapshot` values with deterministic generated IDs for the same owner/title/frame inputs, ownership metadata, frame, zone, system-item heuristic, and timestamp. IDs can change after movement or display geometry changes, so move verification also matches by ownership and metadata.
- `MenuBarScanCoordinator` (Phase 4) gates scanning behind `SettingsStore.proModeEnabled`, `SettingsStore.accessibilityDiscoveryEnabled`, and granted Accessibility permission. It scans on launch, display changes, visibility changes, and manual refresh, with `menuBarScanIntervalSeconds` throttling automatic scans. Manual refresh stays available whenever Pro discovery is configured so the coordinator can re-check a newly granted or revoked Accessibility permission before deciding whether to scan.
- `MenuBarIconCaptureCoordinator` owns the optional Accurate Icons pipeline. It checks the user setting plus Screen Recording status, uses public visible-region ScreenCaptureKit capture through `MenuBarVisibleIconCapturer`, caches cropped thumbnails locally in `MenuBarRenderedIconCache`, and can run a conservative reveal sweep for items hidden by MenuBarDeclutter. It does not use private menu bar APIs or capture offscreen item windows.
- `DogfoodStore` (Phase 9.2) owns local-only dogfood run state, gate checklists, notes, and privacy-safe export bundle creation. It uses `AppSupportPaths` for run storage and does not upload, screenshot, or inspect screen contents.
- `SettingsMigrationService` (Phase 9.5) migrates older alpha settings to v0.1 safe defaults. It stamps fresh installs, backs up older alpha settings under `backups/`, resets risky runtime flags, repairs unsafe separator values, clears stale Accessibility status cache, and leaves local profile JSON in place.

## UI

- AppKit controls real menu bar integration through `NSStatusItem`.
- SwiftUI owns the Settings `NavigationSplitView` sections (General, Behavior, Search, Second Bar, Profiles, Privacy, Diagnostics, Advanced), the Onboarding window, and the diagnostics display.
- The Phase 1/2 app has no default document/content window; the menu bar is the primary surface.
- Phase 3 Settings adds an Advanced section with separator geometry tweaks, App Support discovery (reveal in Finder), and read-only metadata (ring buffer capacity, bundle id).
- Phase 3 Onboarding is a SwiftUI paged `TabView` hosted in an AppKit `OnboardingWindowController`. It runs once on first launch (gated by `SettingsStore.hasCompletedOnboarding`) and can be replayed from Settings → General → Show Onboarding Again.
- Phase 4 Privacy settings add explicit Pro Mode enable/disable controls, an Accessibility Discovery toggle, a "Request Permission" button, an "Open Settings" button, and a scan throttle stepper.
- Phase 4 Diagnostics adds Accessibility permission status, scan counts by zone, last scan time, AX failure count, manual scan refresh, and a table of scanned menu bar snapshots.
- Phase 5 Search settings add Find Icon enablement, reveal-on-selection, highlight-on-selection, a disabled-by-default Find Icon hotkey, and requirement status rows for Pro Mode / Accessibility Discovery / permission.
- Phase 5 Search UI is a floating `NSPanel` with a focused SwiftUI search field, keyboard navigation, app icons, app/title/bundle metadata, zone, and last-seen timestamp. If Pro Mode or Accessibility permission is unavailable, the panel explains the requirement and offers explicit user actions.
- Phase 5 Diagnostics adds Find Icon hotkey registration, search index item count, last query, last selected item, and last activation outcome.
- Phase 6 Second Bar settings add enablement, item source toggles, auto-close, placement mode, icon size, labels, close-on-outside-click, and optional owning-app activation.
- Phase 6 Second Bar UI is a floating SwiftUI panel showing hidden and always-hidden items using app/bundle icons and AX metadata. It supports search, keyboard navigation, context menus, and clear unavailable states for missing Pro requirements.
- Phase 7 Advanced settings add Icon Moving enablement, confirmation behavior, retry count, drag duration, system-item allowance, and warning reset.
- Phase 7 Search and Second Bar rows expose explicit move commands from context menus only. There are no automatic move actions on launch, wake, profile apply, or trigger firing.
- Phase 8 Profiles settings add local profile management, dry-run/apply actions, import/export, and initial Smart Trigger controls.
- Phase 8 Diagnostics adds live Second Bar, icon moving, active profile, last trigger, trigger evaluation, and profile apply rows.
- Phase 9 Diagnostics adds Health status (OK / Warning / Critical), issue rows, Fix Automatically, Reset Basic Mode, Disable Pro Mode, Export Health Report, and Safe Mode Next Launch actions.
- Phase 9.1 Diagnostics adds severity/category filters, Copy Selected, Export Filtered, experimental icon-moving state, smart-trigger state, automation pause state, and Launch at Login status.
- Phase 9.1 Advanced settings adds a Labs / Experimental section. Icon moving remains disabled by default, displays an experimental warning before enablement, and automation can be paused globally. Profiles settings also expose Pause All Automation for smart triggers.
- Phase 9.2 Diagnostics adds Dogfood run controls, gate checklist rows, local notes, and Dogfood bundle export. The controls are local-only and do not add telemetry.
- Phase 9.4/9.5 General and Diagnostics surfaces show installed-app context such as the current bundle path and `/Applications` status so Launch at Login can be validated from the installed app rather than from Xcode or DerivedData.
- All Phase 3 SwiftUI surfaces use semantic colors and `.formStyle(.grouped)`, support light/dark mode, increased contrast, and reduce transparency. No custom transparent effects that would conflict with macOS 26 Liquid Glass are introduced; settings controls remain readable over a transparent menu bar context.

## Hiding Mechanism (Phase 1)

- Hiding is achieved with public `NSStatusItem` behavior only, no private APIs.
- The separator item sits to the left of the user's menu bar icons. When collapsed, its `length` grows large enough to push later items off the visible menu bar (the macOS menu bar is arranged left-to-right in declaration order).
- `HidingService.applyState()` recomputes the separator length and updates the control and separator SF Symbols (`chevron.left` / `chevron.right` family).
- `AppEnvironmentSystemRecoveryCoordinator` observes `NSApplication.didChangeScreenParametersNotification`; the environment recovery path re-applies the collapsed length after display changes.
- State persists across launches via `SettingsStore.isCollapsed`.

## Phase 2 Behavior Layer

- **Visibility state machine**: `HidingVisibilityState` adds a `revealAll` state. Both separators can be expanded, only the primary, or both collapsed.
- **Auto-rehide**: when the user expands or reveals all, `RehideController` starts a one-shot countdown; conditions (mouse in band, Settings key, menu open) postpone the deadline. Manual collapse cancels the countdown.
- **Hover reveal**: `HoverRevealController` polls `NSEvent.mouseLocation` and expands the hidden items when the cursor enters any menu bar band. Leaving the band re-arms auto-rehide if it is enabled.
- **Global hotkey**: `GlobalHotkeyManager` registers a Carbon hotkey (default `Option+Command+B`) and dispatches it back to `HidingService.toggle()`. Disabled by default, enabled in Settings → Hide & Reveal.
- **Always-hidden separator**: an optional second `SeparatorController` of kind `.alwaysHiddenSeparator` collapses independently to provide the always-hidden zone.
- **Option-click**: `StatusBarCommandTarget.controlItemClicked` differentiates Option-click from normal click. With `revealAllOnOptionClick` enabled, Option-click cycles between `revealAll`/`collapsed`.
- **Separator visuals**: `showSeparators` toggles only the separator button's image/title; the underlying `NSStatusItem` length is preserved.

## Phase 4 Accessibility Discovery

- Pro Mode is represented by explicit booleans (`proModeEnabled`, `accessibilityDiscoveryEnabled`) rather than replacing Basic Mode. Basic Mode remains the default and continues to work with Pro disabled.
- Permission status is modeled as `notRequested`, `denied`, `granted`, or `unknown`. A normal status refresh uses `AXIsProcessTrustedWithOptions` with the prompt option set to `false`; the prompt option is `true` only when the user clicks "Request Permission".
- Scanning is read-only. It uses `AXUIElementCreateSystemWide`, app menu bar roots, and SystemUIServer menu extra roots where available; reads safe attributes only; and treats missing/unsupported attributes as logged failures, not crashes.
- Zone classification compares item frames to separator frames: right of the primary separator is `visible`, left of primary but right of the always-hidden separator is `hidden`, left of the always-hidden separator is `alwaysHidden`, and missing/insufficient frames are `unknown`.
- The coordinator has no default polling timer. Automatic triggers are launch, screen changes, and expand/collapse visibility changes, all throttled by the scan interval using the coordinator clock. Manual refresh bypasses the throttle and refreshes permission first, which covers the common System Settings grant/revoke flow without requiring an app restart.
- No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, click simulation, drag simulation, search window, second bar, or icon moving is implemented in Phase 4.

## Phase 5 Find Icon

- Find Icon is a Pro surface layered on top of Phase 4 Accessibility Discovery. It is disabled by default for v0.1 and remains unavailable until the user enables Find Icon plus Pro Mode, Accessibility Discovery, and granted Accessibility permission.
- Opening Find Icon from the status menu or optional search hotkey requests a manual AX refresh, which re-checks permission and updates the latest snapshot list when allowed.
- Search does not perform system automation. Selecting a visible item highlights its frame and tells the user to click manually. Selecting a hidden item expands the primary hidden zone; selecting an always-hidden item enters `revealAll`; both paths can show a short-lived overlay around the last known or clamped approximate frame.
- Search settings allow the user to disable Find Icon, disable automatic reveal-on-selection, disable highlighting, and separately opt into the Find Icon hotkey (`Option+Command+F` by default).
- The highlight overlay is a transparent, mouse-ignoring AppKit window. It does not use Screen Recording, ScreenCaptureKit, screenshots, or pixel sampling.
- Live diagnostics show search index size, last query, last selected item, and activation outcome for supportability. The diagnostics exporter records only search settings, not query or selected-item identity.

## Phase 6 Second Bar

- Second Bar is a Pro surface that reuses the Phase 4 Accessibility snapshot index. It is unavailable when Pro Mode, Accessibility Discovery, or Accessibility permission is missing.
- The window is a floating AppKit `NSPanel` with SwiftUI content. It can sit below the menu bar, near the mouse, or at the last position; the placement service keeps it inside visible screen frames and responds to display changes.
- The UI shows hidden and always-hidden items with rendered thumbnails or app fallback icons, app names, optional titles, and zone badges. Rendered thumbnails come only from the separate Accurate Icons opt-in path.
- Selecting an item calls the same non-clicking activation path as Find Icon: hidden zones are revealed, always-hidden items use reveal-all, and a highlight overlay can point to the approximate original frame.
- The Second Bar does not request Screen Recording on its own, use private APIs, or perform automatic clicking.

## Phase 7 Icon Moving

- Icon moving is Pro-only, disabled by default, and requires an explicit user action from Search or Second Bar.
- `IconMoveService` is the safety boundary. It rejects moves when the feature is disabled, Pro Mode is disabled, Accessibility permission is missing, another move is active, the item is MenuBarDeclutter's own item, the source frame is missing, or a likely system item is selected while system moves are not allowed.
- First-use confirmation explains the simulated Command-drag behavior and can be suppressed by the user. Suppression can be reset from Settings.
- Drag planning is separated from execution. The plan contains the source frame, target zone, target point, Command modifier, duration, retry count, and previous visibility state.
- Runtime execution uses `CGEvent` to simulate a conservative Command-drag with non-blocking async waits. Auto-rehide and hover reveal are suspended during the move, then restored.
- Verification rescans Accessibility snapshots and checks that the item is found in the requested zone. Failures restore the previous visibility state and surface user-visible diagnostics.
- No icon moving runs from startup, wake, profile application, smart triggers, or URL automation.

## Phase 8 Profiles, Triggers, Automation

- Profiles are local JSON records stored in Application Support. They describe visibility state, Second Bar visibility, auto-rehide, hover reveal, optional target zones by bundle id, and notes.
- Profile application is intentionally conservative. Basic settings and visibility state apply immediately; zone moves are reported through dry-run summaries and require separate explicit move actions.
- Smart triggers are opt-in. Runtime observers cover display changes, app launch, frontmost app changes, and a one-minute timer for time-based rules. Trigger evaluation is debounced and skips firing when the target profile is already active.
- The trigger UI can configure display-count, launched-app, frontmost-app, battery-low, and time-of-day rules. Runtime context supplies display count, running/frontmost bundle IDs, time, and battery percentage when public power-source APIs expose it. Focus and Wi-Fi rules remain model-level placeholders until safe providers are added.
- URL automation is the implemented lightweight automation path. The app registers `menubardeclutter://` in `Info.plist` and handles `expand`, `collapse`, `reveal-all`, `second-bar`, and `profile/<name>` through `AutomationURLHandler`.
- AppleScript dictionary and richer Shortcuts actions remain future work documented in `docs/automation-roadmap.md`.
- Profiles, triggers, and URL automation are local-only. They do not add network calls, telemetry, cloud sync, or background icon moving.

## Phase 9 Health, Recovery, macOS 26 Hardening

- Startup is recovery-first. The app writes a `running.marker` after Application Support is ready and removes it on clean termination; a leftover marker on the next launch is treated as a previous crash and forces Safe Mode plus an expanded/reveal-all start.
- Collapsed launch requests are deferred until after status items are installed and health has passed. If health is unhealthy, recovery runs first and the bar stays expanded.
- Safe Mode can be entered by holding Option at launch, by setting a one-shot flag from Diagnostics, or by the previous-crash marker. It suppresses auto-rehide, hover reveal, Pro AX scans, icon moving, hotkeys, and smart triggers for that launch while keeping Basic Mode control visible.
- Wake/display recovery observes screen parameter changes, workspace wake, and active Space changes. It cancels pending auto-rehide, recomputes separator geometry, reapplies current visibility, refreshes Second Bar placement, forces a Pro scan only when Pro requirements are already met, and logs the resulting health report.
- Diagnostics can export a standalone health report. The report contains health status, issue codes, details, and suggested recovery actions; it does not include screenshots, screen contents, network data, or personal file paths.

## Phase 9.1 Alpha RC Hardening

- Product identity cleanup is temporarily aligned on `MenuBarDeclutter`: the app target, built wrapper/executable, bundle identifier, and canonical shared scheme use `MenuBarDeclutter`. The deprecated `MenuBar-Manager` compatibility scheme remains, and the `.xcodeproj` package plus source/test folders keep their legacy names until the later final-name rename.
- Privacy verification is scriptable through `scripts/verify_privacy_boundary.sh`, which checks project/source files and optionally a built app bundle for network entitlements, ScreenCaptureKit, sensitive usage strings, LSUIElement, URL scheme, local App Support paths, and diagnostics exclusions.
- QA support scripts cover preflight validation, local artifact collection without screenshots, manual network-watch guidance, and release artifact verification.
- Risky Pro surfaces are visibly experimental. Icon moving displays the simulated Command-drag warning before enablement and remains off after settings reset. Smart triggers can be paused globally from Profiles, Advanced, and the status menu.
- Diagnostics are structured and filterable by severity and category. Filtered exports remain privacy-safe and do not include live search text or selected item identity.
- Launch at Login validation is hardened for real installs: Settings and Diagnostics show `SMAppService` status and the last registration action, and Settings can open Login Items in System Settings.

## Phase 9.2 Dogfood Harness

- `MenuBarFixtureApp` is a separate LSUIElement fixture app target under `Tools/MenuBarFixtureApp/`. It creates deterministic AppKit `NSStatusItem` cases for local QA and is intentionally not a dependency of the shipping app.
- Dogfood Mode is stored in `SettingsStore` through `dogfoodModeEnabled`, `dogfoodRunID`, and `dogfoodNotesEnabled`. Defaults keep Dogfood Mode off.
- `DogfoodRun`, `DogfoodChecklistItem`, and related models represent local gates A-E, checklist results, run IDs, notes, and bundle metadata.
- `DogfoodStore` saves run and notes JSON under `Application Support/MenuBarDeclutter/Dogfood/runs/` and exports local bundles under `Dogfood/exports/`.
- `DogfoodNotesView` is embedded in Diagnostics and exposes start/end run, checklist, notes, and export controls.
- Dogfood export bundles include diagnostics, optional health report, run JSON, notes JSON, metadata, and a manifest. They exclude screenshots, screen contents, live search text, selected item identity, telemetry, and network data.

## Phase 9.3 Installed Alpha Workflow

- Release scripts create a clean archive/export/package/install workflow around `MenuBarDeclutter`.
- The dry-run path supports local validation without notarization credentials: archive, export, verify, package, dry-run notarize, install to `/Applications`, verify installed bundle, and run an installed-app socket probe.
- Real notarization/stapling/Gatekeeper release remains blocked until a Developer ID Application identity and notary credentials exist.
- Installed-app docs distinguish Xcode/DerivedData behavior from `/Applications` behavior, especially for Launch at Login.

## Phase 9.4 Stability Gates

- Safe defaults are enforced for v0.1: Pro Mode, Find Icon, Second Bar, Icon Moving, Smart Triggers, Auto-rehide, Hover Reveal, Hotkey, Always-hidden, and Start Collapsed are off; automation is paused.
- Launch at Login UI is clearer about current bundle path and installed-app validation.
- Diagnostics surfaces installed-app context and an emergency recovery command is available from the status menu.
- Trigger debounce and URL command throttling remain in place, and automation pause stops trigger evaluation plus URL automation without blocking manual Basic Mode commands.

## Phase 9.5 v0.1 Basic Stable Freeze

- v0.1 scope is frozen around permission-free Basic Mode plus optional, gated Pro surfaces.
- `SettingsMigrationService` migrates older alpha state to safe defaults, backs up pre-migration settings, repairs invalid values, and shows a one-time safe-defaults notice only when needed.
- Release docs now separate included v0.1 scope, accepted limitations, public-release blockers, privacy promises, installation/uninstall steps, troubleshooting, FAQ, and post-v0.1 roadmap items.
- Automated validation covers canonical build/test, privacy verification, QA preflight, dogfood preflight, release archive/export/package, dry-run notarization, local install, installed-app verification, and installed-app socket probing. Remaining release blockers are external signing/notarization and hands-on system-state QA.

## Phase Status

- Phase 0: implemented (project skeleton).
- Phase 1: implemented (no-permission core hiding MVP).
- Phase 2: implemented (Basic UX polish: hotkey, auto-rehide, hover reveal, always-hidden zone, option-click reveal all, separator visuals).
- Phase 3: implemented (full Settings UI with Advanced tab, first-run Onboarding, Launch at Login via `SMAppService.mainApp`, privacy-safe Diagnostics export to `.txt`/`.json`, Application Support directory tree, App version/build number metadata, Reset App Layout / Reset All Settings, macOS 26-friendly Settings styling, notarize template, expanded tests and manual QA).
- Phase 4: implemented (opt-in Pro Mode Accessibility permission flow, defensive menu bar scanner, scan coordinator, diagnostics table, pure-logic tests, manual QA).
- Phase 5: implemented (Find Icon search panel, ranking service, non-clicking reveal/highlight activation, optional search hotkey, settings/diagnostics/manual QA).
- Phase 6: implemented (Second Bar floating panel, placement service, settings/diagnostics/manual QA).
- Phase 7: implemented (explicit Pro icon moving, drag planning/execution/verification, safety settings/diagnostics/manual QA).
- Phase 8: implemented (local profiles, smart triggers, URL automation, settings/diagnostics/manual QA).
- Phase 9: implemented (health checks, recovery actions, Safe Mode, crash marker, wake/display recovery, diagnostics repair UI, manual QA).
- Phase 9.1: implemented (Alpha RC validation, release hardening, canonical shared scheme, privacy verification, experimental labels, automation pause, diagnostics filters, Launch at Login validation support, QA/release docs).
- Phase 9.2: implemented (local dogfood harness, fixture app target/scheme, Dogfood Mode UI/store/export bundles, dogfood preflight).
- Phase 9.3: implemented (installed alpha archive/export/package/install/dry-run notarization workflow; public notarization remains credential-blocked).
- Phase 9.4: implemented (safe-default gating, migration groundwork, installed-app clarity, emergency recovery, automated stability gates).
- Phase 9.5: implemented (v0.1 Basic Stable Freeze docs/defaults/migration/release validation; public release still blocked by signing/notarization and manual system QA).
- Phase 10+: planned (visual capture remains postponed and requires a separate privacy review).

## Basic Mode Architecture (Phase 9.5 boundary)

Basic Mode is a deliberately permission-free utility:

- Real menu bar hiding uses only public `NSStatusItem` behavior (variable-length separator that pushes later items off-screen). No private APIs.
- "Launch at Login" uses `SMAppService.mainApp` (ServiceManagement), which does **not** require Accessibility, Apple Events, or Input Monitoring and works inside the App Sandbox. It is only ever activated on explicit user opt-in.
- Hover reveal and the shortcuts menu work by polling `NSEvent.mouseLocation` and using `ScreenGeometryService`; no event taps and no Input Monitoring.
- Diagnostics is an in-memory ring buffer plus an on-demand privacy-safe export — no automatic telemetry, no network calls, no personal file paths in the export.
- Health and Safe Mode are local-only recovery features. They use Application Support marker files and public AppKit notifications; they do not add sensitive permission requests.
- Onboarding is fully local SwiftUI content with no telemetry.
- Dogfood Mode is local-only, off by default, and stores run/checklist/notes/export bundles under Application Support without screenshots, screen-content capture, network calls, or telemetry.
- v0.1 settings migration is local-only and writes backups under Application Support before resetting risky alpha flags to safe defaults.

## Why Basic Mode does not request permissions

Basic Mode deliberately stays permission-free so the app is usable immediately and trustworthy by default. Phase 4 adds Pro Mode as a separate opt-in capability, not as a replacement for Basic Mode. Phase 5 Find Icon and Phase 6 Second Bar depend on that Pro discovery index and degrade to explanatory panels when Pro Mode or Accessibility permission is unavailable. Phase 7 icon moving is disabled by default and additionally requires explicit user actions. Phase 8 profiles/triggers apply conservative Basic settings unless the user separately initiates Pro moves. Phase 9 Safe Mode suppresses Pro scans, icon moving, hotkeys, and triggers while preserving the visible Basic control and reset menu. Phase 9.1 global automation pause stops smart trigger evaluation and URL automation without affecting manual Basic Mode commands. Phase 9.2 dogfood support is local-only QA instrumentation. Phase 9.5 migration resets risky alpha flags to safe defaults instead of enabling permission-dependent behavior. If Pro Mode is disabled, Accessibility Discovery is disabled, or Accessibility permission is denied/revoked/unavailable, the scan coordinator clears Pro diagnostics and the Basic `NSStatusItem` hiding workflow continues unchanged.

## Privacy Boundary

Basic Mode does not request sensitive permissions and does not use network access. Phase 4-9.5 Pro Mode requests only Accessibility, only after explicit user action, and only for menu bar item frames/labels used by discovery, search, Second Bar display, and explicit icon moving. Accurate Icons can request Screen Recording only after the user enables it and presses the permission action; it stores cropped thumbnails locally and excludes them from diagnostics. Health reports, crash markers, dogfood bundles, and migration backups are local files under Application Support and do not include screenshots or screen contents. The app does not request Apple Events, Input Monitoring, or network access. Phase 2/5 hotkeys use Carbon's `RegisterEventHotKey`, which does not require Input Monitoring on macOS 26+. URL automation uses a local custom URL scheme and does not add a scripting permission prompt.
