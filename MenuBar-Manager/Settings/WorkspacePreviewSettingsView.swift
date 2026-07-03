import SwiftUI

struct WorkspacePreviewSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var liveStatus: LiveDiagnosticsStatus?
    let switchingService: WorkspaceSwitchingService
    @Bindable var setBuilderViewModel: SetBuilderViewModel
    let functionBarController: FunctionBarController
    let infoStripController: InfoStripController
    var knownGroupIDs: Set<UUID> = []
    var protectedGroupIDs: Set<UUID> = []
    var knownProfileIDs: Set<UUID> = []
    var routeCommand: ((MenuBarCommand) -> MenuBarCommandResult)? = nil
    var onOpenFindRescue: (() -> Void)? = nil
    var onOpenRecovery: (() -> Void)? = nil

    var body: some View {
        ClearGlassSettingsPage(
            "Workspaces",
            subtitle: "Preview workspace sets for MenuBarDeclutter-owned surfaces.",
            badges: [.experimental, .privacySafe, .diagnostics],
            sectionAnchors: [
                ClearGlassPageAnchor("Integration", systemImage: "point.3.connected.trianglepath.dotted", targetID: "Workspace Integration"),
                ClearGlassPageAnchor("Gates", systemImage: "switch.2", targetID: "Preview Gates"),
                ClearGlassPageAnchor("Active", systemImage: "rectangle.3.group", targetID: "Active Workspace"),
                ClearGlassPageAnchor("Actions", systemImage: "bolt", targetID: "Quick Actions"),
                ClearGlassPageAnchor("List", systemImage: "list.bullet.rectangle", targetID: "Workspace List"),
                ClearGlassPageAnchor("Function Bar", systemImage: "menubar.rectangle", targetID: "Preview Controls"),
                ClearGlassPageAnchor("Info Strip", systemImage: "info.circle", targetID: "Info Strip Preview"),
                ClearGlassPageAnchor("Set Builder", systemImage: "slider.horizontal.3"),
                ClearGlassPageAnchor("Diagnostics", systemImage: "waveform.path.ecg")
            ]
        ) {
            integrationOverviewSection
            previewGatesSection
            activeWorkspaceSection
            quickActionsSection
            workspaceListSection
            previewControlsSection
            infoStripPreviewSection
            linkedGroupsSection
            setBuilderSection
            diagnosticsSection
        }
        .onAppear {
            setBuilderViewModel.refresh()
        }
        .onChange(of: settingsStore.workspacesPreviewEnabled) { _, isEnabled in
            guard !isEnabled else { return }
            hideFunctionBar()
            hideInfoStrip()
        }
        .onChange(of: settingsStore.functionBarPreviewEnabled) { _, isEnabled in
            guard !isEnabled else { return }
            hideFunctionBar()
        }
        .onChange(of: settingsStore.infoStripPreviewEnabled) { _, isEnabled in
            guard !isEnabled else { return }
            hideInfoStrip()
        }
    }

    private var previewGatesSection: some View {
        ClearGlassSection(
            "Preview Gates",
            subtitle: "Everything here stays app-owned and off unless explicitly enabled."
        ) {
            Text("Workspaces configure MenuBarDeclutter's app-owned Function Bar and Info Strip. They do not replace or control the macOS system menu bar.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ClearGlassDivider()

            workspaceToggleRow(
                "Enable Workspaces Preview",
                subtitle: "Unlock local Workspace records and app-owned preview surfaces.",
                systemImage: "rectangle.3.group",
                isOn: $settingsStore.workspacesPreviewEnabled
            )

            ClearGlassDivider()

            workspaceToggleRow(
                "Enable Function Bar Preview",
                subtitle: "Show an app-owned strip for Workspace shortcuts.",
                systemImage: "menubar.rectangle",
                isOn: $settingsStore.functionBarPreviewEnabled,
                disabled: !settingsStore.workspacesPreviewEnabled
            )

            ClearGlassDivider()

            workspaceToggleRow(
                "Enable Set Builder Preview",
                subtitle: "Edit local Workspace sets inside Settings.",
                systemImage: "slider.horizontal.3",
                isOn: $settingsStore.setBuilderPreviewEnabled,
                disabled: !settingsStore.workspacesPreviewEnabled
            )

            ClearGlassDivider()

            workspaceToggleRow(
                "Enable Info Strip Preview",
                subtitle: "Show a local idle strip for selected Workspace tiles.",
                systemImage: "info.circle",
                isOn: $settingsStore.infoStripPreviewEnabled,
                disabled: !settingsStore.workspacesPreviewEnabled
            )

            ClearGlassDivider()

            workspaceToggleRow(
                "Use Function Bar on status-item click",
                subtitle: "Route the primary status-item click to the Function Bar.",
                systemImage: "cursorarrow.click",
                isOn: $settingsStore.functionBarPrimaryClickEnabled,
                disabled: !settingsStore.workspacesPreviewEnabled || !settingsStore.functionBarPreviewEnabled
            )

            ClearGlassDivider()

            workspaceToggleRow(
                "Auto-show Info Strip",
                subtitle: "Show the Info Strip automatically for enabled Workspaces.",
                systemImage: "sparkles",
                isOn: $settingsStore.infoStripAutoShowEnabled,
                disabled: !settingsStore.workspacesPreviewEnabled || !settingsStore.infoStripPreviewEnabled
            )
        }
    }

    private var integrationOverviewSection: some View {
        let snapshot = switchingService.currentSnapshot()
        let usage = WorkspaceUsageIndex().rebuild(
            snapshot: snapshot,
            groups: setBuilderViewModel.groups
        )
        let integration = WorkspaceIntegrationDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            usageSnapshot: usage,
            newItemInbox: NewMenuBarItemInbox.empty,
            functionBarFallbackEnabled: settingsStore.functionBarPreviewEnabled,
            physicalProfileBindingCount: snapshot.workspaces.filter { $0.physicalProfileBinding != nil }.count,
            lastCrowdedRescueWorkspaceDecision: nil
        )

        return ClearGlassSection(
            "Workspace Integration",
            subtitle: "Local-only status for Workspace-aware item assignment, search badges, placement hints, and rescue fallback."
        ) {
            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                diagnosticsRow("Indexed Workspaces", "\(integration.workspaceCount)")
                diagnosticsRow("Indexed Items", "\(integration.indexedItemReferenceCount)")
                diagnosticsRow("Unassigned Items", "\(integration.unassignedItemReferenceCount)")
                diagnosticsRow("Missing Group Refs", "\(integration.missingGroupReferenceCount)")
                diagnosticsRow("Physical Bindings", "\(integration.physicalProfileBindingCount)")
                diagnosticsRow("Command Automation", "Internal only")
            }
        }
    }

    private var activeWorkspaceSection: some View {
        let snapshot = switchingService.currentSnapshot()
        let active = switchingService.activeWorkspace()
        let usageIndex = WorkspaceUsageIndex()
        let usage = usageIndex.rebuild(snapshot: snapshot, groups: setBuilderViewModel.groups)
        let unassignedCount = liveStatus.map { status in
            usageIndex.unassignedItemHashes(from: status.scannedMenuBarItems.map { snapshot in
                MenuBarItemReference(
                    stableHash: snapshot.id,
                    source: .accessibilitySnapshot,
                    lastKnownDisplayName: snapshot.owningApplicationName ?? snapshot.title,
                    lastKnownBundleIdentifier: snapshot.bundleIdentifier
                )
            }).count
        } ?? 0
        return ClearGlassSection(
            "Active Workspace",
            subtitle: "\(snapshot.workspaces.filter { !$0.isArchived }.count) available, \(snapshot.workspaces.filter(\.isArchived).count) archived."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        activeWorkspaceIdentity(active)

                        Spacer(minLength: 12)

                        switchDefaultWorkspaceButton(snapshot)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        activeWorkspaceIdentity(active)
                        switchDefaultWorkspaceButton(snapshot)
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                    diagnosticsRow("Function Bar", functionBarLandingStatus)
                    diagnosticsRow("Info Strip", infoStripLandingStatus)
                    diagnosticsRow("Workspace Items", "\(active.functionItems.count)")
                    diagnosticsRow("Linked Groups", "\(activeLinkedGroupCount)")
                    diagnosticsRow("New Items", "\(liveStatus?.newMenuBarItemReviewCount ?? 0)")
                    diagnosticsRow("Unassigned Items", "\(unassignedCount)")
                    diagnosticsRow("Profile Binding", active.physicalProfileBinding == nil ? "Preview none" : "Dry-run bound")
                    diagnosticsRow("Used In Active", "\(usage.usagesByItemHash.values.filter(\.isUsedInActiveWorkspace).count)")
                }
            }
        }
    }

    private var quickActionsSection: some View {
        ClearGlassSection(
            "Quick Actions",
            subtitle: "Local app-owned shortcuts for the active Workspace."
        ) {
            ClearGlassButtonGrid(minimumItemWidth: 150) {
                Button("Show Function Bar", systemImage: "menubar.rectangle") {
                    showFunctionBar()
                }
                .disabled(functionBarControlsDisabled)

                Button("Show Info Strip", systemImage: "info.circle") {
                    showInfoStrip()
                }
                .disabled(infoStripControlsDisabled || !activeInfoStripConfig.isEnabled)

                Button("Open Set Builder", systemImage: "slider.horizontal.3") {
                    setBuilderViewModel.selectWorkspace(id: switchingService.activeWorkspace().id)
                }
                .disabled(!settingsStore.workspacesPreviewEnabled || !settingsStore.setBuilderPreviewEnabled)

                Button("Review New Items", systemImage: "tray.full") {
                    onOpenFindRescue?()
                }

                Button("Create Workspace", systemImage: "plus") {
                    setBuilderViewModel.createWorkspace()
                    refreshAfterWorkspaceMutation()
                }

                Button("Duplicate Workspace", systemImage: "doc.on.doc") {
                    setBuilderViewModel.selectedWorkspaceID = switchingService.activeWorkspace().id
                    setBuilderViewModel.duplicateSelectedWorkspace()
                    refreshAfterWorkspaceMutation()
                }
            }

            if let result = setBuilderViewModel.lastCommitResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var workspaceListSection: some View {
        let activeID = switchingService.activeWorkspace().id
        let workspaces = switchingService.currentSnapshot().workspaces.filter { !$0.isArchived }

        return ClearGlassSection(
            "Workspace List",
            subtitle: "Switch local Workspace records without moving real menu bar icons."
        ) {
            VStack(spacing: 0) {
                ForEach(Array(workspaces.enumerated()), id: \.element.id) { offset, workspace in
                    HStack(spacing: 10) {
                        Image(systemName: workspace.iconName)
                            .frame(width: 20)
                            .foregroundStyle(workspace.id == activeID ? Color.accentColor : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(WorkspaceDiagnosticsRedactor.displayName(for: workspace))
                                .font(.callout)
                            Text("\(workspace.functionItems.count) item\(workspace.functionItems.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if workspace.id == activeID {
                            Text("Active")
                                .font(.caption2)
                                .foregroundStyle(Color.accentColor)
                        }
                        Button("Switch", systemImage: "arrow.triangle.2.circlepath") {
                            _ = switchingService.switchWorkspace(id: workspace.id, source: .settings)
                            setBuilderViewModel.refresh()
                            refreshWorkspacePanelsAfterSettingsChange()
                        }
                        .labelStyle(.iconOnly)
                    }
                    .padding(.vertical, 8)

                    if offset < workspaces.count - 1 {
                        ClearGlassDivider()
                    }
                }
            }
        }
    }

    private var linkedGroupsSection: some View {
        let active = switchingService.activeWorkspace()
        let linked = active.functionItems.compactMap { item -> WorkspaceGroupReference? in
            guard case .group(let reference) = item.kind,
                  reference.referenceMode == .linked else {
                return nil
            }
            return reference
        }

        return ClearGlassSection(
            "Linked Groups",
            subtitle: "Reusable Groups can appear in multiple Workspaces; detached copies stay one-off."
        ) {
            if linked.isEmpty {
                ContentUnavailableView("No linked Groups in this Workspace.", systemImage: "person.2")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(linked.enumerated()), id: \.element.groupID) { offset, reference in
                        HStack {
                            Label(linkedGroupDisplayName(for: reference.groupID), systemImage: "person.2")
                            Spacer()
                            Text("Linked")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)

                        if offset < linked.count - 1 {
                            ClearGlassDivider()
                        }
                    }
                }
            }
        }
    }

    private var previewControlsSection: some View {
        ClearGlassSection(
            "Preview Controls",
            subtitle: "Panels are app-owned previews. They do not inspect pixels, capture the screen, replace the macOS menu bar, or move menu bar items."
        ) {
            Text("Function Bar is app-owned UI. It does not replace the macOS menu bar and does not capture screen pixels.")
                .font(.caption)
                .foregroundStyle(.secondary)

            WorkspaceFunctionBarPreview(
                showLabels: settingsStore.functionBarShowLabels,
                density: FunctionBarDensity(rawValue: settingsStore.functionBarDensity) ?? .regular,
                infoStripEnabled: settingsStore.infoStripPreviewEnabled,
                functionBarEnabled: settingsStore.functionBarPreviewEnabled
            )

            ClearGlassButtonGrid(minimumItemWidth: 150) {
                Button("Show Function Bar", systemImage: "menubar.rectangle") {
                    showFunctionBar()
                }
                .disabled(!settingsStore.workspacesPreviewEnabled || !settingsStore.functionBarPreviewEnabled)

                Button("Hide", systemImage: "xmark.circle") {
                    hideFunctionBar()
                }

                Button("Show Info Strip", systemImage: "info.circle") {
                    showInfoStrip()
                }
                .disabled(!settingsStore.workspacesPreviewEnabled || !settingsStore.infoStripPreviewEnabled)

                Button("Recovery", systemImage: "cross.case") {
                    onOpenRecovery?()
                }
            }

            Picker("Function Bar placement", selection: $settingsStore.functionBarPlacementPreference) {
                ForEach(FunctionBarPlacementPreference.allCases) { preference in
                    Text(preference.displayName).tag(preference.rawValue)
                }
            }
            .pickerStyle(.menu)

            Toggle("Show Set Switcher", isOn: $settingsStore.functionBarShowSetSwitcher)
                .disabled(functionBarControlsDisabled)
            Toggle("Show Function Bar Labels", isOn: $settingsStore.functionBarShowLabels)
                .disabled(functionBarControlsDisabled)
            Picker("Function Bar Density", selection: $settingsStore.functionBarDensity) {
                ForEach(FunctionBarDensity.allCases) { density in
                    Text(density.displayName).tag(density.rawValue)
                }
            }
            .pickerStyle(.menu)
            .disabled(functionBarControlsDisabled)
            Toggle("Close Function Bar on outside click", isOn: $settingsStore.functionBarCloseOnOutsideClick)
                .disabled(functionBarControlsDisabled)
            Toggle("Enable Function Bar keyboard navigation", isOn: $settingsStore.functionBarKeyboardNavigationEnabled)
                .disabled(functionBarControlsDisabled)
            Toggle("Hover from Info Strip to Function Bar", isOn: $settingsStore.infoStripHoverToFunctionBarEnabled)

            Picker("Crowded rescue fallback", selection: $settingsStore.crowdedRescueWorkspaceFallbackPreference) {
                ForEach(CrowdedRescueWorkspaceFallbackPreference.allCases) { preference in
                    Text(preference.displayName).tag(preference.rawValue)
                }
            }
            .pickerStyle(.menu)
            .disabled(!settingsStore.workspacesPreviewEnabled)
        }
    }

    private var infoStripPreviewSection: some View {
        let active = switchingService.activeWorkspace()
        let config = activeInfoStripConfig
        let selectedIDs = Set(config.selectedTileProviderIDs)

        return ClearGlassSection(
            "Info Strip Preview",
            subtitle: "Configure the active Workspace's app-owned idle strip."
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Info Strip is app-owned UI, not a system menu bar replacement. It does not capture pixels, use Screen Recording, use network widgets, scrape notifications, move menu bar icons, or apply physical layouts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label("Preview", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(settingsStore.infoStripShowPreviewBadge ? Color.accentColor : .secondary)
            }

            WorkspaceInfoStripPreview(
                selectedProviderIDs: config.selectedTileProviderIDs,
                compactMode: config.compactMode,
                showTileLabels: config.showTileLabels,
                idleDelaySeconds: config.idleDelaySeconds,
                rotationIntervalSeconds: config.rotationIntervalSeconds,
                isEnabled: config.isEnabled && settingsStore.infoStripPreviewEnabled
            )

            Toggle("Enable Info Strip for active Workspace", isOn: Binding(
                get: { activeInfoStripConfig.isEnabled },
                set: { setActiveInfoStripEnabled($0) }
            ))
            .disabled(infoStripControlsDisabled)

            ClearGlassControlRow(
                systemImage: "timer",
                title: "Idle delay",
                subtitle: "Idle delay: \(config.idleDelaySeconds) seconds before showing the strip."
            ) {
                Stepper(
                    "Idle delay",
                    value: Binding(
                        get: { activeInfoStripConfig.idleDelaySeconds },
                        set: { setActiveInfoStripIdleDelay($0) }
                    ),
                    in: WorkspaceValidationConstants.minIdleDelaySeconds...WorkspaceValidationConstants.maxIdleDelaySeconds
                )
                .labelsHidden()
                .accessibilityLabel("Idle delay")
            }
            .disabled(infoStripControlsDisabled)

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "arrow.triangle.2.circlepath",
                title: "Rotation interval",
                subtitle: "Rotation: \(config.rotationIntervalSeconds) seconds between selected tiles."
            ) {
                Stepper(
                    "Rotation interval",
                    value: Binding(
                        get: { activeInfoStripConfig.rotationIntervalSeconds },
                        set: { setActiveInfoStripRotationInterval($0) }
                    ),
                    in: WorkspaceValidationConstants.minRotationIntervalSeconds...WorkspaceValidationConstants.maxRotationIntervalSeconds
                )
                .labelsHidden()
                .accessibilityLabel("Rotation interval")
            }
            .disabled(infoStripControlsDisabled)

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "hand.point.up.left",
                title: "Hover behavior",
                subtitle: "Choose what happens when the pointer reaches the strip."
            ) {
                Picker("Hover behavior", selection: Binding(
                    get: { activeInfoStripConfig.hoverBehavior },
                    set: { setActiveInfoStripHoverBehavior($0) }
                )) {
                    ForEach(WorkspaceInfoStripHoverBehavior.allCases) { behavior in
                        Text(infoStripHoverBehaviorLabel(behavior)).tag(behavior)
                    }
                }
                .pickerStyle(.menu)
            }
            .disabled(infoStripControlsDisabled)

            ClearGlassDivider()

            workspaceToggleRow(
                "Compact mode",
                subtitle: "Use a tighter tile layout for this Workspace.",
                systemImage: "rectangle.compress.vertical",
                isOn: Binding(
                    get: { activeInfoStripConfig.compactMode },
                    set: { setActiveInfoStripCompactMode($0) }
                ),
                disabled: infoStripControlsDisabled
            )

            Toggle("Show tile labels", isOn: Binding(
                get: { activeInfoStripConfig.showTileLabels },
                set: { setActiveInfoStripShowTileLabels($0) }
            ))
            .disabled(infoStripControlsDisabled)

            Toggle("Show preview badge", isOn: $settingsStore.infoStripShowPreviewBadge)
                .disabled(!settingsStore.workspacesPreviewEnabled || !settingsStore.infoStripPreviewEnabled)

            VStack(alignment: .leading, spacing: 8) {
                Text("Tile Picker")
                    .font(.headline)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 170), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(setBuilderViewModel.infoTileLibrary) { item in
                        let providerID = infoTileProviderID(for: item)
                        let isSelected = providerID.map { selectedIDs.contains($0) } ?? false
                        Button {
                            if let providerID {
                                setActiveInfoTileSelected(providerID)
                            }
                        } label: {
                            Label(item.title, systemImage: isSelected ? "checkmark.circle.fill" : item.systemImage)
                        }
                        .disabled(infoStripControlsDisabled || providerID == nil || isSelected)
                    }
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(config.selectedTileProviderIDs, id: \.self) { providerID in
                            HStack(spacing: 5) {
                                Label(InfoTileProviderID(rawValue: providerID).displayName, systemImage: "info.circle")
                                Button("Move earlier", systemImage: "arrow.left") {
                                    moveActiveInfoTile(providerID: providerID, direction: -1)
                                }
                                .labelStyle(.iconOnly)
                                Button("Move later", systemImage: "arrow.right") {
                                    moveActiveInfoTile(providerID: providerID, direction: 1)
                                }
                                .labelStyle(.iconOnly)
                                Button("Remove", systemImage: "xmark") {
                                    removeActiveInfoTile(providerID)
                                }
                                .labelStyle(.iconOnly)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            .disabled(infoStripControlsDisabled)

            ClearGlassButtonGrid(minimumItemWidth: 170) {
                Button("Open Info Strip Preview", systemImage: "info.circle") {
                    showInfoStrip()
                }
                .disabled(infoStripControlsDisabled || !activeInfoStripConfig.isEnabled)

                Button("Save Workspace Info Strip", systemImage: "square.and.arrow.down") {
                    saveActiveInfoStripDraft()
                }
                .disabled(setBuilderViewModel.draft?.workspaceID != active.id || setBuilderViewModel.draft?.isDirty != true)
            }

            if let result = setBuilderViewModel.lastCommitResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var setBuilderSection: some View {
        ClearGlassSection(
            "Set Builder",
            subtitle: "Create, duplicate, archive, arrange, and save local Workspace sets."
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Set Builder is Preview. It edits MenuBarDeclutter's app-owned Workspace and Function Bar configuration. It does not move real macOS menu bar icons.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Groups can be reused across multiple Workspaces. Linked references update everywhere; Detached Copy creates a one-off version for a single Workspace.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            workspaceToggleRow(
                "Enable library drag and drop",
                subtitle: "Allow dragging local library items into the draft set.",
                systemImage: "hand.draw",
                isOn: $settingsStore.setBuilderDragDropEnabled,
                disabled: !settingsStore.workspacesPreviewEnabled
            )

            ClearGlassDivider()

            workspaceToggleRow(
                "Show advanced library items",
                subtitle: "Include lower-level builder blocks in the item library.",
                systemImage: "square.grid.3x3",
                isOn: $settingsStore.setBuilderShowAdvancedLibraryItems,
                disabled: !settingsStore.workspacesPreviewEnabled
            )

            ClearGlassDivider()

            workspaceToggleRow(
                "Show Function Bar preview",
                subtitle: "Open the Function Bar from Set Builder while editing.",
                systemImage: "menubar.rectangle",
                isOn: $settingsStore.setBuilderShowFunctionBarPreview,
                disabled: !settingsStore.workspacesPreviewEnabled || !settingsStore.functionBarPreviewEnabled
            )

            ClearGlassDivider()

            workspaceToggleRow(
                "Autosave drafts while switching",
                subtitle: "Preserve local Set Builder edits when changing Workspaces.",
                systemImage: "square.and.arrow.down",
                isOn: $settingsStore.setBuilderAutosaveDrafts,
                disabled: !settingsStore.workspacesPreviewEnabled
            )

            ClearGlassDivider()

            workspaceToggleRow(
                "Warn before linked Group edits",
                subtitle: "Confirm edits that affect linked Groups in multiple Workspaces.",
                systemImage: "exclamationmark.triangle",
                isOn: $settingsStore.setBuilderWarnBeforeLinkedGroupEdits,
                disabled: !settingsStore.workspacesPreviewEnabled
            )

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "person.2",
                title: "Default Group insertion",
                subtitle: "Choose how Groups are inserted into new Workspace items."
            ) {
                Picker("Default Group insertion", selection: $settingsStore.setBuilderDefaultGroupReferenceMode) {
                    ForEach(WorkspaceGroupReferenceMode.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!settingsStore.workspacesPreviewEnabled)
            }

            if settingsStore.setBuilderPreviewEnabled {
                SetBuilderView(viewModel: setBuilderViewModel)
            } else {
                ContentUnavailableView("Set Builder Disabled", systemImage: "rectangle.3.group")
                    .frame(maxWidth: .infinity, minHeight: 220)
            }
        }
    }

    private var diagnosticsSection: some View {
        let snapshot = switchingService.currentSnapshot()
        let active = switchingService.activeWorkspace()
        let workspaceDiagnostics = WorkspaceDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            snapshot: snapshot,
            validationIssues: [],
            lastLoadStatus: .loaded,
            knownGroupIDs: knownGroupIDs.isEmpty ? Set(setBuilderViewModel.groups.map(\.id)) : knownGroupIDs,
            protectedGroupIDs: protectedGroupIDs.isEmpty ? Set(setBuilderViewModel.groups.filter(\.isProtected).map(\.id)) : protectedGroupIDs,
            knownProfileIDs: knownProfileIDs,
            availableMenuBarItemHashes: availableMenuBarItemHashesForDiagnostics
        )
        let functionDiagnostics = FunctionBarDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            controller: functionBarController
        )
        let setBuilderDiagnostics = setBuilderViewModel.diagnosticsSnapshot
        let infoDiagnostics = InfoStripDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            controller: infoStripController,
            registry: InfoTileProviderRegistry(),
            context: InfoTileContext(
                activeWorkspace: active,
                functionBarVisible: functionDiagnostics.isVisible,
                hiddenItemCount: liveStatus?.menuBarScanHiddenCount,
                alwaysHiddenItemCount: liveStatus?.menuBarScanAlwaysHiddenCount,
                newItemCount: liveStatus?.newMenuBarItemReviewCount,
                healthWarningCount: liveStatus?.healthReport?.issues.count ?? 0,
                latestScanAgeSeconds: nil,
                proDiscoveryAvailable: settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled,
                safeModeActive: liveStatus?.safeModeActive ?? false,
                currentDate: Date()
            )
        )

        return ClearGlassSection(
            "Diagnostics",
            subtitle: "Counts and states are safe to export; protected names are redacted."
        ) {
            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                diagnosticsRow("Store", workspaceDiagnostics.lastLoadStatus.rawValue)
                diagnosticsRow("Workspaces", "\(workspaceDiagnostics.workspaceCount)")
                diagnosticsRow("Active", workspaceDiagnostics.activeWorkspacePresent ? "Present" : "Missing")
                diagnosticsRow("Function Bar", functionDiagnostics.displayState)
                diagnosticsRow("Function Items", "\(functionDiagnostics.visibleItemCount)")
                diagnosticsRow("Set Builder", setBuilderDiagnostics.previewEnabled ? "Enabled" : "Disabled")
                diagnosticsRow("Workspace Items", "\(setBuilderDiagnostics.totalWorkspaceItemCount)")
                diagnosticsRow("Group Refs", "\(workspaceDiagnostics.groupReferenceCount)")
                diagnosticsRow("Linked Groups", "\(setBuilderDiagnostics.linkedGroupReferenceCount)")
                diagnosticsRow("Protected Groups", "\(workspaceDiagnostics.protectedGroupReferenceCount)")
                diagnosticsRow("Missing Groups", "\(setBuilderDiagnostics.missingGroupReferenceCount)")
                diagnosticsRow("Detached Sources Missing", "\(setBuilderDiagnostics.detachedSourceGroupMissingCount)")
                diagnosticsRow("Proxy Items", "\(setBuilderDiagnostics.menuBarProxyReferenceCount)")
                diagnosticsRow("Unresolved Proxies", "\(setBuilderDiagnostics.unresolvedMenuBarProxyReferenceCount)")
                diagnosticsRow("Info Strip", infoDiagnostics.displayState)
                diagnosticsRow("Current Tile", infoDiagnostics.currentTileProviderID ?? "None")
                diagnosticsRow("New Items", "\(liveStatus?.newMenuBarItemReviewCount ?? 0)")
            }
        }
    }

    private func diagnosticsRow(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
        }
    }

    private func activeWorkspaceIdentity(_ workspace: MenuBarWorkspace) -> some View {
        HStack(spacing: 12) {
            Image(systemName: workspace.iconName)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(WorkspaceDiagnosticsRedactor.displayName(for: workspace))
                    .font(.headline)
                    .lineLimit(1)

                Text("App-owned \(workspace.displayMode.rawValue) Workspace")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func switchDefaultWorkspaceButton(_ snapshot: WorkspaceStoreSnapshot) -> some View {
        Button("Switch Default", systemImage: "rectangle.3.group") {
            if let first = snapshot.workspaces.first(where: { !$0.isArchived }) {
                _ = switchingService.switchWorkspace(id: first.id, source: .settings)
                setBuilderViewModel.refresh()
            }
        }
    }

    private func workspaceToggleRow(
        _ title: String,
        subtitle: String,
        systemImage: String,
        isOn: Binding<Bool>,
        disabled: Bool = false
    ) -> some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle
        ) {
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .accessibilityLabel(Text(title))
        }
        .disabled(disabled)
    }

    private func showFunctionBar() {
        if let routeCommand {
            _ = routeCommand(.init(action: .showFunctionBar, target: .functionBar, source: .settings))
        } else {
            functionBarController.show(source: .settings)
        }
    }

    private func hideFunctionBar() {
        if let routeCommand {
            _ = routeCommand(.init(action: .hideFunctionBar, target: .functionBar, source: .settings))
        } else {
            functionBarController.hide(source: .settings)
        }
    }

    private func showInfoStrip() {
        if let routeCommand {
            _ = routeCommand(.init(action: .showInfoStrip, target: .infoStrip, source: .settings))
        } else {
            infoStripController.show()
        }
    }

    private func hideInfoStrip() {
        if let routeCommand {
            _ = routeCommand(.init(action: .hideInfoStrip, target: .infoStrip, source: .settings))
        } else {
            infoStripController.hide()
        }
    }

    private var functionBarControlsDisabled: Bool {
        !settingsStore.workspacesPreviewEnabled || !settingsStore.functionBarPreviewEnabled
    }

    private var infoStripControlsDisabled: Bool {
        !settingsStore.workspacesPreviewEnabled || !settingsStore.infoStripPreviewEnabled
    }

    private var activeLinkedGroupCount: Int {
        switchingService.activeWorkspace().functionItems.filter { item in
            guard case .group(let reference) = item.kind else { return false }
            return reference.referenceMode == .linked
        }.count
    }

    private var functionBarLandingStatus: String {
        guard settingsStore.workspacesPreviewEnabled else { return "Workspace Preview off" }
        guard settingsStore.functionBarPreviewEnabled else { return "Preview off" }
        return functionBarController.displayState.isVisible ? "Visible" : "Ready"
    }

    private var infoStripLandingStatus: String {
        guard settingsStore.workspacesPreviewEnabled else { return "Workspace Preview off" }
        guard settingsStore.infoStripPreviewEnabled else { return "Preview off" }
        guard activeInfoStripConfig.isEnabled else { return "Disabled for Workspace" }
        if case .visible = infoStripController.displayState {
            return "Visible"
        }
        return "Ready"
    }

    private func linkedGroupDisplayName(for groupID: UUID) -> String {
        guard let group = setBuilderViewModel.groups.first(where: { $0.id == groupID }) else {
            return "Missing Group"
        }
        return group.isProtected ? "Protected Group" : group.name
    }

    private func refreshAfterWorkspaceMutation() {
        setBuilderViewModel.refresh()
        refreshWorkspacePanelsAfterSettingsChange()
    }

    private func refreshWorkspacePanelsAfterSettingsChange() {
        functionBarController.refresh(reason: .workspaceChanged)
        infoStripController.refresh()
    }

    private var availableMenuBarItemHashesForDiagnostics: Set<String>? {
        guard settingsStore.proModeEnabled,
              settingsStore.accessibilityDiscoveryEnabled,
              settingsStore.lastAccessibilityPermissionStatus == AccessibilityPermissionStatus.granted.rawValue,
              liveStatus?.lastMenuBarScanTime != nil else {
            return nil
        }
        return Set(liveStatus?.scannedMenuBarItems.map(\.id) ?? [])
    }

    private var activeInfoStripConfig: WorkspaceInfoStripConfig {
        let active = switchingService.activeWorkspace()
        if let draft = setBuilderViewModel.draft,
           draft.workspaceID == active.id {
            return draft.editedWorkspace.infoStripConfig
        }
        return active.infoStripConfig
    }

    private func prepareActiveInfoStripDraft() {
        let activeID = switchingService.activeWorkspace().id
        setBuilderViewModel.refresh()
        if setBuilderViewModel.selectedWorkspaceID != activeID
            || setBuilderViewModel.draft?.workspaceID != activeID {
            setBuilderViewModel.selectWorkspace(id: activeID)
        }
    }

    private func setActiveInfoStripEnabled(_ isEnabled: Bool) {
        prepareActiveInfoStripDraft()
        setBuilderViewModel.setInfoStripEnabled(isEnabled)
    }

    private func setActiveInfoStripIdleDelay(_ seconds: Int) {
        prepareActiveInfoStripDraft()
        setBuilderViewModel.setInfoStripIdleDelay(seconds)
    }

    private func setActiveInfoStripRotationInterval(_ seconds: Int) {
        prepareActiveInfoStripDraft()
        setBuilderViewModel.setInfoStripRotationInterval(seconds)
    }

    private func setActiveInfoStripHoverBehavior(_ behavior: WorkspaceInfoStripHoverBehavior) {
        prepareActiveInfoStripDraft()
        setBuilderViewModel.setInfoStripHoverBehavior(behavior)
    }

    private func setActiveInfoStripCompactMode(_ compactMode: Bool) {
        prepareActiveInfoStripDraft()
        setBuilderViewModel.setInfoStripCompactMode(compactMode)
    }

    private func setActiveInfoStripShowTileLabels(_ showTileLabels: Bool) {
        prepareActiveInfoStripDraft()
        setBuilderViewModel.setInfoStripShowTileLabels(showTileLabels)
    }

    private func setActiveInfoTileSelected(_ providerID: String) {
        prepareActiveInfoStripDraft()
        setBuilderViewModel.addInfoTile(providerID)
    }

    private func removeActiveInfoTile(_ providerID: String) {
        prepareActiveInfoStripDraft()
        setBuilderViewModel.removeInfoTile(providerID)
    }

    private func moveActiveInfoTile(providerID: String, direction: Int) {
        prepareActiveInfoStripDraft()
        setBuilderViewModel.moveInfoTile(providerID: providerID, direction: direction)
    }

    private func saveActiveInfoStripDraft() {
        prepareActiveInfoStripDraft()
        setBuilderViewModel.commitDraft()
        infoStripController.refresh()
    }

    private func infoStripHoverBehaviorLabel(_ behavior: WorkspaceInfoStripHoverBehavior) -> String {
        switch behavior {
        case .showFunctionBar:
            "Show Function Bar"
        case .keepInfoStrip:
            "Keep Info Strip"
        case .pinInfoStrip:
            "Pin Info Strip"
        }
    }

    private func infoTileProviderID(for item: SetBuilderLibraryItem) -> String? {
        if case .infoTile(let providerID) = item.kind {
            return providerID
        }
        return nil
    }
}

