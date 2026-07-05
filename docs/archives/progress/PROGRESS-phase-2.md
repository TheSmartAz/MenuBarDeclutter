# Progress: Phase 2

Status: implemented.

Historical snapshot: this file records the end-of-phase state for Phase 2. Later progress files, `docs/project-summary.md`, and release docs supersede old scheme names, test counts, defaults, and deferred-scope notes.

## Tech Stack

- Swift 6 mode.
- Native macOS 26.0+ target.
- AppKit for `NSStatusItem` menu bar control (`squareLength` control item, `variableLength` primary and always-hidden separator items).
- Carbon `RegisterEventHotKey` for the global hotkey (no third-party hotkey package).
- SwiftUI for Settings (General, Behavior, Privacy, Diagnostics) and Diagnostics live status.
- Observation framework through `@Observable` and `@Bindable`.
- `NotificationCenter` for cross-service hiding/visibility state notifications.
- `Synchronization.Mutex` for the Carbon callback → MainActor dispatch bridge.
- UserDefaults for new Phase 2 settings (auto-rehide, hover reveal, always-hidden, show separators, global hotkey, Option-click reveal all).
- Swift Testing for new unit tests.

## Added

- `Hiding/HidingVisibilityState.swift`: three-state enum (`collapsed` / `expanded` / `revealAll`) with per-separator `HidingState` mapping, normal toggle, and Option-click toggle.
- `Hiding/RehideController.swift`: one-shot auto-rehide timer with postponement conditions (mouse in band, Settings key, menu open) and a pure `processTick` logic for tests. Logs the last rehide reason.
- `Hiding/HoverRevealController.swift`: polling-timer-based hover reveal using `NSEvent.mouseLocation` and `ScreenGeometryService.isPointInAnyMenuBarBand`. Pure `processMouseLocation` decision for tests; no event taps.
- `Hotkeys/HotkeyModel.swift`: pure value type with Carbon modifier translation, default hotkey (Option+Command+B), and display-name helpers.
- `Hotkeys/GlobalHotkeyManager.swift`: Carbon `RegisterEventHotKey` wrapper with a `Mutex`-based callback bridge back to `MainActor`. Failure-friendly: never crashes, logs conflicts.
- `Settings/BehaviorSettingsView.swift`: new Behavior section surfacing all Phase 2 toggles/sliders plus a Reset to Default hotkey button. `.onChange` calls back to `AppEnvironment.refreshBehaviorSettings()`.
- `Core/LiveDiagnosticsStatus.swift`: `@Observable` runtime snapshot surfaced in Diagnostics (visibility state, separator lengths, hotkey/polling/auto-rehide flags, last rehide reason).
- `MenuBar-ManagerTests/HidingVisibilityStateTests.swift`: 5 tests covering separator state mappings, collapsed/reveal-all flags, normal toggle, Option-click toggle, and `allCases`.
- `MenuBar-ManagerTests/RehideControllerTests.swift`: 7 tests covering fire, postpone on each condition (mouse/Settings/menu), disabled cancellation, user-cancelled path, and zero-delay immediate fire.
- `MenuBar-ManagerTests/HoverRevealControllerTests.swift`: 5 tests covering reveal-on-enter, rehide-scheduled-on-leave, disabled-auto-rehide, no reveal when expanded, and no leave event without prior enter.
- `MenuBar-ManagerTests/HotkeyModelTests.swift`: 7 tests covering default hotkey, display name modifier ordering, Carbon flag translation, empty-modifier rejection, key fallback name, default reset, and clearing.
- Phase 2 manual QA checklist in `docs/testing/manual-qa.md` covering hotkey, auto-rehide, hover reveal, always-hidden separator, Option-click reveal all, show/hide separators, transparent menu bar, external display, and notch display.

## Removed

- None.

## Modified

