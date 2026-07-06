# Manual QA: Pro Second Bar Compact Strip

Last updated: 2026-07-05

## Scope

This checklist covers the Pro compact Second Bar strip. These behaviors require real macOS menu bar state, Accessibility, Screen Recording, and third-party status items, so they cannot be fully validated by unit tests.

## Preconditions

- Build and launch `MenuBarDeclutter`.
- Have at least three third-party menu bar apps installed and visible in the menu bar.
- Keep one third-party menu bar item in the hidden zone.
- Keep one item in the always-hidden zone, if Always Hidden is enabled.
- Enable Optional Pro only for Pro test cases.
- Enable Accessibility Discovery only for Pro test cases.
- Enable Accurate Icons only for ready-state test cases.

## Pro Setup Flow

1. Open Settings -> Privacy.
2. Confirm `Pro Second Bar Setup` is visible near the top of the page.
3. Starting from Basic Mode, confirm only `Optional Pro` is actionable and later steps are waiting.
4. Click `Enable Pro` and confirm no macOS permission prompt appears.
5. Click `Enable Discovery` and confirm no macOS permission prompt appears.
6. Click `Request Permission` for Accessibility and confirm the macOS Accessibility permission flow is user-initiated.
7. Enable Accurate Icons and confirm no Screen Recording prompt appears until its `Request Permission` button is clicked.
8. Click `Request Permission` for Screen Recording and confirm the macOS Screen Recording flow is user-initiated.
9. Confirm the setup checklist reports ready only when Optional Pro, Accessibility Discovery, Accessibility, Accurate Icons, and Screen Recording are all ready.
10. Open Settings -> Second Bar and confirm the same setup checklist and readiness state are shown there.
11. Click `Warm Up Icons` after the checklist is ready.
12. Confirm hidden items may briefly reveal, thumbnails refresh, and the previous visibility state is restored.

## Basic Mode

1. Reset to Basic Mode with Optional Pro disabled.
2. Confirm no Accessibility prompt appears.
3. Confirm no Screen Recording prompt appears.
4. Left-click the MenuBarDeclutter status item.
5. Confirm the existing inline hide/show behavior still runs.
6. Confirm no compact strip is shown.

## Pro Readiness Gate

1. Enable Optional Pro and Second Bar.
2. Disable Accessibility Discovery.
3. Left-click the MenuBarDeclutter status item.
4. Confirm a compact requirements strip appears near the status item.
5. Confirm it names Accessibility Discovery as missing.
6. Enable Accessibility Discovery but deny or revoke Accessibility permission.
7. Left-click again and confirm the requirements strip names Accessibility permission.
8. Grant Accessibility, disable Accurate Icons, and left-click again.
9. Confirm Accurate Icons is named as missing.
10. Enable Accurate Icons but revoke Screen Recording.
11. Confirm Screen Recording is named as missing.
12. Confirm the status menu `Show Second Bar` command is blocked by the same missing gate.

## Compact Strip Layout

1. Grant Accessibility and Screen Recording, then prepare Accurate Icons.
2. Move the MenuBarDeclutter status item so there is enough space to the right edge of the screen.
3. Left-click the status item.
4. Confirm the strip starts under the status item and extends toward the right screen edge.
5. Move the status item close to the right edge so the status-item-to-edge region is too narrow.
6. Left-click again.
7. Confirm the strip falls back to the notch-left-edge-to-right-edge region.
8. Confirm the strip is one row only.
9. Confirm visible content uses icon-only buttons with tooltips/accessibility labels.
10. Confirm the strip repositions or closes cleanly after display changes, Space changes, and wake.

## Item Inclusion

1. Confirm Hidden-zone items with prepared Accurate Icons appear in the compact strip.
2. Confirm Visible-zone items do not appear.
3. Confirm Always Hidden items do not appear.
4. Confirm the MenuBarDeclutter status item does not appear.
5. Add more Hidden-zone items than fit in one row.
6. Confirm extra ready items are represented by `+N`.
7. Confirm hidden items that still need Accurate Icons contribute to the additional count.
8. Click the Manage/Search control and confirm the full Second Bar panel opens.

## Direct Activation

1. Open the compact strip with a Hidden third-party item ready.
2. Click a third-party icon in the compact strip.
3. Confirm the third-party menu opens or performs the same action as clicking the real menu bar item.
4. Confirm the compact strip closes on successful activation.
5. Test an item whose owner app has quit or whose AX element changed since the last scan.
6. Confirm activation failure leaves the strip open and shows a retry/failure state.
7. Confirm failure is logged in diagnostics without revealing private item names beyond stable diagnostic IDs.
8. Record failures in `docs/testing/pro-second-bar-direct-activation-matrix.md`.

## Regression Checks

1. Right-click the status item and confirm the status menu still opens.
2. Option-click the status item and confirm reveal-all behavior still works when enabled.
3. Confirm `Hide Second Bar` can close either the full panel or compact strip.
4. Confirm Basic Mode remains usable after revoking all Pro permissions.
5. Confirm no network access is required for compact strip behavior.
