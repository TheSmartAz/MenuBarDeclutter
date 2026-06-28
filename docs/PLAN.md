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

## Future Phases

- Phase 4+: Optional Pro capabilities behind explicit opt-in (Accessibility-based icon discovery, search, second bar, profiles, hardening). Pro Mode degrades to Basic Mode when permissions are missing.

## Product Principles

- Basic Mode must not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
- System integration must use public APIs only.
- Pure logic should stay testable outside AppKit and SwiftUI.
- Manual QA must cover menu bar, display, permission, and launch behavior that cannot be unit tested reliably.
