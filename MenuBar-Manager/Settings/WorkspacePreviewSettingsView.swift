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
    var applyLayout: (@MainActor () async -> WorkspaceLayoutApplyResult?)? = nil
    var isLayoutApplyEnabled: () -> Bool = { false }
    @State private var functionBarDetailsExpanded = false
    @State private var infoStripDetailsExpanded = false
    @State private var setBuilderOptionsExpanded = false

    @State private var workspacePreparedRevision = 0
    @State private var isApplyingLayout = false
    @State private var lastLayoutOutcome: String?

    private var workspaceState: WorkspacePreviewPreparedState {
        _ = workspacePreparedRevision
        return makeWorkspacePreparedState()
    }

    var body: some View {
        workspacePage(state: workspaceState)
            .onAppear {
                setBuilderViewModel.refresh()
            }
            .onChange(of: settingsStore.workspacesPreviewEnabled) { _, isEnabled in
                if !isEnabled {
                    hideFunctionBar()
                    hideInfoStrip()
                }
            }
            .onChange(of: settingsStore.functionBarPreviewEnabled) { _, isEnabled in
                if !isEnabled {
                    hideFunctionBar()
                }
            }
            .onChange(of: settingsStore.infoStripPreviewEnabled) { _, isEnabled in
                if !isEnabled {
                    hideInfoStrip()
                }
            }
    }

    private func workspacePage(state: WorkspacePreviewPreparedState) -> some View {
        ClearGlassSettingsPage(
            "Workspaces",
            subtitle: "Switch between local Workspace sets and configure app-owned preview surfaces.",
            badges: [.preview, .privacySafe],
            style: .tool,
            sectionAnchors: [
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
            workspacePageContent(state)
        }
    }

    @ViewBuilder
    private func workspacePageContent(_ state: WorkspacePreviewPreparedState) -> some View {
        previewGatesSection
        activeWorkspaceSection(state)
        quickActionsSection
        menuBarLayoutSection
        workspaceListSection(state)
        previewControlsSection
        infoStripPreviewSection
        linkedGroupsSection(state)
        setBuilderSection
        diagnosticsSection(state)
    }

    private func makeWorkspacePreparedState() -> WorkspacePreviewPreparedState {
        let snapshot = switchingService.currentSnapshot()
        let liveSnapshots = liveStatus?.scannedMenuBarItems ?? []
        let groups = setBuilderViewModel.groups
        let usageIndex = WorkspaceUsageIndex()
        let usage = usageIndex.rebuild(
            snapshot: snapshot,
            groups: groups,
            discoveredSnapshots: liveSnapshots
        )
        let active = switchingService.activeWorkspace()
        let activeLinkedGroupRows = active.functionItems.compactMap { item -> WorkspaceLinkedGroupRow? in
            guard case .group(let reference) = item.kind,
                  reference.referenceMode == .linked else {
                return nil
            }
            return WorkspaceLinkedGroupRow(id: item.id, reference: reference)
        }
        let integration = WorkspaceIntegrationDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            usageSnapshot: usage,
            newItemInbox: NewMenuBarItemInbox.empty,
            functionBarFallbackEnabled: settingsStore.functionBarPreviewEnabled,
            physicalProfileBindingCount: snapshot.workspaces.filter { $0.physicalProfileBinding != nil }.count,
            lastCrowdedRescueWorkspaceDecision: nil
        )
        let availableHashes = availableMenuBarItemHashesForDiagnostics
        let effectiveKnownGroupIDs = knownGroupIDs.isEmpty ? Set(groups.map(\.id)) : knownGroupIDs
        let effectiveProtectedGroupIDs = protectedGroupIDs.isEmpty ? Set(groups.filter(\.isProtected).map(\.id)) : protectedGroupIDs
        let workspaceDiagnostics = WorkspaceDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            snapshot: snapshot,
            validationIssues: [],
            lastLoadStatus: .loaded,
            knownGroupIDs: effectiveKnownGroupIDs,
            protectedGroupIDs: effectiveProtectedGroupIDs,
            knownProfileIDs: knownProfileIDs,
            availableMenuBarItemHashes: availableHashes
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

        return WorkspacePreviewPreparedState(
            snapshot: snapshot,
            integrationDiagnostics: integration,
            workspaceDiagnostics: workspaceDiagnostics,
            functionDiagnostics: functionDiagnostics,
            setBuilderDiagnostics: setBuilderDiagnostics,
            infoDiagnostics: infoDiagnostics,
            availableWorkspaces: snapshot.workspaces.filter { !$0.isArchived },
            archivedWorkspaceCount: snapshot.workspaces.filter(\.isArchived).count,
            activeWorkspace: active,
            groupsByID: Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) }),
            activeLinkedGroupRows: activeLinkedGroupRows,
            activeLinkedGroupCount: activeLinkedGroupRows.count,
            unassignedItemCount: liveStatus.map { status in
                usageIndex.unassignedItemHashes(from: status.scannedMenuBarItems).count
            } ?? 0,
            usedInActiveWorkspaceCount: usage.usagesByItemHash.values.filter(\.isUsedInActiveWorkspace).count
        )
    }

    private func refreshWorkspacePreparedState() {
        workspacePreparedRevision = workspacePreparedRevision == Int.max ? 0 : workspacePreparedRevision + 1
    }

    private var previewGatesSection: some View {
        ClearGlassSection(
            "Preview Gates",
            subtitle: "Enable only the local preview surfaces you want."
        ) {
            ClearGlassInlineMessage(
                text: "Workspaces configure only MenuBarDeclutter-owned Function Bar, Set Builder, and Info Strip previews. They do not replace or control the macOS system menu bar.",
                systemImage: "lock.shield",
                style: .success
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 220), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                WorkspaceGateCard(
                    title: "Workspaces Preview",
                    subtitle: "Use local Workspace records.",
                    systemImage: "rectangle.3.group",
                    isOn: $settingsStore.workspacesPreviewEnabled
                )

                WorkspaceGateCard(
                    title: "Function Bar",
                    subtitle: "Show the app-owned shortcut strip.",
                    systemImage: "menubar.rectangle",
                    isOn: $settingsStore.functionBarPreviewEnabled,
                    disabled: !settingsStore.workspacesPreviewEnabled
                )

                WorkspaceGateCard(
                    title: "Set Builder",
                    subtitle: "Edit local Workspace sets.",
                    systemImage: "slider.horizontal.3",
                    isOn: $settingsStore.setBuilderPreviewEnabled,
                    disabled: !settingsStore.workspacesPreviewEnabled
                )

                WorkspaceGateCard(
                    title: "Info Strip",
                    subtitle: "Show selected tiles when idle.",
                    systemImage: "info.circle",
                    isOn: $settingsStore.infoStripPreviewEnabled,
                    disabled: !settingsStore.workspacesPreviewEnabled
                )
            }
        }
    }

    private func activeWorkspaceSection(_ state: WorkspacePreviewPreparedState) -> some View {
        ClearGlassSection(
            "Active Workspace",
            subtitle: "\(state.availableWorkspaces.count) available, \(state.archivedWorkspaceCount) archived."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        activeWorkspaceIdentity(state.activeWorkspace)

                        Spacer(minLength: 12)

                        switchDefaultWorkspaceButton(state.snapshot)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        activeWorkspaceIdentity(state.activeWorkspace)
                        switchDefaultWorkspaceButton(state.snapshot)
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                    diagnosticsRow("Function Bar", functionBarLandingStatus)
                    diagnosticsRow("Info Strip", infoStripLandingStatus)
                    diagnosticsRow("Workspace Items", "\(state.activeWorkspace.functionItems.count)")
                    diagnosticsRow("Linked Groups", "\(state.activeLinkedGroupCount)")
                    diagnosticsRow("New Items", "\(liveStatus?.newMenuBarItemReviewCount ?? 0)")
                    diagnosticsRow("Needs Assignment", "\(state.unassignedItemCount)")
                }
            }
        }
    }

    private var layoutPlanSummary: WorkspaceLayoutPlanSummary {
        _ = workspacePreparedRevision
        let plan = WorkspaceLayoutSwitcher().plan(
            for: switchingService.activeWorkspace(),
            currentScan: liveStatus?.scannedMenuBarItems ?? []
        )
        return WorkspaceLayoutPlanSummary(plan)
    }

    private var menuBarLayoutSection: some View {
        ClearGlassSection(
            "Menu Bar Layout",
            subtitle: "Capture this Workspace's real menu bar layout, then apply it on demand. Requires Assisted Move (Optional Pro + Accessibility)."
        ) {
            ClearGlassActionStrip(
                "Real Layout",
                subtitle: layoutPlanSummary.sentence,
                systemImage: "rectangle.righthalf.inset.filled.arrow.right",
                statusText: isLayoutApplyEnabled() ? "Assisted Move On" : "Assisted Move Off",
                statusStyle: isLayoutApplyEnabled() ? .success : .secondary
            ) {
                Button("Save Current Layout", systemImage: "square.and.arrow.down") {
                    captureCurrentLayout()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("workspaces.layout.save")

                Button("Apply Layout Now", systemImage: "wand.and.stars") {
                    applyLayoutNow()
                }
                .accessibilityIdentifier("workspaces.layout.apply")
                .disabled(applyLayout == nil || !isLayoutApplyEnabled() || layoutPlanSummary.isEmpty || isApplyingLayout)
            }

            if let lastLayoutOutcome {
                Text(lastLayoutOutcome)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func captureCurrentLayout() {
        var workspace = switchingService.activeWorkspace()
        workspace.itemTargets = WorkspaceItemTarget.capture(from: liveStatus?.scannedMenuBarItems ?? [])
        _ = switchingService.updateWorkspace(workspace)
        lastLayoutOutcome = "Saved \(workspace.itemTargets.count) item target(s) for this Workspace."
        refreshAfterWorkspaceMutation()
    }

    private func applyLayoutNow() {
        guard let applyLayout else { return }
        isApplyingLayout = true
        Task { @MainActor in
            let result = await applyLayout()
            lastLayoutOutcome = result.map { Self.layoutOutcomeText($0) }
                ?? "Not applied — enable Assisted Move and save a layout first."
            isApplyingLayout = false
            refreshAfterWorkspaceMutation()
        }
    }

    private static func layoutOutcomeText(_ result: WorkspaceLayoutApplyResult) -> String {
        let outcome = result.outcome
        let skipped = result.skippedUnmovableKeys.count
        var text: String
        if outcome.isNoOp && skipped == 0 {
            text = "Bar already matches — nothing to move."
        } else if outcome.failedCount == 0 {
            text = "Applied \(outcome.appliedCount) move\(outcome.appliedCount == 1 ? "" : "s")."
        } else if outcome.appliedCount == 0 {
            text = "Couldn't move \(outcome.failedCount) item\(outcome.failedCount == 1 ? "" : "s") — they may not support moving."
        } else {
            text = "Applied \(outcome.appliedCount), couldn't move \(outcome.failedCount)."
        }
        if skipped > 0 {
            text += " (\(skipped) skipped as unmovable)"
        }
        return text
    }

    private var quickActionsSection: some View {
        ClearGlassSection(
            "Quick Actions",
            subtitle: "Local app-owned shortcuts for the active Workspace."
        ) {
            ClearGlassActionStrip(
                "Workspace Actions",
                subtitle: "Open app-owned preview surfaces or create Workspace records without touching the system menu bar.",
                systemImage: "bolt",
                statusText: settingsStore.workspacesPreviewEnabled ? "Ready" : "Preview Off",
                statusStyle: settingsStore.workspacesPreviewEnabled ? .success : .secondary
            ) {
                Button("Show Function Bar", systemImage: "menubar.rectangle") {
                    showFunctionBar()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("workspaces.quickAction.showFunctionBar")
                .disabled(functionBarControlsDisabled)

                Button("Show Info Strip", systemImage: "info.circle") {
                    showInfoStrip()
                }
                .accessibilityIdentifier("workspaces.quickAction.showInfoStrip")
                .disabled(infoStripControlsDisabled || !activeInfoStripConfig.isEnabled)

                Menu("More", systemImage: "ellipsis.circle") {
                    Button("Open Set Builder", systemImage: "slider.horizontal.3") {
                        setBuilderViewModel.selectWorkspace(id: switchingService.activeWorkspace().id)
                    }
                    .disabled(!settingsStore.workspacesPreviewEnabled || !settingsStore.setBuilderPreviewEnabled)

                    Button("Review New Items", systemImage: "tray.full") {
                        onOpenFindRescue?()
                    }

                    Divider()

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
            }

            if let result = setBuilderViewModel.lastCommitResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func workspaceListSection(_ state: WorkspacePreviewPreparedState) -> some View {
        ClearGlassSection(
            "Workspace List",
            subtitle: "Switch local Workspace records without moving real menu bar icons."
        ) {
            VStack(spacing: 0) {
                ForEach(Array(state.availableWorkspaces.enumerated()), id: \.element.id) { offset, workspace in
                    HStack(spacing: 10) {
                        Image(systemName: workspace.iconName)
                            .frame(width: 20)
                            .foregroundStyle(workspace.id == state.activeWorkspace.id ? Color.accentColor : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(WorkspaceDiagnosticsRedactor.displayName(for: workspace))
                                .font(.callout)
                            Text("\(workspace.functionItems.count) item\(workspace.functionItems.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if workspace.id == state.activeWorkspace.id {
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

                    if offset < state.availableWorkspaces.count - 1 {
                        ClearGlassDivider()
                    }
                }
            }
        }
    }

    private func linkedGroupsSection(_ state: WorkspacePreviewPreparedState) -> some View {
        ClearGlassSection(
            "Linked Groups",
            subtitle: "Reusable Groups can appear in multiple Workspaces; detached copies stay one-off."
        ) {
            if state.activeLinkedGroupRows.isEmpty {
                SettingsUnavailableGate(
                    .emptyData,
                    title: "No Linked Groups",
                    message: "Linked Groups will appear here when this Workspace reuses a saved Group.",
                    systemImage: "person.2",
                    minHeight: 140,
                    nextSteps: ["Open Set Builder.", "Insert a saved Group as a linked reference."]
                )
                .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(state.activeLinkedGroupRows.enumerated()), id: \.element.id) { offset, row in
                        HStack {
                            Label(state.displayName(forLinkedGroupID: row.reference.groupID), systemImage: "person.2")
                            Spacer()
                            Text("Linked")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)

                        if offset < state.activeLinkedGroupRows.count - 1 {
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
            subtitle: "Panels are app-owned previews. They do not inspect pixels, capture the screen, replace the macOS menu bar, or move menu bar items.",
            anchorID: "Function Bar"
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

            ClearGlassActionStrip(
                "Preview Actions",
                subtitle: "Show or hide the app-owned Function Bar and Info Strip previews.",
                systemImage: "menubar.rectangle",
                statusText: settingsStore.functionBarPreviewEnabled ? "Function Bar On" : "Function Bar Off",
                statusStyle: settingsStore.functionBarPreviewEnabled ? .success : .secondary
            ) {
                Button("Show Function Bar", systemImage: "menubar.rectangle") {
                    showFunctionBar()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("workspaces.previewControls.showFunctionBar")
                .disabled(!settingsStore.workspacesPreviewEnabled || !settingsStore.functionBarPreviewEnabled)

                Button("Show Info Strip", systemImage: "info.circle") {
                    showInfoStrip()
                }
                .accessibilityIdentifier("workspaces.previewControls.showInfoStrip")
                .disabled(!settingsStore.workspacesPreviewEnabled || !settingsStore.infoStripPreviewEnabled)

                Menu("More", systemImage: "ellipsis.circle") {
                    Button("Hide Function Bar", systemImage: "xmark.circle") {
                        hideFunctionBar()
                    }

                    Button("Open Recovery", systemImage: "cross.case") {
                        onOpenRecovery?()
                    }
                }
            }

            WorkspaceSettingsDisclosure(
                title: "Function Bar Details",
                systemImage: "slider.horizontal.3",
                isExpanded: $functionBarDetailsExpanded
            ) {
                workspaceToggleRow(
                    "Use Function Bar on status-item click",
                    subtitle: "Route the primary status-item click to the Function Bar.",
                    systemImage: "cursorarrow.click",
                    isOn: $settingsStore.functionBarPrimaryClickEnabled,
                    disabled: functionBarControlsDisabled
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "rectangle.portrait.topthird.inset.filled",
                    title: "Function Bar placement",
                    subtitle: "Choose where the app-owned preview strip appears."
                ) {
                    Picker("Function Bar placement", selection: $settingsStore.functionBarPlacementPreference) {
                        ForEach(FunctionBarPlacementPreference.allCases) { preference in
                            Text(preference.displayName).tag(preference.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .disabled(functionBarControlsDisabled)

                ClearGlassDivider()

                workspaceToggleRow(
                    "Show Set Switcher",
                    subtitle: "Keep Workspace switching visible in the Function Bar.",
                    systemImage: "rectangle.3.group",
                    isOn: $settingsStore.functionBarShowSetSwitcher,
                    disabled: functionBarControlsDisabled
                )

                ClearGlassDivider()

                workspaceToggleRow(
                    "Show Function Bar Labels",
                    subtitle: "Display text labels next to Function Bar icons.",
                    systemImage: "textformat",
                    isOn: $settingsStore.functionBarShowLabels,
                    disabled: functionBarControlsDisabled
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "rectangle.compress.vertical",
                    title: "Function Bar density",
                    subtitle: "Adjust how tightly Function Bar controls are packed."
                ) {
                    Picker("Function Bar Density", selection: $settingsStore.functionBarDensity) {
                        ForEach(FunctionBarDensity.allCases) { density in
                            Text(density.displayName).tag(density.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .disabled(functionBarControlsDisabled)

                ClearGlassDivider()

                workspaceToggleRow(
                    "Close on outside click",
                    subtitle: "Dismiss the Function Bar when focus moves elsewhere.",
                    systemImage: "cursorarrow.click.2",
                    isOn: $settingsStore.functionBarCloseOnOutsideClick,
                    disabled: functionBarControlsDisabled
                )

                ClearGlassDivider()

                workspaceToggleRow(
                    "Enable keyboard navigation",
                    subtitle: "Allow keyboard movement through Function Bar items.",
                    systemImage: "keyboard",
                    isOn: $settingsStore.functionBarKeyboardNavigationEnabled,
                    disabled: functionBarControlsDisabled
                )

                ClearGlassDivider()

                workspaceToggleRow(
                    "Hover from Info Strip to Function Bar",
                    subtitle: "Let pointer hover hand off from the idle strip to the Function Bar.",
                    systemImage: "hand.point.up.left",
                    isOn: $settingsStore.infoStripHoverToFunctionBarEnabled,
                    disabled: functionBarControlsDisabled
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "lifepreserver",
                    title: "Crowded rescue fallback",
                    subtitle: "Choose what Workspaces suggest when inline reveal is crowded."
                ) {
                    Picker("Crowded rescue fallback", selection: $settingsStore.crowdedRescueWorkspaceFallbackPreference) {
                        ForEach(CrowdedRescueWorkspaceFallbackPreference.allCases) { preference in
                            Text(preference.displayName).tag(preference.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .disabled(!settingsStore.workspacesPreviewEnabled)
            }
        }
    }

    private var infoStripPreviewSection: some View {
        let active = switchingService.activeWorkspace()
        let config = activeInfoStripConfig
        let selectedIDs = Set(config.selectedTileProviderIDs)

        return ClearGlassSection(
            "Info Strip Preview",
            subtitle: "Configure the active Workspace's app-owned idle strip.",
            anchorID: "Info Strip"
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

            WorkspaceSettingsDisclosure(
                title: "Info Strip Details",
                systemImage: "slider.horizontal.3",
                isExpanded: $infoStripDetailsExpanded
            ) {
                workspaceToggleRow(
                    "Auto-show Info Strip",
                    subtitle: "Show the Info Strip automatically for enabled Workspaces.",
                    systemImage: "sparkles",
                    isOn: $settingsStore.infoStripAutoShowEnabled,
                    disabled: infoStripControlsDisabled
                )

                ClearGlassDivider()

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

                ClearGlassDivider()

                workspaceToggleRow(
                    "Show tile labels",
                    subtitle: "Display labels inside selected Info Strip tiles.",
                    systemImage: "textformat",
                    isOn: Binding(
                        get: { activeInfoStripConfig.showTileLabels },
                        set: { setActiveInfoStripShowTileLabels($0) }
                    ),
                    disabled: infoStripControlsDisabled
                )

                ClearGlassDivider()

                workspaceToggleRow(
                    "Show preview badge",
                    subtitle: "Display a small preview indicator on the Info Strip.",
                    systemImage: "tag",
                    isOn: $settingsStore.infoStripShowPreviewBadge,
                    disabled: !settingsStore.workspacesPreviewEnabled || !settingsStore.infoStripPreviewEnabled
                )

                ClearGlassDivider()

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
            }

            ClearGlassButtonGrid(minimumItemWidth: 170) {
                Button("Open Info Strip Preview", systemImage: "info.circle") {
                    showInfoStrip()
                }
                .accessibilityIdentifier("workspaces.infoStrip.openPreview")
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

            WorkspaceSettingsDisclosure(
                title: "Builder Options",
                systemImage: "slider.horizontal.3",
                isExpanded: $setBuilderOptionsExpanded
            ) {
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
                }
                .disabled(!settingsStore.workspacesPreviewEnabled)
            }

            if settingsStore.setBuilderPreviewEnabled {
                SetBuilderView(viewModel: setBuilderViewModel)
            } else {
                SettingsUnavailableGate(
                    .previewDisabled,
                    title: "Set Builder Disabled",
                    message: "Turn on Set Builder to edit local Workspace records.",
                    systemImage: "rectangle.3.group",
                    minHeight: 220,
                    nextSteps: ["Enable Workspaces Preview.", "Turn on the Set Builder gate above."]
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            }
        }
    }

    private func diagnosticsSection(_ state: WorkspacePreviewPreparedState) -> some View {
        ClearGlassSection(
            "Diagnostics",
            subtitle: "Deeper local counts for troubleshooting. Protected names stay redacted."
        ) {
            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                diagnosticsRow("Store", state.workspaceDiagnostics.lastLoadStatus.rawValue)
                diagnosticsRow("Workspace Records", "\(state.workspaceDiagnostics.workspaceCount)")
                diagnosticsRow("Active", state.workspaceDiagnostics.activeWorkspacePresent ? "Present" : "Missing")
                diagnosticsRow("Function Bar", state.functionDiagnostics.displayState)
                diagnosticsRow("Function Items", "\(state.functionDiagnostics.visibleItemCount)")
                diagnosticsRow("Set Builder", state.setBuilderDiagnostics.previewEnabled ? "Enabled" : "Disabled")
                diagnosticsRow("Workspace Items", "\(state.setBuilderDiagnostics.totalWorkspaceItemCount)")
                diagnosticsRow("Item References", "\(state.integrationDiagnostics.indexedItemReferenceCount)")
                diagnosticsRow("Unassigned References", "\(state.integrationDiagnostics.unassignedItemReferenceCount)")
                diagnosticsRow("Group References", "\(state.workspaceDiagnostics.groupReferenceCount)")
                diagnosticsRow("Linked Groups", "\(state.setBuilderDiagnostics.linkedGroupReferenceCount)")
                diagnosticsRow("Protected Groups", "\(state.workspaceDiagnostics.protectedGroupReferenceCount)")
                diagnosticsRow("Missing Group References", "\(state.setBuilderDiagnostics.missingGroupReferenceCount)")
                diagnosticsRow("Missing Detached Sources", "\(state.setBuilderDiagnostics.detachedSourceGroupMissingCount)")
                diagnosticsRow("Proxy Items", "\(state.setBuilderDiagnostics.menuBarProxyReferenceCount)")
                diagnosticsRow("Unresolved Proxies", "\(state.setBuilderDiagnostics.unresolvedMenuBarProxyReferenceCount)")
                diagnosticsRow("Physical Profile Bindings", "\(state.integrationDiagnostics.physicalProfileBindingCount)")
                diagnosticsRow("Command Automation", "Reserved")
                diagnosticsRow("Active Item Matches", "\(state.usedInActiveWorkspaceCount)")
                diagnosticsRow("Info Strip", state.infoDiagnostics.displayState)
                diagnosticsRow("Current Tile", state.infoDiagnostics.currentTileProviderID ?? "None")
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
                refreshWorkspacePanelsAfterSettingsChange()
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
        refreshWorkspacePreparedState()
    }

    private func hideFunctionBar() {
        if let routeCommand {
            _ = routeCommand(.init(action: .hideFunctionBar, target: .functionBar, source: .settings))
        } else {
            functionBarController.hide(source: .settings)
        }
        refreshWorkspacePreparedState()
    }

    private func showInfoStrip() {
        if let routeCommand {
            _ = routeCommand(.init(action: .showInfoStrip, target: .infoStrip, source: .settings))
        } else {
            infoStripController.show()
        }
        refreshWorkspacePreparedState()
    }

    private func hideInfoStrip() {
        if let routeCommand {
            _ = routeCommand(.init(action: .hideInfoStrip, target: .infoStrip, source: .settings))
        } else {
            infoStripController.hide()
        }
        refreshWorkspacePreparedState()
    }

    private var functionBarControlsDisabled: Bool {
        !settingsStore.workspacesPreviewEnabled || !settingsStore.functionBarPreviewEnabled
    }

    private var infoStripControlsDisabled: Bool {
        !settingsStore.workspacesPreviewEnabled || !settingsStore.infoStripPreviewEnabled
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

    private func refreshAfterWorkspaceMutation() {
        setBuilderViewModel.refresh()
        refreshWorkspacePanelsAfterSettingsChange()
    }

    private func refreshWorkspacePanelsAfterSettingsChange() {
        functionBarController.refresh(reason: .workspaceChanged)
        infoStripController.refresh()
        refreshWorkspacePreparedState()
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
        refreshWorkspacePreparedState()
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

private struct WorkspacePreviewPreparedState: Equatable {
    let snapshot: WorkspaceStoreSnapshot
    let integrationDiagnostics: WorkspaceIntegrationDiagnosticsSnapshot
    let workspaceDiagnostics: WorkspaceDiagnosticsSnapshot
    let functionDiagnostics: FunctionBarDiagnosticsSnapshot
    let setBuilderDiagnostics: SetBuilderDiagnosticsSnapshot
    let infoDiagnostics: InfoStripDiagnosticsSnapshot
    let availableWorkspaces: [MenuBarWorkspace]
    let archivedWorkspaceCount: Int
    let activeWorkspace: MenuBarWorkspace
    let groupsByID: [UUID: IconGroup]
    let activeLinkedGroupRows: [WorkspaceLinkedGroupRow]
    let activeLinkedGroupCount: Int
    let unassignedItemCount: Int
    let usedInActiveWorkspaceCount: Int

    func displayName(forLinkedGroupID groupID: UUID) -> String {
        guard let group = groupsByID[groupID] else {
            return "Missing Group"
        }
        return group.isProtected ? "Protected Group" : group.name
    }
}

private struct WorkspaceLinkedGroupRow: Identifiable, Equatable {
    let id: UUID
    let reference: WorkspaceGroupReference
}

private struct WorkspaceGateCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool
    var disabled = false

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(iconTint)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 6) {
                ClearGlassStatusValue(text: statusText, style: statusStyle)
                    .font(.caption)

                Toggle(title, isOn: $isOn)
                    .labelsHidden()
                    .accessibilityLabel(Text(title))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.74 : 1)
        .accessibilityElement(children: .combine)
    }

    private var iconTint: Color {
        isOn ? .accentColor : .secondary
    }

    private var statusText: String {
        isOn ? "On" : disabled ? "Waiting" : "Off"
    }

    private var statusStyle: ClearGlassStatusStyle {
        isOn ? .success : .secondary
    }
}

private struct WorkspaceSettingsDisclosure<Content: View>: View {
    let title: String
    let systemImage: String
    @Binding var isExpanded: Bool
    private let content: Content

    init(
        title: String,
        systemImage: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        _isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 0) {
                content
            }
            .padding(.top, 6)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.58), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
        }
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
        .opacity(functionBarEnabled ? 1 : 0.74)
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
        .opacity(isEnabled ? 1 : 0.76)
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
