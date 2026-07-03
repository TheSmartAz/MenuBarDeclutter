# Safe Mode

Safe Mode is the recovery path for `v0.1.10`.

Enter Safe Mode by launching with the intended Option-launch path or the one-shot Safe Mode flag available from Recovery and Diagnostics. The one-shot flag and crash-marker paths have scripted evidence; Option-launch still needs a physical installed-app QA pass before release completion.

Safe Mode behavior:

- Starts expanded.
- Keeps the Basic control visible.
- Suppresses optional/risky services.
- Skips Pro Accessibility scans.
- Keeps reset and diagnostics reachable.
- Does not require Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

Use Safe Mode when layout looks wrong, a display change left items crowded, or a previous crash marker needs recovery.

After Safe Mode opens:

1. Confirm the app starts expanded or reveal-all.
2. Open Settings or Diagnostics from the status menu.
3. Use Reset Layout if the control or separators are in a bad position.
4. Quit and relaunch normally once Basic Mode is reachable again.

If Safe Mode was triggered by a crash marker, export diagnostics before clearing more state.