- `App/AppConstants.swift`
  - Added Phase 2 defaults: `defaultAutoRehideDelaySeconds` (5), `defaultHoverRevealPollingIntervalSeconds` (0.25), `minHoverRevealPollingIntervalSeconds` (0.05), `minAutoRehideDelaySeconds` (0), `maxAutoRehideDelaySeconds` (600).
  - Added default hotkey constants: `defaultHotkeyCode` (11 = B), `defaultHotkeyModifierFlags` (cmdKey | optionKey), and `hotkeyIDSignature` ('MBDH').
  - Added `alwaysHiddenSeparatorAccessibilityLabel`.
- `Core/SettingsStore.swift`
  - Added Phase 2 keys: `autoRehideEnabled`, `autoRehideDelaySeconds`, `hoverRevealEnabled`, `hoverRevealPollingIntervalSeconds`, `alwaysHiddenEnabled`, `showSeparators`, `globalHotkeyEnabled`, `globalHotkeyKeyCode`, `globalHotkeyModifiersRaw`, `revealAllOnOptionClick`.
  - Registered defaults and clamped invalid values on both setter and load paths (`clampAutoRehideDelay`, `clampHoverPollingInterval`).
  - Updated `restoreDefaults()` to reset all Phase 2 fields.
  - Added `effectiveGlobalHotkey()`, `setGlobalHotkey(_:)`, and `resetGlobalHotkeyToDefault()` helpers.
- `Hiding/HidingService.swift`
  - Promoted internal storage to `HidingVisibilityState` while preserving `currentState` (`HidingState`) for Phase 1 callers and tests.
  - Added `revealAll()`, `toggleRevealAll()`, `setVisibility(_:)` transitions and `onVisibilityChange` closure.
  - Added `visibilityDidChangeNotification` alongside the existing `stateDidChangeNotification`.
- `Hiding/HidingState.swift`
  - Unchanged binary enum, still drives per-separator presentation.
- `StatusBar/StatusItemKind.swift`
  - Added `.alwaysHiddenSeparator` case with its own accessibility label and SF Symbol pair (`circle.dashed` / `circle.fill`).
- `StatusBar/StatusItemFactory.swift`
  - `makeSeparatorItem` now accepts `kind` and reuses the same factory for both separator kinds.
  - `updateSymbol` accepts `showVisualMarker`; when `false`, the button is blanked without changing the underlying length.
- `StatusBar/SeparatorController.swift`
  - Refactored to take a `kind` parameter so the same controller powers primary and always-hidden separators.
  - Added `currentLength`, `applyVisualMarkerEnabled(_:)`, and heuristic `hidingStateFromCurrentLength()` for `showSeparators` toggling.
- `StatusBar/StatusBarController.swift`
  - Now owns primary AND always-hidden `SeparatorController` instances, plus `RehideController`, `HoverRevealController`, `GlobalHotkeyManager`, and `LiveDiagnosticsStatus`.
  - Wires `HidingService.onVisibilityChange` to update both separators and the control item.
  - Auto-rehide: arms the timer on expand/revealAll, cancels on collapse.
  - `StatusBarCommandTarget.controlItemClicked` now differentiates Option-click to toggle revealAll when enabled.
  - Added `refreshSeparatorVisuals()`, `refreshAlwaysHiddenSeparator()`, `refreshHoverReveal()`, and `refreshGlobalHotkey()` so Settings changes apply live.
- `StatusBar/StatusBarMenuBuilder.swift`
  - Added `revealAll` and `toggleRevealAll` actions and menu items.
  - `refresh(for:)` accepts a `HidingVisibilityState`; backward-compatible `refresh(for: HidingState)` maps to it.
- `Settings/SettingsRootView.swift`
  - Added the `.behavior` section to the sidebar and `onBehaviorChanged` callback.
- `Settings/SettingsWindowController.swift`
  - Threads `liveStatus` and `onBehaviorChanged` through to `SettingsRootView`.
- `Settings/DiagnosticsSettingsView.swift`
  - Added a Live Status section showing visibility state, separator lengths, always-hidden installed, hotkey registered, hover polling, auto-rehide scheduled, and last rehide reason.