private struct WorkspaceFunctionBarPreview: View {
    let showLabels: Bool
    let density: FunctionBarDensity
    let infoStripEnabled: Bool
    let functionBarEnabled: Bool

    private let workspaces = [
        ("Focus", "moon"),
        ("Live", "dot.radiowaves.left.and.right"),
        ("Travel", "airplane")
    ]
    private let actions = [
        ("Reveal", "eye"),
        ("Find", "magnifyingglass"),
        ("Groups", "person.2"),
        ("Info", "info.circle")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("Function Bar Preview", systemImage: "menubar.rectangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                ClearGlassStatusValue(
                    text: functionBarEnabled ? "Ready" : "Off",
                    style: functionBarEnabled ? .info : .secondary
                )
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    workspaceSwitcher
                    Divider().frame(height: 28)
                    actionStrip
                }

                VStack(alignment: .leading, spacing: 10) {
                    workspaceSwitcher
                    actionStrip
                }
            }

            HStack(spacing: 8) {
                Label(density.displayName, systemImage: "rectangle.compress.vertical")
                Label(showLabels ? "Labels" : "Icons only", systemImage: "textformat")
                Label(infoStripEnabled ? "Info Strip linked" : "Info Strip off", systemImage: "info.circle")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.62), lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Function Bar preview")
    }

    private var workspaceSwitcher: some View {
        HStack(spacing: 6) {
            ForEach(workspaces, id: \.0) { workspace in
                Label(workspace.0, systemImage: workspace.1)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        workspace.0 == "Focus" ? Color.accentColor.opacity(0.13) : Color(nsColor: .controlBackgroundColor),
                        in: .rect(cornerRadius: 6)
                    )
                    .foregroundStyle(workspace.0 == "Focus" ? Color.accentColor : .secondary)
            }
        }
    }

    private var actionStrip: some View {
        HStack(spacing: density == .compact ? 8 : 12) {
            ForEach(actions, id: \.0) { action in
                VStack(spacing: 4) {
                    Image(systemName: action.1)
                        .font(.system(size: density == .compact ? 15 : 17, weight: .regular))
                        .frame(width: 22, height: 22)

                    if showLabels {
                        Text(action.0)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
                .frame(minWidth: showLabels ? 42 : 26)
                .foregroundStyle(functionBarEnabled ? .primary : .secondary)
            }
        }
        .opacity(functionBarEnabled ? 1 : 0.58)
    }
}

private struct WorkspaceInfoStripPreview: View {
    let selectedProviderIDs: [String]
    let compactMode: Bool
    let showTileLabels: Bool
    let idleDelaySeconds: Int
    let rotationIntervalSeconds: Int
    let isEnabled: Bool

    private var previewIDs: [String] {
        let selected = Array(selectedProviderIDs.prefix(4))
        return selected.isEmpty ? [
            InfoTileProviderID.currentWorkspace.rawValue,
            InfoTileProviderID.hiddenCount.rawValue,
            InfoTileProviderID.recoveryWarning.rawValue
        ] : selected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("Info Strip Preview", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                ClearGlassStatusValue(
                    text: isEnabled ? "Auto-show" : "Off",
                    style: isEnabled ? .info : .secondary
                )
            }

            HStack(spacing: compactMode ? 8 : 12) {
                ForEach(previewIDs, id: \.self) { providerID in
                    infoTile(providerID)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, compactMode ? 8 : 12)
            .padding(.vertical, compactMode ? 6 : 9)
            .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    timingLabel("Idle", value: "\(idleDelaySeconds)s", systemImage: "timer")
                    timingLabel("Rotate", value: "\(rotationIntervalSeconds)s", systemImage: "arrow.triangle.2.circlepath")
                    timingLabel(compactMode ? "Compact" : "Regular", value: showTileLabels ? "Labels" : "Icons", systemImage: "rectangle.compress.vertical")
                }

                VStack(alignment: .leading, spacing: 5) {
                    timingLabel("Idle", value: "\(idleDelaySeconds)s", systemImage: "timer")
                    timingLabel("Rotate", value: "\(rotationIntervalSeconds)s", systemImage: "arrow.triangle.2.circlepath")
                    timingLabel(compactMode ? "Compact" : "Regular", value: showTileLabels ? "Labels" : "Icons", systemImage: "rectangle.compress.vertical")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.62), lineWidth: 0.5)
        }
        .opacity(isEnabled ? 1 : 0.68)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Info Strip preview")
    }

    private func infoTile(_ providerID: String) -> some View {
        let title = InfoTileProviderID(rawValue: providerID).displayName
        return VStack(spacing: showTileLabels ? 4 : 0) {
            Image(systemName: tileIcon(for: providerID))
                .font(.system(size: compactMode ? 15 : 17, weight: .regular))
                .frame(width: 22, height: 22)

            if showTileLabels {
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .frame(minWidth: showTileLabels ? 58 : 28)
        .foregroundStyle(isEnabled ? .primary : .secondary)
    }

    private func timingLabel(_ title: String, value: String, systemImage: String) -> some View {
        Label("\(title): \(value)", systemImage: systemImage)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
    }

    private func tileIcon(for providerID: String) -> String {
        switch providerID {
        case InfoTileProviderID.currentWorkspace.rawValue:
            "rectangle.3.group"
        case InfoTileProviderID.hiddenCount.rawValue:
            "eye.slash"
        case InfoTileProviderID.newItemCount.rawValue:
            "tray"
        case InfoTileProviderID.recoveryWarning.rawValue:
            "heart.text.square"
        case InfoTileProviderID.staleScanWarning.rawValue:
            "clock.badge.exclamationmark"
        case InfoTileProviderID.clock.rawValue:
            "clock"
        case InfoTileProviderID.battery.rawValue:
            "battery.100"
        default:
            "info.circle"
        }
    }
}
