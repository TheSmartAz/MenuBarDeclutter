import AppKit

@MainActor
final class IconGroupStatusItemController {
    private let settingsStore: SettingsStore
    private let groupStore: IconGroupStore
    private let factory: IconGroupStatusItemFactory
    private let diagnosticsLogger: DiagnosticsLogger
    private let openGroup: (IconGroup) -> Void
    private let editGroup: (IconGroup) -> Void

    private var handles: [UUID: IconGroupStatusItemHandle] = [:]

    var visibleCount: Int { handles.count }

    init(
        settingsStore: SettingsStore,
        groupStore: IconGroupStore,
        factory: IconGroupStatusItemFactory,
        diagnosticsLogger: DiagnosticsLogger,
        openGroup: @escaping (IconGroup) -> Void,
        editGroup: @escaping (IconGroup) -> Void
    ) {
        self.settingsStore = settingsStore
        self.groupStore = groupStore
        self.factory = factory
        self.diagnosticsLogger = diagnosticsLogger
        self.openGroup = openGroup
        self.editGroup = editGroup
    }

    func refresh() {
        removeAll()
        guard settingsStore.groupsEnabled, settingsStore.groupStatusItemsEnabled else {
            diagnosticsLogger.log("Group status items not installed because they are disabled.", level: .debug, category: .layout)
            return
        }

        for group in groupStore.groups where group.isEnabled && group.showAsStatusItem {
            let handle = factory.makeStatusItem(
                for: group,
                open: { [weak self] in self?.openGroup(group) },
                edit: { [weak self] in self?.editGroup(group) },
                hide: { [weak self] in self?.hideStatusItem(for: group.id) }
            )
            handles[group.id] = handle
        }

        diagnosticsLogger.log("Group status items refreshed: \(handles.count) installed.", category: .layout)
    }

    func removeAll() {
        for handle in handles.values {
            factory.remove(handle.item)
        }
        handles.removeAll()
    }

    func enterSafeMode() {
        removeAll()
        diagnosticsLogger.log("Group status items hidden for Safe Mode.", level: .warning, category: .layout)
    }

    private func hideStatusItem(for groupID: UUID) {
        groupStore.updateGroup(id: groupID) { group in
            group.showAsStatusItem = false
        }
        refresh()
    }
}
