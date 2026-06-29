# Phase 9.3 Installed Alpha QA Run

Date: 2026-06-28 local machine time
Tester: Codex implementation and installed-app dry-run pass
Scheme: `MenuBarDeclutter`
Version/build: `0.1.0 (1)` after Phase 9.5 version freeze

Allowed results: PASS, FAIL, BLOCKED, NOT TESTED.

| Check | Result | Notes |
| --- | --- | --- |
| Build environment recorded | PASS | Xcode 26.3, macOS 26.1 local audit output captured in signing audit |
| Git commit | NOT TESTED | Current working tree has uncommitted implementation work |
| Archive | PASS | `scripts/release_archive.sh` created `build/Archives/MenuBarDeclutter.xcarchive` |
| Export | PASS | `scripts/release_export_app.sh` created `build/Export/MenuBarDeclutter.app` by deterministic archive app copy because `Config/ExportOptions.plist` is absent |
| Package | PASS | `scripts/release_package_zip.sh` created `build/Dist/MenuBarDeclutter-alpha.zip` and `build/Dist/MenuBarDeclutter-v0.1.0.zip` |
| Notarization | BLOCKED | Developer ID identity and notary credentials were not found; `scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-alpha.zip` passed |
| Staple | BLOCKED | `scripts/release_staple.sh build/Export/MenuBarDeclutter.app` failed with error 65 because no notarization ticket exists |
| Gatekeeper validation | BLOCKED | `codesign --verify` passed; `spctl` rejected and `stapler validate` reported no ticket, expected for dry-run notarization |
| Installed path | PASS | Installed to `/Applications/MenuBarDeclutter.app` |
| Launch from installed app | PASS | `scripts/release_install_local.sh build/Export/MenuBarDeclutter.app` copied and launched the installed app |
| Launch at Login status | NOT TESTED | Requires hands-on System Settings verification; Settings/Diagnostics now show the running bundle path and `/Applications` status |
| Restart/login test | NOT TESTED | Requires hands-on login cycle |
| Basic Mode smoke test | NOT TESTED | Requires real menu bar interaction |
| Pro Mode permission smoke test | NOT TESTED | Requires System Settings Accessibility flow |
| Diagnostics export | PASS | Covered by unit tests and preflight; installed hands-on export remains manual |
| Privacy verification | PASS | `scripts/verify_privacy_boundary.sh build/Export/MenuBarDeclutter.app` and `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` passed |
| Network observation | PASS | `scripts/qa_network_watch.sh --installed` found the running PID and observed no sockets with `lsof -nP -a -i -p`; interactive `nettop` remains manual |

## Known Issues

- Real notarization is blocked until Developer ID Application and notary credentials are configured.
- Installed Launch at Login restart/login verification remains a manual validation gate.
- Interactive network observation remains manual.
