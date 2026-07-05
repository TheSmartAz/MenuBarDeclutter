# macOS 26 Test Matrix

Last reviewed: 2026-07-05

| Area | Scenario | Expected v0.1.10 Result |
| --- | --- | --- |
| Launch | First launch on macOS 26.0+ | App runs as an LSUIElement/accessory utility with no Dock icon and shows onboarding when appropriate. |
| Launch | Previous crash marker present | App starts in Safe Mode, expanded/reveal-all, with Basic controls and Recovery reachable. |
| Launch | Safe Mode flag or Option held | Auto-rehide, hover reveal, Pro scans, icon moving, hotkeys, and triggers are suppressed for that launch. |
| Basic Mode | Pro disabled or permission missing | Collapse/expand, reveal all, Settings, Diagnostics, Recovery, and Quit remain usable. |
| Menu Bar | Standard menu bar | Control item, primary separator, and optional always-hidden separator remain reachable and user-draggable. |
| Menu Bar | Transparent or auto-hidden menu bar | Basic hiding and panel surfaces remain legible and usable. |
| Guided Arrange | Command-drag placement | User can place separators/icons manually through normal macOS behavior. |
| Health | Missing status items or invalid geometry | Diagnostics reports issues and recovery can recreate/reset state. |
| Health | Corrupted settings | Safe defaults and reset flows keep Basic Mode reachable. |
| Find Icon | Pro requirements missing | Unavailable state explains requirements and does not prompt automatically. |
| Find Icon | Pro requirements met | Search uses local Accessibility snapshots and non-clicking reveal/highlight actions. |
| Second Bar | Pro requirements missing | Unavailable state explains requirements and Basic Mode continues working. |
| Second Bar | Pro requirements met | Floating panel shows hidden/always-hidden items, remains in visible bounds, and closes cleanly. |
| Accurate Icons | Disabled or permission missing | No Screen Recording prompt appears; app-icon/stale-thumbnail fallbacks are used. |
| Accurate Icons | Explicitly enabled and granted | Visible menu bar items can use locally cached rendered thumbnails. |
| Workspaces | Preview enabled | Workspaces configure app-owned Function Bar, Set Builder, Info Strip, and local assignments only. |
| Function Bar | Preview gates enabled | App-owned panel shows workspace actions and routes commands through shared gates. |
| Info Strip | Preview gates enabled | App-owned strip shows local tiles without Screen Recording, network widgets, or notification scraping. |
| Groups | Group panel | App-owned panel resolves saved local references and respects protected group policy. |
| Icon Moving | Disabled or permission missing | Move actions are skipped with diagnostics and no drag occurs. |
| Icon Moving | Explicit move | Experimental Command-drag attempt is confirmed, run once, verified, and reported. |
| Profiles | Create/apply/import/export | Local JSON profiles persist and apply conservative settings without background bulk moves. |
| Smart Triggers | Enabled by user | Display/app/time triggers are debounced, gated, and paused by global automation pause. |
| Automation | URL scheme/App Intents | Commands route through `MenuBarCommandRouter` and do not bypass gates. |
| Recovery | Sleep/wake | Timers pause, geometry reapplies, optional scans refresh only when already allowed, and health logs. |
| Recovery | Active Space/fullscreen change | Status item state remains coherent and health is logged. |
| Appearance | Light/Dark/contrast/transparency | Settings, onboarding, panels, badges, and diagnostics remain readable. |
| Displays | Built-in notch display | Status items and panels avoid unusable notch overlap where possible. |
| Displays | External display | Separator lengths, scan classification, panel placement, and triggers handle attach/detach. |
| Stress | 30+ menu bar controls | A visible control item remains recoverable and recovery leaves the bar usable. |
| Privacy | Basic Mode | No Accessibility, Screen Recording, Apple Events, Input Monitoring, network, telemetry, or ScreenCaptureKit use. |
| Privacy | Optional Pro Discovery | Accessibility is requested only from explicit user action and degrades cleanly when missing. |
| Privacy | Accurate Icons | Screen Recording is scoped to explicit Accurate Icons controls and local visible thumbnail capture. |
| Privacy | Health/Diagnostics | Reports and exports stay local and exclude screenshots, screen contents, thumbnails, search text, selected identity, network data, and sensitive paths. |
| Hardware | Apple Silicon Mac | Primary supported hardware path. |
| Hardware | Intel Mac | Not claimed without a separate support decision and QA pass. |
