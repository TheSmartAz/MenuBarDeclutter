Implement Phase 9.3 — Signed / Notarized Installed-App Alpha.

Context:
Phases 0–9.1 are implemented for MenuBarDeclutter. Post-9.1 refactoring/hardening is also complete. Phase 10 ScreenCaptureKit visual capture remains intentionally deferred.

Current status:
- Canonical product/target/scheme: MenuBarDeclutter.
- Deprecated compatibility scheme: MenuBar-Manager.
- macOS minimum target: 26.0+.
- App type: LSUIElement menu bar utility.
- Basic Mode is permission-free.
- Pro Mode is opt-in and Accessibility-only.
- Release artifact verification has passed locally.
- Notarization and installed-app Launch at Login validation are not yet tested.
- Interactive nettop/network monitoring remains manual QA.

Phase goal:
Create a repeatable signed/notarized installed-app alpha workflow and validate that MenuBarDeclutter works correctly as an installed app, not just from Xcode or DerivedData.

Hard constraints:
1. Do not implement Phase 10.
2. Do not add ScreenCaptureKit.
3. Do not add Screen Recording permission.
4. Do not add Apple Events.
5. Do not add Input Monitoring.
6. Do not add network access.
7. Do not add telemetry.
8. Keep Basic Mode fully usable without Accessibility.
9. Keep Pro Mode opt-in.
10. Keep icon moving disabled by default and visibly experimental.
11. Do not rename final product identity yet unless the final product name has been explicitly chosen.
12. If Developer ID credentials are unavailable, implement dry-run notarization checks and document the exact missing credentials.
Task 1 — Release signing configuration audit
Audit signing and release configuration.

Run:
- xcodebuild -list
- xcodebuild -showBuildSettings -scheme MenuBarDeclutter -configuration Release
- security find-identity -v -p codesigning || true

Create/update:
- docs/release/phase-9.3-signing-audit.md

Audit:
1. Bundle identifier.
2. Product name.
3. Executable name.
4. Wrapper extension.
5. LSUIElement.
6. URL scheme.
7. Deployment target.
8. Hardened Runtime setting.
9. App Sandbox setting.
10. Entitlements file.
11. Network entitlements.
12. Accessibility-related usage strings or docs.
13. ScreenCaptureKit linkage absence.
14. Screen Recording usage string absence.
15. Apple Events usage string absence.
16. Input Monitoring usage string absence.
17. Code signing identity availability.
18. Developer ID Application identity availability.
19. Team ID availability.
20. Notarization credential availability.

Acceptance criteria:
- Signing audit doc exists.
- Missing signing/notarization requirements are documented clearly.
- No privacy-boundary regression is introduced.
Task 2 — Archive and export scripts
Create production-grade archive/export scripts.

Create:
- scripts/release_archive.sh
- scripts/release_export_app.sh
- scripts/release_package_zip.sh
- scripts/release_clean.sh

Requirements:
- Use set -euo pipefail.
- Print every major command.
- Default scheme: MenuBarDeclutter.
- Default configuration: Release.
- Default archive path: build/Archives/MenuBarDeclutter.xcarchive.
- Default export path: build/Export/MenuBarDeclutter.app.
- Default zip path: build/Dist/MenuBarDeclutter-alpha.zip.
- Do not require network.
- Do not notarize yet in this task.
- Should fail loudly if archive/export path is missing.

release_archive.sh:
- Run xcodebuild archive.
- Use generic/platform=macOS destination.
- Store archive under build/Archives/.
- Write logs to build/Logs/.

release_export_app.sh:
- Export app from archive.
- Prefer xcodebuild -exportArchive with ExportOptions.plist if available.
- If exportArchive is too project-specific, copy Products/Applications/MenuBarDeclutter.app from archive and document why.

release_package_zip.sh:
- Create a notarization-ready zip or ditto archive.
- Use ditto -c -k --keepParent when appropriate.
- Store under build/Dist/.

release_clean.sh:
- Remove build/Archives, build/Export, build/Dist, build/Logs.
- Do not remove DerivedData unless explicit flag is provided.

Acceptance criteria:
- Archive script creates an .xcarchive.
- Export script creates MenuBarDeclutter.app.
- Package script creates a distributable zip.
- Scripts are executable.
- Scripts are documented in docs/release/phase-9.3-installed-alpha.md.
Task 3 — Notarization and stapling workflow
Implement notarization workflow.

Create:
- scripts/release_notarize.sh
- scripts/release_staple.sh
- scripts/release_validate_gatekeeper.sh
- docs/release/notarization-setup.md
- docs/release/notarization-runbook.md

release_notarize.sh:
- Accept packaged zip path.
- Use xcrun notarytool submit.
- Support:
  - --keychain-profile
  - --apple-id / --team-id / app-specific password through environment variables
- Prefer keychain profile.
- Support dry-run mode if credentials are missing.
- Write submission output to build/Logs/notarization-submit.log.
- If using --wait, record final status.
- If not using --wait, document how to poll.

release_staple.sh:
- Use xcrun stapler staple on exported .app or packaged app.
- Validate staple result.
- Write logs.

release_validate_gatekeeper.sh:
- Run:
  - codesign --verify --deep --strict --verbose=4 MenuBarDeclutter.app
  - spctl --assess --type execute --verbose=4 MenuBarDeclutter.app
  - xcrun stapler validate MenuBarDeclutter.app
- Print clear PASS/FAIL.

