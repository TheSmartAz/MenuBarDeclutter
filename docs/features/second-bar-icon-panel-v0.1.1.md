# Second Bar And Icon Panel v0.1.1

Status: Second Bar is Stable/Preview depending on action. Icon Panel is Deferred.

Second Bar is a horizontal, menu-bar-like floating panel for hidden and always-hidden items discovered through the optional Pro Accessibility index. It uses item metadata and app/bundle icons only.

## Implemented

- Horizontal Second Bar with search, hidden/always-hidden sections, labels, app icons, recents, favorites, and zone filtering.
- Placement below the menu bar, near the mouse, or at the last position, with visible-frame clamping and display-change recovery.
- Outside-click close, Escape close, and left/right/Return keyboard navigation.
- Reveal, highlight, open owning app, create group from item, add to group, and show item actions route through Command Center where implemented.
- Clear degraded states for disabled Second Bar, Pro off, Discovery off, and missing Accessibility permission.

## Deferred

- Icon Panel grid/list presentation. The `showIconPanel` command currently reports unavailable.
- Group/protected/stale filters in the Second Bar UI.
- Full keyboard grid/list navigation and Command+Return/Option+Return action variants.

