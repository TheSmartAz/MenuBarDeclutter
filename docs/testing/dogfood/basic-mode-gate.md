# Gate A: Basic Mode Daily Use

Basic Mode must work for 3 to 5 days of daily use before Pro Mode work can block the alpha.

Allowed results: PASS, FAIL, BLOCKED, NOT TESTED.

| Scenario | Result | Notes |
| --- | --- | --- |
| App starts cleanly | PASS | 2026-07-04: `scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app` launched the installed app and completed successfully. Direct `spctl` assessment still reports local `Too many open files` system-policy instability for the non-notarized dry-run app, but runtime launch passed. |
| Onboarding is understandable | NOT TESTED | |
| Separator can be Command-dragged | NOT TESTED | |
| Collapse/expand works with real icons | NOT TESTED | |
| Reveal all works | NOT TESTED | |
| Always-hidden works | NOT TESTED | |
| Auto-rehide does not collapse while interacting | NOT TESTED | |
| Hover reveal does not flicker | NOT TESTED | |
| Hotkey does not conflict | NOT TESTED | |
| App survives sleep/wake | NOT TESTED | |
| App survives display changes | NOT TESTED | |
| App recovers after force quit | NOT TESTED | |
| Safe Mode works | PARTIAL | 2026-07-04: installed smoke verified one-shot next-launch Safe Mode flag consumption and normal relaunch. Option-launch Safe Mode remains hands-on and not tested. |
| Reset layout works | NOT TESTED | |
| Diagnostics export works | NOT TESTED | |
| No Accessibility prompt appears | PASS | 2026-07-04: installed smoke launched Basic Mode without an Accessibility prompt, and installed privacy verification confirmed Accessibility remains behind opt-in Pro discovery. |
| No network connection appears | PASS | 2026-07-04: installed smoke observed no network sockets for the running installed app PID. Source and installed-bundle privacy checks also passed with no network entitlements or direct network/analytics APIs. |

## 2026-07-04 Notes

- Treat this gate as smoke-started, not completed for real daily use. Installed launch, URL reuse, privacy, no-network, and one-shot Safe Mode flag smoke now pass.
- Next valid dogfood run should start from a locally launchable installed app, then record day-by-day behavior in `docs/testing/dogfood/daily-use-template.md`.
