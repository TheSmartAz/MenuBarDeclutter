Implement Phase 1 — No-Permission Core Hiding MVP.

Context:
Phase 0 created the macOS 26+ project skeleton. Now implement the first real product feature: Basic Mode menu bar hiding using only public AppKit NSStatusItem behavior.

Important:
This phase must not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network permissions.

Tasks:

1. Build StatusBar module.
   Create/modify:
   - StatusBar/StatusBarController.swift
   - StatusBar/StatusItemFactory.swift
   - StatusBar/StatusItemKind.swift
   - StatusBar/SeparatorController.swift
   - StatusBar/StatusBarMenuBuilder.swift

2. Status items.
   StatusBarController should own:
   - controlItem: NSStatusItem with square length.
   - primarySeparatorItem: NSStatusItem with variable length.

   controlItem:
   - left click toggles hidden items.
   - right click opens app menu.
   - use SF Symbol:
     - expanded: "chevron.left" or "eye"
     - collapsed: "chevron.right" or "eye.slash"
   - set accessibility label.

   primarySeparatorItem:
   - visible small separator when expanded.
   - huge width when collapsed.
   - accessibility label: "Hidden items separator".
   - title can be "|" or subtle icon for now.

3. Hiding service.
   Create:
   - Hiding/HidingService.swift
   - Hiding/HidingState.swift
   - Hiding/ScreenGeometryService.swift

   HidingState:
   - expanded
   - collapsed

   HidingService:
   - currentState
   - expand()
   - collapse()
   - toggle()
   - applyState()
   - persist state into SettingsStore
   - notify UI to update control icon/menu labels

4. Screen geometry.
   ScreenGeometryService should provide:
   - widestScreenWidth()
   - recommendedCollapsedSeparatorLength()
   - menuBarBand(for screen:)
   - isPointInAnyMenuBarBand(_ point:)

   Recommended collapsed length:
   - max(widestScreenWidth * 2, 1200)
   - cap at 10000
   - use constants in AppConstants

   Because this app is macOS 26+ only:
   - no old API fallback.
   - still handle multiple NSScreen instances.
   - account for menu bar on primary screen.
   - add TODO for notch-specific refinement.

5. Settings.
   Extend SettingsStore:
   - isCollapsed: Bool
   - expandedSeparatorLength: Double default 20
   - collapsedSeparatorLengthOverride: Double?
   - hasSeenDragHint: Bool
   - showPrimarySeparator: Bool default true

6. Screen changes.
   Observe:
   - NSApplication.didChangeScreenParametersNotification

   Behavior:
   - recompute collapsed length.
   - if currently collapsed, reapply collapsed state.
   - log screen changes.

7. App menu.
   Update StatusBarMenuBuilder:
   - Expand Hidden Items
   - Collapse Hidden Items
   - Toggle Hidden Items
   - Reset Separator Length
   - Show Drag Hint
   - Settings
   - Diagnostics
   - Quit

8. Drag hint.
   Add visible first-run hint:
   - “Hold Command and drag the separator to choose which icons are hidden.”
   - Add menu item to show the hint again.
   - Full onboarding comes later.

9. Tests.
   Add:
   - ScreenGeometryServiceTests
   - HidingServiceTests
   - SettingsStoreTests

   Test:
   - collapsed length uses widest screen.
   - collapsed length minimum/cap.
   - state transition expanded -> collapsed -> expanded.
   - SettingsStore persists isCollapsed.

10. Manual QA.
   Update docs/testing/manual-qa.md:
   - launch app.
   - hold Command and drag separator.
   - move separator to the right of icons to hide.
   - click control item to collapse.
   - verify icons left of separator disappear.
   - click again to expand.
   - restart app and confirm persisted state.
   - test external display if available.
   - test transparent menu bar and menu bar background enabled.

Acceptance criteria:
- User can Command-drag separator.
- Clicking control item toggles expanded/collapsed.
- Collapsed state hides icons left of separator.
- Expanded state restores icons.
- State persists after app relaunch.
- Display changes do not break state.
- No sensitive permission prompt appears.

Out of scope:
- No global hotkey.
- No hover reveal.
- No auto-rehide.
- No always-hidden second separator.
- No Accessibility.
- No search.
- No second bar.