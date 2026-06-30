# Manual QA

Manual QA is required for behavior that depends on macOS menu bar state, app activation, display configuration, and system privacy prompts.

## Phase 0 Checklist

- Launch the app and confirm no Dock icon appears.
- Confirm one temporary status item appears in the menu bar.
- Click the status item and confirm the menu opens.
- Choose Settings and confirm the settings window opens.
- Choose Show Diagnostics and confirm the settings window opens to Diagnostics.
- Choose About and confirm the standard About panel opens.
- Choose Quit and confirm the app terminates.
- Confirm Basic Mode does not prompt for Accessibility.
- Confirm Basic Mode does not prompt for Screen Recording.
- Confirm Basic Mode does not prompt for Apple Events.
- Confirm Basic Mode does not prompt for Input Monitoring.
- Confirm Basic Mode does not initiate network access.

## Phase 1 Checklist — No-Permission Core Hiding MVP

### Status bar surface

- Launch the app and confirm two new menu bar items appear: a square control toggle and a thin separator.
- Confirm the control icon is `chevron.left` while expanded.
- Confirm the separator icon is `chevron.left.2` while expanded.
- Open the menu (right-click the control item on macOS 26+); confirm these items are present: Expand Hidden Items, Collapse Hidden Items, Toggle Hidden Items, Reset Separator Length, Show Drag Hint, Settings…, Diagnostics…, About MenuBarDeclutter, Quit.

### Drag hint

- On first launch, confirm a visible popover appears near the separator with the "Hold Command and drag the separator..." hint.
- Confirm the same hint is logged to Diagnostics.
- Choose Show Drag Hint from the menu and confirm the popover appears again and the message is logged again.

### Command-drag separator

- Hold Command and drag the separator item to position it to the right of the icons you want hidden.
- Verify you can move the separator freely when Command is held (NSStatusItem built-in behavior).

### Collapse / expand

- Click the control item once; verify the separator becomes very wide and icons left of the separator are no longer visible in the menu bar.
- Confirm the control icon switches to `chevron.right` and the separator icon to `chevron.right.2`.
- Click the control item again; verify the separator returns to its slim length and the hidden icons reappear.
- Choose Toggle Hidden Items from the menu; verify it collapses/expands regardless of current state.
- Choose Collapse Hidden Items from the menu while expanded; verify it collapses.
- Choose Expand Hidden Items from the menu while collapsed; verify it expands.
- Choose Reset Separator Length; verify the collapsed length recomputes from the widest screen (any user-override is gone).

### Persistence

- Collapse the items, then Quit the app.
- Relaunch the app; confirm the state is still collapsed on launch.
- Expand the items, then Quit; relaunch and confirm expanded.

### Display changes

- If available, attach an external display while the app is collapsed.
- Confirm the separator remains wide enough to keep items hidden on the larger menu bar.
- Detach the external display; confirm the separator still hides items on the builtin screen.
- Change resolution in System Settings while collapsed; verify items remain hidden.

### Menu bar appearance variations

- Enable "Desktop & Dock → Menu bar → Autohide" in System Settings; verify collapse/expand still works.
- Test with a transparent menu bar wallpaper; verify hidden items remain hidden while the menu bar is showing.

### Privacy

- Confirm no Accessibility permission prompt appears during any of the above.
- Confirm no Screen Recording permission prompt appears.
- Confirm no Apple Events / Automation permission prompt appears.
- Confirm no Input Monitoring permission prompt appears.
- Confirm no network activity originates from MenuBarDeclutter while testing Phase 1.

## Notes

This checklist verifies the Phase 1 hiding MVP. Later-phase features such as global hotkey, hover reveal, auto-rehide, always-hidden separator, Accessibility-based control, search, and second bar should be verified against their own phase plans/manual QA.

## Phase 2 Checklist — Basic UX Polish

### Global hotkey

- Open Settings → Behavior → Global Hotkey.
- Enable the global hotkey toggle; confirm Diagnostics reports "Registered global hotkey ⌥⌘B".
- Focus another app and press Option+Command+B; confirm the menu bar toggles between collapsed and expanded.
- Disable the toggle; confirm the hotkey no longer fires.
- Re-enable; choose Reset to Default; confirm the displayed hotkey is `⌥⌘B` again.
- Confirm no Accessibility, Input Monitoring, Screen Recording, or Apple Events prompt appeared.

### Auto-rehide

- Enable Auto-Rehide with a delay of 3 seconds.
- Collapse the menu bar, then click the control item to expand.
- Wait 3 seconds without touching the mouse; confirm the menu bar collapses again and Diagnostics shows "Auto-rehide fired".
- Hold the mouse over the menu bar band after expanding; confirm the timer keeps postponing (Diagnostics shows "postponedMouseInMenuBar" as last reason).
- Open the Settings window and leave it key; confirm the timer still postpones ("postponedSettingsWindow").
- Collapse manually; confirm the running countdown is cancelled and Diagnostics shows "userCollapsed".

### Hover reveal

- Enable Hover Reveal in Settings → Behavior.
- Collapse the menu bar.
- Move the cursor up into the menu bar band; confirm the hidden items expand automatically.
- Move the cursor out of the band; confirm an auto-rehide countdown begins (when Auto-Rehide is also enabled).
- Disable Hover Reveal; confirm the cursor entering the band no longer expands.
- Adjust the polling interval slider; confirm restart behaviour in Diagnostics.

