# Gate C: Pro Assisted

Pro Assisted validates user-visible Pro surfaces while keeping icon movement conservative.

Allowed results: PASS, FAIL, BLOCKED, NOT TESTED.

| Scenario | Result | Notes |
| --- | --- | --- |
| Second Bar setup gates ready | PASS | 2026-07-07 `scripts/qa_second_bar_permission_preflight.sh --prepare-local-gates` passed against `/Applications/MenuBarDeclutter.app` with CDHash `8539bb7dff6bd994edcef7ed09603a86b337f94b`; Optional Pro, Accessibility Discovery, Accurate Icons, Screen Recording, Second Bar, and primary-click compact strip opt-in are enabled, and app-observed Accessibility/Screen Recording are both `granted`. |
| Second Bar compact strip opens and closes | PASS | 2026-07-07 live status-item click opened `Second Bar Compact Strip` at `597x34` after the compact strip top-origin frame and fixed-placement updates; the window appeared from the real MenuBarDeclutter status item and remained a one-line menu-bar-like strip. Clicking both visible hidden icons closed the strip after successful direct activation. Final installed QA URL diagnostics also recorded notch-avoiding placement `976 x 34` with `lastCompactVisibleItemCount = 1` in `build/qa-artifacts/second-bar-live/2026-07-07-current-compact/final-installed-after-compact-url.json`. Evidence: `build/qa-artifacts/second-bar-live/2026-07-07-current-compact/fixed-compact-strip-after-refresh.png`, `after-codex-computer-use-click.json`, and `after-mole-click.json`. |
| Second Bar Accurate Icons warm-up | PASS | 2026-07-07 diagnostics export `build/qa-artifacts/second-bar-live/2026-07-07-current-compact/fixed-after-status-click.json` recorded `lastIconWarmUpResult = Refreshed 14 thumbnail(s)` and `iconWarmUpInProgress = false` before manual gate audit. The final installed QA URL export `final-installed-after-compact-url.json` recorded `lastIconWarmUpResult = Refreshed 15 thumbnail(s)`. |
| Second Bar notch placement | PASS | 2026-07-07 nil-anchor QA URL run with outside-click temporarily disabled opened a one-line strip and exported `lastCompactAvoidedNotch = true`; screenshot: `build/qa-artifacts/second-bar-live/compact-strip-notch-fallback-after-warmup-fix.png`, diagnostics: `build/qa-artifacts/second-bar-live/notch-placement-diagnostics.json`. |
| Second Bar external display placement | BLOCKED | `system_profiler SPDisplaysDataType` reports only the built-in Liquid Retina XDR display on this machine; no external display is available for physical placement/Space/wake dogfood. |
| Second Bar direct activation matrix | PASS | 2026-07-07 fixture-assisted installed-app run `build/qa-artifacts/second-bar-live/after-cgevent-top-origin-batch.json` recorded 8/8 compact-strip activation rows as `PASS`; 6 rows used the guarded CGEvent click fallback after `AXPress`/`AXShowMenu` were unavailable. Real third-party follow-up then exercised WeChat, Magnet, and Surge from the compact strip with target AX/CGWindow evidence in `build/qa-artifacts/second-bar-live/real-third-party/observed-third-party-activation-evidence.txt`; matching diagnostics exports are `wechat-observed-final.json`, `magnet-observed-final.json`, and `surge-observed-final.json`. The refreshed installed run also activated `Codex Computer Use` and `Mole` from the compact strip with `PASS` diagnostics in `build/qa-artifacts/second-bar-live/2026-07-07-current-compact/after-codex-computer-use-click.json` and `after-mole-click.json`. A Magnet stale/relaunch follow-up recorded `FAIL_TARGET_NOT_FOUND` with Retry available after the owner app was told to terminate, then relaunched Magnet; evidence is under `build/qa-artifacts/second-bar-live/stale-relaunch/`. Controlled permission-revoked coverage comes from screenshot manifest row `34-compact-second-bar-accessibility-required`, which simulates Accessibility revocation after startup without changing actual local TCC. Remaining reviewed-matrix gap is popover-style rows. |
| Second Bar manual gate audit passes | PASS | `SECOND_BAR_DIAGNOSTICS_JSON=build/qa-artifacts/second-bar-live/2026-07-07-current-compact/after-mole-click.json SECOND_BAR_AUDIT_MATRIX_OUTPUT=docs/testing/pro-second-bar-direct-activation-matrix.generated.md DOGFOOD_SECOND_BAR_AUDIT_ONLY=1 scripts/qa_dogfood_preflight.sh` passed with one warning because this latest export has no failure row. Earlier `SECOND_BAR_DIAGNOSTICS_JSON=build/qa-artifacts/second-bar-live/second-bar-diagnostics-live.json SECOND_BAR_AUDIT_MATRIX_OUTPUT=docs/testing/pro-second-bar-direct-activation-matrix.generated.md SECOND_BAR_AUDIT_REQUIRE_FAILURE_ROW=1 DOGFOOD_SECOND_BAR_AUDIT_ONLY=1 scripts/qa_dogfood_preflight.sh` passed with 0 warnings for failure-row coverage. |
| Profiles create/duplicate/delete | NOT TESTED | |
| Profile dry run | NOT TESTED | |
| Conservative profile apply | NOT TESTED | |
| Triggers paused/resumed | NOT TESTED | |
| URL automation expand/collapse/reveal-all | NOT TESTED | |
| URL automation profile apply | NOT TESTED | |
| No silent bulk icon moves | NOT TESTED | |

After the Second Bar rows above are updated and reviewed direct activation rows
have been copied into `docs/testing/pro-second-bar-direct-activation-matrix.md`,
run:

```sh
scripts/qa_second_bar_signoff_audit.sh
```

For the diagnostics-backed dogfood preflight hook, set
`SECOND_BAR_AUDIT_MIN_WARMED_ICONS` when the Accurate Icons warm-up threshold
should be stricter than the default of one refreshed thumbnail.
