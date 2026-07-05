Implement Stable Release v0.1 — Release Candidate to Stable Distribution.

Context:
Phase 9.5 froze v0.1 scope, defaults, migration, docs, and release blockers. Now produce the final v0.1 stable release artifact and release record.

Phase goal:
Create a clean v0.1.0 stable build, run the full release validation suite, notarize/staple if credentials are available, package the artifact, and generate final release notes.

Hard constraints:
1. Do not add features.
2. Do not change defaults unless fixing a release blocker.
3. Do not implement Phase 10.
4. Do not add ScreenCaptureKit.
5. Do not add Screen Recording.
6. Do not add Apple Events.
7. Do not add Input Monitoring.
8. Do not add network access.
9. Do not add telemetry.
10. Do not ship with unreviewed experimental features enabled by default.
11. Do not ship if privacy verification fails.
12. Do not ship if Safe Mode fails.
13. Do not ship if Basic Mode release gate fails.
Task 1 — Final release preflight
Create:
- docs/release/v0.1-final-preflight.md

Run:
1. git status --short
2. xcodebuild -list
3. xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'
4. xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
5. scripts/verify_privacy_boundary.sh
6. scripts/qa_preflight.sh

Preflight checks:
- MARKETING_VERSION = 0.1.0.
- Build number set.
- Bundle identifier final enough for v0.1.
- Product name final enough for v0.1 or documented as temporary/private.
- URL scheme final enough for v0.1.
- App Support path final enough for v0.1.
- Privacy docs match implementation.
- Known limitations complete.
- Release blockers closed or accepted.

Acceptance criteria:
- Preflight doc exists.
- No unexplained dirty state.
- Tests pass.
- Privacy verification passes.
Task 2 — Final artifact build
Run final clean release artifact build.

Commands:
1. scripts/release_clean.sh
2. scripts/release_archive.sh
3. scripts/release_export_app.sh
4. scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app
5. scripts/release_package_zip.sh

Artifacts:
- build/Archives/MenuBarDeclutter.xcarchive
- build/Export/MenuBarDeclutter.app
- build/Dist/MenuBarDeclutter-v0.1.0.zip

If DMG support exists:
- build/Dist/MenuBarDeclutter-v0.1.0.dmg

If DMG support does not exist:
- Do not add complex DMG work unless trivial.
- Zip is acceptable for private stable v0.1.

Acceptance criteria:
- Clean release app exists.
- Release zip exists.
- Artifact verification passes.
Task 3 — Notarization, stapling, Gatekeeper validation
Run notarization if credentials are available.

Commands:
1. scripts/release_notarize.sh build/Dist/MenuBarDeclutter-v0.1.0.zip
2. scripts/release_staple.sh build/Export/MenuBarDeclutter.app
3. scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app

If credentials are not available:
- Do not fake success.
- Mark release as "local stable / unnotarized".
- Document why notarization is blocked.
- Do not call it public stable if notarization is required for intended distribution.

Create:
- docs/release/v0.1-notarization-report.md

Report:
- submission id.
- status.
- log path.
- staple result.
- Gatekeeper result.
- skip reason if not run.

Acceptance criteria:
- Notarization status is explicit.
- Gatekeeper validation status is explicit.
- Release label accurately reflects notarization status.
Task 4 — Final installed-app regression run
Install and validate final v0.1 build.

Commands:
1. scripts/release_install_local.sh build/Export/MenuBarDeclutter.app
2. scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app
3. scripts/qa_network_watch.sh --installed

Manual regression:
Use docs/testing/v0.1-regression-suite.md and fill:
- docs/testing/v0.1-regression-run-YYYY-MM-DD.md

Minimum required PASS for stable:
1. First launch.
2. No Dock icon.
3. Menu bar item appears.
4. Basic collapse/expand.
5. Real Command-drag separator placement.
6. Reset layout.
7. Diagnostics export.
8. Safe Mode.
9. Force-quit recovery.
10. Privacy verification.
11. No unexpected network connection.
12. Launch at Login if advertised as working.
13. Accessibility grant/revoke if Pro Mode remains visible.
14. Find Icon/Second Bar unavailable states if no permission.
15. Icon Moving disabled by default.

Acceptance criteria:
- Installed final app is validated.
- Regression run doc exists.
- Any NOT TESTED item has a reason.
Task 5 — Final release notes and changelog
Finalize:
- CHANGELOG.md
- docs/release/v0.1-release-notes.md
- docs/release/v0.1-known-limitations.md
- docs/release/v0.1-privacy.md
- docs/release/v0.1-installation.md
- docs/release/v0.1-uninstall.md
- docs/release/v0.1-troubleshooting.md
- docs/release/v0.1-final-release-report.md

