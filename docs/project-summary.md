# Project Summary

Phases 0-9 are implemented for `MenuBarDeclutter`.

## Current Checkout Status

- Product display name is `MenuBarDeclutter`; the Xcode project and active scheme are still `MenuBar-Manager`.
- The app is a native macOS 26.0+ LSUIElement menu bar utility with no default document window.
- Basic Mode is usable by default without Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
- Pro Mode is opt-in. Its user-facing surfaces are implemented, but they depend on Accessibility permission and degrade to explanatory unavailable states when Pro Mode, Accessibility Discovery, or permission is missing.
- Automated coverage includes unit tests for pure logic plus UI workflow tests for Diagnostics, Privacy, Find Icon unavailable state, Second Bar settings requirements, and launch screenshots.
- The latest recorded full validation is `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`, which passed on 2026-06-28. See `docs/testing/manual-qa-run-2026-06-28.md`.
- Hands-on QA is still required for real Command-drag separator placement, third-party menu bar item movement, external display/notch behavior, Launch at Login through System Settings, real Accessibility prompt grant/revoke flows, and interactive network-monitor checks.

## Usable Features Today

- Permission-free Basic Mode hiding with expand, collapse, toggle, reveal-all, drag hint, separator length reset, persisted state, and display-change reapplication.
- Daily-use Basic behavior controls: auto-rehide, hover reveal, optional always-hidden zone, Option-click reveal all, separator visual markers, and an optional global visibility hotkey.
- Settings, onboarding, Launch at Login opt-in, diagnostics live status, privacy-safe diagnostics export, reset actions, and Application Support directory management.
- Opt-in Pro discovery of menu bar item metadata through Accessibility, with read-only scanning, zone classification, manual refresh, diagnostics tables, and graceful permission handling.
- Find Icon search panel with keyboard navigation, non-clicking reveal/highlight activation, optional Find Icon hotkey, and privacy-preserving diagnostics.
- Floating Second Bar for hidden and always-hidden items using Accessibility metadata and app/bundle icons, with search, keyboard navigation, placement settings, and non-clicking activation.
- Explicit Pro icon moving commands from Search or Second Bar, guarded by settings, permission checks, first-use confirmation, safety rules, retry/verification, and diagnostics.
- Local JSON profiles, conservative profile apply/dry-run, smart triggers for supported local signals, and command-limited `menubardeclutter://` URL automation.
- Health checks, targeted recovery, Safe Mode, crash markers, wake/display recovery, and health report export.

## Phase 0 (project skeleton)

- Native macOS 26.0+ Swift/AppKit/SwiftUI bootstrap.
- LSUIElement menu bar utility baseline.
- Temporary `NSStatusItem` with Settings, Diagnostics, About, and Quit.
- SwiftUI settings window with General, Privacy, and Diagnostics sections.
- Typed UserDefaults settings store.
- In-memory diagnostics ring buffer.
- Build/test scripts, architecture docs, research/license boundaries, manual QA docs, and unit tests.

## Phase 1 (no-permission core hiding MVP)

- Basic Mode menu bar hiding using only public `NSStatusItem` behavior — no private APIs, no sensitive permissions.
- Square-length control item: left-click toggles hidden items, right-click opens the app menu.
- Variable-length primary separator item: slim when expanded, very wide when collapsed to push later items off-screen.
- SF Symbol icons per hiding state (`chevron.left` / `chevron.right` family) with accessibility labels.
- `HidingService` (expand/collapse/toggle/applyState) with persisted `isCollapsed` and `NotificationCenter` notifications.
- `ScreenGeometryService` computes `max(widestScreenWidth * 2, 1200)` capped at `10000`, with injectable width provider for tests.
- Observes `NSApplication.didChangeScreenParametersNotification` and re-applies the collapsed length after display changes.
- Menu actions: Expand/Collapse/Toggle Hidden Items, Reset Separator Length, Show Drag Hint, Settings, Diagnostics, About, Quit.
- First-run drag hint ("Hold Command and drag the separator...") shown as a visible popover and logged to Diagnostics.
- Phase 1 manual QA checklist covering drag, collapse/expand, persistence, display changes, menu bar appearance variations, and privacy.
- New unit tests for `ScreenGeometryService`, `HidingService`, and the extended `SettingsStore` fields.

## Phase 2 (Basic UX polish)

