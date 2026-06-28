# MenuBarDeclutter Plan

MenuBarDeclutter is a native macOS 26.0+ menu bar decluttering utility. The project starts with a privacy-first Basic Mode that uses public AppKit `NSStatusItem` behavior and SwiftUI settings surfaces, then layers opt-in Pro features only after explicit permission boundaries are designed.

## Phase 0: Bootstrap

Status: implemented.

- Native SwiftUI app lifecycle with an AppKit delegate.
- LSUIElement menu bar utility baseline.
- Temporary status item with Settings, Diagnostics, About, and Quit commands.
- SwiftUI settings skeleton for General, Privacy, and Diagnostics.
- UserDefaults-backed settings store.
- In-memory diagnostics logger.
- Documentation, scripts, and unit tests for pure logic.

## Phase 1: No-Permission Core Hiding MVP

Status: implemented.

- Square-length control item (`NSStatusItem`) and variable-length separator, with SF Symbol chevrons and accessibility labels.
- `HidingService`/`ScreenGeometryService`/`SeparatorController` for `max(width * 2, 1200)` capped at `10000` collapsed length; persistence of `isCollapsed`; screen-parameters-change observer.
- First-run drag hint, menu actions (Expand/Collapse/Toggle/Reset Separator Length/Settings/Diagnostics/About/Quit), and manual QA.

## Phase 2: Basic UX Polish

Status: implemented.

- `HidingVisibilityState` (collapsed / expanded / revealAll) and per-separator state.
- Auto-rehide (one-shot `RehideController` with postponement heuristics).
- Hover reveal (`HoverRevealController` polling `NSEvent.mouseLocation`).
- Optional always-hidden separator.
- Global hotkey (Carbon `RegisterEventHotKey`, default Option+Command+B), no Input Monitoring required.
- Option-click reveal all.
- Separator visuals toggle.

## Phase 3: Settings, Onboarding, Launch at Login, Diagnostics Export

Status: implemented.

- Full Settings UI: General, Behavior, Privacy, Diagnostics, Advanced (new tab).
- First-run Onboarding (SwiftUI paged flow in an AppKit window) with `hasCompletedOnboarding` gating and "Show Onboarding Again" from Settings.
- Launch at Login via `SMAppService.mainApp` (ServiceManagement); never auto-enabled; errors surfaced in Diagnostics.
- Privacy-safe Diagnostics export to `.txt`/`.json` (excludes screenshots, screen contents, personal paths, network data).
- Application Support directory tree (`Diagnostics/`, `Profiles/`, `Backups/`) created lazily.
- App version, marketing version, and build number metadata in Settings.
- Reset App Layout and Reset All Settings actions.
- macOS 26-friendly Settings styling (light/dark, increased contrast, reduce transparency, no custom transparent effects).
- `scripts/notarize_template.sh` and an expanded `docs/release-checklist.md`.
- Manual QA + unit tests for the new pure logic.

## Phase 4-9: Pro Features And Hardening

Status: implemented.

- Opt-in Accessibility discovery, Find Icon, Second Bar, explicit icon moving, profiles, smart triggers, URL automation, health checks, recovery, Safe Mode, and macOS 26 hardening.
- Basic Mode remains fully usable with Pro Mode disabled or permission unavailable.
- Icon moving is disabled by default and only runs after explicit user action.
- Profiles apply conservative Basic settings and never silently run bulk icon moves.

## Phase 9.1: Alpha RC Validation And Release Hardening

Status: implemented.

- Canonical shared scheme: `MenuBarDeclutter`.
- Deprecated compatibility scheme retained: `MenuBar-Manager`.
- Privacy boundary verification script and docs.
- Alpha QA matrix, run template, known-risk docs, and release checklist.
- Settings now labels risky Pro surfaces as experimental and provides global Pause All Automation.
- Diagnostics now includes category/severity filters, copy-selected event, filtered export, experimental state, automation pause state, and Launch at Login status.
- Launch at Login settings now show `SMAppService` status and provide an Open Login Items Settings recovery action.

## Future Phases

- Phase 10 visual capture research remains postponed. No ScreenCaptureKit,
  Screen Recording, Apple Events, Input Monitoring, or network access should be
  added without a separate opt-in privacy/design review.

## Product Principles

- Basic Mode must not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
- System integration must use public APIs only.
- Pure logic should stay testable outside AppKit and SwiftUI.
- Manual QA must cover menu bar, display, permission, and launch behavior that cannot be unit tested reliably.
