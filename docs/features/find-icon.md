# Find Icon

Find Icon is a private-access surface for locating menu bar items by app name, title, bundle identifier, zone, and recency. The panel is available by default, while real results require macOS Accessibility permission.

## What It Does

- Opens a floating AppKit `NSPanel` with SwiftUI search UI.
- Uses the latest Accessibility discovery snapshot as a local search index.
- Ranks exact app-name matches, exact title matches, prefix matches, contains matches, bundle identifier matches, hidden-zone priority, and recency.
- Supports keyboard navigation with Up, Down, Return, and Escape.
- Reveals hidden zones before highlighting when configured.
- Shows a short-lived transparent highlight overlay around the approximate menu bar item frame.
- Provides an optional Find Icon hotkey, defaulting to Option + Command + F, disabled by default.
- Shows clear unavailable states for missing private-access requirements without showing a separate Find Icon enable page.

## User Flow

1. Open Settings -> Find & Rescue.
2. Use Open Find Icon, or open its detailed settings from the Find Icon card.
3. Grant macOS Accessibility permission if real menu bar metadata is not already available.
4. Open Find Icon from the status menu or optional hotkey.
5. Search by app name, item title, or bundle identifier.
6. Press Return or click a result to reveal and highlight the item.
7. Click the original menu bar item manually if an action is needed.

## Privacy And Permissions

Find Icon requires the Pro Accessibility discovery index. It does not click, drag, activate, request Screen Recording on its own, use the network, or export live query/selected item identity. When Accurate Icons is enabled from Privacy settings, shared local rendered thumbnails can replace app-icon fallbacks.

## Implementation

- `MenuBar-Manager/Search/SearchRootView.swift`
- `MenuBar-Manager/Search/SearchWindowController.swift`
- `MenuBar-Manager/Search/SearchService.swift`
- `MenuBar-Manager/Search/SearchResultRowView.swift`
- `MenuBar-Manager/Search/MenuItemActivator.swift`
- `MenuBar-Manager/Search/HighlightOverlayWindow.swift`
- `MenuBar-Manager/Settings/SearchSettingsView.swift`

## Verification

- `MenuBar-ManagerTests/SearchServiceTests.swift`
- `MenuBar-ManagerTests/HotkeyModelTests.swift`
- UI tests for unavailable states
- Manual QA: `docs/testing/manual-qa.md`

## Known Limitations

- Search quality depends on the latest Accessibility scan.
- Highlighting uses approximate frames and can be stale after movement or display changes.
- Find Icon no longer has a separate app-level enable gate. Real results appear after macOS Accessibility permission is granted and the local discovery index refreshes.