notarization-setup.md:
- Explain required Apple Developer Program membership.
- Explain Developer ID Application certificate.
- Explain notarytool credential profile.
- Explain no credentials should be committed.
- Explain how to run dry-run if credentials are unavailable.

notarization-runbook.md:
- Full steps:
  1. Clean.
  2. Archive.
  3. Export.
  4. Verify privacy boundary.
  5. Package.
  6. Submit notarization.
  7. Staple.
  8. Validate Gatekeeper.
  9. Install locally.
  10. Run installed-app QA.

Acceptance criteria:
- Notarization scripts exist.
- Scripts support dry-run.
- No secrets are stored in repo.
- Gatekeeper validation script exists.
- Notarization docs are clear enough to follow manually.
Task 4 — Installed-app validation workflow
Create installed-app validation workflow.

Create:
- scripts/release_install_local.sh
- scripts/release_uninstall_local.sh
- docs/testing/installed-app-qa.md
- docs/testing/installed-app-qa-run-template.md

release_install_local.sh:
- Accept app path.
- Default install destination:
  - /Applications/MenuBarDeclutter.app
- If /Applications requires permissions, print instructions.
- Quit running MenuBarDeclutter before install.
- Copy app.
- Clear quarantine only if explicitly requested by flag.
- Launch installed app with open.
- Print installed app bundle path.

release_uninstall_local.sh:
- Quit MenuBarDeclutter.
- Remove installed app if user confirms or --yes is passed.
- Do not delete Application Support by default.
- Offer optional --purge-user-data flag.
- If purging, remove only MenuBarDeclutter app support/preferences/cache paths and print them first.

installed-app-qa.md:
Test:
1. Launch from /Applications.
2. Confirm no Dock icon.
3. Confirm menu bar item appears.
4. Confirm Basic Mode works.
5. Confirm Settings opens.
6. Confirm URL scheme works.
7. Confirm diagnostics export works.
8. Confirm privacy boundary script passes on installed app.
9. Confirm Launch at Login status display.
10. Enable Launch at Login.
11. Restart/logout-login test.
12. Confirm app launches after login.
13. Disable Launch at Login.
14. Confirm System Settings reflects status.
15. Confirm Pro Mode permission request opens the real Accessibility flow.
16. Confirm revoking Accessibility degrades Pro features.

Acceptance criteria:
- Local install/uninstall scripts exist.
- Installed-app QA doc exists.
- Launch at Login installed-app behavior is explicitly tested.
- Purge behavior is safe and opt-in.
Task 5 — Installed-app privacy and network validation
Extend privacy validation to installed app.

Modify:
- scripts/verify_privacy_boundary.sh
- scripts/verify_release_artifact.sh
- scripts/qa_network_watch.sh

Add:
- scripts/verify_installed_app.sh

verify_installed_app.sh:
- Default path: /Applications/MenuBarDeclutter.app
- Check:
  1. App exists.
  2. Bundle identifier.
  3. LSUIElement.
  4. URL scheme.
  5. Entitlements.
  6. No network entitlements.
  7. No ScreenCaptureKit linkage.
  8. No Screen Recording usage string.
  9. No Apple Events usage string.
  10. No Input Monitoring usage string.
  11. codesign validity.
  12. spctl assessment if notarized.
  13. stapler validation if notarized.

qa_network_watch.sh:
- Add installed-app mode:
  - find running MenuBarDeclutter PID.
  - run lsof -i for that PID.
  - print nettop command for interactive observation.
  - do not require sudo unless user chooses nettop.
  - do not upload data.

Acceptance criteria:
- Installed app can be privacy-verified.
- Network watch remains local/manual.
- No privacy claims become false.
Task 6 — Phase 9.3 QA run docs
Create:
- docs/testing/phase-9.3-installed-alpha-qa-run.md
- docs/status/phase-9.3-final-report.md
- docs/release/alpha-installed-release-notes-template.md

QA run should include:
1. Build environment.
2. Git commit.
3. Scheme.
4. Archive result.
5. Export result.
6. Package result.
7. Notarization result or dry-run reason.
8. Staple result or skip reason.
9. Gatekeeper validation.
10. Installed path.
11. Launch from installed app.
12. Launch at Login status.
13. Restart/login test result.
14. Basic Mode smoke test.
15. Pro Mode permission smoke test.
16. Diagnostics export.
17. Privacy verification.
18. Network observation.
19. Known issues.

Final report should include:
- completed tasks.
- skipped tasks with reasons.
- exact commands run.
- exact PASS/FAIL/BLOCKED status.
- whether app is ready for Phase 9.4 dogfood bugfix sprint.

Acceptance criteria:
- Phase 9.3 has a concrete run record.
- Notarization is either completed or blocked by documented credentials.
- Installed-app Launch at Login is tested or explicitly blocked.
Task 7 — Final validation commands
Run and record:

1. xcodebuild -list
2. xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'
3. xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
4. scripts/verify_privacy_boundary.sh
5. scripts/release_clean.sh
6. scripts/release_archive.sh
7. scripts/release_export_app.sh
8. scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app
9. scripts/release_package_zip.sh
10. scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-alpha.zip
11. scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app
12. scripts/release_install_local.sh build/Export/MenuBarDeclutter.app
13. scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app
14. scripts/qa_network_watch.sh --installed

If notarization credentials are available, run real notarization and stapling instead of dry-run.

Acceptance criteria:
- Main app builds/tests.
- Release archive/export/package path works.
- Installed app validation works.
- Privacy boundary passes.
- Final report is updated.