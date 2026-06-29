# Phase 11 Starting Audit

## Build Status
- `xcodebuild -list`: Schemes `MenuBarDeclutter`, `MenuBar-Manager`, `MenuBarFixtureApp`.
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'`: **BUILD SUCCEEDED**

## Existing Modules Audited
1. Search snapshots — `MenuBarItemSnapshot` with stable IDs.
2. Second Bar item derivation — `SecondBarViewModel`.
3. Profiles/ProfileStore — local JSON persistence.
4. Hotkeys/GlobalHotkeyManager — Carbon-based hotkey registration.
5. URL automation — `AutomationURLHandler` with throttling.
6. Settings tabs — General, Behavior, Layout, Search, Second Bar, Profiles, Privacy, Diagnostics, Advanced.
7. Diagnostics export privacy rules — privacy-safe metadata only.
8. Safe Mode behavior — crash markers and expanded launch.
9. Phase 10 Layout module — `LayoutCoordinator` and all services.

## Phase 11 Non-Goals
- No ScreenCaptureKit.
- No screen/pixel capture.
- No AppleScript dictionary.
- No Apple Events.
- No network/cloud sync.
- No telemetry.
- No automatic competitor config scraping.

## Risks
- Private Access depends on LocalAuthentication availability. Mitigated by
  graceful degradation and mock service for tests.
- Group matching may be stale if AX snapshots are old. Mitigated by stale
  snapshot warnings from Phase 10.
- Hotkey conflicts. Mitigated by HotkeyConflictDetector.
- Import may introduce experimental flags. Mitigated by dry-run and
  explicit "import experimental settings" opt-in.
