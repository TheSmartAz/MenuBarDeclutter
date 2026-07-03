# Installed-App QA

Installed-app QA is required for release candidates and installed-app behavior claims. It is not required for ordinary patch-lane changes; see `docs/testing/qa-process.md`.

Allowed results: PASS, FAIL, BLOCKED, NOT TESTED.

## Install

1. Build/export with `scripts/release_archive.sh` and `scripts/release_export_app.sh`.
2. Install with `scripts/release_install_local.sh build/Export/MenuBarDeclutter.app`.
3. Confirm the installed path is `/Applications/MenuBarDeclutter.app`.

## Test Matrix

| Scenario | Expected |
| --- | --- |
| Launch from `/Applications` | App starts without a Dock icon |
| Menu bar item appears | Control item is visible and opens the status menu |
| Basic Mode works | Collapse, expand, reveal all, reset separator length work without permissions |
| Settings opens | General, Behavior, Privacy, Search, Second Bar, Profiles, Advanced, Diagnostics are reachable |
| URL scheme works | `open menubardeclutter://expand` is local and command-limited |
| Diagnostics export works | Export contains version/build and privacy exclusions |
| Privacy boundary | `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` passes |
| Launch at Login status | Settings shows SMAppService status and bundle path |
| Enable Launch at Login | System Settings reflects the item or requires approval |
| Restart/logout-login | App launches after login when enabled |
| Disable Launch at Login | System Settings reflects disabled/not registered |
| Pro Mode permission flow | Enabling Pro opens the real Accessibility flow only after opt-in |
| Accessibility revoke | Find Icon and Second Bar degrade without breaking Basic Mode |
| Network watch | `scripts/qa_network_watch.sh --installed` shows no Basic Mode connections |

## Stale Login Item Repair

If Launch at Login status is stale or points at an old build:

1. Disable Launch at Login in MenuBarDeclutter.
2. Open System Settings -> General -> Login Items.
3. Remove stale MenuBarDeclutter entries.
4. Quit all running copies.
5. Launch `/Applications/MenuBarDeclutter.app`.
6. Refresh Login Item Status in Settings.
7. Enable Launch at Login again.

Do not validate Launch at Login from Xcode or DerivedData.