### Always-hidden separator

- Enable "Enable always-hidden separator" in Settings → Behavior.
- Confirm a second status item appears to the right of the primary separator.
- Command-drag items you want always hidden to the right of that separator.
- Collapse the menu bar (primary control click); confirm all primary zone and always-hidden items disappear.
- Expand the menu bar; confirm the primary zone is visible but the always-hidden zone is still collapsed.
- Option-click the control item (with `revealAllOnOptionClick` enabled); confirm both zones become visible.
- Option-click again; confirm both zones collapse again.
- Disable always-hidden; confirm the second separator disappears cleanly.

### Option-click reveal all

- With `revealAllOnOptionClick` enabled: Option-click the control item while collapsed. Confirm the menu bar enters revealAll (both separators expanded).
- Option-click again; confirm it collapses to the previous collapsed state.
- Disable `revealAllOnOptionClick` in Settings; Option-click should now behave exactly like a normal click.

### Show / hide separator visuals

- Toggle `showSeparators` off in Settings → Behavior.
- Confirm both separator icons disappear, but the separators still occupy their length in the menu bar (collapsing still pushes items off-screen).
- Toggle it on; confirm the chevron icons reappear.

### Menu interactions

- Right-click the control item; confirm the menu includes "Reveal All Hidden Items" and "Toggle Reveal All".
- Choose "Reveal All Hidden Items" while collapsed; confirm the bar enters revealAll.
- Choose "Toggle Reveal All"; confirm it flips between revealAll and collapsed.

### Diagnostics live status

- Open Settings → Diagnostics; confirm the Live Status section shows visibility state, primary separator length, always-hidden separator length, hotkey registered, hover polling active, auto-rehide scheduled, and last rehide reason.
- Toggle behaviors and confirm the live status updates.

### Display matrix

- Repeat the collapse/expand path on a multi-display setup; confirm the always-hidden separator still pushes items off-screen on the widest display.
- If a notch display is available, confirm collapse/expand still hides items correctly around the notch.
- Toggle the macOS 26 transparent menu bar appearance; confirm hidden items remain hidden.

### Privacy

- Confirm no Accessibility prompt appears during any Phase 2 operation.
- Confirm no Screen Recording prompt appears.
- Confirm no Apple Events / Automation prompt appears.
- Confirm no Input Monitoring prompt appears.
- Confirm no network activity originates from MenuBarDeclutter while testing Phase 2.

## Phase 3 Checklist — Settings, Onboarding, Launch at Login, Diagnostics Export

### First-launch onboarding

- Launch the app on a clean install (delete `~/Library/Preferences/<bundle-id>.plist` if needed) and confirm the Onboarding window appears centered.
- Step through all seven onboarding pages: intro, native cleanup, Command-drag, hidden vs always-hidden, hotkey & auto-rehide, privacy, macOS 26 note.
- On the native cleanup page, click "Open Menu Bar Settings"; confirm System Settings opens best-effort and no permission prompt appears.
- Confirm the macOS 26 note page shows the "Transparent menu bar visible." callout.
- Click "Get Started"; confirm the window closes and Diagnostics logs "Onboarding completed.".
- Quit and relaunch; confirm onboarding does NOT reappear (`hasCompletedOnboarding` persisted).
- Open Settings → General → Onboarding and choose "Show Onboarding Again"; confirm the onboarding window reappears centered.
- Confirm no Accessibility / Screen Recording / Apple Events / Input Monitoring / network prompt appears during any onboarding step.

### Settings — General

- Confirm Settings → General shows "Launch at Login", "Start collapsed", "Last Known App Version", layout resets, "Show Onboarding Again", and an "App" section listing Marketing Version, Build Number, App Version, and Bundle Identifier.
- Toggle "Launch at Login" on; confirm macOSmacOS shows no permission prompt and that a Login Item allowing the app to launch at login appears in System Settings → General → Login Items (managed by the user). Confirm Diagnostics logs "Launch at Login enabled via SMAppService."
- Toggle it off; confirm the Login Item disappears and Diagnostics logs "Launch at Login disabled via SMAppService."
- Toggle "Start collapsed" on; quit and relaunch while collapsed; confirm the bar launches collapsed every time regardless of last state.
- Toggle "Start collapsed" off; quit while expanded; relaunch and confirm the bar remembers the last state.

### Settings — Behavior, Advanced

- Smoke-test the existing Phase 2 Behavior toggles from the new Settings shell (auto-rehide, hover reveal, always-hidden, separator visuals, hotkey, option-click).
- Open Settings → Advanced and adjust the "Expanded separator length" slider; confirm the separator visual width updates in the menu bar.
- Toggle "Use custom collapsed separator length" on and pick a value within the slider bounds; collapse and confirm the override length is applied. Toggle it off; confirm the collapsed length recomputes from the widest screen.
- Choose "Reveal Diagnostics Folder in Finder"; confirm the MenuBarDeclutter Diagnostics directory opens in Finder.

### Settings — Diagnostics (live status + export)

