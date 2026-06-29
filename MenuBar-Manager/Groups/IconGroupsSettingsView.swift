import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct IconGroupsSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    let groupStore: IconGroupStore
    let snapshots: [MenuBarItemSnapshot]
    let proModeAvailable: Bool
    let onOpenPrivacySettings: () -> Void
    var onGroupsChanged: (() -> Void)?

    @State private var selectedID: UUID?
    @State private var editingGroup: IconGroup?
    @State private var revision = 0
    @State private var statusMessage: String?

    private var groups: [IconGroup] {
        _ = revision
        return IconGroupSort.sort(groupStore.groups)
    }

    private var selectedGroup: IconGroup? {
        groups.first { $0.id == selectedID } ?? groups.first
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Groups",
            subtitle: "Organize related menu bar items without adding permissions.",
            badges: [.basicMode, .privacySafe]
        ) {
            ClearGlassSection("Groups") {
                ClearGlassControlRow(
                    systemImage: "person.2",
                    title: "Enable Groups",
                    subtitle: "Show group organization features throughout the app."
                ) {
                    Toggle("Enable Groups", isOn: $settingsStore.groupsEnabled)
                        .labelsHidden()
                        .onChange(of: settingsStore.groupsEnabled) { _, _ in notifyChanged() }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "menubar.rectangle",
                    title: "Group Status Items",
                    subtitle: "Show optional app-owned menu bar items for groups that opt in."
                ) {
                    Toggle("Group Status Items", isOn: $settingsStore.groupStatusItemsEnabled)
                        .labelsHidden()
                        .onChange(of: settingsStore.groupStatusItemsEnabled) { _, _ in notifyChanged() }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "lock",
                    title: "Protected Groups Require Auth",
                    subtitle: "Private Access can require Touch ID or device password before opening protected groups."
                ) {
                    Toggle("Protected Groups Require Auth", isOn: $settingsStore.protectedGroupsRequireAuth)
                        .labelsHidden()
                        .onChange(of: settingsStore.protectedGroupsRequireAuth) { _, _ in notifyChanged() }
                }
            }

            ClearGlassSection("Manage Groups", subtitle: "Create groups manually or from the current Pro snapshot.") {
                HStack(alignment: .top, spacing: 16) {
                    groupList
                        .frame(minWidth: 250, idealWidth: 280, maxWidth: 320)

                    VStack(alignment: .leading, spacing: 12) {
                        if let selectedGroup {
                            IconGroupPreviewView(
                                group: selectedGroup,
                                snapshots: snapshots,
                                isProtectedRedacted: selectedGroup.isProtected && settingsStore.protectedGroupsRequireAuth
                            )

                            HStack(spacing: 10) {
                                Button("Edit", systemImage: "pencil") {
                                    editingGroup = selectedGroup
                                }

                                Button("Export", systemImage: "square.and.arrow.up") {
                                    export(selectedGroup)
                                }

                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    groupStore.removeGroup(id: selectedGroup.id)
                                    selectedID = groups.first?.id
                                    notifyChanged()
                                }
                            }
                        } else {
                            ContentUnavailableView("No Groups", systemImage: "person.2", description: Text("Create a group to organize menu bar items."))
                                .frame(maxWidth: .infinity, minHeight: 220)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }

                if !proModeAvailable {
                    ClearGlassInlineMessage(
                        text: "Manual bundle ID, app name, and title groups work in Basic Mode. Enable Pro Mode for the current menu bar item picker.",
                        systemImage: "star",
                        style: .info
                    )

                    Button("Open Privacy Settings", systemImage: "hand.raised") {
                        onOpenPrivacySettings()
                    }
                }

                if let statusMessage {
                    ClearGlassInlineMessage(text: statusMessage, systemImage: "info.circle")
                }
            }
        }
        .onAppear {
            groupStore.load()
            selectedID = selectedID ?? groups.first?.id
        }
        .sheet(item: $editingGroup) { group in
            IconGroupEditorView(
                group: group,
                existingGroups: groups,
                snapshots: snapshots,
                proModeAvailable: proModeAvailable,
                onSave: save,
                onCancel: {
                    editingGroup = nil
                }
            )
        }
    }

    private var groupList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Groups")
                    .font(.headline)

                Spacer()

                Button("Add Group", systemImage: "plus") {
                    editingGroup = IconGroup(
                        name: "New Group",
                        symbolName: "folder",
                        sortOrder: groups.count
                    )
                }
                .labelStyle(.iconOnly)
                .help("Add Group")

                Button("Import", systemImage: "square.and.arrow.down") {
                    importGroups()
                }
                .labelStyle(.iconOnly)
                .help("Import Groups")
            }

            VStack(spacing: 0) {
                ForEach(groups) { group in
                    IconGroupRowView(
                        group: group,
                        isSelected: group.id == selectedGroup?.id
                    ) {
                        selectedID = group.id
                    }

                    if group.id != groups.last?.id {
                        ClearGlassDivider()
                    }
                }
            }
            .background(.quaternary.opacity(0.4), in: .rect(cornerRadius: 8))
        }
    }

    private func save(_ group: IconGroup) {
        if groupStore.groups.contains(where: { $0.id == group.id }) {
            groupStore.updateGroup(id: group.id) { stored in
                stored.name = group.name
                stored.symbolName = group.symbolName
                stored.colorName = group.colorName
                stored.notes = group.notes
                stored.isEnabled = group.isEnabled
                stored.isProtected = group.isProtected
                stored.showInSecondBar = group.showInSecondBar
                stored.showAsStatusItem = group.showAsStatusItem
                stored.itemRefs = group.itemRefs
            }
        } else {
            let created = groupStore.createGroup(name: group.name)
            groupStore.updateGroup(id: created.id) { stored in
                stored.symbolName = group.symbolName
                stored.colorName = group.colorName
                stored.notes = group.notes
                stored.isEnabled = group.isEnabled
                stored.isProtected = group.isProtected
                stored.showInSecondBar = group.showInSecondBar
                stored.showAsStatusItem = group.showAsStatusItem
                stored.itemRefs = group.itemRefs
            }
            selectedID = created.id
        }

        editingGroup = nil
        notifyChanged()
    }

    private func export(_ group: IconGroup) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(group.name)-group.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try IconGroupImportExport.exportGroup(group).write(to: url, options: .atomic)
            statusMessage = "Group exported."
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func importGroups() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let imported = try IconGroupImportExport.importFrom(data: Data(contentsOf: url))
            for group in imported {
                let created = groupStore.createGroup(name: uniqueName(group.name))
                groupStore.updateGroup(id: created.id) { stored in
                    stored.symbolName = group.symbolName
                    stored.colorName = group.colorName
                    stored.notes = group.notes
                    stored.isEnabled = group.isEnabled
                    stored.isProtected = group.isProtected
                    stored.showInSecondBar = group.showInSecondBar
                    stored.showAsStatusItem = group.showAsStatusItem
                    stored.itemRefs = group.itemRefs
                }
            }
            statusMessage = "Imported \(imported.count) group(s)."
            notifyChanged()
        } catch {
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    private func uniqueName(_ base: String) -> String {
        let names = Set(groupStore.groups.map(\.name))
        guard names.contains(base) else { return base }
        var counter = 2
        while names.contains("\(base) \(counter)") {
            counter += 1
        }
        return "\(base) \(counter)"
    }

    private func notifyChanged() {
        revision += 1
        groupStore.load()
        onGroupsChanged?()
    }
}
