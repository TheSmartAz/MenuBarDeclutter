# Phase 11 Group Schema

## Store

Groups are stored locally in Application Support as `groups.json` through
`IconGroupStore`.

```json
{
  "schemaVersion": 1,
  "groups": []
}
```

## IconGroup

```json
{
  "id": "UUID",
  "name": "Work",
  "symbolName": "briefcase",
  "colorName": "blue",
  "notes": "optional",
  "isEnabled": true,
  "isProtected": false,
  "showInSecondBar": true,
  "showAsStatusItem": false,
  "sortOrder": 0,
  "itemRefs": [],
  "createdAt": "date",
  "updatedAt": "date"
}
```

## IconGroupItemRef

```json
{
  "id": "UUID",
  "bundleIdentifier": "com.example.App",
  "appName": "Example",
  "snapshotStableID": "optional-stable-id",
  "titleContains": "optional title fragment",
  "zone": "left",
  "manualLabel": "Example item"
}
```

## Matching Rules

- Bundle ID, app name, stable snapshot ID, title fragment, and zone are all
  optional matching strategies.
- A ref should contain at least one matchable criterion.
- Manual labels are for user display and are not sufficient for matching by
  themselves.
- Protected groups redact item names in protected previews and diagnostics.

## Corruption Handling

If the store cannot decode, the corrupted file is copied to the backups
directory and the in-memory group list resets to empty.
