# Automation Roadmap

Last reviewed: 2026-07-05

MenuBarDeclutter automation is local and command-gated. It does not add Apple Events control of other apps, Input Monitoring, network access, telemetry, cloud sync, or background icon moving.

## Implemented

The app registers `menubardeclutter://` in `Info.plist` and installs a local URL handler at launch.

Supported URL commands:

- `menubardeclutter://expand`
- `menubardeclutter://collapse`
- `menubardeclutter://reveal-all`
- `menubardeclutter://second-bar`
- `menubardeclutter://profile/<ProfileName>`

Examples:

```sh
open 'menubardeclutter://expand'
open 'menubardeclutter://collapse'
open 'menubardeclutter://profile/Work'
```

App Intents and dynamic hotkeys are also wired through the shared command router where implemented.

## Safety Rules

- Automation is local-only.
- Automation does not add network access.
- Automation does not request Screen Recording, Input Monitoring, Apple Events, or Accessibility by itself.
- Automation does not run Icon Moving.
- Applying a profile through automation uses the same conservative profile path as Settings.
- Missing or unknown profiles are logged to Diagnostics and do not crash the app.
- Global automation pause rejects trigger and URL automation while preserving manual Basic Mode commands.

## Future Scope

Future work can add a small AppleScript dictionary or richer App Shortcuts for:

- Applying a profile by name.
- Reading current visibility state.
- Expanding, collapsing, or reveal-all.
- Showing or hiding app-owned panels.
- Listing profile names.

Icon Moving should remain out of automatic scripting by default. Any automation support for moves would require a separate explicit opt-in, confirmation policy, and diagnostics trail.
