# Phase 11 Groups QA

## Steps

1. Open Settings > Groups.
2. Create a group with a unique name.
3. Add refs using bundle ID, manual label, and picker where available.
4. Edit symbol, color, protection, Second Bar visibility, and status item
   visibility.
5. Export groups to JSON.
6. Delete the group and import it back.
7. Open the group panel from Settings and from the optional group status item.
8. Mark the group protected and confirm protected previews redact item labels.

## Expected

- Group list persists after restart.
- Duplicate or empty names are rejected.
- Group status items disappear when disabled or in Safe Mode.
- Import/export does not request extra permissions.
- Group panel opens as a borderless floating utility panel with no titlebar or
  traffic-light controls, compact search, list-like item rows, readable
  protected-state affordances, Escape dismissal, and outside-click dismissal.
