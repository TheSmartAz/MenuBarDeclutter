# Manual QA

Last reviewed: 2026-07-05

Manual QA is required for behavior that depends on macOS menu bar state, physical displays, installed-app launch behavior, and system privacy prompts.

Allowed results: `PASS`, `FAIL`, `BLOCKED`, `NOT TESTED`, `PARTIAL`.

## Setup

- Confirm the active scheme is `MenuBarDeclutter` with `xcodebuild -list`.
- Prefer an installed app for Launch at Login, URL scheme, and installed privacy checks.
- Record macOS version, hardware, display setup, app version/build, command results, and blockers.
- Keep Basic Mode and Optional Pro/Preview checks separate.

## Basic Mode

| Area | Expected Result |
| --- | --- |
| Launch | App launches as an accessory/menu bar utility with no Dock icon. |
| Status item | Control item and separator items appear and remain reachable. |
| Status menu | Menu opens and exposes Basic commands, Settings, Recovery, Diagnostics, and Quit. |
| Collapse/expand | Control item and menu commands collapse, expand, toggle, and reveal all. |
| Always-hidden | Optional always-hidden separator reveals only through reveal-all behavior. |
| Guided arrange | User can Command-drag separators and icons using normal macOS behavior. |
| Auto-rehide | User-triggered reveal starts a one-shot rehide timer when enabled. |
| Hover reveal | Cursor entering the menu bar band reveals hidden items when enabled. |
| Basic hotkey | Registered hotkey toggles visibility when enabled; no Input Monitoring prompt appears. |
| Launch at Login | Registration/unregistration happens only after explicit user opt-in. |
| Diagnostics export | Export writes `.txt` or `.json` only after user action and excludes sensitive content. |
| Recovery | Reset layout, reset settings, health repair, and Safe Mode remain reachable. |
| Privacy | No Accessibility, Screen Recording, Apple Events, Input Monitoring, or network prompt appears. |

## Optional Pro Discovery

| Area | Expected Result |
| --- | --- |
| Permission status | Accessibility status can be refreshed without prompting. |
| Permission request | Accessibility prompt appears only after explicit request action. |
| Missing permission | Find Icon, Second Bar, placement helpers, groups, and workspace assignment show unavailable/degraded states. |
| Granted permission | Manual refresh reads local menu bar metadata and updates Pro surfaces. |
| Revoked permission | Pro surfaces degrade without breaking Basic Mode. |
| Non-automation | Pro discovery does not click, drag, record the screen, or use the network. |

## Accurate Icons

| Area | Expected Result |
| --- | --- |
| Disabled default | No Screen Recording prompt appears while Accurate Icons is off. |
| Permission request | Screen Recording request is reachable only from explicit Accurate Icons controls. |
| Visible capture | With permission granted, visible menu bar items can show local rendered thumbnails. |
| Missing capture | Hidden, offscreen, notch-hidden, or unavailable items fall back to stale thumbnails or app icons. |
| Cache controls | Thumbnail cache can be refreshed or cleared from Privacy controls. |
| Diagnostics | Diagnostics exports do not include rendered icon thumbnails or screen contents. |

## Workspaces And Preview Panels

| Area | Expected Result |
| --- | --- |
| Workspaces | Workspaces configure app-owned Preview surfaces only; they do not replace the macOS system menu bar. |
| Function Bar | App-owned panel can show enabled workspace actions when Preview gates allow it. |
| Info Strip | App-owned strip can show local status tiles and hand off to Function Bar. |
| Set Builder | Workspace item editing stays local and validates missing references. |
| Groups | Group panels resolve local item references and respect Private Access when configured. |
| Find Icon and Second Bar | Floating panels remain in visible display bounds and close with Escape. |
| Crowded rescue | Fallback choices are clear and do not require physical icon movement. |

## Automation And Private Access

| Area | Expected Result |
| --- | --- |
| URL automation | `menubardeclutter://expand`, `collapse`, `reveal-all`, `second-bar`, and profile commands route through shared gates. |
| App Intents | Shortcuts/App Intents actions route through shared command availability. |
| Automation pause | Pause blocks trigger/URL automation without blocking manual Basic Mode. |
| Profiles | Profiles apply conservative Basic settings and report move requirements instead of running background moves. |
| Dynamic hotkeys | Optional hotkeys register/unregister without Input Monitoring prompts. |
| Private Access | Protected actions require unlock policy and degrade when unavailable. |
| Icon Moving | Experimental moves run only from explicit user action and never from automation. |

## Display And System Behavior

| Area | Expected Result |
| --- | --- |
| Built-in display | Status items, panels, and overlays remain reachable and legible. |
| Notch display | Separators and panels avoid unusable notch placement where possible. |
| External display | Attach/detach recomputes separator length, panel placement, and recovery health. |
| Display scaling | Geometry and placement remain coherent after resolution/scale changes. |
| Sleep/wake | Runtime pauses timers, reapplies geometry, and logs health after wake. |
| Fullscreen/Space changes | Status item state remains coherent after active Space changes. |
| Appearance | Light, dark, increased contrast, reduce transparency, and transparent menu bar remain usable. |

## Release/Installed App

| Area | Expected Result |
| --- | --- |
| Dry-run install | `/Applications/MenuBarDeclutter.app` verifies with expected version/build and bundle identity. |
| Installed launch | Installed app launches and stays running without Developer ID/notarization requirements. |
| URL reuse | URL commands address the installed app process rather than launching duplicates. |
| Installed privacy | Bundle contains only scoped Accurate Icons Screen Recording usage string; no Apple Events/Input Monitoring strings or network entitlements. |
| Network observation | Installed app opens no network sockets during Basic and current Preview smoke tests. |
| Safe Mode | One-shot Safe Mode flag is consumed; Option-launch remains a hands-on check. |
| Gatekeeper | Non-notarized dry-run `spctl` instability is recorded as infra/out-of-scope, not hidden. |

## Current Result Files

- `docs/testing/manual-v0.1.10-results.md`
- `docs/testing/manual-v0.1.10-system-qa.md`
- `docs/testing/manual-v0.1.10-workspaces-qa.md`
- `docs/testing/manual-v0.1.10-panels-display-qa.md`
- `docs/testing/manual-v0.1.10-privacy-qa.md`
- `docs/testing/manual-rendered-icon-capture-qa.md`