Release notes should include:

Headline:
MenuBarDeclutter v0.1.0 — privacy-first macOS 26+ menu bar decluttering utility.

Stable:
- Basic Mode separator-based hiding.
- reveal/collapse/reveal-all.
- optional always-hidden zone.
- auto-rehide / hover / hotkey according to actual defaults.
- settings/onboarding.
- diagnostics/export.
- Launch at Login if validated.
- Health/Safe Mode.

Optional Pro:
- Accessibility discovery.
- Find Icon.
- Second Bar.

Experimental:
- icon moving.
- smart triggers if shipped.
- profile target-zone behavior if shipped.

Not included:
- ScreenCaptureKit.
- Screen Recording.
- visual pixel capture.
- Apple Events.
- Input Monitoring.
- network/telemetry/cloud sync.

Known limitations:
- Basic Mode relies on user-placed separators.
- Some menu bar items may not be discoverable.
- Some menu bar items may not be movable.
- Second Bar uses app/bundle icons, not captured menu bar pixels.
- Icon moving is experimental and disabled by default.
- External display/notch layouts may require manual adjustment.

Acceptance criteria:
- Release notes are honest.
- Changelog has v0.1.0 section.
- Final release report exists.
Task 6 — Tagging and artifact manifest
Create release manifest.

Create:
- docs/release/v0.1-artifact-manifest.md
- build/Dist/MenuBarDeclutter-v0.1.0-manifest.json if build/Dist exists

Manifest:
- version.
- build number.
- git commit.
- scheme.
- configuration.
- macOS deployment target.
- bundle identifier.
- artifact paths.
- artifact sizes.
- SHA256 checksums.
- notarization status.
- stapling status.
- Gatekeeper status.
- privacy verification status.
- test result summary.

Add script if useful:
- scripts/release_manifest.sh

Git tag:
- Do not create tag automatically unless repo policy allows.
- Print suggested command:
  - git tag -a v0.1.0 -m "MenuBarDeclutter v0.1.0"
  - git push origin v0.1.0

Acceptance criteria:
- Artifact manifest exists.
- Checksums are generated.
- Tag command is documented but not forced.
Task 7 — Stable release go/no-go gate
Create:
- docs/release/v0.1-go-no-go.md

Go criteria:
1. Tests pass.
2. Privacy verification passes.
3. Basic Mode regression passes.
4. Safe Mode passes.
5. Installed app launches.
6. Diagnostics export works.
7. Launch at Login status is either validated or not advertised.
8. Pro Mode permission flow is either validated or clearly marked optional.
9. Icon Moving is disabled by default.
10. Known limitations are complete.
11. Artifact verification passes.
12. Notarization status is explicit.

No-go criteria:
1. Basic Mode collapse/expand broken.
2. App can hide/trap its own controls unrecoverably.
3. Safe Mode broken.
4. Privacy boundary false.
5. Unexpected network activity.
6. Screen Recording permission appears.
7. Launch at Login advertised but broken.
8. Gatekeeper blocks intended artifact unexpectedly.
9. User data/settings migration crashes.
10. Release notes hide major limitations.

Acceptance criteria:
- Go/no-go doc exists.
- Final release report states GO or NO-GO.
Task 8 — Final validation commands
Run and record:

1. git status --short
2. xcodebuild -list
3. xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'
4. xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
5. scripts/verify_privacy_boundary.sh
6. scripts/release_clean.sh
7. scripts/release_archive.sh
8. scripts/release_export_app.sh
9. scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app
10. scripts/release_package_zip.sh
11. scripts/release_notarize.sh build/Dist/MenuBarDeclutter-v0.1.0.zip, or documented dry-run/skip
12. scripts/release_staple.sh build/Export/MenuBarDeclutter.app, if notarized
13. scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app
14. scripts/release_install_local.sh build/Export/MenuBarDeclutter.app
15. scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app
16. scripts/qa_network_watch.sh --installed
17. scripts/release_manifest.sh, if implemented

Create/update:
- docs/release/v0.1-final-release-report.md

Acceptance criteria:
- Final report includes exact command results.
- Final report says GO or NO-GO.
- If GO, artifact is ready for intended distribution level.
Recommended release policy

For v0.1, I would use this policy:

Stable:
- Basic Mode
- Settings
- Onboarding
- Diagnostics
- Privacy-safe export
- Safe Mode
- Launch at Login only if installed-app QA passes

Optional:
- Accessibility Pro discovery
- Find Icon
- Second Bar

Experimental:
- Icon Moving
- Smart Triggers
- advanced profile zone behavior

Deferred:
- Phase 10 ScreenCaptureKit visual icon capture