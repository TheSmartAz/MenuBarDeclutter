# Placement Planner v0.1.3

Status: Preview, advisory only.

Placement Planner recommends where menu bar items should live without moving items by default.

## v0.1.3 Focus

- Advisory plans call out visible, hidden, always-hidden, and review-later recommendations.
- Item preferences persist locally by hashed item identity.
- New Item Inbox decisions can write Placement Planner preferences.
- Recommendation reasons include user preference, new-item state, hidden/always-hidden state, and confidence signals.
- Handoffs to Assisted Move remain explicit and show dry-run facts before any Experimental attempt.

## Privacy

Placement preferences are stored using hashed item keys. Diagnostics should avoid raw titles, bundle identifiers, selected item IDs, coordinates, screenshots, and query text by default.

## Boundaries

Placement Planner does not claim stable automated moving, bulk movement, or broad activation. Manual Command-drag guidance remains the stable arrangement path.

## Verification

- `Phase14ProductDietTests`
- `IconMovePlanningTests`
- `AppSupportPathsTests`
- `docs/testing/manual-v0.1.3-system-qa.md`
