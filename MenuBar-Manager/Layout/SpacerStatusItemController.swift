import AppKit
import Foundation

/// Owns and manages all app-owned spacer/divider `NSStatusItem` instances.
@MainActor
final class SpacerStatusItemController {
    private let store: SpacerItemStore
    private let factory: SpacerStatusItemFactory
    private let diagnosticsLogger: DiagnosticsLogger

    /// Maps spacer model IDs to their active NSStatusItem instances.
    private var activeItems: [UUID: NSStatusItem] = [:]

    var visibleItemCount: Int { activeItems.count }

    init(
        store: SpacerItemStore,
        factory: SpacerStatusItemFactory,
        diagnosticsLogger: DiagnosticsLogger
    ) {
        self.store = store
        self.factory = factory
        self.diagnosticsLogger = diagnosticsLogger
    }

    /// Load from store and install all visible spacer items.
    func installAll() {
        store.load()
        rebuildItems()
        diagnosticsLogger.log(
            "Spacer items installed: \(activeItems.count) visible of \(store.itemCount) total.",
            category: .layout
        )
    }

    /// Rebuild all active status items from the store.
    func rebuildItems() {
        removeAllItems()
        for model in store.visibleItems {
            let item = factory.makeStatusItem(for: model)
            activeItems[model.id] = item
        }
    }

    /// Add a new spacer of the given type.
    @discardableResult
    func add(type: SpacerItemType, title: String = "") -> SpacerItemModel {
        let model = store.add(type: type, title: title)
        let item = factory.makeStatusItem(for: model)
        activeItems[model.id] = item
        diagnosticsLogger.log("Added spacer: \(type.displayName).", category: .layout)
        return model
    }

    /// Remove a spacer by ID.
    func remove(id: UUID) {
        if let item = activeItems.removeValue(forKey: id) {
            factory.remove(item)
        }
        store.remove(id: id)
        diagnosticsLogger.log("Removed spacer.", category: .layout)
    }

    /// Toggle spacer markers visibility.
    func setMarkersVisible(_ visible: Bool) {
        if visible {
            store.showAllMarkers()
        } else {
            store.hideAllMarkers()
        }
        rebuildItems()
        diagnosticsLogger.log("Spacer markers \(visible ? "shown" : "hidden").", category: .layout)
    }

    /// Hide all optional spacer items (used by Safe Mode).
    func hideAllOptional() {
        store.setAllVisible(false)
        removeAllItems()
        diagnosticsLogger.log("All optional spacer items hidden (Safe Mode).", level: .warning, category: .layout)
    }

    /// Reset all spacers.
    func reset() {
        removeAllItems()
        store.reset()
        diagnosticsLogger.log("All spacer items reset.", category: .layout)
    }

    /// Remove all active NSStatusItem instances (does not clear the store).
    func removeAllItems() {
        for (_, item) in activeItems {
            factory.remove(item)
        }
        activeItems.removeAll()
    }

    /// Get all active spacer model IDs.
    var activeIDs: Set<UUID> {
        Set(activeItems.keys)
    }
}
