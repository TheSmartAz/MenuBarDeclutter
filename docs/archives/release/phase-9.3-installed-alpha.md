# Phase 9.3 Installed Alpha Workflow

Phase 9.3 validates MenuBarDeclutter as an installed app instead of only from Xcode or DerivedData.

## Scripts

| Step | Command | Output |
| --- | --- | --- |
| Clean | `scripts/release_clean.sh` | Removes `build/Archives`, `build/Export`, `build/Dist`, and `build/Logs` |
| Archive | `scripts/release_archive.sh` | `build/Archives/MenuBarDeclutter.xcarchive` |
| Export | `scripts/release_export_app.sh` | `build/Export/MenuBarDeclutter.app` |
| Package | `scripts/release_package_zip.sh` | `build/Dist/MenuBarDeclutter-alpha.zip` and `build/Dist/MenuBarDeclutter-v0.1.0.zip` |
| Notarize | `scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-alpha.zip` | Dry-run or `notarytool` submit log |
| Staple | `scripts/release_staple.sh build/Export/MenuBarDeclutter.app` | Stapled app if notarization succeeded |
| Gatekeeper | `scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app` | Codesign, `spctl`, and stapler validation |
| Install | `scripts/release_install_local.sh build/Export/MenuBarDeclutter.app` | `/Applications/MenuBarDeclutter.app` by default |
| Verify Installed | `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` | Installed-app privacy and signature checks |

`release_export_app.sh` uses `xcodebuild -exportArchive` when `Config/ExportOptions.plist` exists. This project does not currently need export customization, so the script otherwise copies `Products/Applications/MenuBarDeclutter.app` from the archive.

## Defaults

- Scheme: `MenuBarDeclutter`
- Configuration: `Release`
- Archive: `build/Archives/MenuBarDeclutter.xcarchive`
- Exported app: `build/Export/MenuBarDeclutter.app`
- Alpha zip: `build/Dist/MenuBarDeclutter-alpha.zip`
- Versioned v0.1 zip: `build/Dist/MenuBarDeclutter-v0.1.0.zip`

## Notes

- The workflow does not require network unless real notarization is explicitly run.
- Dry-run notarization is the expected path until Developer ID and notary credentials are configured.
- `release_clean.sh` never removes DerivedData unless `--derived-data` is supplied.
- Local install leaves quarantine intact unless `--clear-quarantine` is supplied.
