# Phase 11 Import/Export QA

## Steps

1. Open Settings > Import Export.
2. Export a package.
3. Inspect that JSON includes package version, settings, groups, hotkeys,
   spacers, profiles, and private access policy preferences.
4. Import the package and review dry-run results.
5. Import a package with duplicate hotkeys and confirm conflict reporting.
6. Import a package that would enable icon moving, spacing labs, or smart
   triggers and confirm risky flag reporting.
7. Create backup before apply.
8. Cancel import and confirm no settings changed.

## Expected

- Imports are user-selected only.
- No competitor config scraping occurs.
- Active unlock sessions are never exported.
- File paths do not appear in diagnostics.
