# Basic Behavior Controls

Basic behavior controls are optional enhancements layered on top of Basic Mode hiding. They remain permission-free and are disabled by default where v0.1 safe defaults require caution.

## What It Does

- Auto-rehide can collapse hidden items again after a delay.
- Hover reveal can expand hidden items when the pointer enters a menu bar band.
- Always-hidden mode can install a second separator for items that remain hidden until Reveal All.
- Option-click can toggle Reveal All from the control item.
- Separator visual markers can be shown or hidden without changing separator lengths.
- A global visibility hotkey can toggle hidden items. The default model is Option + Command + B, but the hotkey is disabled by default.

## User Flow

1. Open Settings -> Hide & Reveal.
2. Enable only the controls desired for the current layout.
3. Adjust auto-rehide delay or hover polling interval if those controls are enabled.
4. Use Option-click on the control item to reveal all when that setting is enabled.
5. Enable the global hotkey only after checking for conflicts.

## Privacy And Permissions

These controls do not use event taps and do not require Input Monitoring. Hover reveal reads `NSEvent.mouseLocation` in process. The global hotkey uses Carbon `RegisterEventHotKey`, which does not require Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access for this app.

## Implementation

- `MenuBar-Manager/Settings/BehaviorSettingsView.swift`
- `MenuBar-Manager/Hiding/RehideController.swift`
- `MenuBar-Manager/Hiding/HoverRevealController.swift`
- `MenuBar-Manager/Hiding/HidingVisibilityState.swift`
- `MenuBar-Manager/Hotkeys/GlobalHotkeyManager.swift`
- `MenuBar-Manager/Hotkeys/HotkeyModel.swift`
- `MenuBar-Manager/StatusBar/StatusBarController.swift`

## Verification

- `MenuBar-ManagerTests/RehideControllerTests.swift`
- `MenuBar-ManagerTests/HoverRevealControllerTests.swift`
- `MenuBar-ManagerTests/HotkeyModelTests.swift`
- `MenuBar-ManagerTests/HotkeyCallbackResolverTests.swift`
- `MenuBar-ManagerTests/HidingVisibilityStateTests.swift`
- Manual QA: `docs/testing/manual-qa.md`

## Known Limitations

- Auto-rehide postponement is heuristic when a status item menu is open.
- Hover reveal depends on polling cadence and current screen geometry.
- Hotkey registration can fail if another app already owns the shortcut; failures are logged rather than fatal.
- v0.1 safe defaults keep auto-rehide, hover reveal, hotkey, always-hidden, and Start Collapsed off until the user opts in.