- `HidingVisibilityState` (collapsed / expanded / revealAll) plus per-separator state.
- Auto-rehide with postponement conditions (mouse in band, Settings key, status menu heuristics).
- Hover reveal polling `NSEvent.mouseLocation` (no event taps, no permissions).
- Optional always-hidden separator (`SeparatorController` of kind `.alwaysHiddenSeparator`).
- Global hotkey via Carbon `RegisterEventHotKey` (default Option+Command+B), no Input Monitoring required.
- Option-click reveal all and separator visuals toggle.
- Unit tests for RehideController, HoverRevealController, HotkeyModel, and HidingVisibilityState.

## Phase 3 (Settings, Onboarding, Launch at Login, Diagnostics Export)

- Full Settings UI with a new **Advanced** tab (General, Behavior, Privacy, Diagnostics, Advanced).
- First-run **Onboarding**: SwiftUI paged `TabView` hosted in an AppKit window, gated by `SettingsStore.hasCompletedOnboarding`; "Show Onboarding Again" reachable from Settings → General.
- **Launch at Login** via the public `SMAppService.mainApp` API (ServiceManagement). Only enabled on explicit user opt-in — never auto-enabled — and works inside the App Sandbox; errors are surfaced in Diagnostics.
- **Diagnostics export** to privacy-safe `.txt` / `.json` through an `NSSavePanel`. The bundle contains app version, macOS version, machine architecture, screen frames only, current settings, and recent log events. It explicitly excludes screenshots, screen contents, personal file paths, and network data.
- **Application Support** directory tree (`MenuBarDeclutter/`, `Diagnostics/`, `Profiles/`, `Backups/`) created lazily by `AppSupportPaths.ensureDirectoriesExist()`. Diagnostics exports and local profile/trigger JSON use this tree; `Backups/` remains reserved.
- New `startCollapsed` setting honoring the "Start collapsed" preference on launch.
- App version, marketing version, and build number surfaced in Settings → General → App.
- **Reset App Layout** and **Reset All Settings** actions in Settings → General.
- macOS 26-friendly Settings styling: semantic colors, `.formStyle(.grouped)`, light/dark, increased contrast, reduce transparency support; no custom transparent effects that conflict with Liquid Glass.
- `scripts/notarize_template.sh` and an expanded `docs/release-checklist.md`.
- New unit tests for `SettingsStore` (Phase 3 fields, onboarding, restore-defaults), `AppSupportPaths` (path nesting, lazy directory creation, idempotency), `DiagnosticsExporter` (txt/json structure, exclusions, current-settings reflection), `LaunchAtLoginService` (pure logic: result flags, error fallback), and `OnboardingStep` (step ordering, privacy content).
- Expanded manual QA for first-launch onboarding, settings persistence, launch at login, diagnostics export, reset settings, quit/relaunch, transparent menu bar, reduce transparency, increased contrast, and external display.

## Phase 4 (Accessibility-Based Icon Discovery)

- Optional Pro Mode settings: `proModeEnabled`, `accessibilityDiscoveryEnabled`, `lastAccessibilityPermissionStatus`, and throttled `menuBarScanIntervalSeconds`.
- `AccessibilityPermissionService` checks Accessibility trust without prompting, prompts only from the explicit "Request Permission" button, opens the Accessibility privacy pane, persists mapped status, and logs transitions.
- Read-only Accessibility scanner built from `AXElementReader`, `AXMenuBarScanner`, `MenuBarItemSnapshot`, `MenuBarZone`, and `MenuBarScanResult`.
- Scanner reads safe public AX attributes only: role, subrole, title, description, position, size, identifier, process id, and children. Failed/missing attributes are logged and counted, never fatal.
- Zone classification maps item frames against the primary and always-hidden separator frames into visible, hidden, always-hidden, or unknown.
- `MenuBarScanCoordinator` runs scans only when Pro Mode and Accessibility Discovery are enabled and Accessibility permission is granted. It scans on launch, screen changes, expand/collapse visibility changes, and manual refresh with automatic scan throttling. Manual refresh re-checks permission first, so Diagnostics recovers cleanly after grant/revoke changes in System Settings.
- Settings → Privacy now includes Pro Mode enable/disable, Accessibility Discovery, permission request/open-settings controls, scan throttle, and clear privacy explanations.
- Settings → Diagnostics now shows Accessibility permission status, scanned item count, zone counts, last scan time, AX failure count, manual refresh, and a snapshot table.
- Unit tests cover zone classification, stable snapshot ID generation, scan result dedup/merge behavior, permission status mapping, coordinator refresh/throttle/degradation behavior, and Phase 4 settings persistence/clamping/default reset.
- Manual QA now covers Pro Mode disabled, enable/request/grant/revoke flows, Diagnostics scan refresh, graceful degradation, restart, and Basic Mode privacy boundaries.

