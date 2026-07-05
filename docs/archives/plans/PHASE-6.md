Implement Phase 6 — Second Menu Bar / Floating Bar.

Context:
Phase 5 added search. Now add a second bar / floating bar that displays hidden and always-hidden menu bar items using Accessibility snapshots and app icons.

Important:
Do not use ScreenCaptureKit yet.
Use NSRunningApplication icons or bundle icons instead of pixel-capturing real menu bar icons.

Tasks:

1. SecondBar module.
   Create:
   - SecondBar/SecondBarWindowController.swift
   - SecondBar/SecondBarRootView.swift
   - SecondBar/SecondBarItemView.swift
   - SecondBar/SecondBarPositioningService.swift
   - SecondBar/SecondBarViewModel.swift

2. Window behavior.
   Use NSPanel:
   - borderless or utility-style panel.
   - floats below menu bar.
   - does not activate app unnecessarily.
   - closes on escape.
   - closes when user clicks outside if setting enabled.
   - supports keyboard navigation.

3. Positioning.
   SecondBarPositioningService:
   - choose active screen based on mouse location or menu bar screen.
   - position below menu bar.
   - avoid notch region if possible.
   - keep inside visible frame.
   - handle external displays.
   - handle screen changes.

4. Content.
   Display:
   - hidden items.
   - always-hidden items optionally separated.
   - app icon from NSRunningApplication or bundle.
   - app name.
   - item title if available.
   - zone badge.

5. Interactions.
   On item click:
   - reveal relevant section in original menu bar.
   - show highlight overlay.
   - optionally bring owning app to front if user setting enabled.
   - do not automate clicking original menu yet.

6. Status item menu.
   Add:
   - Show Second Bar
   - Hide Second Bar
   - Toggle Second Bar

7. Settings.
   Add Second Bar section:
   - Enable Second Bar.
   - Show hidden items.
   - Show always-hidden items.
   - Auto-close after selection.
   - Position: below menu bar / near mouse / last position.
   - Icon size.
   - Show labels.

8. Styling for macOS 26.
   - Avoid overusing custom glass effects.
   - Ensure text contrast on Liquid Glass background.
   - Respect Reduce Transparency and Increase Contrast.
   - Use system materials only where readable.

9. Diagnostics.
   Show:
   - second bar visible.
   - item count.
   - current screen.
   - last position.
   - last selected item.

10. Tests.
   Add:
   - SecondBarPositioningServiceTests.

   Test:
   - panel stays within screen bounds.
   - panel below menu bar.
   - fallback when screen missing.
   - notch avoidance logic if modeled.

11. Manual QA.
   Add:
   - show/hide second bar.
   - select hidden item.
   - select always-hidden item.
   - external display.
   - notch display.
   - transparent menu bar.
   - reduce transparency.
   - increase contrast.
   - full screen app behavior.

Acceptance criteria:
- User can open a second bar showing hidden items.
- Items can be searched/selected from second bar.
- Selecting an item reveals/highlights original item.
- Works on macOS 26+ with transparent menu bar.
- Does not require Screen Recording.
- Basic Mode still works when Pro Mode disabled.

Out of scope:
- No automatic clicking.
- No programmatic icon moving.
- No pixel-perfect captured menu bar icons.