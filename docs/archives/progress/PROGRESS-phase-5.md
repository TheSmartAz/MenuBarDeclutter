# Progress: Phase 5

Status: implemented.

Historical snapshot: this file records the end-of-phase state for Phase 5. Later progress files, `docs/project-summary.md`, and release docs supersede old scheme names, test counts, defaults, and deferred-scope notes.

## Tech Stack

- Swift 6 with app declarations isolated to `MainActor`.
- Native macOS 26.0+.
- AppKit for `NSPanel`, transparent overlay windows, `NSWorkspace` app icon lookup, and named Carbon global hotkeys.
- SwiftUI for the Find Icon panel and Settings → Search section.
- Swift Testing for pure search ranking coverage.

## Added

- `Search/SearchService.swift`: pure ranking service over `MenuBarItemSnapshot` values. Supports exact app-name matches, exact title matches, prefix matches, fuzzy contains, bundle identifier matches, hidden-zone boosts, and empty-query recent ordering.
- `Search/SearchWindowController.swift`: floating centered `NSPanel` hosting the SwiftUI search UI.
- `Search/SearchRootView.swift`: focused search field, result list, keyboard navigation, permission-gated explanatory states, and activation footer messaging.
- `Search/SearchResultRowView.swift`: result row with app icon, app/title metadata, zone, match reason, and last-seen timestamp.
- `Search/MenuItemActivator.swift`: non-clicking selection behavior. Reveals hidden / always-hidden zones when configured, highlights approximate frames, and records activation outcomes.
- `Search/HighlightOverlayWindow.swift`: transparent borderless highlight overlay that ignores mouse events and auto-dismisses after two seconds.
- `Settings/SearchSettingsView.swift`: Find Icon enablement, reveal/highlight toggles, optional disabled-by-default Find Icon hotkey, and requirement status rows.
- `MenuBar-ManagerTests/SearchServiceTests.swift`: coverage for exact matching, prefix matching, bundle id matching, hidden item priority, and empty-query recent ordering.
- `docs/progress/PROGRESS-phase-5.md`: this progress log.

## Modified

- `Hotkeys/GlobalHotkeyManager.swift`: refactored from one active hotkey to named registrations. Existing visibility-toggle API remains, while Phase 5 adds a separate Find Icon registration.
- `App/AppEnvironment.swift`: owns search services, presents Find Icon, refreshes the AX index before opening search, toggles Pro Mode from the status menu, and registers/unregisters the Find Icon hotkey.
- `StatusBar/StatusBarMenuBuilder.swift`: added "Find Icon...", "Refresh Menu Bar Items", and dynamic Enable/Disable Pro Mode menu commands.
- `Core/SettingsStore.swift`: added `searchEnabled`, `searchHotkeyEnabled`, stored search hotkey fields, `searchRevealOnSelection`, `searchHighlightOnSelection`, defaults, restore-default handling, and hotkey helpers.
- `App/AppConstants.swift`: added default Find Icon hotkey constants (`Option+Command+F`).
- `Core/LiveDiagnosticsStatus.swift`: added Find Icon hotkey registration, search index count, last query, last selected item, and activation outcome.
- `Accessibility/MenuBarScanCoordinator.swift`: keeps search index item count synchronized with the latest scan state.
- `Settings/SettingsRootView.swift` and `Settings/SettingsWindowController.swift`: added the Search settings section and callback plumbing.
- `Settings/DiagnosticsSettingsView.swift`: added live search diagnostics rows.
- `Core/DiagnosticsExporter.swift`: includes Phase 5 search settings in privacy-safe exports while excluding live query and selected-item identities.
- `MenuBar-ManagerTests/HotkeyModelTests.swift`: added default Find Icon hotkey coverage.
- `docs/architecture/architecture-overview.md`: documented Phase 5 services, UI, diagnostics, hotkeys, and privacy boundary.
- `docs/project-summary.md`: updated through Phase 5.
- `docs/testing/manual-qa.md`: added Phase 5 manual QA.

## Privacy And Permissions

- Basic Mode remains fully usable without Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
- Find Icon is a Pro surface and only searches when Pro Mode, Accessibility Discovery, and granted Accessibility permission are all available.
- Missing permission shows an explanatory panel with explicit user actions; it does not request permission automatically on open.
- Selecting search results never simulates click, drag, activation, or icon movement.
- Highlighting uses a transparent AppKit overlay window only. It does not capture screenshots, sample pixels, use ScreenCaptureKit, or request Screen Recording.
- Diagnostics export records search settings but does not export live search query or selected item identity.

## Verification

- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - First Phase 5 run result: build failed because `SearchResultRowView` used the `UTType.application` fallback icon without importing `UniformTypeIdentifiers`.
  - Fix: imported `UniformTypeIdentifiers`.
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
  - Final result: `TEST SUCCEEDED`.
  - Passing Phase 5 tests include:
    - `SearchServiceTests/exactAppNameMatchRanksFirst()`
    - `SearchServiceTests/prefixMatchFindsAppOrTitle()`
    - `SearchServiceTests/bundleIdentifierContainsMatchFindsItem()`
    - `SearchServiceTests/hiddenItemsRankAboveVisibleItemsForSameMatch()`
    - `SearchServiceTests/emptyQueryReturnsRecentItems()`
    - `HotkeyModelTests/searchHotkeyDefaultsToOptionCommandFAndIsDisabled()`

## Notes

- The project still uses `PBXFileSystemSynchronizedRootGroup`, so new Swift files under `MenuBar-Manager/` and `MenuBar-ManagerTests/` were picked up by the app/test targets without manual target-membership edits.
- The checkout's git index currently tracks only the original template files while the implemented app sources/docs are untracked; Phase 5 work was added within the existing untracked synchronized source/test/doc directories without reverting unrelated changes.
- Out of scope for Phase 5 remains unchanged: no second bar, no CGEvent clicking/dragging, no ScreenCaptureKit, and no automated icon activation.
