# Workspace Profile Binding v0.1.8 Preview

A Workspace may reference a Profile for preview planning.

Supported modes:

- `none`
- `dryRunOnly`
- `applySafeBasicSettings`

The preview planner never moves real menu bar items automatically. Missing profile references are reported as diagnostics and produce no safe changes.
