# Phase 11 Private Access Plan

## Scope

Private Access gates selected app-owned actions with LocalAuthentication. It is
off by default and does not encrypt settings, hide third-party menu bar items
outside MenuBarDeclutter, or request new macOS privacy permissions.

## Protected Resources

- Always-Hidden controls.
- Second Bar access.
- Find Icon reveal/highlight.
- Explicit icon moving.
- Spacing Labs.
- User-created protected groups.

## Runtime Flow

1. User enables Private Access in Settings.
2. A protected action asks `ProtectedActionGate` for access.
3. The gate checks `PrivateAccessPolicy` and the active `UnlockSession`.
4. If needed, `PrivateAccessCoordinator` uses LocalAuthentication.
5. Success opens a time-limited unlock session.
6. Failure returns a degraded result and leaves Basic Mode usable.

## Privacy Rules

- No biometric data is stored.
- Logs may include generic success, failure, cancel, or unavailable status.
- Protected group names and protected hotkey targets are not exported in
  diagnostics.
- Basic Mode remains usable if authentication is unavailable.

## Safe Mode

Safe Mode clears active unlock sessions and keeps Settings, Diagnostics, and
Reset accessible.
