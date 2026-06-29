# Project Summary

Phases 0-11 are implemented for `MenuBarDeclutter`. The checkout also includes the post-9.1 refactoring and hardening work tracked in `docs/refactoring-audit.md`, the Phase 9.2 local dogfood harness, the Phase 9.3 installed-app dry-run release workflow, the Phase 9.4 stability gates, the Phase 9.5 v0.1 Basic Stable Freeze, the Phase 10 Capacity & Layout Pack, and the Phase 11 Private Access & Power User Pack.

## Current Checkout Status

- Product display name, app target, built wrapper/executable, bundle identifier, and canonical shared scheme currently use `MenuBarDeclutter`.
- The `MenuBar-Manager` scheme is retained as a deprecated compatibility fallback. The `.xcodeproj` package and source/test folder names still use `MenuBar-Manager` because `MenuBarDeclutter` is a temporary name and the final product name will be chosen later.
- A separate local-only `MenuBarFixtureApp` target and shared scheme exist for dogfood and menu bar fixture QA. The shipping app has no runtime dependency on it.
- The app is a native macOS 26.0+ LSUIElement menu bar utility with no default document window.
- The app source is split across focused modules for App composition, StatusBar, Hiding, Hotkeys, Settings, Onboarding, Accessibility, Search, Second Bar, Moving, Profiles, Health, Permissions, Dogfood, Layout, Groups, PrivateAccess, Shortcuts, Migration, and Core support.
- Basic Mode is usable by default without Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
- Pro Mode is opt-in. Its user-facing surfaces are implemented, and permission-dependent features degrade to explanatory unavailable states when Pro Mode, Accessibility Discovery, Accessibility permission, LocalAuthentication availability, or Labs gates are missing.
- Automated coverage includes pure-logic unit tests plus UI workflow tests for Diagnostics, Privacy, Find Icon unavailable state, Second Bar settings requirements, and launch screenshots. Phase 10/11 adds focused coverage for layout capacity, suggestions, Full Menu Bar Mode, crowded rescue, spacers, spacing backups, icon groups, Private Access, dynamic hotkeys, App Intents, import/export, profile integration, health, and diagnostics schemas.
- The newest Phase 10/11 validation snapshot records `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` passing with 310 Swift/unit tests in 60 suites plus 7 UI tests, `scripts/qa_preflight.sh` passing, `scripts/qa_dogfood_preflight.sh` passing, and `docs/testing/phase-10-11-qa-run-2026-06-29.md` documenting the installed-app sweep.
- v0.1 build settings currently use marketing version `0.1.0`, build `1`, bundle ID `Yongjun-Zhang.MenuBarDeclutter`, and deployment target macOS `26.0`.
- Local Release artifact verification passed for `/Users/thesmartaz/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Build/Products/Release/MenuBarDeclutter.app`, including version/build checks, codesign, LSUIElement, URL scheme, no network entitlements, privacy usage-string checks, and no ScreenCaptureKit linkage.
- Installed-app dry-run validation passed for `/Applications/MenuBarDeclutter.app` after replacing a stale installed copy with the fresh Phase 10/11 Release artifact. Notarization warnings are expected because no Developer ID notarization ticket exists.
- A Phase 10/11 local alpha package run created `build/Dist/MenuBarDeclutter-alpha.zip` and `build/Dist/MenuBarDeclutter-v0.1.0.zip`; `docs/release/phase-10-11-alpha-package-2026-06-29.md` records the archive/export/package/hash and expected non-notarized Gatekeeper results.
- A non-interactive runtime `lsof` network probe for the installed app recorded no network sockets; `scripts/qa_network_watch.sh --installed` also passed for the Phase 10/11 installed app.
- Public distribution remains blocked by missing Developer ID Application identity/notarization credentials and by hands-on system-state QA for real menu bar behavior, Launch at Login restart/login behavior, Accessibility grant/revoke, Safe Mode option/crash recovery, external display/notch/sleep-wake/Spaces, interactive network monitoring, Touch ID/password flows, Shortcuts app discovery, command-drag spacer/group status items, real crowded-menu-bar rescue, and any real Spacing Labs apply/restore/reset flow.

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
- Alpha RC hardening: temporary `MenuBarDeclutter` target/product/bundle identity, canonical `MenuBarDeclutter` scheme, privacy verification scripts/docs, QA helpers, visible experimental labels for risky Pro features, global Pause All Automation, diagnostics severity/category filters, filtered diagnostics export, and Launch at Login status/recovery support.
- Local dogfood support: `MenuBarFixtureApp`, fixture run/stop scripts, Dogfood Mode, local run checklists, notes, and privacy-safe dogfood export bundles.
- Installed-app release workflow: archive, export, package, dry-run notarization, stapling/Gatekeeper validation scripts, local install/uninstall, installed-app verification, and installed network-watch helpers.
- v0.1 stable-freeze support: safe defaults, settings migration/backups, one-time migration notice, release blockers, privacy/FAQ/install/uninstall/troubleshooting docs, and post-v0.1 roadmap separation.
- Post-9.1 codebase hardening: narrower coordinators, safer settings/logging isolation, structured diagnostics/export cleanup, cached/off-main AX scanning, indexed search, cached Second Bar derivation, trigger coalescing, safer automation URL handling, icon-move cancellation/reentrancy fixes, shared test helpers, and `.xcconfig` build-setting factoring.
- Phase 10 layout assistance: Basic/Pro capacity estimates, non-invasive layout suggestions, Full Menu Bar Mode with auto-exit, crowded reveal rescue, app-owned spacer/divider items, and Labs-only menu bar spacing backup/restore/reset.
- Phase 11 power-user surfaces: icon groups and group panels, optional app-owned group status items, Private Access with LocalAuthentication, dynamic hotkey bindings, App Intents/Shortcuts integration, settings import/export, import backups, and reusable profile packs.

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
- **Application Support** directory tree is created lazily by `AppSupportPaths.ensureDirectoriesExist()`. The current tree includes `MenuBarDeclutter/`, `diagnostics/`, `profiles/`, `backups/`, `Dogfood/`, `Dogfood/runs/`, and `Dogfood/exports/`. Diagnostics exports, local profile/trigger JSON, v0.1 settings backups, and local dogfood bundles use this tree.
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

