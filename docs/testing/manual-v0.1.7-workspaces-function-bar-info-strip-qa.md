# Manual QA: v0.1.7 Workspaces, Function Bar, and Info Strip

Use macOS 26.0+.

## Basic Mode Boundary

1. Launch the app with all previews off.
2. Confirm existing hide, show, reveal all, Settings, Recovery, and Diagnostics flows still work.
3. Confirm no Accessibility, Screen Recording, Apple Events, Input Monitoring, or network prompt appears.

## Workspaces Preview

1. Open Settings -> Advanced -> Workspaces Preview.
2. Enable Workspaces Preview.
3. Confirm Default, Focus, and Meeting workspaces are present.
4. Create, duplicate, archive, switch, commit, and revert a workspace in Set Builder.
5. Relaunch and confirm `Workspaces/workspaces.json` persisted the active workspace.

## Function Bar Preview

1. Enable Function Bar Preview.
2. Click Show Function Bar.
3. Confirm the panel appears as an app-owned floating panel.
4. Use the Set Switcher to switch workspaces.
5. Enable primary-click preview and confirm the status item opens Function Bar; disable it and confirm the status item returns to Basic toggle behavior.

## Info Strip Preview

1. Enable Info Strip Preview.
2. Click Show Info Strip.
3. Confirm local tiles rotate without requesting permissions.
4. Confirm Pro-derived tiles show degraded availability when Pro Discovery is off.
5. Confirm Hover to Function Bar opens Function Bar only when configured.

## Safe Mode

1. Request Safe Mode for next launch from Recovery.
2. Relaunch.
3. Confirm Function Bar and Info Strip previews are suppressed and Basic Mode recovery controls remain available.
