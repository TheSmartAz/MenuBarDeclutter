# Alpha RC QA Run

Use this template for Release Candidate lane work from `docs/testing/qa-process.md`. For patch or risk-lane work, record only the relevant commands and manual rows.

Date:
Tester:
Machine:
macOS version:
Build:
Git commit:

Allowed results: PASS, FAIL, BLOCKED, NOT TESTED.

## Preflight

| Check | Result | Notes |
| --- | --- | --- |
| `scripts/qa_preflight.sh` | NOT TESTED | |
| `scripts/verify_privacy_boundary.sh` | NOT TESTED | |
| Clean working tree or documented diff | NOT TESTED | |

## Basic Mode

| Scenario | Result | Notes |
| --- | --- | --- |
| First launch | NOT TESTED | |
| Onboarding | NOT TESTED | |
| Command-drag separator placement | NOT TESTED | |
| Collapse/expand | NOT TESTED | |
| Reveal all | NOT TESTED | |
| Always-hidden section | NOT TESTED | |
| Option-click reveal all | NOT TESTED | |
| Auto-rehide | NOT TESTED | |
| Hover reveal | NOT TESTED | |
| Global hotkey | NOT TESTED | |
| Reset separator length | NOT TESTED | |
| Reset app layout | NOT TESTED | |
| Reset all settings | NOT TESTED | |

## Visual And Display

| Scenario | Result | Notes |
| --- | --- | --- |
| Transparent menu bar | NOT TESTED | |
| Reduce Transparency | NOT TESTED | |
| Increase Contrast | NOT TESTED | |
| Light mode | NOT TESTED | |
| Dark mode | NOT TESTED | |
| Built-in display | NOT TESTED | |
| Notch display | NOT TESTED | |
| External display | NOT TESTED | |
| External display as primary | NOT TESTED | |
| Display disconnected while collapsed | NOT TESTED | |
| Sleep/wake | NOT TESTED | |
| Full-screen app / Space switch | NOT TESTED | |

## Pro Mode

| Scenario | Result | Notes |
| --- | --- | --- |
| Pro Mode disabled | NOT TESTED | |
| Enable Pro Mode | NOT TESTED | |
| Request Accessibility permission | NOT TESTED | |
| Grant permission | NOT TESTED | |
| Revoke permission | NOT TESTED | |
| Relaunch after revoke | NOT TESTED | |
| Manual scan refresh | NOT TESTED | |
| Diagnostics table | NOT TESTED | |

## Find Icon And Second Bar

| Scenario | Result | Notes |
| --- | --- | --- |
| Find Icon unavailable state | NOT TESTED | |
| Find Icon search and keyboard navigation | NOT TESTED | |
| Find Icon visible/hidden/always-hidden activation | NOT TESTED | |
| Highlight overlay | NOT TESTED | |
| Second Bar unavailable state | NOT TESTED | |
| Second Bar placements | NOT TESTED | |
| Second Bar search/keyboard/auto-close | NOT TESTED | |
| External display/notch Second Bar behavior | NOT TESTED | |

## Icon Moving

| Scenario | Result | Notes |
| --- | --- | --- |
| Disabled by default | NOT TESTED | |
| Experimental warning before enablement | NOT TESTED | |
| Move third-party item to Hidden/Visible/Always Hidden | NOT TESTED | |
| Move Left / Move Right | NOT TESTED | |
| Reject own app/system items | NOT TESTED | |
| Permission revoke/display change during move | NOT TESTED | |

## Profiles, Triggers, Health

| Scenario | Result | Notes |
| --- | --- | --- |
| Profile create/duplicate/delete/export/import | NOT TESTED | |
| Dry run and Basic-only apply | NOT TESTED | |
| Pro moves are report-only on profile apply | NOT TESTED | |
| Display/app/time triggers | NOT TESTED | |
| Pause all automation | NOT TESTED | |
| Crash marker Safe Mode | NOT TESTED | |
| Option-key Safe Mode | NOT TESTED | |
| Safe Mode next launch flag | NOT TESTED | |
| Fix Automatically | NOT TESTED | |
| Export Health Report | NOT TESTED | |

## Release Install

| Scenario | Result | Notes |
| --- | --- | --- |
| Archive | NOT TESTED | |
| Codesign verification | NOT TESTED | |
| Notarization or skip reason | NOT TESTED | |
| Installed app launch | NOT TESTED | |
| Launch at Login from installed signed app | NOT TESTED | |
| Network watch | NOT TESTED | |

## Summary

Blocking issues:

Known limitations confirmed:

Alpha RC recommendation:
