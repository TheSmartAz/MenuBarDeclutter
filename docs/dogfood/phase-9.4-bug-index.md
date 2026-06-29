# Phase 9.4 Bug Index

No confirmed dogfood bug reports with reproduction steps were present in the repository at the start of this implementation pass. The table below tracks known risks and manual gaps as issue candidates.

| ID | Area | Summary | Severity | Release Blocking | Status |
| --- | --- | --- | --- | --- | --- |
| DF-001 | Basic Mode | Real Command-drag separator placement not hands-on validated | S1 if failed | v0.1-blocker if failed | Manual QA pending |
| DF-002 | Basic Mode | Collapse/expand/reveal all with real menu bar icons not hands-on validated | S1 if failed | v0.1-blocker if failed | Manual QA pending |
| DF-003 | Auto-rehide / hover | Auto-rehide and hover reveal not fully dogfooded | S1 if unstable | Known limitation | Defaults frozen off |
| DF-004 | Launch at Login | Installed-app `SMAppService` flow not validated | S2 | v0.1-blocker if advertised and failed | Scripts/docs added |
| DF-005 | Pro Accessibility | Grant/revoke flow needs real System Settings QA | S3 | post-v0.1 unless Basic affected | Manual QA pending |
| DF-006 | Find Icon | Real AX search depends on live metadata | S3 | post-v0.1 | Disabled until Pro requirements |
| DF-007 | Second Bar | Placement and stale cache need live display QA | S3 | post-v0.1 | Disabled until Pro requirements |
| DF-008 | Icon Moving | Simulated Command-drag may fail on third-party/system items | S4 | Not blocking | Disabled by default; emergency recovery added |
| DF-009 | Automation | Triggers should not run silently or loop | S3 | v0.1-blocker if unsafe | Paused by default; existing debounce/throttle retained |
| DF-010 | Safe Mode | Crash marker and option-launch flow require hands-on QA | S1 if failed | v0.1-blocker if failed | Manual QA pending |
| DF-011 | Signing | Developer ID/notary credentials missing | S2 | Blocks notarized public release | Dry-run workflow documented |
| DF-012 | Hardware | Notch/external display/sleep-wake/Spaces need real QA | S1/S5 | v0.1-blocker only if Basic unrecoverable | Known limitation/manual QA |

## Fixed In This Pass

- v0.1 defaults freeze disables risky alpha defaults: auto-rehide, Pro discovery, Find Icon, Icon Moving, Smart Triggers, and hotkeys are off; automation is paused.
- Migration resets risky alpha flags and backs up settings.
- Installed-app scripts and validation docs added.
- Emergency status menu action added: Reveal All + Reset Separators.
- Diagnostics now show bundle path and whether the app is running from `/Applications`.
