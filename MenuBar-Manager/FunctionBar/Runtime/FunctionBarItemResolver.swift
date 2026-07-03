import Foundation

@MainActor
struct FunctionBarItemResolver {
    var groupsProvider: () -> [IconGroup]
    var snapshotsProvider: () -> [MenuBarItemSnapshot]
    var proDiscoveryAvailable: () -> Bool
    var accessibilityAvailable: () -> Bool

    func resolve(workspace: MenuBarWorkspace) -> [FunctionBarItemModel] {
        workspace.functionItems.map { resolve(item: $0) }
    }

    func resolve(item: WorkspaceItem) -> FunctionBarItemModel {
        switch item.kind {
        case .command(let command):
            let isKnown = command.menuBarCommand != nil
                || [
                    WorkspaceCommandReference.openSettings.actionID,
                    WorkspaceCommandReference.openRecovery.actionID,
                    WorkspaceCommandReference.showWorkspacePreview.actionID,
                    WorkspaceCommandReference.showFunctionBar.actionID,
                    WorkspaceCommandReference.hideFunctionBar.actionID,
                    WorkspaceCommandReference.showInfoStrip.actionID,
                    WorkspaceCommandReference.hideInfoStrip.actionID,
                    WorkspaceCommandReference.nextInfoStripTile.actionID,
                    WorkspaceCommandReference.openInfoStripSettings.actionID,
                    WorkspaceCommandReference.showFunctionBarFromInfoStrip.actionID
                ].contains(command.actionID)
            return FunctionBarItemModel(
                id: item.id,
                kind: .command(command),
                title: item.displayNameOverride ?? command.displayTitle,
                subtitle: isKnown ? nil : "Unsupported command",
                icon: FunctionBarIcon(systemName: item.iconOverride ?? iconName(for: command)),
                status: isKnown ? .available : .unavailable,
                availability: isKnown ? .available : .unavailable(.itemUnavailable),
                badge: nil
            )
        case .menuBarItem(let reference):
            guard proDiscoveryAvailable() else {
                return proxyModel(item: item, reference: reference, title: "Menu Bar Item", status: .requiresPro, reason: .requiresPro)
            }
            guard accessibilityAvailable() else {
                return proxyModel(item: item, reference: reference, title: "Menu Bar Item", status: .requiresAccessibility, reason: .requiresAccessibility)
            }
            let match = snapshotsProvider().first { $0.id == reference.stableHash }
            guard let match else {
                return proxyModel(item: item, reference: reference, title: "Menu Bar Item", status: .missingReference, reason: .missingReference)
            }
            let title = reference.redactionPolicy == .protected
                ? "Protected Item"
                : (item.displayNameOverride ?? match.owningApplicationName ?? match.title ?? "Menu Bar Item")
            return proxyModel(item: item, reference: reference, title: title, status: .available, reason: nil)
        case .group(let reference):
            if let group = groupsProvider().first(where: { $0.id == reference.groupID }) {
                let title = group.isProtected ? "Protected Group" : group.name
                return FunctionBarItemModel(
                    id: item.id,
                    kind: .group(reference),
                    title: item.displayNameOverride ?? title,
                    subtitle: "\(group.itemCount) item\(group.itemCount == 1 ? "" : "s")",
                    icon: FunctionBarIcon(systemName: item.iconOverride ?? group.symbolName ?? "person.2"),
                    status: group.isProtected ? .protected : .available,
                    availability: .available,
                    badge: groupBadge(for: group, reference: reference)
                )
            }
            return FunctionBarItemModel(
                id: item.id,
                kind: .group(reference),
                title: "Missing Group",
                subtitle: "This group reference no longer resolves.",
                icon: FunctionBarIcon(systemName: "questionmark.folder"),
                status: .missingReference,
                availability: .unavailable(.missingReference),
                badge: FunctionBarItemBadge(title: "Missing")
            )
        case .spacer:
            return FunctionBarItemModel(
                id: item.id,
                kind: .spacer,
                title: "Spacer",
                subtitle: nil,
                icon: FunctionBarIcon(systemName: "arrow.left.and.right"),
                status: .previewOnly,
                availability: .unavailable(.itemUnavailable),
                badge: nil
            )
        case .divider:
            return FunctionBarItemModel(
                id: item.id,
                kind: .divider,
                title: "Divider",
                subtitle: nil,
                icon: FunctionBarIcon(systemName: "line.3.horizontal"),
                status: .previewOnly,
                availability: .unavailable(.itemUnavailable),
                badge: nil
            )
        case .infoTile:
            return FunctionBarItemModel(
                id: item.id,
                kind: .infoTilePlaceholder,
                title: "Info Strip Item",
                subtitle: "Info Strip items are handled by Info Strip Preview.",
                icon: FunctionBarIcon(systemName: "info.circle"),
                status: .deferred,
                availability: .unavailable(.itemUnavailable),
                badge: FunctionBarItemBadge(title: "Info Strip")
            )
        }
    }

