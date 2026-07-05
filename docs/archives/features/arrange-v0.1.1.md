# Arrange v0.1.1

Status: Stable for Guided Manual Arrange, Preview for Placement Planner, Experimental for Assisted Move.

Arrange is the normal icon-placement workflow in `v0.1.1`. It keeps placement important without making automated movement look stable.

## Layers

| Layer | Status | Permission Model |
| --- | --- | --- |
| Guided Manual Arrange | Stable | Basic Mode, no Accessibility, no automation. |
| Placement Planner | Preview | Pro Mode, Accessibility Discovery, and Accessibility permission. |
| Assisted Move | Experimental | Pro gates plus Icon Moving enablement and explicit confirmation. |

## Implemented

- Settings -> Arrange page with a SwiftUI-owned diagram.
- Command-drag steps for the control item, primary separator, hidden side, optional always-hidden side, collapse/reveal test, and reset.
- Basic placement test actions: expand, collapse, reveal all, reset layout, and drag hint.
- Pro Placement Planner entry that reads the latest local Accessibility metadata when gates are satisfied and produces manual instructions only.
- Placement Planner rows with local new/favorite indicators, reviewed marks, suggested zone, and command hooks for highlight, Second Bar, owning app, group creation, and Assisted Move dry-run.
- Assisted Move subflow that clearly labels automated movement as Experimental, requires dry-run plus first-use and per-move confirmations, reuses the existing moving service after confirmation, and shows recovery actions after failures.
- Recovery link for users who cannot find the control item.
- Status menu route: Arrange Items...

## Boundaries

Arrange must not:

- request Accessibility during the stable manual flow
- use Screen Recording or ScreenCaptureKit
- capture screenshots or pixels
- control third-party menu extras through private APIs
- make bulk icon movement stable
- hide recovery behind Advanced

## Primary Files

- `MenuBar-Manager/Settings/ArrangeSettingsView.swift`
- `MenuBar-Manager/Arrange/ArrangeStep.swift`
- `MenuBar-Manager/Arrange/PlacementPlanner.swift`
- `MenuBar-Manager/Arrange/AssistedMoveGate.swift`
- `MenuBar-Manager/Arrange/AssistedMoveViewModel.swift`
- `MenuBar-Manager/Arrange/AssistedMoveIntroView.swift`
- `MenuBar-Manager/Arrange/AssistedMoveDryRunView.swift`
- `MenuBar-Manager/Arrange/AssistedMoveConfirmationView.swift`
- `MenuBar-Manager/Arrange/AssistedMoveResultView.swift`
- `MenuBar-Manager/Arrange/NewMenuBarItemInbox.swift`