- Open Settings → Diagnostics; confirm the Live Status section shows visibility state, primary separator length, always-hidden separator length, installed flag, hotkey registered, hover polling, auto-rehide scheduled, and last rehide reason.
- Toggle behaviors and confirm live status updates.
- Choose the "TXT" format and click "Export…"; pick a destination in the save panel; confirm a `.txt` file is written and Diagnostics logs the export.
- Open the exported `.txt` and verify it contains app version, build, macOS version, architecture, screen count + rectangles, current settings, and logs; verify it does NOT contain screenshots, screen contents, personal file paths, or network data.
- Repeat the export with the "JSON" format and verify the same inclusions/exclusions via a JSON viewer.
- Click "Clear" with events present; confirm the events list becomes empty.

### Settings — Privacy

- Open Settings → Privacy; confirm Basic Mode lists Accessibility, Screen Recording, Apple Events, Input Monitoring as "Not Requested" and "Network Access" as "Not Used".
- Confirm the Pro Mode section lists "Permission-Gated Features" as "Disabled" with a note about explicit opt-in.
- Confirm the Diagnostics Export note summarizes what is included and what is excluded.

### Launch at Login persistence

- Enable Launch at Login, then Quit.
- Restart macOS if possible (or log out/in); confirm MenuBarDeclutter launches automatically on login.
- Disable Launch at Login in Settings; log out/in; confirm the app does NOT launch on login.
- Confirm no sensitive permission prompt appears at any point during this flow.

### Diagnostics export privacy

- Confirm the default save location is inside Application Support/MenuBarDeclutter/diagnostics/.
- Confirm the file name pattern is `MenuBarDeclutter-diagnostics-<timestamp>.<ext>`.
- Export to a non-default location (e.g. Desktop); confirm the file is written there.

### Reset settings

- Choose "Reset App Layout" in Settings → General; confirm the collapsed separator recomputes to the recommended length (any user-override cleared) and Diagnostics logs "App layout reset to recommended separator length."
- Choose "Reset All Settings" → confirm a destructive dialog appears; choose "Reset" and confirm preferences revert to defaults (auto-rehide on, hover reveal off, hotkey off, startCollapsed off, onboarding circle toggle unchecked, etc.) and Diagnostics logs "All settings reset to defaults."
- Confirm Live Status reflects the reset without requiring relaunch.

### Quit / relaunch and restart macOS

- Quit from the status menu and relaunch; confirm the menu bar item, Settings window, and Diagnostics persist as before.
- Quit while collapsed; relaunch; confirm collapsed state persists.
- If possible, restart macOS (with Start collapsed enabled and Launch at Login enabled) and confirm:
  - The app launches at login.
  - The bar starts collapsed.
  - Settings persist across the restart.

### macOS 26 appearance matrix

- Toggle System Settings → Appearance between Light and Dark; confirm Settings, Onboarding, and Advanced tab adapt.
- Enable System Settings → Accessibility → Display → "Increase contrast"; confirm Settings/Onboarding controls remain readable.
- Enable System Settings → Accessibility → Display → "Reduce transparency"; confirm Settings/Onboarding avoid custom transparent effects and remain readable.
- Set the menu bar to a transparent wallpaper; confirm hidden items remain hidden under the transparent bar; confirm Settings → Advanced "Diagnostics Directory" reveal still works.

### External display

- Attach an external display while collapsed; confirm the separator still hides items on the widest display.
- Open Settings → Diagnostics; confirm Screens list shows both displays. Export Diagnostics and confirm the exported bundle lists both screen frames (with the main marker).
- Detach the external display; confirm the live status separator length still hides items on the builtin screen.

### Privacy (Phase 3)

- Confirm no Accessibility prompt appears during any Phase 3 operation.
- Confirm no Screen Recording prompt appears.
- Confirm no Apple Events / Automation prompt appears.
- Confirm no Input Monitoring prompt appears.
- Confirm no network activity originates from MenuBarDeclutter while testing Phase 3.

## Phase 4 Checklist — Accessibility-Based Icon Discovery

### Pro Mode disabled

- Start from a clean install or choose Settings → General → Reset All Settings.
- Confirm Settings → Privacy shows Pro Mode disabled and Accessibility Discovery disabled.
- Collapse and expand hidden items from the menu bar control; confirm Basic Mode still works.
- Open Settings → Diagnostics; confirm Accessibility permission status is shown, but no Accessibility snapshots are required for Basic Mode.
- Confirm no Accessibility prompt appears while Pro Mode is disabled.
- Confirm no Screen Recording, Apple Events, Input Monitoring, or network prompt appears.

### Enable Pro Mode without prompting

- Open Settings → Privacy and click "Enable Pro Mode".
- Confirm Accessibility Discovery becomes enabled.
- Confirm no Accessibility prompt appears yet.
- Confirm the Accessibility status is either Not Requested, Denied, Granted, or Unknown depending on the current system state.
- Toggle Accessibility Discovery off and on; confirm no permission prompt appears.
- Adjust the scan throttle stepper; confirm Diagnostics does not show an aggressive polling loop.

### Request Accessibility permission

- In Settings → Privacy, click "Request Permission".
- Confirm the macOS Accessibility permission prompt appears only after this click.
- If the prompt offers an "Open System Settings" path, open it; otherwise click "Open Settings" in the app.
- In System Settings → Privacy & Security → Accessibility, enable MenuBarDeclutter.
- Return to MenuBarDeclutter and click "Refresh AX Scan" in Settings → Diagnostics.
- Confirm Diagnostics shows permission status "Granted".

