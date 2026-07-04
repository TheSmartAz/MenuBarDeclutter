import Foundation

@MainActor
protocol SetBuilderLibraryProviding {
    func items() -> [SetBuilderLibraryItem]
}

@MainActor
struct CommandLibraryProvider: SetBuilderLibraryProviding {
    var showAdvancedItems: Bool = false

    func items() -> [SetBuilderLibraryItem] {
        var commands: [WorkspaceCommandReference] = [
            .findIcon,
            .showSecondBar,
            .revealAll,
            .expand,
            .collapse,
            .toggle,
            .openSettings,
            .openRecovery,
            .showFunctionBar,
            .hideFunctionBar,
            .showInfoStrip,
            .hideInfoStrip,
            .nextInfoStripTile,
            .openInfoStripSettings,
            .showFunctionBarFromInfoStrip
        ]
        if showAdvancedItems {
            commands.append(.showWorkspacePreview)
        }
        return commands.map { command in
            SetBuilderLibraryItem(
                id: "command.\(command.actionID)",
                title: command.displayTitle,
                subtitle: "Safe app command",
                systemImage: iconName(for: command),
                kind: .command(command),
                isEnabled: true,
                badge: nil
            )
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
        default: "command"
        }
    }
}

@MainActor
struct GroupLibraryProvider: SetBuilderLibraryProviding {
    var groups: [IconGroup]
    var protectedNamesRedacted: Bool = true

    func items() -> [SetBuilderLibraryItem] {
        groups.map { group in
            SetBuilderLibraryItem(
                id: "group.\(group.id.uuidString)",
                title: group.isProtected && protectedNamesRedacted ? "Protected Group" : group.name,
                subtitle: "\(group.itemCount) item\(group.itemCount == 1 ? "" : "s")",
                systemImage: group.symbolName ?? "person.2",
                kind: .group(group.id),
                isEnabled: group.isEnabled,
                badge: group.isProtected ? "Protected" : "Linked"
            )
        }
    }
}

@MainActor
struct MenuBarItemLibraryProvider: SetBuilderLibraryProviding {
    var snapshots: [MenuBarItemSnapshot]
    var proDiscoveryAvailable: Bool
    var accessibilityAvailable: Bool

    func items() -> [SetBuilderLibraryItem] {
        guard proDiscoveryAvailable else {
            return [unavailable("Menu Bar Items", subtitle: "Enable Optional Pro Discovery to add menu bar item proxies.", badge: "Requires Optional Pro")]
        }
        guard accessibilityAvailable else {
            return [unavailable("Menu Bar Items", subtitle: "Grant Accessibility only from the explicit Privacy setup flow.", badge: "Requires Accessibility")]
        }
        guard !snapshots.isEmpty else {
            return [unavailable("No Discovered Items", subtitle: "Run a menu bar scan from Find & Rescue.", badge: "Unavailable")]
        }
        return snapshots.map { snapshot in
            let reference = MenuBarItemReference(
                stableHash: snapshot.id,
                lastKnownDisplayName: snapshot.owningApplicationName ?? snapshot.title,
                lastKnownBundleIdentifier: snapshot.bundleIdentifier
            )
            return SetBuilderLibraryItem(
                id: "proxy.\(snapshot.id)",
                title: snapshot.owningApplicationName ?? snapshot.title ?? "Menu Bar Item",
                subtitle: snapshot.zone.rawValue,
                systemImage: "app.badge",
                kind: .menuBarItem(reference),
                isEnabled: true,
                badge: nil
            )
        }
    }

    private func unavailable(_ title: String, subtitle: String, badge: String) -> SetBuilderLibraryItem {
        SetBuilderLibraryItem(
            id: "proxy.unavailable.\(badge)",
            title: title,
            subtitle: subtitle,
            systemImage: "app.badge",
            kind: .spacer,
            isEnabled: false,
            badge: badge
        )
    }
}

@MainActor
struct NewItemLibraryProvider: SetBuilderLibraryProviding {
    var inbox: NewMenuBarItemInbox?

    func items() -> [SetBuilderLibraryItem] {
        guard let inbox else {
            return [unavailable("New Item Inbox", subtitle: "New Item Inbox is unavailable.", badge: "Unavailable")]
        }
        guard !inbox.items.isEmpty else {
            return [unavailable("No New Items", subtitle: "New menu bar items will appear here after a permitted scan.", badge: "Empty")]
        }

        return inbox.items.enumerated().map { offset, item in
            let reference = MenuBarItemReference(
                stableHash: item.id,
                source: .itemMemory
            )
            let seenLabel = item.seenCount == 1 ? "Seen once" : "Seen \(item.seenCount) times"
            return SetBuilderLibraryItem(
                id: "newItem.\(item.id)",
                title: offset == 0 ? "New Menu Bar Item" : "New Menu Bar Item \(offset + 1)",
                subtitle: "\(seenLabel). App-owned proxy; no icon is moved.",
                systemImage: "tray",
                kind: .menuBarItem(reference),
                isEnabled: true,
                badge: "New"
            )
        }
    }

