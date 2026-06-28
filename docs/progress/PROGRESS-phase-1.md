# Progress: Phase 1

Status: implemented.

## Tech Stack

- Swift 6 mode.
- Native macOS 26.0+ target.
- AppKit for `NSStatusItem` menu bar control (`squareLength` control item, `variableLength` separator item).
- SwiftUI retained for Settings, Onboarding, Diagnostics, and future UI surfaces.
- Observation framework through `@Observable` and `@Bindable`.
- `NotificationCenter` for cross-service hiding state notifications.
- UserDefaults for new Phase 1 settings (hiding state and separator geometry).
- Swift Testing for new unit tests.

## Added

- `Hiding/HidingState.swift`: `expanded` / `collapsed` enum with `toggled` and `isCollapsed` helpers.
- `Hiding/ScreenGeometryService.swift`: computes widest screen width, recommended collapsed separator length (`max(width * 2, 1200)` capped at `10000`), menu bar band rectangles, and a hit-test helper. Width provider is injectable for unit tests.
- `Hiding/HidingService.swift`: owns current hiding state, exposes `expand()`, `collapse()`, `toggle()`, `applyState()`, and `handleScreenParametersChanged()`; persists `isCollapsed` through `SettingsStore`; notifies observers via `onStateChange` closure and `NotificationCenter`.
- `StatusBar/StatusItemKind.swift`: enumerates control vs primary separator with their accessibility labels and SF Symbol names per hiding state.
- `StatusBar/StatusItemFactory.swift`: builds and updates `NSStatusItem` instances (square control, variable separator), applies template SF Symbol images, accessibility labels, and length updates.
- `StatusBar/SeparatorController.swift`: owns the primary separator `NSStatusItem`, computes expanded vs collapsed length (honouring user override), and applies the length/symbol for a given `HidingState`.
- `MenuBar-ManagerTests/ScreenGeometryServiceTests.swift`: 4 tests covering collapsed length minimum, widest-screen math, and cap behaviour with injected screen widths.
- `MenuBar-ManagerTests/HidingServiceTests.swift`: 6 tests covering expanded default, persisted collapsed launch, expand/collapse transitions, toggle, reapply (no state change but notification reposted), and persistence across store reload.
- Phase 1 manual QA checklist in `docs/testing/manual-qa.md` covering status bar surface, drag hint, Command-drag separator, collapse/expand, persistence, display changes, menu bar appearance variations, and privacy.

## Removed

- None.

## Modified

- `App/AppConstants.swift`
  - Added separator geometry constants: `defaultExpandedSeparatorLength` (20), `collapsedSeparatorWidthMultiplier` (2), `collapsedSeparatorMinimumLength` (1200), `collapsedSeparatorMaximumLength` (10000).
  - Added accessibility label constants for the control and separator items.
- `Core/SettingsStore.swift`
  - Added `isCollapsed`, `expandedSeparatorLength`, `collapsedSeparatorLengthOverride`, `hasSeenDragHint`, and `showPrimarySeparator` properties with UserDefaults persistence and registered defaults.
  - Updated `restoreDefaults()` to reset the new fields.
- `StatusBar/StatusBarController.swift`
  - Replaced the temporary status item with a square-length control item plus a variable-length primary separator item.
  - Left click toggles hidden items; right click opens the app menu.
  - Wires `HidingService.onStateChange` to refresh separator length, symbols, and menu.
  - Observes `NSApplication.didChangeScreenParametersNotification` and forwards to `HidingService.handleScreenParametersChanged()`.
  - Exposes `expand()`, `collapse()`, `toggle()`, `resetSeparatorLength()`, and `showDragHint()` for the menu.
- `StatusBar/StatusBarMenuBuilder.swift`
  - Expanded the menu with Expand Hidden Items, Collapse Hidden Items, Toggle Hidden Items, Reset Separator Length, Show Drag Hint, Settings..., Show Diagnostics, About, and Quit.
  - Added `refresh(for:)` hook for future state-dependent menu badges.
- `App/AppEnvironment.swift`
  - Constructed `ScreenGeometryService`, `HidingService`, `StatusItemFactory`, `SeparatorController`, and the refactored `StatusBarController`.
  - Wired menu actions for expand/collapse/toggle, reset separator length, and show drag hint.
  - Shows the drag hint on first launch (when `hasSeenDragHint` is false) and records it in diagnostics.
- `docs/architecture/architecture-overview.md`
  - Added Hiding module and refactored StatusBar ownership.
  - Noted Phase 1 status and the permission-free Basic Mode hiding approach.

## Privacy And Permissions

- Basic Mode remains the only implemented mode.
- Phase 1 uses only public `NSStatusItem` behavior. Hiding is achieved by growing a separator item's length so later items are pushed left off the visible menu bar.
- No Accessibility prompt is requested.
- No Screen Recording prompt is requested.
- No Apple Events prompt is requested.
- No Input Monitoring prompt is requested.
- No network feature or dependency was added.

## Verification

- `xcodebuild -scheme MenuBar-Manager -destination 'platform=macOS' build`
  - Result: `BUILD SUCCEEDED`.
  - One harmless warning from `appintentsmetadataprocessor` (no AppIntents dependency) — unaffected.
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - Result: `TEST SUCCEEDED`.
  - Swift Testing unit tests passed:
    - `DiagnosticsLoggerTests/capacityIsAtLeastOne()`
    - `DiagnosticsLoggerTests/ringBufferRetainsLatestEvents()`
    - `SettingsStoreTests/defaultValuesAreRegistered()`
    - `SettingsStoreTests/valuesPersistToUserDefaults()`
    - `SettingsStoreTests/phase1HidingFieldsPersist()`
    - `SettingsStoreTests/collapsedSeparatorOverrideCanBeCleared()`
    - `ScreenGeometryServiceTests/minimumLengthHonouredWhenNoScreens()`
    - `ScreenGeometryServiceTests/collapsedLengthUsesWidestScreen()`
    - `ScreenGeometryServiceTests/collapsedLengthRespectsMinimum()`
    - `ScreenGeometryServiceTests/collapsedLengthRespectsCap()`
    - `HidingServiceTests/defaultsToExpandedWhenStoreIsClean()`
    - `HidingServiceTests/startsFromPersistedCollapsed()`
    - `HidingServiceTests/collapseThenExpandTransitions()`
    - `HidingServiceTests/toggleFlipsStateAndPersists()`
    - `HidingServiceTests/reapplyDoesNotChangeStateButReposts()`
    - `HidingServiceTests/reloadedStoreReflectsPersistedState()`
  - Existing UI launch tests passed (4 tests).

## Notes

- The Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so new Swift files are automatically included in the correct target. No `project.pbxproj` edits were required.
- Out of scope for Phase 1 (to be addressed in later phases): global hotkey, hover reveal, auto-rehide, always-hidden second separator, Accessibility-based icon discovery, search, second bar, and any network/network permission behavior.