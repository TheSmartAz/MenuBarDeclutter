# Automation Roadmap

Phase 8 implements lightweight local automation with a custom URL scheme rather than a full AppleScript dictionary.

## Implemented in Phase 8

The app registers `menubardeclutter://` in `Info.plist` and installs a `kAEGetURL` handler at launch.

Supported commands:

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

## Safety Rules

- URL automation is local-only.
- URL automation does not add network access.
- URL automation does not request Screen Recording, Input Monitoring, or Accessibility by itself.
- URL automation does not run icon moving.
- Applying a profile through URL automation uses the same conservative profile application path as the Settings UI.
- Missing or unknown profiles are logged to Diagnostics and do not crash the app.

## Future AppleScript / Shortcuts Scope

A future phase can add a small scripting dictionary or App Shortcuts layer for:

- applying a profile by name,
- reading the current visibility state,
- expanding/collapsing/reveal-all,
- showing or hiding the Second Bar,
- listing profile names.

Icon moving should remain out of automatic scripting by default. If automation support is ever added for moves, it should require a separate explicit opt-in, confirmation policy, and clear diagnostics.