### Scan diagnostics

- With Pro Mode enabled, Accessibility Discovery enabled, and permission granted, open Settings → Diagnostics.
- Click "Refresh AX Scan".
- Confirm Diagnostics shows:
  - scanned item count,
  - visible / hidden / always-hidden / unknown counts,
  - last scan time,
  - AX failure count,
  - a table with scanned snapshots.
- Confirm the table includes only metadata such as title/label, owning app, bundle identifier, role, zone, frame, and system-item heuristic.
- Confirm no screenshot, screen contents, Apple Events data, Input Monitoring data, or network data is collected.

### Zone classification smoke test

- Position the primary separator between visible and hidden menu bar items.
- If enabled, position the always-hidden separator further left/right according to the current layout.
- Click "Refresh AX Scan".
- Confirm items to the right of the primary separator are generally classified visible.
- Confirm items between the primary and always-hidden separators are generally classified hidden.
- Confirm items past the always-hidden separator are generally classified always-hidden.
- If separator frames are unavailable, confirm affected items are shown as unknown rather than crashing.

### Expand/collapse and screen-change triggers

- Collapse and expand the menu bar while Pro Mode is enabled and permission is granted.
- Confirm Diagnostics updates after visibility changes, subject to the scan throttle.
- Attach or detach an external display if available.
- Confirm the app does not crash and Diagnostics can refresh scans after the screen configuration changes.

### Async scan race smoke test

- Enable Pro Mode and Accessibility Discovery with Accessibility permission granted.
- Open Settings -> Diagnostics and click "Refresh AX Scan" repeatedly while also collapsing/expanding the menu bar.
- If available, attach or detach an external display while refreshes may still be pending.
- Disable Pro Mode or revoke Accessibility permission while a refresh may still be pending.
- Confirm Settings and Diagnostics stay responsive during the refresh burst.
- Confirm stale scan results do not repopulate snapshots after Pro Mode is disabled or Accessibility permission is revoked.
- Confirm that when multiple refreshes overlap while Pro Mode remains enabled, the latest successful refresh wins.
- Confirm Basic Mode collapse/expand still works and no Screen Recording, Apple Events, Input Monitoring, or network prompt appears.

### Deny or revoke permission

- If permission has not been granted, click "Request Permission" and deny/leave it disabled.
- Confirm Diagnostics shows a denied/not-requested state and Basic Mode continues working.
- If permission was granted, go to System Settings → Privacy & Security → Accessibility and disable MenuBarDeclutter.
- Return to the app and click "Refresh AX Scan" or toggle Pro Mode.
- Confirm Pro scan diagnostics clear or stop updating gracefully.
- Confirm collapse/expand, hotkey, hover reveal, auto-rehide, and Settings remain usable.

### Disable Pro Mode

- In Settings → Privacy, click "Disable Pro Mode".
- Confirm Accessibility Discovery turns off.
- Confirm Diagnostics no longer requires or refreshes AX snapshots.
- Confirm Basic Mode still collapses/expands items with no permission prompt.

### Restart

- Enable Pro Mode and Accessibility Discovery, then quit MenuBarDeclutter.
- Relaunch the app.
- Confirm Pro settings persist, but no permission prompt appears on launch.
- If Accessibility permission is granted, confirm Diagnostics can refresh scans.
- If Accessibility permission is revoked before relaunch, confirm the app degrades gracefully and Basic Mode still works.

## Phase 5 Checklist — Find Icon / Icon Panel

### Search unavailable states

- Start from a clean install or choose Settings → General → Reset All Settings.
- Open the status menu and choose "Find Icon…".
- Confirm the Find Icon panel opens centered as a native floating utility panel with the search field focused.
- With Pro Mode disabled, confirm the panel explains that Pro Mode is required and Basic Mode remains available.
- Click "Enable Pro Mode" in the panel; confirm no Accessibility prompt appears automatically.
- If Accessibility permission is not granted, confirm the panel explains that Accessibility permission is needed and offers Request Permission / System Settings actions.
- Confirm Basic Mode collapse/expand still works while the panel is showing an unavailable state.

### Enable requirements and refresh index

- Open Settings → Privacy.
- Enable Pro Mode and Accessibility Discovery.
- Click "Request Permission" and grant Accessibility permission in System Settings.
- Return to MenuBarDeclutter and choose "Refresh Menu Bar Items" from the status menu.
- Open Settings → Diagnostics and confirm Search Index Items matches the latest scanned item count.
- Confirm no Screen Recording, Apple Events, Input Monitoring, or network prompt appears.

### Open search and type

- Choose "Find Icon…" from the status menu.
- Confirm the search field is focused on open.
- Type a visible app name from the menu bar; confirm matching results appear.
- Type part of a bundle identifier shown in Diagnostics; confirm bundle-id matches appear.
- Clear the query; confirm recent indexed items appear.
- Press Escape; confirm the panel closes.

### Keyboard navigation

- Reopen Find Icon and type a query with more than one result.
- Press Down Arrow and Up Arrow; confirm the highlighted selection moves without resizing the panel.
- Press Return on a selected result; confirm the result activates according to its zone.
- Confirm the footer says that clicks are manual and no automated clicking occurs.

### Select visible item

