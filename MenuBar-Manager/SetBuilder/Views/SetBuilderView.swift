import SwiftUI

struct SetBuilderView: View {
    @Bindable var viewModel: SetBuilderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Set Builder")
                        .font(.title3)
                    Text("Preview tool for app-owned Workspace and Function Bar configuration. It does not move real macOS menu bar icons.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Preview", systemImage: "menubar.rectangle", action: viewModel.previewFunctionBar)
                    .disabled(!viewModel.canPreviewFunctionBar)
                Button("Revert", systemImage: "arrow.counterclockwise", action: viewModel.revertDraft)
                    .disabled(viewModel.draft?.isDirty != true)
                Button("Commit", systemImage: "checkmark.circle", action: viewModel.commitDraft)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.draft?.isDirty != true)
            }

            if let message = viewModel.lastCommitResult {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 12) {
                WorkspaceListPane(viewModel: viewModel)
                    .frame(minWidth: 180, idealWidth: 210, maxWidth: 240)

                WorkspaceCanvasPane(viewModel: viewModel)
                    .frame(minWidth: 260, maxWidth: .infinity)

                SetBuilderLibraryPane(viewModel: viewModel)
                    .frame(minWidth: 240, idealWidth: 280, maxWidth: 320)
            }
            .frame(minHeight: 360)
        }
        .accessibilityIdentifier("setBuilder.preview")
    }
}

struct WorkspaceListPane: View {
    @Bindable var viewModel: SetBuilderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Workspaces")
                .font(.headline)

            ForEach(viewModel.workspaces) { workspace in
                Button {
                    viewModel.selectWorkspace(id: workspace.id)
                } label: {
                    HStack {
                        Image(systemName: workspace.iconName)
                        Text(WorkspaceDiagnosticsRedactor.displayName(for: workspace))
                            .lineLimit(1)
                        Spacer()
                        if viewModel.selectedWorkspaceID == workspace.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 8)
            Button("Create", systemImage: "plus", action: viewModel.createWorkspace)
            Button("Duplicate", systemImage: "doc.on.doc", action: viewModel.duplicateSelectedWorkspace)
            Button("Archive", systemImage: "archivebox", action: viewModel.archiveSelectedWorkspace)
            Button("Switch Active", systemImage: "arrow.triangle.2.circlepath", action: viewModel.switchSelectedWorkspace)
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
    }
}

struct WorkspaceCanvasPane: View {
    @Bindable var viewModel: SetBuilderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Function Bar Layout")
                    .font(.headline)
                Spacer()
                if viewModel.draft?.isDirty == true {
                    Text("Unsaved")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            if let draft = viewModel.draft {
                TextField("Workspace Name", text: Binding(
                    get: { draft.editedWorkspace.name },
                    set: { viewModel.renameDraft($0) }
                ))
                .textFieldStyle(.roundedBorder)

                if draft.editedWorkspace.functionItems.isEmpty {
                    ContentUnavailableView("No function items yet.", systemImage: "square.dashed")
                        .frame(maxWidth: .infinity, minHeight: 140)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(draft.editedWorkspace.functionItems) { item in
                                WorkspaceItemRow(
                                    item: item,
                                    linkedGroupUsageCount: viewModel.linkedGroupUsageCount(for: item),
                                    showsLinkedGroupWarning: viewModel.showsLinkedGroupWarnings,
                                    onSelect: { viewModel.selection = .item(item.id) },
                                    onRemove: { viewModel.removeItem(id: item.id) },
                                    onMoveUp: { viewModel.moveItem(id: item.id, direction: -1) },
                                    onMoveDown: { viewModel.moveItem(id: item.id, direction: 1) }
                                )
                            }
                        }
                    }
                }

                InfoStripConfigMiniPane(viewModel: viewModel, config: draft.editedWorkspace.infoStripConfig)
            } else {
                ContentUnavailableView("Select a workspace.", systemImage: "rectangle.3.group")
            }
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
    }
}

struct WorkspaceItemRow: View {
    let item: WorkspaceItem
    let linkedGroupUsageCount: Int?
    let showsLinkedGroupWarning: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            WorkspaceItemPreview(item: item)
            Spacer()
            if showsLinkedGroupWarning, let linkedGroupUsageCount, linkedGroupUsageCount > 1 {
                Label("Used in \(linkedGroupUsageCount) Workspaces", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Button("Up", systemImage: "arrow.up", action: onMoveUp)
                .labelStyle(.iconOnly)
            Button("Down", systemImage: "arrow.down", action: onMoveDown)
                .labelStyle(.iconOnly)
            Button("Remove", systemImage: "trash", action: onRemove)
                .labelStyle(.iconOnly)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
        .onTapGesture(perform: onSelect)
    }
}

struct WorkspaceItemPreview: View {
    let item: WorkspaceItem

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var title: String {
        switch item.kind {
        case .command(let command): command.displayTitle
        case .menuBarItem(let reference): reference.lastKnownDisplayName ?? "Menu Bar Item"
        case .group(let reference): reference.referenceMode == .linked ? "Linked Group" : "Detached Group"
        case .infoTile(let tile): InfoTileProviderID(rawValue: tile.providerID).displayName
        case .spacer: "Spacer"
        case .divider: "Divider"
        }
    }

    private var subtitle: String {
        switch item.kind {
        case .command: "Command"
        case .menuBarItem: "Proxy reference"
        case .group(let reference): reference.referenceMode.displayName
        case .infoTile: "Info Strip tile"
        case .spacer, .divider: "Layout"
        }
    }

