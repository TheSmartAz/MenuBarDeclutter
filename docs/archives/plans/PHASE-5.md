Implement Phase 5 — Find Icon / Icon Panel.

Context:
Phase 4 added optional Accessibility-based menu bar item discovery. Now build a user-facing Find Icon feature.

Tasks:

1. Search module.
   Create:
   - Search/SearchService.swift
   - Search/SearchWindowController.swift
   - Search/SearchRootView.swift
   - Search/SearchResultRowView.swift
   - Search/MenuItemActivator.swift
   - Search/HighlightOverlayWindow.swift

2. SearchService.
   Input:
   - latest MenuBarItemSnapshot list.
   - query string.

   Output:
   - ranked search results.

   Ranking:
   - exact app name match.
   - prefix match.
   - fuzzy contains.
   - bundle id contains.
   - zone priority optional:
     - hidden and alwaysHidden can rank higher because user likely searches missing items.

3. Search UI.
   Use NSPanel + SwiftUI:
   - floating centered panel.
   - search field focused on open.
   - list results.
   - keyboard navigation:
     - up/down
     - enter
     - escape
   - show:
     - app icon if available from NSRunningApplication or bundle.
     - app name.
     - title/description.
     - zone.
     - last seen timestamp.

4. Open behavior.
   Create MenuItemActivator:
   - If item is visible:
     - move mouse/click is NOT implemented yet unless safe.
     - Instead highlight item and instruct user to click.
   - If item is hidden:
     - temporarily reveal hidden items.
     - highlight approximate frame.
     - allow user to click manually.
   - If alwaysHidden:
     - reveal all.
     - highlight approximate frame.
   - Do not automate clicking yet.

5. Highlight overlay.
   HighlightOverlayWindow:
   - borderless transparent window.
   - draw rounded rectangle around item frame.
   - auto-dismiss after 2 seconds.
   - handle multiple screens.
   - do not capture screen.

6. Status item menu.
   Add:
   - Find Icon...
   - Refresh Menu Bar Items
   - Enable/Disable Pro Mode

7. Hotkey.
   Add optional search hotkey setting:
   - default disabled.
   - suggested Option + Command + Space or Option + Command + F.
   - reuse GlobalHotkeyManager if it supports multiple hotkeys.
   - If not, refactor it to support multiple registrations.

8. Settings UI.
   Add Search section:
   - Enable Find Icon.
   - Search hotkey.
   - Reveal item when selected.
   - Highlight selected item.

9. Diagnostics.
   Show:
   - latest search index item count.
   - last query.
   - last selected item.
   - activation outcome.

10. Tests.
   Add:
   - SearchServiceTests.

   Test:
   - exact matching.
   - prefix matching.
   - bundle id matching.
   - hidden item priority.
   - empty query returns recent/common items.

11. Manual QA.
   Add:
   - open search.
   - type app name.
   - navigate results.
   - select visible item.
   - select hidden item.
   - select always-hidden item.
   - verify reveal + highlight.
   - verify no crash if Accessibility revoked.

Acceptance criteria:
- User can search menu bar items by name/title/bundle id.
- Selecting hidden item reveals relevant section.
- Highlight overlay points to approximate item frame.
- Search works only when Pro Mode + Accessibility permission are available.
- Without permission, UI explains how to enable Pro Mode.
- No automated clicking yet.

Out of scope:
- No second bar.
- No CGEvent clicking/dragging.
- No ScreenCaptureKit.