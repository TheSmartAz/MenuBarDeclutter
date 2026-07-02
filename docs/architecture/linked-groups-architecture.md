# Linked Groups Architecture

Linked Groups use `WorkspaceGroupReference` in Workspace items.

Reference modes:

- `linked`: references the source Group ID directly.
- `detached`: references a copied Group ID and stores the source Group ID for traceability.

Function Bar and Set Builder resolve linked Groups through `IconGroupStore`. Missing references degrade to unavailable/missing states. Detached copies are independent because they point at a new Group ID.

Diagnostics report linked, detached, and missing reference counts without exporting protected names.
