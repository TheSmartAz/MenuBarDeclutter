# Phase 9.4 Dogfood Triage

Date: 2026-06-28

Inputs reviewed:

- `docs/testing/dogfood/`
- `docs/testing/alpha-rc-qa-run-2026-06-28.md`
- `docs/testing/known-risk-areas.md`
- `docs/testing/manual-qa.md`
- `docs/release/alpha-rc-known-limitations.md`

## Classification Summary

| Area | Current Issues | Severity | Release Decision |
| --- | --- | --- | --- |
| Basic Mode | No confirmed automated blocker; real menu bar placement/collapse/expand remains manual QA | S1 if failure appears | v0.1-blocker only if hands-on QA fails |
| Status items / separators | Display-change and manual Command-drag placement require real QA | S1/S5 | v0.1-nice-to-fix unless Basic Mode fails |
| Auto-rehide / hover | Not fully dogfooded; defaults frozen off for v0.1 | S1 if enabled and unstable | Known limitation, optional off by default |
| Hotkeys | Conflict handling covered by tests; default off | S1 if conflict traps user | Known limitation, optional off by default |
| Settings / onboarding | Copy clarified for v0.1 defaults and privacy | S5 | Fixed/docs |
| Launch at Login | Installed-app validation pending; Xcode/DerivedData status can be stale | S2 | Manual gate |
| Pro Accessibility | Grant/revoke requires System Settings QA | S3 | Optional, degrade gracefully |
| Find Icon | Unavailable state tests pass; real AX data manual | S3 | Optional, disabled by default |
| Second Bar | Unavailable state tests pass; placement manual | S3 | Optional, disabled by default |
| Icon Moving | Experimental, not hands-on validated | S4 | Disabled by default; not v0.1 blocker |
| Profiles / triggers / automation | Debounced and command-limited; automation paused by default | S3/S4 | Disabled/paused by default |
| Health / Safe Mode | Unit/manual docs exist; hands-on crash-marker QA pending | S1 if failure appears | v0.1 manual gate |
| Packaging / signing / notarization | Developer ID/notary credentials missing | S2 | Blocks notarized release, not dry-run workflow |
| Privacy boundary | Automated checks pass in prior alpha; scripts strengthened | S0 if regression | v0.1-blocker if failing |
| macOS 26 visual behavior | Light/dark UI tests pass; system appearance scenarios manual | S5 | Known limitation |
| External display / notch / sleep-wake / Spaces | Hardware/system-state QA pending | S1/S5 | Manual gate/known limitation |

## v0.1 Blockers

No confirmed automated v0.1 Basic Mode blocker is present in the reviewed evidence. The following gates remain blocking until passed or explicitly accepted:

- Privacy verification must pass.
- Safe Mode hands-on rescue behavior must pass.
- Installed-app launch must pass if Launch at Login is advertised.
- Any discovered S0/S1 Basic Mode failure blocks v0.1.

## Non-Blocking For v0.1

- Icon Moving reliability issues, while disabled by default and recoverable.
- Phase 10 visual icon capture.
- Notch/external display limitations when documented and not causing unrecoverable Basic Mode failure.
- Real notarization if the release is explicitly labeled dry-run/internal only.