    private var iconName: String {
        switch item.kind {
        case .command: "command"
        case .menuBarItem: "app.badge"
        case .group: "person.2"
        case .infoTile: "info.circle"
        case .spacer: "arrow.left.and.right"
        case .divider: "line.3.horizontal"
        }
    }
}

struct SetBuilderLibraryPane: View {
    @Bindable var viewModel: SetBuilderViewModel

    var body: some View {
        TabView {
            LibraryList(title: "Commands", items: viewModel.commandLibrary, onAdd: viewModel.addLibraryItem(_:))
                .tabItem { Label("Commands", systemImage: "command") }
            LibraryList(title: "Groups", items: viewModel.groupLibrary, onAdd: viewModel.addLibraryItem(_:), onAddDetached: { item in
                if case .group(let id) = item.kind {
                    viewModel.addDetachedGroup(groupID: id)
                }
            })
            .tabItem { Label("Groups", systemImage: "person.2") }
            LibraryList(title: "Items", items: viewModel.proxyLibrary, onAdd: viewModel.addLibraryItem(_:))
                .tabItem { Label("Items", systemImage: "app.badge") }
            LibraryList(title: "New Items", items: viewModel.newItemLibrary, onAdd: viewModel.addLibraryItem(_:))
                .tabItem { Label("New Items", systemImage: "tray") }
            LibraryList(title: "Unassigned Items", items: viewModel.unassignedItemLibrary, onAdd: viewModel.addLibraryItem(_:))
                .tabItem { Label("Unassigned", systemImage: "questionmark.app") }
            LibraryList(title: "Layout", items: viewModel.layoutLibrary, onAdd: viewModel.addLibraryItem(_:))
                .tabItem { Label("Layout", systemImage: "rectangle.split.1x2") }
            LibraryList(title: "Info", items: viewModel.infoTileLibrary, onAdd: viewModel.addLibraryItem(_:))
                .tabItem { Label("Info", systemImage: "info.circle") }
        }
    }
}

struct LibraryList: View {
    let title: String
    let items: [SetBuilderLibraryItem]
    let onAdd: (SetBuilderLibraryItem) -> Void
    var onAddDetached: ((SetBuilderLibraryItem) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(items) { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.systemImage)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.callout)
                                if let subtitle = item.subtitle {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("Add", systemImage: "plus") {
                                onAdd(item)
                            }
                            .labelStyle(.iconOnly)
                            .disabled(!item.isEnabled)
                            if let onAddDetached {
                                Button("Detached", systemImage: "square.on.square") {
                                    onAddDetached(item)
                                }
                                .labelStyle(.iconOnly)
                                .disabled(!item.isEnabled)
                            }
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
                    }
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
    }
}

struct InfoStripConfigMiniPane: View {
    @Bindable var viewModel: SetBuilderViewModel
    let config: WorkspaceInfoStripConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Info Strip enabled for this Workspace", isOn: Binding(
                get: { config.isEnabled },
                set: { viewModel.setInfoStripEnabled($0) }
            ))

            Stepper(
                "Idle delay: \(config.idleDelaySeconds)s",
                value: Binding(
                    get: { config.idleDelaySeconds },
                    set: { viewModel.setInfoStripIdleDelay($0) }
                ),
                in: WorkspaceValidationConstants.minIdleDelaySeconds...WorkspaceValidationConstants.maxIdleDelaySeconds
            )

            Stepper(
                "Rotation: \(config.rotationIntervalSeconds)s",
                value: Binding(
                    get: { config.rotationIntervalSeconds },
                    set: { viewModel.setInfoStripRotationInterval($0) }
                ),
                in: WorkspaceValidationConstants.minRotationIntervalSeconds...WorkspaceValidationConstants.maxRotationIntervalSeconds
            )

            Picker("Hover", selection: Binding(
                get: { config.hoverBehavior },
                set: { viewModel.setInfoStripHoverBehavior($0) }
            )) {
                ForEach(WorkspaceInfoStripHoverBehavior.allCases) { behavior in
                    Text(behavior.rawValue).tag(behavior)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Show tile labels", isOn: Binding(
                get: { config.showTileLabels },
                set: { viewModel.setInfoStripShowTileLabels($0) }
            ))
            Toggle("Compact mode", isOn: Binding(
                get: { config.compactMode },
                set: { viewModel.setInfoStripCompactMode($0) }
            ))

            ScrollView(.horizontal) {
                HStack {
                    ForEach(config.selectedTileProviderIDs, id: \.self) { providerID in
                        HStack(spacing: 4) {
                            Label(InfoTileProviderID(rawValue: providerID).displayName, systemImage: "info.circle")
                            Button("Move earlier", systemImage: "arrow.left") {
                                viewModel.moveInfoTile(providerID: providerID, direction: -1)
                            }
                            .labelStyle(.iconOnly)
                            Button("Move later", systemImage: "arrow.right") {
                                viewModel.moveInfoTile(providerID: providerID, direction: 1)
                            }
                            .labelStyle(.iconOnly)
                            Button("Remove", systemImage: "xmark") {
                                viewModel.removeInfoTile(providerID)
                            }
                            .labelStyle(.iconOnly)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(nsColor: .textBackgroundColor), in: .capsule)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7), in: .rect(cornerRadius: 7))
    }
}
