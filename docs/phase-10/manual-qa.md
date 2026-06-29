# Phase 10 Manual QA

## Basic
1. Start app.
2. Add divider from status menu.
3. Add thin spacer from status menu.
4. Add wide spacer from Settings → Layout → Spacer Items.
5. Command-drag spacers in the menu bar.
6. Hide/show spacer markers via status menu.
7. Reset spacers from Settings.
8. Enter Full Menu Bar Mode from status menu.
9. Exit Full Menu Bar Mode from status menu.
10. Confirm auto-rehide is suspended while full mode is active.
11. Confirm Safe Mode disables layout automation.

## Capacity
1. Check capacity estimate without Pro Mode (Settings → Layout → Capacity).
2. Enable Pro Mode and grant Accessibility.
3. Refresh AX scan.
4. Check improved estimate.
5. Trigger crowded estimate with fixture app if available.

## Crowded rescue
1. Make menu bar crowded using fixture app.
2. Activate hidden item from Find Icon.
3. Confirm Second Bar opens instead of unreachable inline reveal.
4. Use "Reveal Inline Anyway" from status menu.

## Spacing Labs
1. Confirm feature is off by default.
2. Enable Labs in Settings → Layout → Menu Bar Spacing Labs.
3. Back up current values (automatic on first apply).
4. Apply Compact preset.
5. Restore Previous.
6. Reset to System Default.
7. Confirm no automatic SystemUIServer/ControlCenter restart.
8. Confirm diagnostics log every action.

## Privacy
1. Run `scripts/verify_privacy_boundary.sh`.
2. Confirm no Screen Recording prompt.
3. Confirm no network.

## URL Automation
1. `menubardeclutter://full-menu-bar` — enters Full Menu Bar Mode.
2. `menubardeclutter://exit-full-menu-bar` — exits Full Menu Bar Mode.
3. `menubardeclutter://layout-suggestions` — opens Layout settings.
4. Confirm existing URL commands still work.