- Search for an item currently classified as visible.
- Press Return or click the row.
- Confirm the item is not clicked automatically.
- If "Highlight selected item" is enabled, confirm a rounded highlight appears around the approximate menu bar item frame and disappears after about two seconds.
- Confirm Diagnostics shows Last Search Selection and Last Search Activation.

### Select hidden item

- Position the primary separator so at least one item is classified hidden.
- Collapse the primary hidden zone.
- Search for the hidden item and select it.
- Confirm hidden items are revealed.
- Confirm the highlight overlay appears near the selected item's approximate frame when highlighting is enabled.
- Confirm the user still clicks manually.

### Select always-hidden item

- Enable the always-hidden separator in Settings → Behavior.
- Position at least one item in the always-hidden zone.
- Search for the always-hidden item and select it.
- Confirm the bar enters reveal-all so the always-hidden zone is visible.
- Confirm the highlight overlay appears near the selected item's approximate frame when highlighting is enabled.
- Confirm no automated clicking or dragging occurs.

### Search settings

- Open Settings → Search.
- Disable "Highlight selected item"; select a visible result and confirm no overlay appears.
- Disable "Reveal item when selected"; select a hidden/always-hidden result and confirm visibility is not changed automatically.
- Disable "Enable Find Icon"; open Find Icon from the status menu and confirm the panel explains that Find Icon is disabled.
- Re-enable Find Icon.

### Find Icon hotkey

- Open Settings → Search.
- Confirm "Enable Find Icon hotkey" is off by default and the displayed default is Option+Command+F when enabled.
- Enable the Find Icon hotkey.
- Focus another app and press Option+Command+F; confirm the Find Icon panel opens.
- Disable the Find Icon hotkey and confirm Option+Command+F no longer opens the panel.
- Confirm no Input Monitoring prompt appears.

### Permission revoke / degradation

- With Find Icon working, revoke MenuBarDeclutter's Accessibility permission in System Settings → Privacy & Security → Accessibility.
- Return to the app and choose "Refresh Menu Bar Items" or open Find Icon.
- Confirm the panel shows the permission-required state rather than crashing.
- Confirm Diagnostics clears or stops updating the search index.
- Confirm Basic Mode collapse/expand, global visibility hotkey, hover reveal, auto-rehide, Settings, and Quit remain usable.

### Privacy

- Confirm Find Icon never requests Screen Recording.
- Confirm Find Icon never requests Apple Events / Automation.
- Confirm Find Icon never requests Input Monitoring.
- Confirm no network activity originates from MenuBarDeclutter while testing Find Icon.
- Confirm selecting a search result never clicks, drags, activates, or moves menu bar items automatically.

## Phase 6 Checklist - Second Menu Bar / Floating Bar

### Unavailable states

- Start from Settings -> General -> Reset All Settings.
- Choose "Show Second Bar" from the status menu.
- With Pro Mode disabled, confirm the Second Bar opens with a Pro Mode requirement state and Basic Mode collapse/expand still works.
- Enable Pro Mode but leave Accessibility permission missing; confirm the Second Bar shows the permission-required state and offers explicit settings actions.
- Confirm no Accessibility prompt appears merely from opening the Second Bar.

### Show, hide, and toggle

- Enable Pro Mode, Accessibility Discovery, and grant Accessibility permission.
- Choose "Refresh Menu Bar Items" from the status menu.
- Choose "Show Second Bar"; confirm a floating panel appears near the menu bar.
- Choose "Hide Second Bar"; confirm the panel closes.
- Choose "Toggle Second Bar" twice; confirm it opens and closes.
- Press Escape while the panel is key; confirm it closes.
- If "Close when clicking outside" is enabled, click another app and confirm the panel closes.

### Content and selection

- Position at least one item in the hidden zone and refresh the AX scan.
- Open the Second Bar and confirm hidden items appear with app icons, app names, optional item titles, and zone badges.
- Enable the always-hidden separator, place at least one item in that zone, refresh the AX scan, and confirm it appears when "Show always-hidden items" is enabled.
- Select a hidden item; confirm the primary hidden zone is revealed and the highlight appears if highlighting is enabled.
- Select an always-hidden item; confirm reveal-all is used and the highlight appears if enabled.
- Confirm no original menu bar item is clicked automatically.

### Keyboard and settings

- Open the Second Bar with multiple items.
- Use Left/Right arrows to move selection and Return to activate the selected item.
- Toggle "Show labels" and confirm the panel height changes without overlapping content.
- Change icon size and confirm item tiles remain legible.
- Change placement between below menu bar, near mouse, and last position; confirm the panel stays on-screen.
- Enable "Activate owning app on selection" and select an item owned by a running app; confirm the app activation behavior is optional and user-controlled.

### Display and appearance matrix

- Attach an external display and open the Second Bar from each display; confirm it chooses a sensible screen and stays inside visible bounds.
- On a notch display, confirm the panel does not cover the notch region in a way that hides controls.
- Test with a transparent menu bar wallpaper; confirm contrast remains readable.
- Enable Reduce Transparency; confirm the Second Bar remains legible.
- Enable Increase Contrast; confirm labels, badges, and selection remain readable.
- Enter a full-screen app space and confirm the panel behavior is non-disruptive.

### Privacy

- Confirm Second Bar never requests Screen Recording.
- Confirm Second Bar never requests Apple Events / Automation.
- Confirm Second Bar never requests Input Monitoring.
- Confirm no network activity originates from MenuBarDeclutter while testing Second Bar.
- Confirm icons come from app/bundle metadata rather than captured pixels.

