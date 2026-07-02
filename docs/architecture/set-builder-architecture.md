# Set Builder Architecture

The Set Builder source area lives in `MenuBar-Manager/SetBuilder/`.

Core pieces:

- `SetBuilderDraft` stores original and edited Workspace state plus pending changes.
- `SetBuilderViewModel` owns Workspace list state, drafts, library insertion, reorder, commit, and revert.
- Library providers expose safe command, group, proxy, layout, and Info Strip tile entries.
- `SetBuilderDropValidator` validates drag/drop payloads without logging raw menu bar item names, bundle IDs, protected group names, or workspace names.

Set Builder persists through `WorkspaceSwitchingService.updateWorkspace`, keeping physical layout mutation out of the builder.