## Phase 5 (Find Icon / Icon Panel)

- User-facing Find Icon panel hosted in a floating AppKit `NSPanel` with SwiftUI content.
- `SearchService` ranks the latest Accessibility snapshots by exact app-name match, title match, prefix match, fuzzy contains, bundle identifier match, zone priority, and recency.
- Search result rows show app icon, app name, title/description metadata, zone, match reason, and last-seen timestamp.
- Keyboard support in the panel: focused search field, up/down selection, Return activation, and Escape dismiss.
- Selection behavior is intentionally non-automating:
  - visible items are highlighted and the user is told to click manually,
  - hidden items expand the primary zone before highlighting,
  - always-hidden items enter reveal-all before highlighting,
  - no click, drag, CGEvent, or app activation simulation is performed.
- `HighlightOverlayWindow` draws a transparent, mouse-ignoring rounded rectangle around the approximate item frame and auto-dismisses after two seconds.
- Status menu now includes "Find Icon...", "Refresh Menu Bar Items", and dynamic Enable/Disable Pro Mode.
- `GlobalHotkeyManager` now supports named registrations so the Basic visibility hotkey and optional Find Icon hotkey can coexist. The Find Icon hotkey defaults to Option+Command+F and is disabled by default.
- Settings adds a **Search** section with Find Icon enablement, reveal-on-selection, highlight-on-selection, Find Icon hotkey controls, and requirement status rows for Pro Mode / Accessibility Discovery / Accessibility permission.
- Diagnostics now shows Find Icon hotkey registration, search index item count, last query, last selected item, and activation outcome.
- Diagnostics export includes Phase 5 search settings but does not export live query text or selected-item identity.
- Unit tests cover search exact/prefix/bundle matching, hidden priority, empty-query recency, and default disabled search hotkey behavior.
- Manual QA now covers opening search, permission-missing states, searching by app/bundle, keyboard navigation, visible/hidden/always-hidden activation, highlight overlay behavior, search hotkey, diagnostics updates, and permission revocation.

## Phase 6 (Second Menu Bar / Floating Bar)

- Floating Second Bar hosted in an AppKit `NSPanel` with SwiftUI content.
- Displays hidden and always-hidden Accessibility snapshots using app or bundle icons, app names, item titles, and zone badges.
- Placement modes: below menu bar, near mouse, and last position. The positioning service chooses the active screen, clamps to visible frames, handles display changes, and models notch avoidance.
- Search, keyboard navigation, and Escape close support.
- Status menu commands: Show Second Bar, Hide Second Bar, Toggle Second Bar.
- Settings -> Second Bar controls enablement, item sources, auto-close, placement mode, icon size, labels, outside-click close, and optional owning-app activation.
- Selection reveals/highlights the original item through the existing non-clicking activation path. It does not automate clicking original menu bar items.
- Diagnostics shows Second Bar visibility, item count, current screen, last position, and last selected item.
- Unit tests cover `SecondBarPositioningService` placement, fallback, and notch-avoidance logic.

## Phase 7 (Programmatic Icon Moving)

- Optional Pro Mode icon moving behind explicit user actions in Search and Second Bar.
- New Moving module: `IconMoveService`, `DragPlan`, `DragExecutor`, `DragVerificationService`, `IconMoveResult`, and `IconMoveError`.
- Move actions: Move to Visible, Move to Hidden, Move to Always Hidden, Move Left, Move Right.
- First-use confirmation explains that the feature simulates Command-drag and may fail depending on the app/system item; warnings can be reset from Settings.
- Safety gates: Pro Mode required, Accessibility permission required, icon moving setting required, one move at a time, own MenuBarDeclutter items blocked, likely system items blocked by default.
- Runtime move flow reveals required zones, suspends auto-rehide/hover interactions, asynchronously executes a conservative `CGEvent` drag plan, rescans, verifies the target zone, retries up to the configured limit, and restores previous visibility on failure.
- Settings -> Advanced -> Icon Moving controls enablement, confirmation, max retries, drag duration, system-item allowance, and warning reset.
- Diagnostics shows move in progress, last result, last error, drag plan summary, verification summary, and retries.
- Unit tests cover drag target calculation, relative movement, safety rejection, verification interpretation, and async move-service cleanup. Real CGEvent drags are not run in tests.

