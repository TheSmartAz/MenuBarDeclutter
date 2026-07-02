# New Item Inbox v0.1.3

Status: Preview.

New Item Inbox helps users answer: "A new app added a menu bar item. Where did it go, and should it stay visible?"

## v0.1.3 Polish

- Detection stores privacy-safe exact and stable review hashes so renamed or moved items do not repeatedly appear as new.
- Dismissed items stay dismissed across stable identity changes.
- Reset clears known, dismissed, and active review items.
- Review rows stay generic and expose placement decisions: keep visible, hide, always hide, and review later.
- Placement decisions write hashed Placement Planner preferences and dismiss the inbox item.
- Utility actions open Find Icon, Second Bar, Collections, Arrange, or the Experimental Assisted Move dry-run path without exposing raw item identity.

## Privacy

The inbox stores hashed item keys only. Diagnostics use aggregate counts such as added count, review count, known key count, and dismissed key count. Raw item titles, app names, bundle identifiers, selected item IDs, coordinates, screenshots, and query text are excluded by default.

## Gates

New Item Inbox remains Pro Discovery gated:

- Pro Mode must be enabled.
- Accessibility Discovery must be enabled.
- Accessibility permission must be granted.
- Safe Mode must be inactive.

Guided Manual Arrange and Basic Mode remain usable when the inbox is unavailable.