## Phase 9.1 (Alpha RC Validation + Release Hardening)

- Temporary app target/product/wrapper/executable/bundle identity renamed to `MenuBarDeclutter`; deprecated `MenuBar-Manager` compatibility scheme retained.
- Build/test scripts prefer `MenuBarDeclutter`.
- Privacy verification and QA scripts added:
  - `scripts/verify_privacy_boundary.sh`
  - `scripts/qa_preflight.sh`
  - `scripts/qa_collect_artifacts.sh`
  - `scripts/qa_network_watch.sh`
  - `scripts/verify_release_artifact.sh`
- Privacy, QA, known-risk, and release docs added under `docs/privacy/`, `docs/testing/`, `docs/release/`, and `docs/status/`.
- Settings -> Advanced now has a Labs / Experimental section, explicit icon-moving warning before enablement, and Pause All Automation.
- Settings -> Profiles also exposes Pause All Automation; smart triggers do not evaluate while paused.
- Status menu adds Pause Automation / Resume Automation.
- Diagnostics events now include timestamp, category, severity, message, and optional privacy-safe metadata.
- Settings -> Diagnostics supports warnings/errors filtering, category filtering, Copy Selected, Export Filtered, and rows for experimental icon moving, smart triggers, automation pause, and Launch at Login status.
- Launch at Login settings show live `SMAppService` status, last registration action, status refresh, and Open Login Items Settings.
- Alpha RC docs now include a dated QA run and release notes. The Phase 9.1 recorded QA run documents 203 unit tests plus 7 UI test executions passing on both the canonical and compatibility schemes, local Release artifact verification passing, and a non-interactive runtime network probe showing no connections.
- Manual Alpha RC blockers remain explicit: clean first launch/onboarding, real menu bar drag/use, Accessibility grant/revoke, real icon moving, external display/notch/sleep-wake/Space behavior, profile/trigger/Safe Mode flows, installed-app Launch at Login, interactive network watch, archive, and notarization.
- Historical note: Phase 9.1 did not include Phase 10 implementation work.

