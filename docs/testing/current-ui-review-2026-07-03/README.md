# MenuBarDeclutter Current UI Review

Generated: 2026-07-03

This folder contains screenshots captured from the current `MenuBarDeclutter`
debug build using the app's UI-testing launch switches.

## Verification

- `xcodebuild -list`: succeeded; canonical scheme is `MenuBarDeclutter`.
- `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build`: succeeded.
- Focused UI smoke test attempt:
  `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests/MenuBar_ManagerUITests/testRedesignedSettingsPagesVisualSmoke`
  failed because XCTest timed out while enabling automation mode in this desktop session.

## Captured Surfaces

- Focused Settings sidebar pages: General, Hide & Reveal, Arrange, Find & Rescue, Workspaces, Privacy, Recovery, Advanced.
- Deep Settings pages still reachable by app actions or launch switches: Diagnostics, Behavior, Layout, Menu Bar Items, Search, Second Bar, Groups, Hotkeys, Profiles, Automation, Private Access, Import / Export.
- Floating panels: Find Icon disabled state, Second Bar unavailable state, Group panel.

## Not Screenshot-Captured

- `NSStatusItem` menu: available in source via `StatusBarMenuBuilder`, but not reliably openable from this session without UI automation/Accessibility.
- Onboarding, drag hint popover, and About panel: no dedicated UI-testing launch switch was present.

## Contact Sheets

- `all-ui-contact-sheet.png`
- `focused-settings-contact-sheet.png`
