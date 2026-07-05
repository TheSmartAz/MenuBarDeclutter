# Phase 10/11 Alpha Package Run - 2026-06-29

Commit: `4795565`

Version/build: `0.1.0 (1)`

This run created a local alpha package from the Phase 10/11 archive/export
workflow. It did not submit to Apple notarization services; notarization was run
in explicit dry-run mode.

## Artifacts

| Artifact | Status | Notes |
| --- | --- | --- |
| `build/Archives/MenuBarDeclutter.xcarchive` | PASS | Created by `scripts/release_archive.sh`. |
| `build/Export/MenuBarDeclutter.app` | PASS | Exported by `scripts/release_export_app.sh`. |
| `build/Dist/MenuBarDeclutter-alpha.zip` | PASS | Created by `scripts/release_package_zip.sh`. |
| `build/Dist/MenuBarDeclutter-v0.1.0.zip` | PASS | Versioned copy of the alpha zip. |

SHA-256:

```text
b378f81aea282ab14a2da593f29ea88785e0fb9a1b98bd6a232cdc9ec8867485  build/Dist/MenuBarDeclutter-alpha.zip
b378f81aea282ab14a2da593f29ea88785e0fb9a1b98bd6a232cdc9ec8867485  build/Dist/MenuBarDeclutter-v0.1.0.zip
```

Both zip files were `2.7M` on disk at creation time.

## Commands

| Command | Result |
| --- | --- |
| `scripts/release_clean.sh` | PASS. Removed release workflow outputs under `build/Archives`, `build/Export`, `build/Dist`, and `build/Logs`; left `build/DerivedData` in place. |
| `scripts/release_archive.sh` | PASS. `** ARCHIVE SUCCEEDED **`; archive created at `build/Archives/MenuBarDeclutter.xcarchive`. |
| `scripts/release_export_app.sh` | PASS. `Config/ExportOptions.plist` was absent, so the script deterministically copied the archived app from `Products/Applications`. |
| `scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app` | PASS. Verified bundle identity, LSUIElement, URL scheme, marketing version, usage-string absence, codesign, hardened runtime metadata, no network entitlements, and no ScreenCaptureKit linkage. |
| `APP_PATH=build/Export/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` | PASS. Source/project and built-app privacy boundary checks passed. |
| `scripts/release_package_zip.sh build/Export/MenuBarDeclutter.app` | PASS. Created `MenuBarDeclutter-alpha.zip` and `MenuBarDeclutter-v0.1.0.zip`. |
| `scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-alpha.zip` | PASS. Notarization submission intentionally skipped by dry-run. |
| `scripts/release_notarize.sh build/Dist/MenuBarDeclutter-alpha.zip` | BLOCKED. The script fell back to dry-run output because notarization credentials are missing. |
| `security find-identity -v -p codesigning` | BLOCKED. Only `Apple Development: emailyongjunzhang@gmail.com (834922P6J6)` is installed; no `Developer ID Application` identity is available. |
| `xcrun notarytool history --keychain-profile MenuBarDeclutterNotary` | BLOCKED. No keychain password item exists for the documented `MenuBarDeclutterNotary` profile. |
| `scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app` | EXPECTED PARTIAL. Strict codesign verification passed; `spctl` rejected the app and stapler validation reported no ticket because the artifact was not notarized. |
| `ditto -x -k build/Dist/MenuBarDeclutter-alpha.zip build/Dist/verify-extract` followed by `scripts/verify_release_artifact.sh build/Dist/verify-extract/MenuBarDeclutter.app` | PASS. The zipped app extracted cleanly and passed release artifact verification. |
| `scripts/release_install_local.sh build/Export/MenuBarDeclutter.app` | PASS. Installed the exported alpha candidate to `/Applications/MenuBarDeclutter.app` and launched it. |
| `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` | PASS. Expected dry-run warnings only: `spctl` rejection and no stapled ticket because the artifact is not notarized. |
| `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` | PASS. Installed-app privacy boundary checks passed. |
| `scripts/qa_network_watch.sh --installed` | PASS. No network sockets observed for installed PID `58247`. |
| `scripts/qa_collect_artifacts.sh` | PASS. Local-only artifact bundle created at `build/qa-artifacts/2026-06-29_151935`. |

## Notes

- Archive emitted the existing warning that no App Category is set for the
  target. This does not block local alpha packaging, but should be resolved
  before broad public distribution.
- The artifact is signed with the available Apple Development identity and has
  hardened runtime metadata, but it is not notarized.
- Real notarization is blocked until a Developer ID Application certificate is
  installed and a notarytool credential profile or environment credentials are
  configured. See `docs/release/notarization-setup.md`.
- `/Applications/MenuBarDeclutter.app` now contains the exported alpha
  candidate from `build/Export/MenuBarDeclutter.app`.
- Public distribution remains blocked on Developer ID notarization credentials,
  stapling, and the remaining manual-only Phase 10/11 QA scenarios.

## Remaining Manual Gate

| Scenario | Status | Reason |
| --- | --- | --- |
| Touch ID/password success, cancel, and failure | NOT RUN | Requires user authentication prompts and hardware/session state. |
| Shortcuts app discovery/execution | NOT RUN | Requires hands-on Shortcuts UI validation. |
| Command-drag spacer/group status items | NOT RUN | Requires hand-driven menu bar interaction. |
| Real crowded menu bar rescue | NOT RUN | Requires a crowded live menu bar and human visual confirmation. |
| Spacing Labs apply/restore/reset | NOT RUN | Mutates global menu bar spacing defaults and needs explicit hands-on QA. |
