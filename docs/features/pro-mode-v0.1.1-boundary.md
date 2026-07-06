# Pro Mode v0.1.1 Boundary

Pro Mode is optional in `v0.1.1`.

## Gates

Permission-dependent Pro features require:

- Pro Mode enabled.
- Accessibility Discovery enabled when metadata is needed.
- macOS Accessibility permission granted.
- Feature-specific setting enabled.
- Safe Mode inactive.

The Accessibility permission prompt must appear only after explicit user action.

Some later Pro surfaces have additional explicit gates. Pro Second Bar compact/status-menu readiness also requires Accurate Icons to be enabled and Screen Recording to be granted through the separate Accurate Icons permission path. Pro Mode alone must still never request Screen Recording.

## Allowed Pro Behavior

Allowed after gates are satisfied:

- Read Accessibility metadata such as roles, titles, descriptions, identifiers, process IDs, frames, ownership metadata, and children.
- Build local search, Second Bar, group, profile, and layout estimates from metadata.
- Execute explicit, user-initiated Icon Moving only when Experimental gates pass.

## Not Allowed

Pro Mode must not:

- Request Screen Recording.
- Use ScreenCaptureKit.
- Use Apple Events.
- Use Input Monitoring.
- Use network telemetry, analytics, crash upload, cloud sync, or remote config.
- Use private menu bar APIs.
- Hide already-visible third-party menu bar items through Private Access claims.
