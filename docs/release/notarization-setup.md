# Notarization Setup

Real notarization requires:

1. Apple Developer Program membership.
2. A Developer ID Application certificate installed in the login keychain.
3. A `notarytool` credential profile or Apple ID credentials with an app-specific password.

## Preferred Credential Setup

```sh
xcrun notarytool store-credentials MenuBarDeclutterNotary \
  --apple-id "you@example.com" \
  --team-id "TEAMID1234" \
  --password "app-specific-password"
```

Then run:

```sh
NOTARYTOOL_KEYCHAIN_PROFILE=MenuBarDeclutterNotary \
  scripts/release_notarize.sh build/Dist/MenuBarDeclutter-v0.1.3.zip
```

## Environment Fallback

```sh
NOTARYTOOL_APPLE_ID="you@example.com" \
NOTARYTOOL_TEAM_ID="TEAMID1234" \
NOTARYTOOL_PASSWORD="app-specific-password" \
scripts/release_notarize.sh build/Dist/MenuBarDeclutter-v0.1.3.zip
```

Do not commit credentials, passwords, exported certificates, or generated keychain profiles.

## Dry Run

When credentials are unavailable:

```sh
scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-v0.1.3-alpha.zip
```

Real notarization fails clearly when no supported credentials are present. Use `--dry-run` when credentials are unavailable.
