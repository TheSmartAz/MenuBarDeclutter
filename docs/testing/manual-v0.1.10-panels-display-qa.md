# Manual QA - v0.1.10 Panels and Display

Status: recorded. App-owned panel smoke tests passed; physical external-display coverage is blocked in this local session.

Run date: 2026-07-03

App build: v0.1.10 build 11

Environment:

- Hardware: MacBook Pro, Mac16,7, Apple M4 Pro, 48 GB memory.
- macOS: 26.1 build 25B78.
- Installed app: `/Applications/MenuBarDeclutter.app`.

| Area | Result | Notes |
| --- | --- | --- |
| Show Function Bar from Workspaces settings | PARTIAL | Function Bar model/runtime/unit coverage passed and Workspaces visual smoke passed, but hands-on clicking the Workspaces toggle to show the live Function Bar panel was not performed. |
| Show Info Strip from Workspaces settings | PARTIAL | Info Strip provider, timing, diagnostics, and Workspaces unit coverage passed, but hands-on clicking the Workspaces toggle to show the live Info Strip panel was not performed. |
| Confirm panels are app-owned and dismiss cleanly | PASS | `testFloatingPanelsVisualSmoke` passed for Find Icon and Second Bar unavailable panel; `testSearchPanelEscapeDismisses` passed. No Screen Recording or system menu bar control was introduced. |
| Available display/notch coverage | PARTIAL | Local built-in MacBook Pro display was used by UI screenshots. Unit test coverage includes modeled notch avoidance, but hands-on notch edge placement was not performed. |
| External display coverage | BLOCKED | No external display was available in this local session. |