## Phase 9.2 (Private Dogfood Harness)

- Added the local-only `MenuBarFixtureApp` target and `MenuBarFixtureApp` shared scheme for deterministic menu bar fixture items. The shipping app target does not depend on the fixture.
- Added fixture QA scripts for build, run, stop, and dogfood preflight flows.
- Added Dogfood Mode settings: `dogfoodModeEnabled`, `dogfoodRunID`, and `dogfoodNotesEnabled`.
- Added Dogfood models/store/UI for local run IDs, gate checklists, checklist results, local notes, and privacy-safe export bundles.
- Added Application Support dogfood folders under `Application Support/MenuBarDeclutter/Dogfood/`, including `runs/` and `exports/`.
- Diagnostics export includes optional dogfood run metadata only while Dogfood Mode is enabled.
- Focused Phase 9.2 dogfood/unit preflight passed. The full UI automation suite still had machine-local instability at that point, so broad manual dogfood gates remained open.

## Phase 9.3 (Installed Alpha Workflow)

- Added release scripts for clean, archive, export, package, notarize/dry-run, staple, Gatekeeper validation, local install, local uninstall, and installed-app verification.
- Added installed-app release docs for signing audit, notarization setup/runbook, installed alpha workflow, and installed QA.
- Verified archive/export/package dry-run distribution and local installation to `/Applications/MenuBarDeclutter.app`.
- `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` passed with expected notarization warnings.
- `scripts/qa_network_watch.sh --installed` observed no installed-app network sockets via `lsof`.
- Real notarization and stapling remain blocked until Developer ID Application and notary credentials are configured.

## Phase 9.4 (Stability Gates and Safe Defaults)

- Added dogfood triage, bug index, and risk board docs.
- Implemented v0.1-safe defaults and clarified that risky features remain off or paused by default.
- Added `SettingsMigrationService` with backup and repair behavior for older alpha settings.
- Improved Launch at Login clarity by showing the current bundle path and warning when not running from `/Applications`.
- Diagnostics now show bundle path and `/Applications` status.
- Added the status-menu emergency recovery command: Reveal All + Reset Separators.
- Automation is paused by default; smart triggers stay disabled until explicitly enabled and resumed.
- Automated preflights passed; public release still depends on manual system-state QA and notarization credentials.

## Phase 9.5 (v0.1 Basic Stable Freeze)

- Froze v0.1 scope around permission-free Basic Mode plus optional, gated Pro surfaces.
- Documented v0.1 defaults, feature gates, privacy, FAQ, installation, uninstall, troubleshooting, release blockers, release notes, and known limitations.
- Moved post-v0.1 work to `docs/roadmap/post-v0.1.md`.
- Validated the canonical scheme, full tests with coverage disabled, privacy boundary, QA preflight, dogfood preflight, release archive/export/package, release artifact verification, dry-run notarization, local install, installed-app verification, and installed-app network socket probe.
- Public stable release is not ready until Developer ID notarization credentials and remaining manual system QA are complete.

## Phase 10 (Capacity & Layout Pack)