## Phase 7 Checklist - Programmatic Icon Moving

### Disabled and permission gates

- Start with Icon Moving disabled in Settings -> Advanced.
- Open Find Icon or Second Bar, right-click a result, and choose a move action.
- Confirm the move is skipped/reported as disabled.
- Enable Icon Moving while Pro Mode is disabled; confirm the move is skipped/reported as requiring Pro Mode.
- Enable Pro Mode but revoke Accessibility permission; confirm the move is skipped/reported as requiring Accessibility.
- Confirm Basic Mode collapse/expand still works in all skipped states.

### Confirmation flow

- Enable Pro Mode, Accessibility Discovery, Accessibility permission, and Icon Moving.
- Ensure "Require confirmation" is enabled and "Do not show again" is not suppressed.
- Choose a move action on a third-party menu bar item.
- Confirm the alert explains that MenuBarDeclutter will simulate a Command-drag and that the move may fail.
- Click Cancel and confirm no drag occurs and Diagnostics records cancellation.
- Repeat and choose "Do not show this warning again"; confirm later moves no longer show the alert.
- Click "Reset moving warnings" in Settings -> Advanced and confirm the alert appears again on next move.

### Supported third-party item move

- Choose a non-system third-party menu bar item that can normally be Command-dragged by hand.
- Move it to Hidden.
- Confirm the app reveals required zones before the move, then rescans and reports success or a clear failure.
- Move it back to Visible.
- If always-hidden is enabled, move it to Always Hidden and confirm verification.
- Confirm the mouse and menu bar layout remain usable after success or failure.

### Safety behavior

- Attempt to move a MenuBarDeclutter control/separator item; confirm it is blocked.
- Attempt to move a likely system item while "Allow moving system items" is disabled; confirm it is blocked.
- Enable "Allow moving system items" only for testing with a low-risk system item, then disable it again.
- During a move, confirm auto-rehide and hover reveal do not fight the drag.
- Try starting a second move while one is in progress if practical; confirm only one move runs at a time.

### Diagnostics and recovery

- After a successful move, confirm Diagnostics shows last move result, drag plan, verification result, and retry count.
- Force a failure if possible by choosing an item that refuses Command-drag; confirm the previous visibility state is restored and the failure is reported clearly.
- Set max retries to 0 and repeat a failing move; confirm no retry loop occurs.
- Increase max retries and confirm the retry count is reflected in Diagnostics.

### Privacy

- Confirm icon moving never runs at startup, wake, profile apply, or trigger firing.
- Confirm icon moving never requests Screen Recording, Apple Events, Input Monitoring, or network access.
- Confirm real CGEvent dragging only occurs after the explicit move action and confirmation policy allow it.

## Phase 8 Checklist - Profiles, Smart Triggers, Automation

### Profile management

- Open Settings -> Profiles.
- Create a profile and rename it.
- Set preferred visibility, Second Bar visibility, auto-rehide, hover reveal, and notes.
- Add at least one bundle-id target zone entry using `bundle.id=zone` syntax.
- Save, close Settings, reopen Settings, and confirm the profile persisted.
- Duplicate the profile and confirm the copy has a new name/id.
- Delete the duplicate and confirm the original remains.

### Profile dry-run and apply

- With recent AX snapshots available, click Dry Run.
- Confirm the summary lists visibility reveals, planned zone moves, unavailable items, and permission requirements.
- Click Apply on a profile that changes only Basic settings; confirm visibility and settings update.
- Include target zones in a profile and click Apply; confirm normal apply reports the zone move requirement but does not silently drag icons.
- Confirm Diagnostics shows active profile and profile apply log.

### Import and export

- Export a profile JSON file.
- Delete the profile from Settings.
- Import the JSON file and confirm the profile appears again.
- Try importing malformed JSON and confirm the UI reports an error without losing existing profiles.

### Smart triggers

- Enable Smart Triggers in Settings -> Profiles.
- Add an external-display trigger if an external display is available.
- Attach/detach the display and confirm the trigger applies the selected profile once, subject to debounce.
- Add a frontmost-app trigger, switch to the selected app, and confirm the selected profile applies.
- Confirm repeated activation within the debounce window does not repeatedly apply the profile.
- Disable Smart Triggers and confirm trigger observations stop.
- Confirm Diagnostics shows last trigger fired and trigger evaluation logs.

### URL automation

- Build and launch the app once so Launch Services sees the registered `menubardeclutter://` scheme.
- Run `open 'menubardeclutter://expand'` and confirm hidden items expand.
- Run `open 'menubardeclutter://collapse'` and confirm hidden items collapse.
- Run `open 'menubardeclutter://reveal-all'` and confirm both zones reveal.
- Run `open 'menubardeclutter://second-bar'` and confirm the Second Bar opens if enabled and requirements are met.
- Run `open 'menubardeclutter://profile/<ProfileName>'` with an existing profile name and confirm it applies.
- Run the same command with a missing profile name and confirm Diagnostics records a warning without crashing.

### Privacy

- Confirm profiles and triggers are stored locally in Application Support.
- Confirm Smart Triggers do not request Accessibility by themselves.
- Confirm triggers never run icon moving automatically.
- Confirm URL automation does not request Screen Recording, Apple Events / Automation, Input Monitoring, or network access.
- Confirm Basic Mode collapse/expand remains usable when profiles, triggers, and Pro Mode are disabled.

