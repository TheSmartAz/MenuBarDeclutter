# Phase 9.4 Risk Board

## v0.1 Blocker Watch

| Risk | Current Control |
| --- | --- |
| Basic Mode fails real menu bar collapse/expand | `docs/testing/v0.1-regression-suite.md` |
| Safe Mode cannot rescue broken state | Safe Mode docs, health UI, reset actions |
| Privacy boundary regression | `scripts/verify_privacy_boundary.sh`, `scripts/verify_installed_app.sh` |
| Installed app does not launch | Release archive/export/install scripts |
| Launch at Login advertised but fails installed app | Installed-app QA and stale-item repair docs |

## Accepted Known Limitations

| Risk | Decision |
| --- | --- |
| Icon Moving may fail | Experimental, disabled by default, not a Basic Mode blocker |
| Phase 10 visual capture absent | Explicitly post-v0.1 |
| Second Bar does not use captured pixels | Documented limitation |
| AX metadata incomplete/stale | Pro surfaces degrade and Basic Mode remains usable |
| Focus/Wi-Fi providers inactive | Disabled until safe providers exist |
| External display/notch behavior | Manual QA and known limitation until real hardware coverage |

## Release Recommendation

Proceed toward Phase 9.5 Basic Stable Freeze with the above manual gates clearly tracked. Do not mark v0.1 stable until privacy, Safe Mode, installed-app launch, and Basic Mode hands-on checks are complete or exceptions are explicitly accepted.