- `App/AppEnvironment.swift`
  - Constructs `GlobalHotkeyManager`, `RehideController`, `HoverRevealController`, `LiveDiagnosticsStatus`, both `SeparatorController`s (primary and always-hidden), and the augmented `StatusBarController`.
  - Wires `RehideController.onRehide` → `collapseAfterRehide()`, with `conditionsProvider` reading the live mouse location, Settings key state, and delegate-tracked status menu state.
  - Wires `HoverRevealController` providers and `onReveal`/`onLeave` callbacks.
  - Wires `GlobalHotkeyManager.onTrigger` → `toggleHiddenItems()`.
  - `refreshBehaviorSettings()` updates live services for any Settings change.
- `MenuBar-ManagerTests/SettingsStoreTests.swift`
  - Added Phase 2 defaults test, persistence test, clamp tests (delay and polling, including non-finite values), and `restoreDefaults` Phase 2 coverage.
- `MenuBar-ManagerTests/HidingServiceTests.swift`
  - Added visibility state defaults, revealAll transitions, and `setVisibility` persistence tests.
- `MenuBar-ManagerTests/ScreenGeometryServiceTests.swift`
  - Added injected menu-bar-band point containment tests.

## Audit Follow-Up

- `RehideController` runtime ticks now consult the live `autoRehideEnabled` provider instead of assuming auto-rehide is enabled.
- `RehideController` now emits a status-change callback so Diagnostics can update while a countdown is scheduled, postponed, cancelled, or fired.
- Status menu openness is now tracked through `NSMenuDelegate` callbacks and participates in rehide postponement.
- `ScreenGeometryService` no longer reads an undocumented `NSScreenMenuBarHeight` device-description key; menu bar bands are derived from public `NSScreen.frame` / `visibleFrame` geometry and are injectable in tests.
- `SettingsStore` clamps `NaN` and infinite persisted delay/polling values.
- Fixed target-wide compile issues in onboarding initialization, diagnostics export imports, and launch-at-login error formatting encountered during verification.
- Marked App Support path tests as `@MainActor` to match the app target's default main-actor isolation.

## Privacy And Permissions

- Basic Mode remains the only implemented mode and is still fully usable with no sensitive permissions.
- Carbon `RegisterEventHotKey` on macOS 26+ does not require Accessibility, Screen Recording, Apple Events, or Input Monitoring.
- `NSEvent.mouseLocation` is read in-process without event taps and does not require Input Monitoring.
- No network feature or dependency was added.

## Verification

- `xcodebuild -scheme MenuBar-Manager -destination 'platform=macOS' build`
  - Result: `BUILD SUCCEEDED`.
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - Result: `TEST SUCCEEDED`.
  - Most recent audit run: `TEST SUCCEEDED` on 2026-06-28.
  - Swift Testing unit tests passed: 57 total across the unit test target (Phase 0 + Phase 1 + Phase 2 suites and newer App Support/Phase 3 prep suites) plus 4 UI launch tests.
  - New Phase 2 suites:
    - `HidingVisibilityStateTests` (5 tests)
    - `RehideControllerTests` (8 tests)
    - `HoverRevealControllerTests` (5 tests)
    - `HotkeyModelTests` (7 tests)
    - Extended `SettingsStoreTests` (Phase 2 defaults/persistence/clamp/restore)
    - Extended `HidingServiceTests` (visibility state, revealAll, setVisibility)
    - Extended `ScreenGeometryServiceTests` (point-in-rect)

## Notes

- The Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so new Swift files were automatically included in the correct target. No `project.pbxproj` edits were required.
- Carbon cleanup is performed in a `nonisolated deinit` using `nonisolated(unsafe)` properties, since the manager is only mutated on `MainActor` and the deinit reads settled values during teardown.
- Out of scope for Phase 2 (deferred to later phases): Accessibility-based icon discovery, search, second bar, profiles, and any network/network permission behavior.
