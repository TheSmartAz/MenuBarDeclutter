# Assisted Move v0.1.3

Status: Experimental.

Assisted Move is an explicit, gated path for testing whether a specific menu bar item can be moved. The preferred v0.1.3 path remains manual macOS Command-drag.

## v0.1.3 Focus

- Dry-run displays source zone, target zone, direction, and risk before any attempt.
- Experimental execution remains opt-in and confirmation-gated.
- System items stay blocked unless the user explicitly enables the relevant Experimental setting.
- Dogfood events record privacy-safe aggregate metadata: source zone, target zone, result, failure category, duration, and redacted item class.
- Failure recovery keeps manual guidance available.

## Privacy

Assisted Move dogfood metadata excludes raw item names, bundle identifiers, coordinates, screenshots, screen contents, selected item IDs, and query text by default.

## Boundaries

Do not claim stable icon moving, bulk moving, or broad third-party activation. Actual movement attempts may fail depending on macOS state, item behavior, app behavior, display layout, and permissions.

## Verification

- `IconMovePlanningTests`
- `Phase14ProductDietTests`
- `docs/testing/manual-qa.md`
- `docs/testing/dogfood/pro-assisted-gate.md`
