# Privacy Boundary

Last reviewed: 2026-07-06

MenuBarDeclutter is local-first. Basic Mode is permission-free. Optional Pro and Preview features are separately gated and must degrade without breaking Basic Mode.

## Basic Mode

Basic Mode includes:

- Expand, collapse, toggle, reveal all, and always-hidden reveal.
- App-owned `NSStatusItem` control and separator behavior.
- Auto-rehide, hover reveal, separator visuals, and Basic visibility hotkey.
- Guided Manual Arrange through normal macOS Command-drag.
- Launch at Login after explicit user opt-in.
- Diagnostics export, backup/restore, health, recovery, Safe Mode, reset layout, and reset settings.

Basic Mode does not request or require:

- Accessibility
- Screen Recording
- Apple Events
- Input Monitoring
- Network access
- Telemetry, analytics, cloud sync, crash upload, remote config, or update checks
- ScreenCaptureKit

## Optional Pro Discovery

Pro Accessibility Discovery is opt-in and read-only.

- Accessibility status checks do not prompt by default.
- The system Accessibility prompt appears only after an explicit user action.
- Scans run only when Pro Mode, Accessibility Discovery, and Accessibility permission are all enabled.
- Discovery reads public Accessibility metadata such as labels, ownership, frames, and roles.
- Discovery does not click, drag, activate third-party items, record the screen, use private APIs, or use the network.

If permission is denied, revoked, or unavailable, Find Icon, Second Bar, placement helpers, groups, workspace assignment, and diagnostics show unavailable or degraded states. Basic Mode remains usable.

## Accurate Icons

Accurate Icons is a separate Preview capability for local rendered thumbnails.

- It is off by default.
- It can request Screen Recording only from explicit Accurate Icons controls.
- It uses public ScreenCaptureKit visible-region capture only after Screen Recording is already granted.
- It crops small thumbnails for currently visible menu bar items and stores them locally.
- It does not capture offscreen/private menu bar items, use private APIs, use Apple Events, use Input Monitoring, or use network access.

If Screen Recording is missing or revoked, most UI surfaces fall back to stale thumbnails or app icons. Pro Second Bar compact/status-menu entry is stricter and stays unavailable until Accurate Icons and Screen Recording are ready. Basic Mode and Pro metadata discovery continue according to their own gates.

## Automation

Local automation routes through the same command gates as manual UI.

- `menubardeclutter://` URL commands are local commands addressed to this app.
- App Intents and dynamic hotkeys route through `MenuBarCommandRouter`.
- Automation pause stops smart trigger and URL-command execution without blocking manual Basic Mode commands.
- Profiles apply conservative Basic settings and report move requirements instead of silently running bulk icon moves.
- Experimental Icon Moving is user-triggered only and must not run from launch, wake, profiles, triggers, URL automation, or App Intents.

## Local Data

Local data stays under UserDefaults and `Application Support/MenuBarDeclutter/`.

Stored data can include:

- Settings
- Diagnostics exports explicitly written by the user
- Profiles, triggers, workspaces, groups, hotkeys, and import/export backups
- Dogfood runs and notes when Dogfood Mode is enabled
- Accurate Icons thumbnail cache when that feature is enabled
- Safe Mode and health marker files

Diagnostics exports exclude screenshots, screen contents, rendered icon thumbnails, live search text, selected item identity, network data, and sensitive personal file paths by default.

## Verification

Source/privacy verification:

```sh
scripts/verify_privacy_boundary.sh
```

Installed bundle verification:

```sh
APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh
```

Installed smoke:

```sh
scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app
```
