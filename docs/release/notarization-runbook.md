# Notarization Runbook

Run from the repository root.

1. Clean:
   ```sh
   scripts/release_clean.sh
   ```
2. Archive:
   ```sh
   scripts/release_archive.sh
   ```
3. Export:
   ```sh
   scripts/release_export_app.sh
   ```
4. Verify the privacy boundary:
   ```sh
   scripts/verify_privacy_boundary.sh build/Export/MenuBarDeclutter.app
   ```
5. Package:
   ```sh
   scripts/release_package_zip.sh
   ```
6. Submit notarization:
   ```sh
   scripts/release_notarize.sh build/Dist/MenuBarDeclutter-alpha.zip
   ```
   If credentials are unavailable:
   ```sh
   scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-alpha.zip
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
