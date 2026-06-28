# Privacy Boundary

MenuBarDeclutter Alpha RC keeps Basic Mode permission-free and local-only.

## Basic Mode

- Uses public AppKit `NSStatusItem` behavior to expand, collapse, and reveal menu bar items.
- Requires no Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
- Hover reveal polls `NSEvent.mouseLocation` in-process and does not install event taps.
- Global hotkeys use Carbon `RegisterEventHotKey` and do not require Input Monitoring.
- Diagnostics and health reports are exported only after explicit user action.

## Pro Mode

- Pro Mode is opt-in.
- Accessibility is checked without prompting by default.
- The Accessibility prompt appears only after the user explicitly requests permission.
- Find Icon, Second Bar, and explicit icon moving degrade gracefully when Pro Mode, Accessibility Discovery, or permission is missing.
- Icon moving is experimental, disabled by default, Pro-only, and user-triggered.

## Local Data

- Application Support data stays under `Application Support/MenuBarDeclutter/`.
- Profiles and triggers are local JSON.
- Health markers and reports are local files.
- URL automation is local and command-limited to expand, collapse, reveal-all, Second Bar, and apply-profile-by-name commands.

## Exclusions

MenuBarDeclutter does not use ScreenCaptureKit, Screen Recording, Apple Events, Input Monitoring, telemetry, cloud sync, or network access through Phase 9.1.

Diagnostics exports exclude screenshots, screen contents, live search text, selected item identity, personal file paths outside explicit App Support display, and network data.

## Verification

Run:

```sh
scripts/verify_privacy_boundary.sh
```

For a built app bundle:

```sh
APP_PATH=/path/to/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh
```
