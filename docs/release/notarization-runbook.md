# Deferred Developer ID Notarization Runbook

Developer ID signing, notarization, stapling, and public distribution are out
of scope for the current project stance. Use this file only as a future
template after Developer ID distribution is explicitly requested. Current local
release validation should use `scripts/build_release.sh --dry-run`.

Run from the repository root only after the Developer ID path is opted in.

1. Clean:
   ```sh
   scripts/release_clean.sh
   ```
2. Archive:
   ```sh
   AD_HOC_SIGNING_OVERRIDES=0 scripts/release_archive.sh
   ```
3. Export:
   ```sh
   DRY_RUN=0 DEVELOPER_ID_EXPORT=1 scripts/release_export_app.sh
   ```
4. Verify the privacy boundary:
   ```sh
   scripts/verify_privacy_boundary.sh build/Export/MenuBarDeclutter.app
   ```
5. Package:
   ```sh
   DRY_RUN=0 scripts/release_package_zip.sh
   ```
   This creates `build/Dist/MenuBarDeclutter-v0.1.10.zip` for the
   opted-in Developer ID path. The default alpha zip remains the local dry-run
   artifact and should not be submitted for real notarization.
6. Submit notarization:
   ```sh
   scripts/release_notarize.sh build/Dist/MenuBarDeclutter-v0.1.10.zip
   ```
   If credentials are unavailable:
   ```sh
   scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-v0.1.10.zip
   ```
7. Staple after a successful notarization:
   ```sh
   scripts/release_staple.sh build/Export/MenuBarDeclutter.app
   ```
8. Validate Gatekeeper:
   ```sh
   scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app
   ```
9. Install locally:
   ```sh
   scripts/release_install_local.sh build/Export/MenuBarDeclutter.app
   ```
10. Run installed-app QA:
   ```sh
   scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app
   scripts/qa_network_watch.sh --installed
   ```

If `--no-wait` is used for notarization, poll with:

```sh
xcrun notarytool info SUBMISSION_ID --keychain-profile MenuBarDeclutterNotary
```
