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
    @State private var groups: [IconGroup] = []
    @State private var statusMessage: String?

    private var selectedGroup: IconGroup? {
        groups.first { $0.id == selectedID } ?? groups.first
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Groups",
            subtitle: "Organize related menu bar items without adding permissions.",
            badges: [.preview, .basicMode, .privacySafe],
            style: .tool,
            sectionAnchors: [
                ClearGlassPageAnchor("Groups", systemImage: "person.2"),
                ClearGlassPageAnchor("Manage Groups", systemImage: "sidebar.left")
            ]
        ) {
            ClearGlassSection("Groups") {
                FeatureGateNotice(
                    .preview,
                    text: "Preview in v0.1.3. Manual groups are local; group status items stay off unless enabled."
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

            ClearGlassSection("Manage Groups", subtitle: "Create local groups manually or from the current Pro snapshot.") {
                VStack(alignment: .leading, spacing: 12) {
                    ClearGlassActionStrip(
                        "Group Library Actions",
                        subtitle: "Create manual groups in Basic Mode, or import a saved group package.",
                        systemImage: "person.2",
                        statusText: groups.isEmpty ? "Empty" : "\(groups.count) Groups",
                        statusStyle: groups.isEmpty ? .secondary : .success
                    ) {
                        Button("Add Group", systemImage: "plus") {
                            editingGroup = newGroup()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Import", systemImage: "square.and.arrow.down") {
                            importGroups()
                        }

                        Button("Privacy Settings", systemImage: "hand.raised") {
                            onOpenPrivacySettings()
                        }
                    }

                    ClearGlassPaneLayout(primaryWidth: 280) {
                        groupList
                    } detail: {
                        selectedGroupDetail
                    }

                    if !proModeAvailable {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: 10) {
                                basicModeGroupMessage

                                openPrivacyButton
                                    .padding(.top, 2)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                basicModeGroupMessage
                                openPrivacyButton
                            }
                        }
                    }

                    if let statusMessage {
                        ClearGlassInlineMessage(text: statusMessage, systemImage: "info.circle")
                    }
                }
            }
        }
        .onAppear {
            reloadGroups()
        }
        .onReceive(NotificationCenter.default.publisher(for: IconGroupStore.groupsDidChangeNotification)) { notification in
            guard let changedStore = notification.object as? IconGroupStore,
                  changedStore === groupStore else {
                return
            }
            reloadGroups(loadFromDisk: false)
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

    private var basicModeGroupMessage: some View {
        ClearGlassInlineMessage(
            text: "Manual bundle ID, app name, and title groups work in Basic Mode. Enable Optional Pro for the current menu bar item picker.",
            systemImage: "star",
            style: .info
        )
    }

    private var openPrivacyButton: some View {
        Button("Open Privacy Settings", systemImage: "hand.raised") {
            onOpenPrivacySettings()
        }
        .controlSize(.small)
        .fixedSize()
    }

    private var selectedGroupDetail: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let selectedGroup {
                IconGroupPreviewView(
                    group: selectedGroup,
                    snapshots: snapshots,
                    isProtectedRedacted: selectedGroup.isProtected && settingsStore.protectedGroupsRequireAuth
                )

                selectedGroupActions(selectedGroup)

                if let commandAvailability = commandAvailability?(selectedGroup) {
                    VStack(spacing: 0) {
                        CommandAvailabilityRow(summary: commandAvailability)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
                    }
                }

                if onAssignGroupHotkey != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hotkeys")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

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
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
                    }
                }
            } else {
                SettingsUnavailableGate(
                    .emptyData,
                    title: "No Groups",
                    message: "Create a group to organize related menu bar items locally.",
                    systemImage: "person.2",
                    minHeight: 220,
                    nextSteps: ["Create a manual group.", "Add item references from the editor."]
                ) {
                    Button("Add Group", systemImage: "plus") {
                        editingGroup = newGroup()
                    }
                }
                    .frame(maxWidth: .infinity, minHeight: 220)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func selectedGroupActions(_ group: IconGroup) -> some View {
        ClearGlassActionStrip(
            "Group Actions",
            subtitle: "Open or reveal the group, then use More for editing, export, and deletion.",
            systemImage: "rectangle.on.rectangle",
            statusText: group.isProtected ? "Protected" : groupItemCountText(group),
            statusStyle: group.isProtected ? .warning : .secondary
        ) {
            selectedGroupActionButtons(group)
        }
    }

    private func groupItemCountText(_ group: IconGroup) -> String {
        group.itemCount == 1 ? "1 Item" : "\(group.itemCount) Items"
    }

    @ViewBuilder
    private func selectedGroupActionButtons(_ group: IconGroup) -> some View {
        if onOpenGroupPanel != nil {
            Button("Open Panel", systemImage: "rectangle.on.rectangle") {
                runOpenPanel(group)
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button("Edit", systemImage: "pencil") {
                editingGroup = group
            }
            .buttonStyle(.borderedProminent)
        }

        if onRevealGroup != nil {
            Button("Reveal", systemImage: "eye") {
                runReveal(group)
            }
        }

        Menu("More", systemImage: "ellipsis.circle") {
            if onOpenGroupPanel != nil {
                Button("Edit", systemImage: "pencil") {
                    editingGroup = group
                }
            }

            Button("Export", systemImage: "square.and.arrow.up") {
                export(group)
            }

            Divider()

            Button("Delete", systemImage: "trash", role: .destructive) {
                let remainingGroups = groups.filter { $0.id != group.id }
                groupStore.removeGroup(id: group.id)
                selectedID = remainingGroups.first?.id
                notifyChanged()
            }
        }
    }

    @ViewBuilder
    private var groupList: some View {
        let selectedGroupID = selectedGroup?.id

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Groups", systemImage: "sidebar.left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(groups.count, format: .number)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                if groups.isEmpty {
                    SettingsUnavailableGate(
                        .emptyData,
                        title: "No Groups",
                        message: "Create a group to collect related menu bar items.",
                        systemImage: "person.2",
                        minHeight: 170,
                        nextSteps: ["Use Add Group above.", "Groups stay local and privacy-safe."]
                    ) {
                        Button("Add Group", systemImage: "plus") {
                            editingGroup = newGroup()
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 170)
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(groups) { group in
                            IconGroupRowView(
                                group: group,
                                isSelected: group.id == selectedGroupID
                            ) {
                                selectedID = group.id
                            }
                        }
                    }
                    .padding(6)
                }
            }
            .frame(minHeight: 220, maxHeight: 420)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
            }
        }
    }

    private func newGroup() -> IconGroup {
        IconGroup(
            name: "New Group",
            symbolName: "folder",
            sortOrder: groups.count
        )
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

    private func reloadGroups(loadFromDisk: Bool = true) {
        if loadFromDisk {
            groupStore.load()
        }

        let sortedGroups = IconGroupSort.sort(groupStore.groups)
        if groups != sortedGroups {
            groups = sortedGroups
        }

        guard let selectedID,
              sortedGroups.contains(where: { $0.id == selectedID }) else {
            let fallbackID = sortedGroups.first?.id
            if selectedID != fallbackID {
                self.selectedID = fallbackID
            }
            return
        }
    }

    private func notifyChanged() {
        reloadGroups()
        onGroupsChanged?()
    }
}