- Added the `Layout` module around `LayoutCoordinator`, keeping layout behavior out of `AppDelegate` and behind focused services.
- `LayoutCapacityService` estimates menu bar crowding from Basic screen geometry and, when available, Pro Accessibility snapshots. Basic Mode remains geometry-only and permission-free.
- `LayoutSuggestionService` converts capacity estimates into non-invasive recommendations without silently enabling Pro Mode, moving icons, or applying global spacing changes.
- `FullMenuBarModeService` temporarily reveals a fuller menu bar state, tracks prior visibility, supports auto-exit, and restores safely unless the user changed state manually.
- `CrowdedRevealRescueService` can route difficult reveals to the Second Bar or Full Menu Bar Mode, with a visible "Reveal Inline Anyway" escape hatch.
- App-owned spacer/divider items are persisted through `SpacerItemStore`, rendered through `SpacerStatusItemController`, and editable in Settings. Safe Mode hides optional spacer items.
- `MenuBarSpacingService` implements Labs-only menu bar spacing backup, dry-run/apply, restore, and reset. It is off by default, reversible, and never restarts system processes automatically.
- Settings now includes **Layout** with capacity, suggestions, Full Menu Bar Mode, crowded reveal, spacer management, and Spacing Labs sections.
- Status menu and URL automation now include Phase 10 actions: Full Menu Bar Mode, Layout Suggestions, spacer/divider helpers, `menubardeclutter://full-menu-bar`, `menubardeclutter://exit-full-menu-bar`, and `menubardeclutter://layout-suggestions`.
- Diagnostics adds the `.layout` category and exports Phase 10 layout, spacer, and spacing fields.
- Health/Safe Mode can exit stale Full Menu Bar Mode and hide optional spacers without mutating global menu bar defaults.
- Focused tests cover capacity, suggestions, Full Menu Bar Mode, crowded rescue, spacer models/stores, spacing backup/restore, settings defaults, health recovery, and diagnostics schema coverage.

## Phase 11 (Private Access & Power User Pack)

- Added icon groups through `IconGroup`, `IconGroupStore`, `IconGroupMatcher`, validation, import/export helpers, Settings UI, group editor/picker/preview views, and a searchable group panel.
- Optional app-owned group status items are managed by `IconGroupStatusItemFactory` and `IconGroupStatusItemController`; they are off unless groups opt in and are hidden by Safe Mode recovery.
- Added Private Access through `PrivateAccessPolicy`, `LocalAuthenticationService`, `UnlockSession`, `PrivateAccessCoordinator`, and `ProtectedActionGate`. It gates selected app-owned actions and does not store biometric data.
- Private Access can protect always-hidden reveal, Second Bar, Find Icon, icon moving, Spacing Labs, protected groups, profile apply, and App Intent actions while keeping Basic Mode usable if authentication is unavailable.
- Added dynamic hotkeys through `HotkeyAction`, `HotkeyBinding`, `HotkeyBindingStore`, `HotkeyConflictDetector`, `HotkeyCallbackResolver`, and `DynamicHotkeyRegistrationService`. Dynamic hotkeys are disabled by default and capped by settings.
- Added App Intents / Shortcuts integration through `AppIntentExecutionService`, `AppIntentResultMapper`, and `MenuBarDeclutterShortcutsProvider` with 11 actions for visibility, Second Bar, Full Menu Bar Mode, profile apply, automation pause/resume, and spacing presets.
- Settings now includes **Private Access**, **Groups**, **Hotkeys**, **Automation**, and **Import / Export** sections. Automation exposes App Intents, profile apply, Labs access, and Shortcuts launch affordances without Apple Events.
- Added import/export and migration support through `SettingsExportPackage`, `SettingsExportService`, `SettingsImportService`, `ImportBackupService`, `ProfilePack`, `ProfilePackStore`, and `MigrationAssistantRootView`. Imports are dry-run first and back up before apply.
- Profiles now understand groups, protected groups, dynamic hotkeys, layout mode, Full Menu Bar Mode preference, and Labs-gated spacing preferences.
- Diagnostics exports Phase 11 settings while explicitly excluding protected group names, protected hotkey targets, import/export paths, screenshots, screen contents, and Accessibility snapshots by default.
- Health/Safe Mode detects duplicate groups, group status items visible while disabled, dynamic hotkey conflicts, dynamic hotkeys registered while disabled, and stale Private Access unlock sessions. Recovery can disable dynamic hotkeys, hide group status items, and clear unlock sessions.
- Focused tests cover groups, matching, validation, Private Access policies/gating, unlock sessions, hotkey binding/conflict/registration, App Intent execution, settings export/import, profile packs, profile integration, health, and diagnostics schema coverage.

