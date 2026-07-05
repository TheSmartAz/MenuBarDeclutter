# MenuBarDeclutter Redesign Guidance Pack

Generated: 2026-06-28

This folder contains implementation-reference images for a full frontend redesign of
MenuBarDeclutter. The visual direction is **Clear Glass Control**: native macOS 26
material depth, quiet graphite and white surfaces, crisp SF Pro-style typography,
thin separators, compact controls, and limited semantic color.

## Style Direction

- Use native SwiftUI/AppKit patterns and `NSStatusItem`-appropriate menu behavior.
- Keep Basic Mode visually complete and calm without implying missing permissions.
- Treat Pro Mode as opt-in and permission-gated, with clear degraded states.
- Use blue for active selection, green for privacy-safe Basic Mode, amber for
  experimental or permission-required states, and red only for destructive actions.
- Prefer dense but readable settings and operator surfaces over marketing-style
  hero panels or decorative dashboards.

## Image Index

| File | Surface |
| --- | --- |
| `00-style-board.png` | Shared Clear Glass Control design system: palette, typography, controls, badges, table, empty state, and floating panels. |
| `01-settings-general.png` | Settings -> General: mode, startup, launch-at-login status, layout reset, onboarding, and app metadata. |
| `02-settings-behavior.png` | Settings -> Behavior: auto-rehide, hover reveal, always-hidden zone, separator appearance, click behavior, and global hotkey. |
| `03-settings-search.png` | Settings -> Search: Find Icon controls, search hotkey, and Pro/Accessibility requirements. |
| `04-settings-second-bar.png` | Settings -> Second Bar: feature controls, position, appearance, preview strip, and requirements. |
| `05-settings-profiles.png` | Settings -> Profiles: profile list, editor, dry run/apply actions, and smart triggers. |
| `06-settings-privacy.png` | Settings -> Privacy: Basic Mode permission boundary, optional Pro Mode, Accessibility discovery, and diagnostics export notes. |
| `07-settings-diagnostics.png` | Settings -> Diagnostics: toolbar, health, screens, live status, scanned item table, and event list. |
| `08-settings-advanced.png` | Settings -> Advanced: separator geometry, Labs/Experimental controls, application support, and diagnostics metadata. |
| `09-onboarding-flow.png` | First-run onboarding: welcome, command-drag separator guidance, and privacy explanation. |
| `10-find-icon-panel.png` | Find Icon floating panel: search results, selected state, context menu, footer status, and unavailable permission state. |
| `11-second-bar-panel.png` | Second Bar floating panel: hidden item strip, search, selected item, zone split, footer, and disabled state. |
| `12-drag-hint-popover.png` | Drag hint popover anchored to the menu bar separator. |
| `13-status-menu-guide.png` | Status menu command grouping and native `NSMenu` hierarchy guidance. |

## Implementation Notes

- The images are visual guidance, not generated source code.
- Keep controls close to native SwiftUI defaults, then layer shared spacing,
  badge, sidebar, and section styling where it improves consistency.
- The Diagnostics and Profiles screens should stay information-dense; the redesign
  should clarify hierarchy rather than expanding them into large cards.
- The Search and Second Bar panels should remain compact transient utilities with
  keyboard-first behavior and clear permission unavailable states.
- The status menu should remain a native AppKit menu; use the guide for grouping
  and labels, not for custom menu rendering.

