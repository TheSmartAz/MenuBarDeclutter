import SwiftUI

struct ArrangeSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var liveStatus: LiveDiagnosticsStatus?
    var permissionService: AccessibilityPermissionService?
    var newItemInboxStore: NewMenuBarItemInboxStore? = nil
    var itemMemoryStore: MenuBarItemMemoryStore? = nil
    var placementPreferenceStore: PlacementItemPreferenceStore? = nil
    var onExpand: (() -> Void)? = nil
    var onCollapse: (() -> Void)? = nil
    var onRevealAll: (() -> Void)? = nil
    var onResetLayout: (() -> Void)? = nil
    var onShowDragHint: (() -> Void)? = nil
    var onOpenRecovery: (() -> Void)? = nil
    var onOpenAdvanced: (() -> Void)? = nil
    var onPlannerCommand: ((MenuBarCommandAction, String) -> MenuBarCommandResult)? = nil
    var onExecuteAssistedMove: ((MenuBarItemSnapshot, IconMoveCommand) async -> IconMoveResult)? = nil
    @State private var localPlacementPreferences: [String: PlacementItemPreference] = [:]

    var body: some View {
        ClearGlassSettingsPage(
            "Arrange",
            subtitle: "Place the control item, separators, and hidden items safely with normal macOS Command-drag.",
            badges: [.stable, .basicMode, .privacySafe]
        ) {
            ArrangeDiagramView(alwaysHiddenEnabled: settingsStore.alwaysHiddenEnabled)

            manualGuideSection
            placementTestSection
            placementPlannerSection
            assistedMoveSection
            recoverySection
        }
    }

    private var manualGuideSection: some View {
        ClearGlassSection(
            "Guided Manual Arrange",
            subtitle: "Stable path. No Optional Pro, Accessibility, Screen Recording, automation, or simulated dragging."
        ) {
            ForEach(ArrangeStep.guidedManualSteps) { step in
                ArrangeStepRow(step: step)
                if step.id != ArrangeStep.guidedManualSteps.last?.id {
                    ClearGlassDivider()
                }
            }
        }
    }

    private var placementTestSection: some View {
        ClearGlassSection(
            "Placement Test",
            subtitle: "Use these Basic Mode actions after Command-dragging items into place."
        ) {
            let readiness = basicModeReadiness

            ClearGlassInlineMessage(
                text: readiness.message,
                systemImage: readiness.systemImage,
                style: readiness.clearGlassStyle
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button("Expand", systemImage: "eye") {
                        onExpand?()
                    }
                    .accessibilityIdentifier("arrange.action.expand")

                    Button("Collapse", systemImage: "eye.slash") {
                        onCollapse?()
                    }
                    .accessibilityIdentifier("arrange.action.collapse")

                    Button("Reveal All", systemImage: "rectangle.expand.vertical") {
                        onRevealAll?()
                    }
                    .accessibilityIdentifier("arrange.action.revealAll")
                }

                HStack(spacing: 10) {
                    Button("Reset Layout", systemImage: "arrow.counterclockwise") {
                        onResetLayout?()
                    }
                    .accessibilityIdentifier("arrange.action.resetLayout")

                    Button("Show Drag Hint", systemImage: "hand.point.up.left") {
                        onShowDragHint?()
                    }
                    .accessibilityIdentifier("arrange.action.showDragHint")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .frame(maxWidth: .infinity, alignment: .leading)

            if readiness.status != .ready {
                ClearGlassInlineMessage(
                    text: "These actions still use only MenuBarDeclutter's own status items and public macOS behavior. They do not request Pro permissions.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }
        }
    }

    private var placementPlannerSection: some View {
        let plan = PlacementPlanner().plan(context: plannerContext)

        return ClearGlassSection(
            "Placement Planner",
            subtitle: "Preview. Uses Optional Pro Discovery metadata to suggest manual placement without moving items."
        ) {
            FeatureGateNotice(
                .preview,
                text: plannerStateText(plan.state)
            )

            if plan.items.isEmpty {
                ContentUnavailableView(
                    plannerEmptyTitle(plan.state),
                    systemImage: "sparkles",
                    description: Text(plannerStateText(plan.state))
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                VStack(spacing: 0) {
                    let displayedItems = Array(plan.items.prefix(10))

                    ForEach(displayedItems) { item in
                        PlacementPlanRow(
                            item: item,
                            onSetPreference: { preference in
                                setPreference(preference, for: item.storageKey)
                            },
                            onClearPreference: {
                                clearPreference(for: item.storageKey)
                            },
                            onCommand: onPlannerCommand
                        )

                        if item.id != displayedItems.last?.id {
                            ClearGlassDivider()
                        }
                    }

                    if plan.items.count > displayedItems.count {
                        ClearGlassDivider()
                        ClearGlassInlineMessage(
                            text: "\(plan.items.count - displayedItems.count) more item(s) are available in Menu Bar Item Inspector.",
                            systemImage: "list.bullet.rectangle",
                            style: .info
                        )
                    }
                }
            }
        }
    }

    private var assistedMoveSection: some View {
        ClearGlassSection(
            "Assisted Move",
            subtitle: "Labs. Single item only, with dry-run and confirmation before any attempt."
        ) {
            AssistedMoveFlowView(
                settingsStore: settingsStore,
                liveStatus: liveStatus,
                permissionService: permissionService,
                onOpenAdvanced: onOpenAdvanced,
                onRevealAll: onRevealAll,
                onResetLayout: onResetLayout,
                onOpenRecovery: onOpenRecovery,
                onRouteCommand: onPlannerCommand,
                onExecuteMove: onExecuteAssistedMove
            )
        }
    }

    private var recoverySection: some View {
        ClearGlassSection(
            "I can't find the control item",
            subtitle: "Recovery stays available even when optional Pro features are off."
        ) {
            ClearGlassInlineMessage(
                text: "Reveal all, reset layout, then use Recovery for Safe Mode instructions and diagnostics export if the menu bar still looks wrong.",
                systemImage: "lifepreserver",
                style: .info
            )

            Button("Open Recovery", systemImage: "cross.case") {
                onOpenRecovery?()
            }
            .buttonStyle(.bordered)
        }
    }

    private var plannerContext: PlacementPlannerContext {
        PlacementPlannerContext(
            proModeEnabled: settingsStore.proModeEnabled,
            accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
            accessibilityPermissionGranted: permissionService?.status == .granted,
            safeModeActive: liveStatus?.safeModeActive == true,
            snapshots: liveStatus?.scannedMenuBarItems ?? [],
            lastScanDate: liveStatus?.lastMenuBarScanTime,
            alwaysHiddenEnabled: settingsStore.alwaysHiddenEnabled,
            newItemIDs: Set(newItemInboxStore?.inbox.items.map(\.id) ?? []),
            favoriteItemIDs: itemMemoryStore?.favoriteItemStorageKeys ?? [],
            itemPreferences: currentPlacementPreferences
        )
    }

    private var currentPlacementPreferences: [String: PlacementItemPreference] {
        placementPreferenceStore?.preferences ?? localPlacementPreferences
    }

    private var basicModeReadiness: BasicModeReadiness {
        BasicModeReadiness.evaluate(
            visibilityState: liveStatus?.visibilityState,
            primarySeparatorLength: liveStatus?.primarySeparatorLength,
            alwaysHiddenEnabled: settingsStore.alwaysHiddenEnabled,
            alwaysHiddenSeparatorInstalled: liveStatus?.alwaysHiddenSeparatorInstalled == true,
            alwaysHiddenSeparatorLength: liveStatus?.alwaysHiddenSeparatorLength
        )
    }

    private func setPreference(_ preference: PlacementItemPreference, for storageKey: String) {
        if let placementPreferenceStore {
            placementPreferenceStore.setPreference(preference, for: storageKey)
        } else {
            localPlacementPreferences[storageKey] = preference
        }
    }

    private func clearPreference(for storageKey: String) {
        if let placementPreferenceStore {
            placementPreferenceStore.clearPreference(for: storageKey)
        } else {
            localPlacementPreferences[storageKey] = nil
        }
    }

    private func plannerStateText(_ state: PlacementPlan.State) -> String {
        switch state {
        case .ready:
            "Planner suggestions are based on the latest local Accessibility scan and produce manual instructions only."
        case .proModeOff:
            "Enable Optional Pro before using Placement Planner. Guided Manual Arrange does not need Optional Pro."
        case .accessibilityDiscoveryOff:
            "Enable Accessibility Discovery to read item metadata locally."
        case .accessibilityPermissionMissing:
            "Grant Accessibility permission manually before Planner can read item metadata."
        case .safeMode:
            "Safe Mode suppresses Planner scans and keeps recovery first."
        case .noScan:
            "Run an Optional Pro Discovery scan before Planner can suggest placements."
        case .staleScan:
            "Refresh Optional Pro Discovery before following any placement suggestions."
        }
    }

    private func plannerEmptyTitle(_ state: PlacementPlan.State) -> String {
        switch state {
        case .ready, .staleScan:
            "No Discovered Items"
        default:
            "Planner Unavailable"
        }
    }
}

private extension BasicModeReadiness {
    var clearGlassStyle: ClearGlassStatusStyle {
        switch tone {
        case .ready:
            .success
        case .info:
            .info
        case .warning:
            .warning
        }
    }
}

private struct ArrangeStepRow: View {
    let step: ArrangeStep

    var body: some View {
        ClearGlassControlRow(
            systemImage: step.systemImage,
            title: step.title,
            subtitle: step.detail,
            iconTint: step.isOptional ? .secondary : .blue
        ) {
            ClearGlassBadge(style: .stable)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("arrange.step.\(step.id)")
    }
}

private struct PlacementPlanRow: View {
    let item: PlacementPlanItem
    var onSetPreference: (PlacementItemPreference) -> Void
    var onClearPreference: () -> Void
    var onCommand: ((MenuBarCommandAction, String) -> MenuBarCommandResult)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: item.recommendation == .likelySystemItem ? "exclamationmark.triangle" : "sparkles")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(item.recommendation == .likelySystemItem ? .orange : .blue)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.displayTitle)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if item.isNewItem {
                            ClearGlassBadge(style: .preview)
                        }

                        if item.isFavorite {
                            Label("Favorite", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                                .labelStyle(.iconOnly)
                                .help("Favorite")
                        }
                    }

                    Text(item.displaySubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(item.reason) \(item.manualInstruction)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 6) {
                    ClearGlassStatusValue(
                        text: item.currentZone.displayName,
                        style: item.currentZone == .visible ? .success : .secondary
                    )

                    if let recommendedZone = item.recommendedZone {
                        ClearGlassStatusValue(
                            text: "Suggest \(recommendedZone.displayName)",
                            style: .info
                        )
                    }

                    if let preference = item.preference {
                        ClearGlassStatusValue(
                            text: preference.title,
                            style: .success
                        )
                    }
                }
                .fixedSize()
            }

            HStack(spacing: 8) {
                plannerActionButton(.highlight, title: "Highlight", systemImage: "scope")
                plannerActionButton(.showInSecondBar, title: "Second Bar", systemImage: "menubar.rectangle")
                plannerActionButton(.openOwningApp, title: "Open App", systemImage: "app")

                Menu("Preference", systemImage: "checklist") {
                    ForEach(PlacementItemPreference.allCases) { preference in
                        Button(preference.title, systemImage: preference.systemImage) {
                            onSetPreference(preference)
                        }
                    }

                    if item.preference != nil {
                        Divider()
                        Button("Clear Preference", systemImage: "xmark.circle") {
                            onClearPreference()
                        }
                    }
                }

                Menu("More", systemImage: "ellipsis.circle") {
                    plannerActionMenuButton(.createGroup, title: "Create Group", systemImage: "tag")
                    plannerActionMenuButton(.dryRunAssistedMove, title: "Dry Run Assisted Move", systemImage: "wand.and.stars")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func plannerActionButton(
        _ hint: PlacementPlanActionHint,
        title: String,
        systemImage: String
    ) -> some View {
        Button(title, systemImage: systemImage) {
            route(hint)
        }
        .disabled(!item.actionHints.contains(hint))
    }

    @ViewBuilder
    private func plannerActionMenuButton(
        _ hint: PlacementPlanActionHint,
        title: String,
        systemImage: String
    ) -> some View {
        Button(title, systemImage: systemImage) {
            route(hint)
        }
        .disabled(!item.actionHints.contains(hint))
    }

    private func route(_ hint: PlacementPlanActionHint) {
        guard let action = commandAction(for: hint) else { return }
        _ = onCommand?(action, item.id)
    }

    private func commandAction(for hint: PlacementPlanActionHint) -> MenuBarCommandAction? {
        switch hint {
        case .highlight:
            .highlightItem
        case .showInSecondBar:
            .showItemInSecondBar
        case .openOwningApp:
            .openOwningApp
        case .createGroup:
            .createGroupFromItem
        case .dryRunAssistedMove:
            .dryRunMoveItem
        }
    }
}

private struct ArrangeDiagramView: View {
    let alwaysHiddenEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                menuToken("Hidden", systemImage: "eye.slash", style: .info)
                menuToken("Separator", systemImage: "parallelpipe", style: .warning)
                menuToken("Visible", systemImage: "eye", style: .success)
                menuToken("Control", systemImage: "menubar.rectangle", style: .secondary)
            }

            if alwaysHiddenEnabled {
                HStack(spacing: 8) {
                    menuToken("Always Hidden", systemImage: "lock", style: .warning)
                    menuToken("Separator", systemImage: "parallelpipe", style: .warning)
                    menuToken("Hidden", systemImage: "eye.slash", style: .info)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Menu bar layout diagram")
        .accessibilityIdentifier("arrange.diagram")
    }

    private func menuToken(_ title: String, systemImage: String, style: ClearGlassStatusStyle) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
                .lineLimit(1)
        }
        .font(.callout)
        .foregroundStyle(style.foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(style.background, in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(style.border, lineWidth: 0.5)
        }
    }
}

#Preview {
    ArrangeSettingsView(settingsStore: SettingsStore())
}
