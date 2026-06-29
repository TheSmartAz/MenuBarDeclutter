# URL Automation

URL automation is the implemented lightweight automation surface for local commands. It uses the registered `menubardeclutter://` scheme and remains intentionally small.

## What It Does

- Registers the `menubardeclutter` URL scheme in the app Info.plist.
- Handles local URL commands through an Apple Event URL handler.
- Supports:
  - `menubardeclutter://expand`
  - `menubardeclutter://collapse`
  - `menubardeclutter://reveal-all`
  - `menubardeclutter://revealAll`
  - `menubardeclutter://second-bar`
  - `menubardeclutter://show-second-bar`
  - `menubardeclutter://profile/<ProfileName>`
- Rate-limits repeated commands.
- Rejects commands while global automation is paused.
- Logs accepted and rejected commands in Diagnostics.

## User Flow

1. Configure profiles if profile automation is needed.
2. Resume automation if global automation is paused.
3. Open a supported `menubardeclutter://` URL locally.
4. Check Diagnostics for success or rejection details.

## Privacy And Permissions

URL automation is local and command-limited. It does not add a scripting dictionary, Apple Events permission prompt, network access, telemetry, cloud sync, hidden icon moves, or background Pro automation.

## Implementation

- `MenuBar-Manager/Profiles/AutomationURLHandler.swift`
- `MenuBar-Manager/Profiles/ProfileAutomationCoordinator.swift`
- `Config/MenuBarDeclutter-Info.plist`
- `docs/automation-roadmap.md`

## Verification

- `MenuBar-ManagerTests/AutomationURLHandlerTests.swift`
- Release verification checks the URL scheme.
- Manual QA: `docs/testing/manual-qa.md`

## Known Limitations

- The command set is deliberately narrow.
- URL automation is blocked while automation is paused.
- AppleScript dictionary and richer Shortcuts support are future work and require a separate privacy review.
