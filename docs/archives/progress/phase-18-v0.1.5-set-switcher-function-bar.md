# Phase 18 Progress - v0.1.5 Set Switcher and Function Bar

Date: 2026-07-02

Implemented in the current v0.1.7 worktree.

Evidence:

- `MenuBar-Manager/FunctionBar/` contains models, runtime controller, resolver, dispatcher, placement, views, and diagnostics.
- `SettingsStore` has Function Bar Preview and primary-click settings; both default off.
- Status menu and Command Center can show/hide/toggle Function Bar behind preview gates.
- `FunctionBarController` owns an app `NSPanel`, suppresses Safe Mode, and refreshes active Workspace items.
- `FunctionBarItemResolver` handles command, group, proxy, spacer, divider, and deferred Info Strip items.

Verification:

- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` passed on 2026-07-02, including 522 app-unit tests across 75 suites and 16 UI tests.