## Phase 9 Checklist - Health, Recovery, macOS 26+ Hardening

### Diagnostics health UI

- Open Settings -> Diagnostics and confirm the Health section shows `Health: OK`, `Health: Warning`, or `Health: Critical`.
- Click Refresh and confirm a new health check is logged.
- If issues are listed, confirm each row shows severity, title, detail, and suggested recovery when available.
- Click Export Health Report and confirm a `.txt` file is written without screenshots, screen contents, personal file paths, or network data.

### Automatic repair

- With the app running, drag separators to unusual positions or set an extreme custom collapsed length in Settings -> Advanced.
- Open Settings -> Diagnostics and click Fix Automatically.
- Confirm separator lengths reset to sane values and the app remains expanded/reveal-all after recovery.
- Click Reset Basic Mode and confirm Basic defaults return while no sensitive permission prompt appears.
- Enable Pro Mode and Accessibility Discovery, then click Disable Pro Mode from Diagnostics; confirm Pro Mode, discovery, icon moving, and triggers are disabled.

### Crash marker and relaunch

- Collapse the menu bar.
- Force quit the app from Activity Monitor or `kill -9 <pid>`.
- Relaunch the app.
- Confirm the app starts expanded/reveal-all, keeps a visible control item, logs Safe Mode/previous crash state in Diagnostics, and does not start collapsed.
- Quit normally, relaunch again, and confirm the crash marker is cleared.

### Safe Mode entry

- In Settings -> Diagnostics, click Safe Mode Next Launch.
- Quit and relaunch.
- Confirm Safe Mode is active in Diagnostics.
- Confirm auto-rehide, hover reveal, Pro scans, icon moving, global hotkeys, Find Icon hotkey, and smart triggers do not run during that launch.
- Confirm the visible control item menu still includes reset/diagnostics/settings/quit actions.
- Quit normally, relaunch, and confirm the one-shot Safe Mode flag has been consumed.
- Relaunch while holding Option and confirm Safe Mode activates for that launch.

### Wake and display recovery

- Collapse the menu bar, then sleep and wake the Mac.
- Confirm auto-rehide is not stuck, separator geometry is reapplied, and Diagnostics logs a health report.
- Attach an external display while collapsed; confirm the collapsed separator length still covers the widest menu bar.
- Detach the display; confirm the app remains usable and logs a new health check.
- Switch Spaces or enter/exit a full-screen app and confirm the menu bar state remains coherent.
- If Pro Mode is enabled and Accessibility is granted, confirm a wake/display recovery can refresh the AX snapshot; if permission is revoked, confirm Basic Mode continues working.

### Permission failure recovery

- Enable Pro Mode and Accessibility Discovery.
- Revoke Accessibility permission in System Settings.
- Return to the app and refresh Diagnostics.
- Confirm Health reports a Pro permission warning and Basic Mode collapse/expand still works.
- Click Fix Automatically or Disable Pro Mode and confirm Pro-dependent features are disabled without affecting Basic Mode.

### macOS 26 visual QA

- Test with a transparent menu bar wallpaper; confirm control/separator items remain visible enough to recover.
- Toggle menu bar background enabled/disabled and confirm status items and Settings remain usable.
- Enable Reduce Transparency and confirm Diagnostics/Health text remains readable.
- Enable Increase Contrast and confirm issue severity colors remain distinguishable with labels.
- Test Light, Dark, and tinted appearance if available.
- Test on a notched display and confirm the control item and separators remain reachable.
- Test with an external display attached and detached.
- Test while a full-screen app owns the active Space.
- Test Stage Manager if relevant to the system configuration.
- Test with 30+ menu bar controls if possible and confirm recovery still leaves a visible control item.
- Record the exact macOS 26 minor release used for the final pass.

### Privacy

- Confirm Phase 9 health checks do not prompt for Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
- Confirm Safe Mode and crash markers are local Application Support files only.
- Confirm Health Report export contains only health status, issue codes/details, and suggested recovery actions.

## Phase 9.1 Checklist - Alpha RC Validation And Release Hardening

### Schemes and scripts

- Run `xcodebuild -list` and confirm both `MenuBarDeclutter` and deprecated fallback `MenuBar-Manager` schemes are listed.
- Run `scripts/build_debug.sh` and confirm it uses `MenuBarDeclutter`.
- Run `scripts/test.sh` and confirm it uses `MenuBarDeclutter`.
- Run `scripts/qa_preflight.sh` and record PASS/FAIL/BLOCKED.

### Privacy boundary

- Run `scripts/verify_privacy_boundary.sh`.
- Confirm no ScreenCaptureKit, Screen Recording usage string, Apple Events usage string, Input Monitoring usage string, or network entitlement is reported.
- Confirm `menubardeclutter://` remains registered.
- Confirm diagnostics filtered export excludes screenshots, screen contents, live search text, selected item identity, personal file paths, and network data.
- Run `scripts/qa_network_watch.sh MenuBarDeclutter` while exercising Basic Mode and Pro surfaces; confirm no unexpected network connections.

### Experimental Pro surfaces