    private func unavailable(_ title: String, subtitle: String, badge: String) -> SetBuilderLibraryItem {
        SetBuilderLibraryItem(
            id: "newItem.unavailable.\(badge)",
            title: title,
            subtitle: subtitle,
            systemImage: "tray",
            kind: .spacer,
            isEnabled: false,
            badge: badge
        )
    }
}

@MainActor
struct UnassignedMenuBarItemLibraryProvider: SetBuilderLibraryProviding {
    var snapshots: [MenuBarItemSnapshot]
    var workspaceSnapshot: WorkspaceStoreSnapshot
    var groups: [IconGroup]
    var proDiscoveryAvailable: Bool
    var accessibilityAvailable: Bool

    func items() -> [SetBuilderLibraryItem] {
        guard proDiscoveryAvailable else {
            return [unavailable("Unassigned Items", subtitle: "Enable Optional Pro Discovery to review unassigned menu bar item proxies.", badge: "Requires Optional Pro")]
        }
        guard accessibilityAvailable else {
            return [unavailable("Unassigned Items", subtitle: "Grant Accessibility only from the explicit Privacy setup flow.", badge: "Requires Accessibility")]
        }
        guard !snapshots.isEmpty else {
            return [unavailable("No Discovered Items", subtitle: "Run a menu bar scan from Find & Rescue.", badge: "Unavailable")]
        }

        let usageIndex = WorkspaceUsageIndex()
        usageIndex.rebuild(
            snapshot: workspaceSnapshot,
            groups: groups,
            discoveredSnapshots: snapshots
        )
        let unassignedSnapshots = snapshots.filter { snapshot in
            usageIndex.usage(for: snapshot.id).isUnassigned
        }

        guard !unassignedSnapshots.isEmpty else {
            return [unavailable("No Unassigned Items", subtitle: "Every discovered item is already used by a Workspace or Group.", badge: "Empty")]
        }

        return unassignedSnapshots.map { snapshot in
            let reference = MenuBarItemReference(
                stableHash: snapshot.id,
                lastKnownDisplayName: snapshot.owningApplicationName ?? snapshot.title,
                lastKnownBundleIdentifier: snapshot.bundleIdentifier
            )
            return SetBuilderLibraryItem(
                id: "unassigned.\(snapshot.id)",
                title: snapshot.owningApplicationName ?? snapshot.title ?? "Menu Bar Item",
                subtitle: "\(snapshot.zone.rawValue). App-owned proxy; no icon is moved.",
                systemImage: "app.badge",
                kind: .menuBarItem(reference),
                isEnabled: true,
                badge: "Unassigned"
            )
        }
    }

    private func unavailable(_ title: String, subtitle: String, badge: String) -> SetBuilderLibraryItem {
        SetBuilderLibraryItem(
            id: "unassigned.unavailable.\(badge)",
            title: title,
            subtitle: subtitle,
            systemImage: "app.badge",
            kind: .spacer,
            isEnabled: false,
            badge: badge
        )
    }
}

@MainActor
struct SpacerLibraryProvider: SetBuilderLibraryProviding {
    func items() -> [SetBuilderLibraryItem] {
        [
            SetBuilderLibraryItem(
                id: "layout.spacer",
                title: "Spacer",
                subtitle: "Adds visual breathing room.",
                systemImage: "arrow.left.and.right",
                kind: .spacer,
                isEnabled: true,
                badge: nil
            ),
            SetBuilderLibraryItem(
                id: "layout.divider",
                title: "Divider",
                subtitle: "Adds a visual separator.",
                systemImage: "line.3.horizontal",
                kind: .divider,
                isEnabled: true,
                badge: nil
            )
        ]
    }
}

@MainActor
struct InfoTileLibraryProvider: SetBuilderLibraryProviding {
    func items() -> [SetBuilderLibraryItem] {
        WorkspaceInfoStripConfig.defaultTileProviderIDs.map { providerID in
            let metadata = Self.metadata(for: providerID)
            return SetBuilderLibraryItem(
                id: "info.\(providerID)",
                title: InfoTileProviderID(rawValue: providerID).displayName,
                subtitle: metadata.subtitle,
                systemImage: "info.circle",
                kind: .infoTile(providerID),
                isEnabled: true,
                badge: metadata.badge
            )
        }
    }

    private static func metadata(for providerID: String) -> (subtitle: String, badge: String) {
        switch providerID {
        case InfoTileProviderID.newItemCount.rawValue,
             InfoTileProviderID.staleScanWarning.rawValue:
            ("Local Info Strip tile. Requires Optional Pro Discovery to show live data.", "Requires Optional Pro")
        default:
            ("Local Info Strip tile", "Info Strip")
        }
    }
}