## Phase 8 (Profiles, Smart Triggers, Automation)

- Local profile system stored as JSON in Application Support.
- Profile fields cover name, timestamps, preferred visibility state, Second Bar visibility, auto-rehide, hover reveal, bundle-id target zones, and notes.
- Settings -> Profiles supports create, duplicate, delete, edit, dry-run, apply, import, and export.
- `ProfileApplicationService` applies Basic settings and visibility immediately, but Pro zone moves are dry-run/report-only during normal profile apply. It never silently runs mass CGEvent moves.
- Smart triggers are opt-in and persisted as JSON. The Settings UI can configure display, app launched, frontmost app, battery-low, and time-of-day rules.
- Trigger evaluator models external display, app launched/frontmost, battery low, time of day, focus placeholder, and Wi-Fi SSID. Runtime context supplies display count, running/frontmost bundle IDs, time, and battery percentage when public power-source APIs expose it; focus/Wi-Fi rules remain inactive until safe providers are added.
- Trigger firing is debounced, avoids profile loops, applies selected profiles conservatively, and records diagnostics.
- Lightweight automation uses the registered `menubardeclutter://` URL scheme:
  - `menubardeclutter://expand`
  - `menubardeclutter://collapse`
  - `menubardeclutter://reveal-all`
  - `menubardeclutter://second-bar`
  - `menubardeclutter://profile/<ProfileName>`
- `docs/automation-roadmap.md` documents the URL automation scope and future AppleScript/Shortcuts direction.
- Diagnostics shows active profile, last trigger fired, trigger evaluation log, and profile apply log.
- Unit tests cover profile save/load, import/export, dry-run warnings, conservative profile apply, trigger matching, and debounce.

## Phase 9 (Health, Recovery, macOS 26+ Hardening)

- New Health module with `HealthService`, `RecoveryService`, `SafeModeService`, `HealthIssue`, and `HealthReport`.
- Health checks cover missing control/separator status items, invalid separator lengths, invalid screen geometry, corrupted settings, hotkey drift, stuck auto-rehide/hover runtime state, Pro permission mismatches, repeated AX failures, and stale Pro scans.
- Automatic health repair is targeted where possible: separator settings, scan interval, Second Bar position, and Accessibility status cache can be repaired individually before falling back to full defaults.
- Startup is recovery-first: the app starts expanded, installs status items, runs health checks, applies recovery when needed, and only honors collapsed launch preferences after a clean health report.
- Crash marker support writes `running.marker` on launch and removes it on clean termination. A leftover marker starts the next launch in Safe Mode and expanded/reveal-all.
- Safe Mode can be entered by holding Option at launch, by a one-shot flag from Diagnostics, or by the crash marker. It suppresses auto-rehide, hover reveal, Pro scans, icon moving, hotkeys, and smart triggers while preserving the visible Basic control and reset menu.
- Wake/display recovery observes screen parameter changes, workspace wake, and active Space changes, then cancels pending rehide, reapplies geometry/state, refreshes Second Bar placement, optionally rescans Pro snapshots, and logs health.
- Settings -> Diagnostics now shows Health status, issue rows, Fix Automatically, Reset Basic Mode, Disable Pro Mode, Export Health Report, and Safe Mode Next Launch.
- Unit tests cover missing separator detection, corrupted settings detection, targeted settings repair actions, stale AX scan detection, recovery length reset, Pro failure disablement, crash-marker Safe Mode, one-shot Safe Mode flags, and clean marker removal.

## Privacy boundary (through Phase 9)

Basic Mode is the default and remains fully usable without sensitive permissions. Phase 4-9 Pro features request only Accessibility, only after explicit opt-in and an explicit permission button click, and degrade gracefully to Basic Mode if permission is missing or revoked.

Second Bar and Find Icon depend on the Pro Accessibility discovery index and show explanatory unavailable states when requirements are missing. Second Bar uses app/bundle icons and AX metadata, not screenshots or ScreenCaptureKit. Icon moving is disabled by default, Pro-only, and only runs after explicit user action. Profiles and triggers are local JSON; triggers apply conservative Basic settings and never silently run bulk icon moves. The URL automation surface is local and command-limited. Health reports and crash markers are local Application Support artifacts. No Screen Recording, Apple Events, Input Monitoring, network access, pixel capture, cloud sync, or telemetry is introduced through Phase 9.