## Post-9.1 Refactoring and Hardening

`docs/refactoring-audit.md` now records the completed top-leverage refactoring actions and follow-up waves after Phase 9.1.

- Core state and diagnostics were tightened: `SettingsStore` and `DiagnosticsLogger` are `@MainActor`, defaults/restores/clamping share central helpers, the diagnostics logger uses a bounded ring buffer, and diagnostics JSON export uses typed `Encodable` DTOs with the same field table as plain-text export.
- Accessibility scanning was hardened with candidate caching, traversal pruning, cached screen snapshots, workspace launch/terminate invalidation, visibility-change debounce, off-main scan execution, and stale-result cancellation.
- Search and Second Bar were optimized with `SearchIndex`, cached result/item derivation in SwiftUI, shared app-icon caching, display-change repositioning/closing, and cached screen snapshots for placement.
- Smart triggers and URL automation were made safer through coalesced evaluation, first-match trigger precedence, batched trigger saves, ordered active-profile updates, automation pause guards, URL throttling, and clearer diagnostics.
- Icon moving and health recovery were strengthened with pre-confirmation move locking, drag cancellation checks, decomposed move flow, explicit success/failure visibility semantics, extracted safety/confirmation types, and health validation issues that carry explicit recovery actions instead of falling back to reset-all-settings by default.
- Status bar and Settings structure were split further: status menu presentation and drag-hint UI moved out of `StatusBarController`, settings callbacks are grouped through `SettingsActions`, and repeated settings slider/change-forwarding patterns now use shared helpers.
- Test/build infrastructure was expanded with shared test-support helpers, unit-test `MainActor` isolation, `.xcconfig` build-setting factoring, and additional coverage for health reports, trigger persistence/runtime behavior, live diagnostics, hotkey callbacks, status menu routing, AX candidate cache, profile resilience, and diagnostics export schemas.
- Deliberate deferrals remain: a full `SettingsStore` property-wrapper migration is still postponed, the actual Accessibility permission prompt path remains manual/system QA, visual icon capture remains out of scope, and competitor config auto-import remains a future roadmap item.

## Privacy boundary (through Phase 11)

Basic Mode is the default and remains fully usable without sensitive permissions. Phase 4-11 Pro features request only Accessibility, only after explicit opt-in and an explicit permission button click, and degrade gracefully to Basic Mode if permission is missing or revoked. Phase 11 Private Access uses LocalAuthentication for app-owned action gates; it does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, network access, or store biometric data.

Second Bar and Find Icon depend on the Pro Accessibility discovery index and show explanatory unavailable states when requirements are missing. Second Bar uses app/bundle icons and AX metadata, not screenshots or ScreenCaptureKit. Icon moving is disabled by default, Pro-only, experimental, and only runs after explicit user action. Profiles, triggers, groups, hotkey bindings, spacer items, import backups, profile packs, and export packages are local JSON or local file artifacts. Triggers apply conservative Basic settings, can be paused globally, and never silently run bulk icon moves. The URL automation and App Intents surfaces are local, command-limited, Safe Mode aware, pause aware, and cannot bypass Private Access or Labs gates. Spacing Labs is off by default, dry-run by default, reversible, and never runs from recovery automatically. Dogfood runs, notes, fixture QA state, settings backups, diagnostics exports, health reports, and crash markers are local Application Support artifacts. Diagnostics and settings exports exclude screenshots, screen contents, network data, Accessibility snapshots, protected group names, protected hotkey targets, active unlock sessions, and import/export paths by default. No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network access, pixel capture, cloud sync, or telemetry is introduced through Phase 11.