    private func proxyModel(
        item: WorkspaceItem,
        reference: MenuBarItemReference,
        title: String,
        status: FunctionBarItemStatus,
        reason: FunctionBarUnavailableReason?
    ) -> FunctionBarItemModel {
        FunctionBarItemModel(
            id: item.id,
            kind: .menuBarItem(reference),
            title: item.displayNameOverride ?? title,
            subtitle: status == .available ? reference.lastKnownBundleIdentifier : status.displayText,
            icon: FunctionBarIcon(systemName: item.iconOverride ?? "app.badge"),
            status: status,
            availability: reason.map(FunctionBarActionAvailability.unavailable) ?? .available,
            badge: proxyBadge(for: reference, status: status)
        )
    }

    private func proxyBadge(
        for reference: MenuBarItemReference,
        status: FunctionBarItemStatus
    ) -> FunctionBarItemBadge? {
        if reference.redactionPolicy == .protected {
            return FunctionBarItemBadge(title: "Protected")
        }

        switch status {
        case .available:
            switch reference.source {
            case .accessibilitySnapshot:
                return FunctionBarItemBadge(title: "Workspace Item")
            case .itemMemory:
                return FunctionBarItemBadge(title: "New Item")
            case .manual:
                return FunctionBarItemBadge(title: "Manual")
            case .imported:
                return FunctionBarItemBadge(title: "Imported")
            }
        case .missingReference:
            return FunctionBarItemBadge(title: "Missing")
        case .requiresPro:
            return FunctionBarItemBadge(title: "Requires Pro")
        case .requiresAccessibility:
            return FunctionBarItemBadge(title: "Requires Accessibility")
        case .stale:
            return FunctionBarItemBadge(title: "Stale")
        case .protected:
            return FunctionBarItemBadge(title: "Protected")
        case .previewOnly:
            return FunctionBarItemBadge(title: "Preview")
        case .deferred:
            return FunctionBarItemBadge(title: "Deferred")
        case .unavailable:
            return FunctionBarItemBadge(title: "Unavailable")
        }
    }

    private func groupBadge(
        for group: IconGroup,
        reference: WorkspaceGroupReference
    ) -> FunctionBarItemBadge {
        if group.isProtected {
            return FunctionBarItemBadge(title: "Protected")
        }

        switch reference.referenceMode {
        case .linked:
            return FunctionBarItemBadge(title: "Linked Group")
        case .detached:
            return FunctionBarItemBadge(title: "Detached")
        }
    }

    private func iconName(for command: WorkspaceCommandReference) -> String {
        switch command.actionID {
        case WorkspaceCommandReference.findIcon.actionID: "magnifyingglass"
        case WorkspaceCommandReference.showSecondBar.actionID: "rectangle.bottomthird.inset.filled"
        case WorkspaceCommandReference.revealAll.actionID: "rectangle.expand.vertical"
        case WorkspaceCommandReference.expand.actionID: "eye"
        case WorkspaceCommandReference.collapse.actionID: "eye.slash"
        case WorkspaceCommandReference.toggle.actionID: "arrow.left.arrow.right"
        case WorkspaceCommandReference.openSettings.actionID: "gearshape"
        case WorkspaceCommandReference.openRecovery.actionID: "cross.case"
        case WorkspaceCommandReference.showFunctionBar.actionID: "menubar.rectangle"
        case WorkspaceCommandReference.hideFunctionBar.actionID: "xmark.rectangle"
        case WorkspaceCommandReference.showInfoStrip.actionID: "info.circle"
        case WorkspaceCommandReference.hideInfoStrip.actionID: "xmark.circle"
        case WorkspaceCommandReference.nextInfoStripTile.actionID: "forward"
        case WorkspaceCommandReference.openInfoStripSettings.actionID: "slider.horizontal.3"
        case WorkspaceCommandReference.showFunctionBarFromInfoStrip.actionID: "menubar.rectangle"
        default: "questionmark.circle"
        }
    }
}
