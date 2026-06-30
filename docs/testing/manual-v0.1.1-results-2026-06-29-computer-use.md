# Manual v0.1.1 Results - 2026-06-29 Computer Use

Date: 2026-06-29
Tester: Codex with Codex Computer Use and local shell verification
Build: `0.1.1 (2)`, dry-run Release build
macOS version: macOS 26.1 (25B78)
Hardware: MacBook Pro, Mac16,7, Apple M4 Pro, 48 GB memory
Displays: Built-in Liquid Retina XDR Display, 3456 x 2234 Retina, main display
Installed path: `/Applications/MenuBarDeclutter.app`

Scope: UI interaction used Codex Computer Use. This run did not change macOS System Settings, grant permissions, enable Login Items, trigger Shortcuts actions, or click any permission-requesting control.

| Gate | PASS/FAIL/BLOCKED | Notes |
| --- | --- | --- |
| Installed app identity | PASS | General Settings showed running from `/Applications/MenuBarDeclutter.app`, marketing version `0.1.1`, build `2`, app version `0.1.1 (2)`, and bundle identifier `Yongjun-Zhang.MenuBarDeclutter`. |
| First-run onboarding replay | PASS | `Show Onboarding Again` opened the seven-step flow. The native cleanup page appeared as step 2 with Apple Menu Bar settings guidance. `Open Menu Bar Settings` opened System Settings to Menu Bar settings. No settings were changed. |
| Privacy Basic Mode boundary | PASS | Privacy page showed Accessibility, Screen Recording, Apple Events, Input Monitoring, and Network Access as `Not Requested` or `Not Used` in Basic Mode. |
| Pro permission no-prompt boundary | PASS | Enabling Pro Mode inside the app did not trigger a macOS permission prompt. Accessibility remained `Not Requested`; request/open-settings controls were visible but not clicked. |
| Search degraded state | PASS | With Pro Mode enabled and Accessibility not granted, Search showed Pro/Accessibility requirements and did not claim usable discovery. |
| Second Bar degraded state | PASS | With Pro Mode enabled and Accessibility not granted, Second Bar controls stayed disabled, preview remained visible, and copy stated it does not use Screen Recording or captured menu bar pixels. |
| Automation/App Intents Settings gates | PASS | Computer Use verified preview action labels: local Basic Mode actions `Ready`, `Apply Profile` `Profile Gate`, and the spacing preset preview action `Labs Gate`. Toggling in-app gates changed labels to `Ready`, `Requires Labs`, and `Disabled` as expected, then settings were restored. |
| Feature status Settings UI | PASS | Computer Use verified Stable/Preview/Labs/Experimental-style badges and notices across Settings. Final spot checks confirmed General, Private Access, Automation, and Import/Export text is readable. A latest debug-build spot check confirmed full `Export` and `Choose File` button labels after the shared row layout fix. |
| Basic live menu bar | BLOCKED | Live command-drag/collapse/reveal verification requires hands-on menu bar interaction. Computer Use could inspect the app window but timed out when attempting to inspect `SystemUIServer`. |
| Crowded menu bar | BLOCKED | Requires a real crowded menu bar setup and hands-on verification. |
| Notch layout | BLOCKED | Built-in display is available, but panel placement/search behavior was not exercised against live menu bar interactions in this Computer Use-only run. |
| External displays | BLOCKED | No external display was attached for this run. |
| Sleep/wake and Spaces | BLOCKED | Not performed because it changes the live workstation session outside the app UI. |
| Appearance variants | PASS | Full UI test launch checks passed in both light and dark appearance. Manual menu bar appearance variants were not changed. |
| Launch at Login | BLOCKED | Settings showed Login Items status as `Not Found`; enabling Launch at Login changes macOS Login Items and was not performed in this run. |
| Pro permission grant/revoke | BLOCKED | Granting/revoking Accessibility requires changing macOS Privacy settings; this run verified only the no-prompt and unavailable-state boundary. |
| Safe Mode | PASS | Automated suite covers Safe Mode controls and gating. Manual Option-launch/crash-marker verification was not run with Computer Use. |
| Private Access | BLOCKED | Touch ID/cancel/unavailable states require live LocalAuthentication prompts and were not exercised. |
| Shortcuts real app surface | BLOCKED | The Settings gate model and unit tests passed, but real Shortcuts discovery/execution was not performed. |
| Labs behavior | BLOCKED | Labs gate labels were verified. Actual Spacing Labs behavior was not exercised. |
| Experimental Icon Moving | BLOCKED | Explicit confirmation and hands-on before/after menu bar positions are required. |
| Diagnostics export redaction | PASS | Full automated tests passed for diagnostics export behavior; no manual diagnostics export was generated in this run. |
| Uninstall | BLOCKED | Not performed; the installed app was left in `/Applications` for further testing. |

Supplementary command results:

| Command | Result |
| --- | --- |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/AppIntentExecutionServiceTests` | PASS, 10 Swift Testing tests |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/DesignSystemSemanticsTests` | PASS, 8 Swift Testing tests |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/SettingsExportImportTests` | PASS, 7 Swift Testing tests |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PASS, installed and verified `/Applications/MenuBarDeclutter.app`; non-notarized `spctl` and `stapler` warnings were expected |
| `scripts/build_release.sh --dry-run` | PASS, archive/export/package/artifact verification completed for the final UI copy/layout changes |
| `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` | PASS, direct installed-app verification after copying the final dry-run export into `/Applications` |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS, 320 Swift Testing tests and 7 UI tests |

Note: one later `scripts/build_release.sh --dry-run --install --verify-installed` re-run completed archive/export/package/artifact verification and copied the app to `/Applications`, but `open` returned LaunchServices error `-600` before the script reached installed-app verification. Direct installed-app verification passed afterward, and `open -na /Applications/MenuBarDeclutter.app` launched cleanly.

No diagnostics export or screenshots were attached.
