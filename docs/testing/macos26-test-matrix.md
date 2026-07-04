# macOS 26 Test Matrix

| Area | Scenario | Expected Phase 9 Result |
| --- | --- | --- |
| Launch | First launch on macOS 26.0+ | App runs as an LSUIElement utility with no Dock icon and shows onboarding when appropriate. |
| Launch | Previous crash marker present | App starts in Safe Mode, expanded/reveal-all, with a visible control item and Diagnostics health state. |
| Launch | Safe Mode flag or Option held | Auto-rehide, hover reveal, Pro scans, icon moving, hotkeys, and smart triggers are suppressed for that launch. |
| Basic Mode | Pro Mode disabled | Collapse/expand, auto-rehide, hover reveal, hotkey, Settings, Diagnostics, and Quit remain usable without sensitive permissions. |
| Menu Bar | Standard menu bar | Control item, primary separator, and optional always-hidden separator remain reachable and draggable by the user. |
| Menu Bar | Transparent menu bar | Control, separators, Search, and Second Bar remain legible and usable. |
| Menu Bar | Menu bar background enabled or disabled | Hiding and reveal-all behavior still works. |
| Health | Missing/misplaced status items | Diagnostics reports warning/critical issues and Fix Automatically recreates or resets state. |
| Health | Corrupted settings | Diagnostics reports settings corruption and Reset Basic Mode returns safe defaults. |
| Health | Stale Pro scan | Diagnostics reports stale scan when Pro requirements are enabled and granted. |
| Search | Pro requirements missing | Find Icon shows explanatory unavailable states in a borderless panel and does not prompt automatically. |
| Second Bar | Pro requirements missing | Second Bar shows explanatory unavailable states and Basic Mode continues working. |
| Second Bar | Pro requirements met | Borderless floating panel shows hidden/always-hidden items, remains in visible bounds, and closes with Escape or outside click when enabled. |
| Groups | Group panel | Borderless floating panel shows saved group items and closes with Escape or outside click. |
| Icon Moving | Disabled or permission missing | Move actions are skipped with clear diagnostics and no drag occurs. |
| Icon Moving | Explicit third-party move | User-triggered Command-drag is confirmed, executed, rescanned, and verified or clearly reported as failed. |
| Profiles | Create/apply/import/export | Local JSON profiles persist and apply conservative settings without automatic bulk moves. |
| Smart Triggers | Enabled by user | Display/app/time triggers are debounced, apply selected profiles conservatively, and log diagnostics. |
| Automation | URL scheme | `menubardeclutter://` commands expand/collapse/reveal/show Second Bar/apply profile when the app is registered. |
| Recovery | Sleep/wake | Auto-rehide is paused, geometry/state reapply, optional AX scan refreshes, and health is logged. |
| Recovery | Active Space/fullscreen change | Status items remain coherent and health is logged. |
| Appearance | Light and Dark Mode | Settings, onboarding, Search, Second Bar, and profile UI remain legible. |
| Appearance | Tinted appearance | Settings/Diagnostics controls and Health severity labels remain readable. |
| Accessibility Display | Reduce Transparency | SwiftUI/AppKit panels remain readable without relying on custom transparent effects. |
| Accessibility Display | Increase Contrast | Text, badges, buttons, and selection states remain readable. |
| Displays | Built-in display with notch | Status items and Second Bar placement remain reachable and avoid unusable notch overlap. |
| Displays | External display | Separator lengths, scan classification, Search, Second Bar placement, and triggers handle attach/detach. |
| Stress | 30+ menu bar controls | A visible control item remains recoverable and Fix Automatically leaves the bar usable. |
| Privacy | Basic Mode | No Accessibility, Screen Recording, Apple Events, Input Monitoring, or network prompt appears. |
| Privacy | Pro Mode | Accessibility is requested only from explicit user action; no Screen Recording, Apple Events, Input Monitoring, or network access is introduced. |
| Privacy | Health/Safe Mode | Health report and marker files are local and contain no screenshots, screen contents, network data, or personal file paths. |
| Hardware | Apple Silicon Mac | Primary supported hardware path. |
| Hardware | Intel Mac | Decision pending separate support note. |
