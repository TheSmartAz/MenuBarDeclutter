# Gate C: Pro Assisted

Pro Assisted validates user-visible Pro surfaces while keeping icon movement conservative.

Allowed results: PASS, FAIL, BLOCKED, NOT TESTED.

| Scenario | Result | Notes |
| --- | --- | --- |
| Second Bar setup gates ready | NOT TESTED | Optional Pro, Accessibility Discovery, Accessibility, Accurate Icons, Screen Recording, and primary-click opt-in are ready. |
| Second Bar compact strip opens and closes | NOT TESTED | Compact strip opens from the menu bar icon, stays one row, and closes on successful activation or outside click. |
| Second Bar Accurate Icons warm-up | NOT TESTED | Warm Up Icons refreshes thumbnails, restores prior visibility, and diagnostics report the refreshed count. |
| Second Bar notch placement | NOT TESTED | Compact strip falls back from the status-item region to the notch-left-edge-to-right-edge region when needed. |
| Second Bar external display placement | NOT TESTED | Compact strip and full panel remain visible and recover after display changes, Space changes, and wake. |
| Second Bar direct activation matrix | NOT TESTED | At least one real third-party item passes direct activation and retry/failure behavior is recorded. |
| Second Bar manual gate audit passes | NOT TESTED | Export diagnostics JSON and run dogfood preflight with `SECOND_BAR_DIAGNOSTICS_JSON=/path/to/diagnostics.json`; attach or record the audit output path. |
| Profiles create/duplicate/delete | NOT TESTED | |
| Profile dry run | NOT TESTED | |
| Conservative profile apply | NOT TESTED | |
| Triggers paused/resumed | NOT TESTED | |
| URL automation expand/collapse/reveal-all | NOT TESTED | |
| URL automation profile apply | NOT TESTED | |
| No silent bulk icon moves | NOT TESTED | |
