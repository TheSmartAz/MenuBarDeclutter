# Automation v0.1.1

Status: Preview.

Automation includes App Intents and the local `menubardeclutter://` URL scheme. It does not use Apple Events scripting dictionaries, network access, telemetry, cloud sync, or remote config.

## Implemented

- App Intents and URL routes construct `MenuBarCommand` values and route through Command Center.
- Gates for Safe Mode, automation pause, App Intents enablement, profile automation opt-in, Labs automation opt-in, Pro, Accessibility, Labs, and Private Access.
- App Intent results now return user-facing dialog messages for success, blocked, permission, Labs, Pro, Private Access, pause, and Safe Mode outcomes.
- v0.1.3 adds Show Find Icon to the basic Shortcuts surface and shows Pro Discovery / feature gates in Automation settings.
- Spacing automation is named and exposed as preview-only while global apply remains deferred.

## Deferred

- Rich App Intent entities for selecting profiles/groups/items by name.
- Full Shortcuts manual QA on a release-signed app.
- A separate URL automation enable toggle beyond existing command and pause gates.