- Open Settings -> Advanced and confirm a Labs / Experimental section is visible.
- Attempt to enable icon moving and confirm the warning appears before it turns on.
- Cancel the warning and confirm icon moving remains disabled.
- Enable icon moving, then Reset All Settings and confirm icon moving returns to disabled.
- Confirm Diagnostics shows Experimental Icon Moving as Enabled/Disabled.

### Automation pause

- Enable Smart Triggers in Settings -> Profiles.
- Turn on Pause All Automation and confirm configured triggers stop applying profiles.
- Confirm the status menu shows Resume Automation.
- Resume automation from the status menu and confirm trigger evaluation resumes.
- Pause automation from the status menu and confirm Settings -> Profiles reflects the paused state.
- Confirm Diagnostics shows Automation Paused.

### Diagnostics filtering

- Generate info, warning, and error events if available.
- In Settings -> Diagnostics, filter to Warnings/Errors and confirm info/debug events are hidden.
- Filter by a specific category and confirm only that category appears.
- Select an event and click Copy Selected; paste into a text editor and confirm category, severity, and message are present.
- Click Export Filtered and confirm the exported file contains only the filtered event set.

### Launch at Login installed-app support

- Open Settings -> General and confirm SMAppService Status is visible.
- Click Refresh Login Item Status and confirm the status updates without crashing.
- Click Open Login Items Settings and confirm System Settings opens.
- Test Launch at Login from an installed, signed app; do not treat Xcode-only behavior as a release pass.
- If registration is stale, remove stale entries in System Settings and retry.

### Alpha RC docs

- Complete `docs/testing/alpha-rc-qa-run-template.md`.
- Review `docs/testing/known-risk-areas.md`.
- Complete `docs/release/alpha-rc-checklist.md`.
- Include `docs/release/alpha-rc-known-limitations.md` in release notes.

### Settings layout consistency across tabs

- Open Settings and click through every tab (General, Behavior, Search, Second Bar, Profiles, Privacy, Diagnostics, Advanced).
- Confirm the sidebar width does not shift between tabs and remains at the same column position.
- Resize the Settings window down to its minimum size and click through every tab; confirm the sidebar stays at least 180 pt wide and content adapts (Diagnostics toolbar wraps to multiple rows, Profiles list/detail panes stay usable).
- Resize the Settings window wider and confirm the Profiles tab still allows dragging the HSplitView divider to rebalance the profile list and detail panes.
- Confirm Diagnostics header and filter controls are reachable when narrow (buttons wrap below pickers) and stay on one row when wide.

## Clear Glass Control Redesign QA

### Appearance and accessibility

- Open Settings in Light and Dark appearances; confirm every Settings tab uses the same compact glass shell, sidebar spacing, page headers, badges, separators, and grouped rows.
- Enable Increase Contrast; confirm badges, warning/error states, selected sidebar rows, Diagnostics severities, profile dirty states, and disabled controls remain distinguishable by text and icons, not color alone.
- Enable Reduce Transparency; confirm Settings, Onboarding, Find Icon, Second Bar, and the drag hint popover remain readable and do not rely on translucent backgrounds for contrast.
- Resize Settings to minimum and wide widths; confirm text does not overlap, buttons remain reachable, and Profiles/Diagnostics dense surfaces stay scannable.

### Privacy and permission boundaries

- Launch a fresh Basic Mode profile and open General, Behavior, Search, Second Bar, Profiles, Privacy, Diagnostics, and Advanced; confirm no Accessibility, Screen Recording, Apple Events, Input Monitoring, or network prompts appear.
- In Privacy, confirm Basic Mode clearly shows Screen Recording, Apple Events, and Input Monitoring as Not Requested, Network Access as Not Used, and Pro Mode as optional.
- Enable Pro Mode without granting Accessibility; confirm Search and Second Bar show permission-missing/unavailable states and route to Privacy without attempting automated clicks.
- Revoke Accessibility while Pro Mode is enabled; confirm Basic Mode controls continue to work and Diagnostics reports the degraded Pro state.

### Floating surfaces

- Complete the seven-step Onboarding flow; confirm the redesigned panels preserve step order, native cleanup copy, privacy copy, completion behavior, and window sizing.
- Open Find Icon with Pro disabled, Pro enabled without Accessibility, and Pro enabled with a seeded scan; confirm native utility chrome, focus, debounce, keyboard selection, empty/unavailable states, and move context menu actions are intact.
- Open Second Bar with Pro disabled, Pro enabled without Accessibility, and Pro enabled with icons available; confirm sizing, positioning, outside-click dismissal, keyboard handling, icon cache loading, and unavailable copy.
- Show the drag hint from the status menu; confirm it anchors to the separator/control item, uses the compact instructional popover, and closes transiently.

### Native status menu

- Open the status menu from the control item and separator right-click path.
- Confirm command groups are visually separated: Visibility, Find & Bars, Pro Features, Layout, Recovery, and app-level commands.
- Confirm key equivalents still work for Toggle Hidden Items, Find Icon, Toggle Second Bar, Refresh Menu Bar Items, Settings, and Quit.
- Pause and resume automation from the menu and confirm the dynamic title updates without changing Basic Mode behavior.
- In a fresh Basic Mode profile, complete onboarding, use the status menu to expand/collapse hidden items, open Settings, open Diagnostics, show the drag hint, and quit/relaunch without any sensitive permission prompts.
