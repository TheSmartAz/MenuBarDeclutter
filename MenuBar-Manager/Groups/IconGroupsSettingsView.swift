import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct IconGroupsSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    let groupStore: IconGroupStore
    let snapshots: [MenuBarItemSnapshot]
    let proModeAvailable: Bool
    let onOpenPrivacySettings: () -> Void
    var commandAvailability: ((IconGroup) -> MenuBarCommandAvailabilitySummary?)?
    var onOpenGroupPanel: ((IconGroup) -> MenuBarCommandResult)?
    var onRevealGroup: ((IconGroup) -> MenuBarCommandResult)?
    var onAssignGroupHotkey: ((IconGroup, GroupHotkeyAssignmentKind) -> GroupHotkeyAssignmentResult)?
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
            badges: [.preview, .basicMode, .privacySafe]
        ) {
            ClearGlassSection("Groups") {
                FeatureGateNotice(
                    .preview,
                    text: "Preview in v0.1.1. Manual groups are local; group status items stay off unless enabled."
                )

                ClearGlassDivider()

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
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        groupList
                            .frame(minWidth: 250, idealWidth: 280, maxWidth: 320)

                        selectedGroupDetail
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        groupList
                            .frame(maxWidth: .infinity)

                        selectedGroupDetail
                    }
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

    private var selectedGroupDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedGroup {
                IconGroupPreviewView(
                    group: selectedGroup,
                    snapshots: snapshots,
                    isProtectedRedacted: selectedGroup.isProtected && settingsStore.protectedGroupsRequireAuth
                )

                if let commandAvailability = commandAvailability?(selectedGroup) {
                    CommandAvailabilityRow(summary: commandAvailability)

                    ClearGlassDivider()
                }

                selectedGroupActions(selectedGroup)

                if onAssignGroupHotkey != nil {
                    ClearGlassDivider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hotkeys")
                            .font(.headline)

                        HStack(spacing: 10) {
                            Button("Assign Open Hotkey", systemImage: "keyboard") {
                                assignHotkey(.openPanel, to: selectedGroup)
                            }

                            Button("Assign Reveal Hotkey", systemImage: "eye") {
                                assignHotkey(.reveal, to: selectedGroup)
                            }
                        }
                        .controlSize(.small)
                    }
                }
            } else {
                ContentUnavailableView("No Groups", systemImage: "person.2", description: Text("Create a group to organize menu bar items."))
                    .frame(maxWidth: .infinity, minHeight: 220)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func selectedGroupActions(_ group: IconGroup) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                selectedGroupActionButtons(group)
            }

            VStack(alignment: .leading, spacing: 8) {
                selectedGroupActionButtons(group)
            }
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private func selectedGroupActionButtons(_ group: IconGroup) -> some View {
        if onOpenGroupPanel != nil {
            Button("Open Panel", systemImage: "rectangle.on.rectangle") {
                runOpenPanel(group)
            }
        }

        if onRevealGroup != nil {
            Button("Reveal", systemImage: "eye") {
                runReveal(group)
            }
        }

        Button("Edit", systemImage: "pencil") {
            editingGroup = group
        }

        Button("Export", systemImage: "square.and.arrow.up") {
            export(group)
        }

        Button("Delete", systemImage: "trash", role: .destructive) {
            groupStore.removeGroup(id: group.id)
            selectedID = groups.first?.id
            notifyChanged()
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
                if groups.isEmpty {
                    Text("No groups yet.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 64)
                } else {
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

    private func runOpenPanel(_ group: IconGroup) {
        guard let result = onOpenGroupPanel?(group) else { return }
        statusMessage = result.message
    }

    private func runReveal(_ group: IconGroup) {
        guard let result = onRevealGroup?(group) else { return }
        statusMessage = result.message
    }

    private func assignHotkey(_ kind: GroupHotkeyAssignmentKind, to group: IconGroup) {
        guard let result = onAssignGroupHotkey?(group, kind) else { return }
        statusMessage = result.message
    }

    private func export(_ group: IconGroup) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = exportFileName(for: group)
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try IconGroupImportExport.exportGroup(group).write(to: url, options: .atomic)
            statusMessage = group.isProtected
                ? "Protected group exported with name and item details redacted."
                : "Group exported."
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
            let report = try IconGroupImportExport.importReport(from: Data(contentsOf: url))
            let imported = report.groups
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
            statusMessage = [
                "Imported \(imported.count) group(s).",
                report.warningSummary
            ]
            .compactMap { $0 }
            .joined(separator: " ")
            notifyChanged()
        } catch {
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    private func exportFileName(for group: IconGroup) -> String {
        let baseName = group.isProtected ? "protected" : group.name
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let sanitized = String(baseName.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        })
        .trimmingCharacters(in: .whitespacesAndNewlines)

        return "\(sanitized.isEmpty ? "group" : sanitized)-group.json"
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
