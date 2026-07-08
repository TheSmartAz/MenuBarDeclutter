import SwiftUI

struct FindAndRescueSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var liveStatus: LiveDiagnosticsStatus?
    var findIconAvailability: MenuBarCommandAvailabilitySummary?
    var secondBarAvailability: MenuBarCommandAvailabilitySummary?
    var newItemCount: Int = 0
    var newItemInboxStore: NewMenuBarItemInboxStore? = nil
    var placementPreferenceStore: PlacementItemPreferenceStore? = nil
    var workspaceSwitchingService: WorkspaceSwitchingService? = nil
    var groupStore: IconGroupStore? = nil
    var onOpenFindIcon: (() -> Void)? = nil
    var onOpenSecondBar: (() -> Void)? = nil
    var onOpenSearchSettings: (() -> Void)? = nil
    var onOpenSecondBarSettings: (() -> Void)? = nil
    var onOpenMenuBarItems: (() -> Void)? = nil
    var onOpenGroups: (() -> Void)? = nil
    var onOpenAdvanced: (() -> Void)? = nil
    var onOpenArrange: (() -> Void)? = nil
    var onOpenPrivacy: (() -> Void)? = nil

    var body: some View {
        ClearGlassSettingsPage(
            "Find & Rescue",
            subtitle: "Find hidden icons, review new items, and recover crowded reveal with Optional Pro local discovery.",
            badges: [
                .preview,
                .optionalProDiscovery(
                    proModeEnabled: settingsStore.proModeEnabled,
                    accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
                    accessibilityPermissionStatus: accessibilityPermissionStatus
                )
            ],
            sectionAnchors: [
                ClearGlassPageAnchor("Setup", systemImage: "lock", targetID: "Setup Checklist"),
                ClearGlassPageAnchor("Surfaces", systemImage: "rectangle.on.rectangle", targetID: "Find Icon and Second Bar"),
                ClearGlassPageAnchor("New Items", systemImage: "tray.full"),
                ClearGlassPageAnchor("Collections", systemImage: "tag"),
                ClearGlassPageAnchor("Rescue", systemImage: "lifepreserver", targetID: "Crowded menu rescue"),
                ClearGlassPageAnchor("Actions", systemImage: "link", targetID: "Item Actions")
            ]
        ) {
            FindRescueOverviewStrip(
                scannedCount: liveStatus?.scannedMenuBarItems.count ?? 0,
                hiddenCount: liveStatus?.menuBarScanHiddenCount ?? 0,
                alwaysHiddenCount: liveStatus?.menuBarScanAlwaysHiddenCount ?? 0,
                newItemCount: visibleNewItemCount
            )

            proRequirementsSection
            primaryWorkflowSection
            newItemsSection
            groupsSection
            crowdedRescueSection
            commandCenterSection
        }
    }

    private var proRequirementsSection: some View {
        ClearGlassSection(
            "Setup Checklist",
            subtitle: "Basic Mode keeps working while each Optional Pro step is waiting."
        ) {
            FindRescueSetupStepRow(
                number: 1,
                title: "Enable Optional Pro",
                detail: "Unlock optional rescue surfaces and item review.",
                statusText: settingsStore.proModeEnabled ? "On" : "Off",
                state: settingsStore.proModeEnabled ? .complete : .current,
                systemImage: "star",
                actionTitle: settingsStore.proModeEnabled ? nil : "Enable Optional Pro",
                action: settingsStore.proModeEnabled ? nil : { enableProMode() }
            )

            ClearGlassDivider()

            FindRescueSetupStepRow(
                number: 2,
                title: "Enable Accessibility Discovery",
                detail: "Build a local item index. Accurate Icons can add local rendered thumbnails when enabled.",
                statusText: discoverySetupStatusText,
                state: discoveryStepState,
                systemImage: "figure.circle",
                actionTitle: discoveryStepState == .current ? "Enable Discovery" : nil,
                action: discoveryStepState == .current ? { enableAccessibilityDiscovery() } : nil
            )

            ClearGlassDivider()

            FindRescueSetupStepRow(
                number: 3,
                title: "Grant Accessibility Permission",
                detail: "Allow local reading of menu bar labels and frames.",
                statusText: permissionSetupStatusText,
                state: permissionStepState,
                systemImage: "hand.raised",
                actionTitle: permissionStepState == .current ? "Open Privacy" : nil,
                action: permissionStepState == .current ? { openPrivacyForPermission() } : nil
            )

            ClearGlassDivider()

            FindRescueSetupStepRow(
                number: 4,
                title: "Open Find Icon",
                detail: "Search, reveal, highlight, or hand off to Second Bar.",
                statusText: findRescueReady ? "Ready" : "Waiting",
                state: findRescueReady ? .current : .locked,
                systemImage: "magnifyingglass",
                actionTitle: findRescueReady ? "Open Find Icon" : nil,
                action: findRescueReady ? { onOpenFindIcon?() } : nil
            )

            ClearGlassInlineMessage(
                text: findRescueSetupMessage,
                systemImage: findRescueReady ? "checkmark.shield" : "lock.shield",
                style: findRescueReady ? .success : .secondary
            )
        }
    }

    private var primaryWorkflowSection: some View {
        ClearGlassSection("Find Icon and Second Bar", subtitle: "The two main rescue surfaces now live together.") {
            FindRescueFlowPreview(
                findIconAvailable: findIconAvailability?.tone == .success,
                secondBarAvailable: secondBarAvailability?.tone == .success
            )

            ClearGlassDivider()

            FindRescueCard(
                title: "Find Icon",
                status: .preview,
                systemImage: "magnifyingglass",
                summary: "Search discovered menu bar items, reveal a match, highlight it, or open the owning app."
            ) {
                HStack(spacing: 8) {
                    Button("Open Find Icon", systemImage: "magnifyingglass") {
                        onOpenFindIcon?()
                    }
                    .disabled(findIconAvailability?.tone != .success)

                    Button("Settings", systemImage: "gearshape") {
                        onOpenSearchSettings?()
                    }
                }
            }

            ClearGlassDivider()

            FindRescueCard(
                title: "Second Bar",
                status: .preview,
                systemImage: "rectangle.bottomthird.inset.filled",
                summary: "Browse hidden and always-hidden items in a secondary surface when Pro gates are satisfied."
            ) {
                HStack(spacing: 8) {
                    Button("Show Second Bar", systemImage: "menubar.rectangle") {
                        onOpenSecondBar?()
                    }
                    .disabled(secondBarAvailability?.tone != .success)

                    Button("Settings", systemImage: "gearshape") {
                        onOpenSecondBarSettings?()
                    }
                }
            }

            ClearGlassDivider()

            FindRescueCard(
                title: "Menu Bar Item Inspector",
                status: .preview,
                systemImage: "list.bullet.rectangle",
                summary: "Inspect discovered zones and metadata without exposing it in diagnostics by default."
            ) {
                Button("Open Inspector", systemImage: "list.bullet.rectangle") {
                    onOpenMenuBarItems?()
                }
            }
        }
    }

    private var newItemsSection: some View {
        ClearGlassSection("New Items", subtitle: "Preview inbox for newly discovered menu bar items.") {
            NewItemInboxReviewView(
                state: newItemReviewState,
                onDismiss: dismissNewItem,
                onSetPreference: resolveNewItem,
                onReset: resetNewItemInbox,
                onOpenFindIcon: onOpenFindIcon,
                onOpenSecondBar: onOpenSecondBar,
                onOpenArrange: onOpenArrange,
                onOpenGroups: onOpenGroups,
                onOpenInspector: onOpenMenuBarItems,
                onOpenPrivacy: onOpenPrivacy,
                workspaceOptions: workspaceAssignmentOptions,
                groupOptions: groupAssignmentOptions,
                onAssignToCurrentWorkspace: assignNewItemToCurrentWorkspace,
                onAssignToWorkspace: assignNewItemToWorkspace,
                onAssignToGroup: assignNewItemToGroup,
                onCreateGroup: createGroupForNewItem
            )

            if let message = lastNewItemAssignmentMessage {
                ClearGlassInlineMessage(
                    text: message,
                    systemImage: "rectangle.3.group",
                    style: .info
                )
            }
        }
    }

    private var groupsSection: some View {
        ClearGlassSection(
            "Collections",
            subtitle: "Lightweight groups and tags support item-finding workflows."
        ) {
            FindRescueCard(
                title: "Collections and Tags",
                status: .preview,
                systemImage: "tag",
                summary: "Use saved collections for search and Second Bar. Advanced group panels and group status items stay in Advanced."
            ) {
                Button("Open Advanced", systemImage: "chevron.left.forwardslash.chevron.right") {
                    onOpenAdvanced?()
                }
            }
        }
    }

    private var crowdedRescueSection: some View {
        ClearGlassSection("Crowded menu rescue", subtitle: "Keep the main UI focused on simple choices.") {
            VStack(spacing: 0) {
                CrowdedRescueExplanationRow()

                ClearGlassDivider()

                rescuePreferenceRow(
                    title: "Open Second Bar when reveal does not fit",
                    subtitle: "Prefer a secondary surface when inline reveal is likely crowded.",
                    systemImage: "rectangle.bottomthird.inset.filled",
                    binding: $settingsStore.crowdedRevealAutoOpenSecondBar
                )

                ClearGlassDivider()

                rescuePreferenceRow(
                    title: "Enable crowded rescue decisions",
                    subtitle: "When off, reveal stays inline and no rescue surface is suggested.",
                    systemImage: "arrow.right.circle",
                    binding: $settingsStore.crowdedRevealRescueEnabled
                )

                ClearGlassDivider()

                rescuePreferenceRow(
                    title: "Ask before switching",
                    subtitle: "Show a suggestion instead of automatically switching surfaces when crowded.",
                    systemImage: "questionmark.circle",
                    binding: $settingsStore.crowdedRevealAskBeforeSwitching
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "rectangle.3.group",
                    title: "Workspace fallback",
                    subtitle: "Choose whether crowded rescue prefers Function Bar, Second Bar, a prompt, inline reveal, or Full Menu Bar Mode."
                ) {
                    Picker("Workspace fallback", selection: $settingsStore.crowdedRescueWorkspaceFallbackPreference) {
                        ForEach(CrowdedRescueWorkspaceFallbackPreference.allCases) { preference in
                            Text(preference.displayName).tag(preference.rawValue)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 210)
                }

                ClearGlassDivider()

                rescuePreferenceRow(
                    title: "Use Full Menu Bar Mode",
                    subtitle: "Temporarily show everything when the bar is very crowded.",
                    systemImage: "rectangle.expand.vertical",
                    binding: $settingsStore.fullMenuBarModeEnabled
                )
            }
        }
    }

    private var commandCenterSection: some View {
        ClearGlassSection("Item Actions", subtitle: "Shows whether Find Icon and Second Bar can run right now.") {
            if let findIconAvailability {
                CommandAvailabilityRow(summary: findIconAvailability)
            }

            if findIconAvailability != nil, secondBarAvailability != nil {
                ClearGlassDivider()
            }

            if let secondBarAvailability {
                CommandAvailabilityRow(summary: secondBarAvailability)
            }

            if findIconAvailability == nil && secondBarAvailability == nil {
                SettingsUnavailableGate(
                    .serviceUnavailable,
                    title: "Item Actions Unavailable",
                    message: "Action status appears once command routing is attached.",
                    systemImage: "link",
                    minHeight: 140,
                    nextSteps: ["Use Setup Checklist first.", "Open Find Icon or Second Bar when the gates are ready."]
                )
                .frame(maxWidth: .infinity, minHeight: 140)
            }
        }
    }

    private var discoveryReady: Bool {
        settingsStore.isProDiscoveryAvailable
    }

    private var findRescueReady: Bool {
        discoveryReady && permissionService?.status == .granted
    }

    private var accessibilityPermissionStatus: AccessibilityPermissionStatus {
        permissionService?.status ?? .notRequested
    }

    private var discoverySetupStatusText: String {
        if settingsStore.accessibilityDiscoveryEnabled {
            return "On"
        }

        return settingsStore.proModeEnabled ? "Off" : "Locked"
    }

    private var permissionSetupStatusText: String {
        if accessibilityPermissionStatus == .granted {
            return "Granted"
        }

        return discoveryReady ? accessibilityPermissionStatus.displayName : "Locked"
    }

    private var discoveryStepState: FindRescueSetupStepState {
        if settingsStore.accessibilityDiscoveryEnabled {
            return .complete
        }
        return settingsStore.proModeEnabled ? .current : .locked
    }

    private var permissionStepState: FindRescueSetupStepState {
        if permissionService?.status == .granted {
            return .complete
        }
        return discoveryReady ? .current : .locked
    }

    private var findRescueSetupMessage: String {
        if findRescueReady {
            return "Find Icon and Second Bar previews can use local Optional Pro metadata. Basic Mode remains available if these previews are turned off later."
        }
        return "Basic Mode keeps working while Optional Pro discovery is off or waiting for permission."
    }

    private func enableProMode() {
        if let permissionService {
            PrivacyProSetupActions.enableProMode(
                settingsStore: settingsStore,
                permissionService: permissionService
            )
        } else {
            settingsStore.proModeEnabled = true
        }
    }

    private func enableAccessibilityDiscovery() {
        settingsStore.accessibilityDiscoveryEnabled = true
    }

    private func openPrivacyForPermission() {
        if let permissionService, permissionService.status != .granted {
            permissionService.openSystemSettingsPrivacyPane()
        } else {
            onOpenPrivacy?()
        }
    }

    private var visibleNewItemCount: Int {
        guard settingsStore.proModeEnabled,
              settingsStore.accessibilityDiscoveryEnabled,
              permissionService?.status == .granted,
              liveStatus?.safeModeActive != true else {
            return 0
        }

        return rawNewItemCount
    }

    private var rawNewItemCount: Int {
        newItemInboxStore?.inbox.reviewCount ?? newItemCount
    }

    private var newItemInboxIsAvailable: Bool {
        settingsStore.proModeEnabled
            && settingsStore.accessibilityDiscoveryEnabled
            && permissionService?.status == .granted
            && liveStatus?.safeModeActive != true
    }

    private var newItemReviewState: NewMenuBarItemInboxReviewState {
        NewMenuBarItemInboxReviewState(
            inbox: newItemInboxStore?.inbox ?? .empty,
            isAvailable: newItemInboxIsAvailable
        )
    }

    @State private var lastNewItemAssignmentMessage: String?

    private func dismissNewItem(_ itemID: String) {
        newItemInboxStore?.dismiss(itemID: itemID)
        refreshNewItemCount()
    }

    private func resolveNewItem(_ itemID: String, preference: PlacementItemPreference) {
        placementPreferenceStore?.setPreference(preference, for: itemID)
        newItemInboxStore?.dismiss(itemID: itemID)
        refreshNewItemCount()
    }

    private func resetNewItemInbox() {
        newItemInboxStore?.reset()
        refreshNewItemCount()
    }

    private var workspaceAssignmentOptions: [WorkspaceAssignmentOption] {
        workspaceSwitchingService?.currentSnapshot().workspaces
            .filter { !$0.isArchived }
            .map { WorkspaceAssignmentOption(id: $0.id, title: WorkspaceDiagnosticsRedactor.displayName(for: $0)) }
            ?? []
    }

    private var groupAssignmentOptions: [WorkspaceAssignmentOption] {
        groupStore?.groups
            .filter(\.isEnabled)
            .map { WorkspaceAssignmentOption(id: $0.id, title: $0.isProtected ? "Protected Group" : $0.name) }
            ?? []
    }

    private func assignNewItemToCurrentWorkspace(_ itemID: String) {
        assignNewItem(itemID, to: .currentWorkspace)
    }

    private func assignNewItemToWorkspace(_ itemID: String, workspaceID: UUID) {
        assignNewItem(itemID, to: .workspace(workspaceID))
    }

    private func assignNewItemToGroup(_ itemID: String, groupID: UUID) {
        assignNewItem(itemID, to: .group(groupID))
    }

    private func createGroupForNewItem(_ itemID: String) {
        assignNewItem(itemID, to: .newGroup(name: "New Item Group", workspaceID: workspaceSwitchingService?.activeWorkspace().id))
    }

    private func assignNewItem(_ itemID: String, to target: WorkspaceAssignmentTarget) {
        guard let item = newItemInboxStore?.inbox.items.first(where: { $0.id == itemID }),
              let workspaceSwitchingService else {
            lastNewItemAssignmentMessage = "Workspace assignment is unavailable."
            return
        }

        let service = WorkspaceAssignmentService(
            switchingService: workspaceSwitchingService,
            groupStore: groupStore,
            newItemInboxStore: newItemInboxStore,
            safeModeActive: { liveStatus?.safeModeActive == true },
            previewEnabled: { settingsStore.workspacesPreviewEnabled }
        )
        let result = service.assignNewItem(item, to: target)
        lastNewItemAssignmentMessage = result.message
        refreshNewItemCount()
    }

    private func refreshNewItemCount() {
        liveStatus?.updateNewMenuBarItemReviewCount(newItemInboxStore?.inbox.reviewCount ?? 0)
    }

    private func rescuePreferenceRow(
        title: String,
        subtitle: String,
        systemImage: String,
        binding: Binding<Bool>
    ) -> some View {
        ClearGlassToggleRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            isOn: binding
        )
    }
}

nonisolated struct WorkspaceAssignmentOption: Identifiable, Equatable, Sendable {
    var id: UUID
    var title: String
}

private enum FindRescueSetupStepState: Equatable {
    case complete
    case current
    case locked

    var style: ClearGlassStatusStyle {
        switch self {
        case .complete:
            .success
        case .current:
            .info
        case .locked:
            .secondary
        }
    }

    var iconTint: Color {
        switch self {
        case .complete:
            .green
        case .current:
            .accentColor
        case .locked:
            .secondary
        }
    }
}

private struct FindRescueSetupStepRow: View {
    let number: Int
    let title: String
    let detail: String
    let statusText: String
    let state: FindRescueSetupStepState
    let systemImage: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: "\(number). \(title)",
            subtitle: detail,
            iconTint: state.iconTint
        ) {
            VStack(alignment: .trailing, spacing: 8) {
                ClearGlassStatusValue(text: statusText, style: state.style)

                if let actionTitle, let action {
                    stepButton(title: actionTitle, action: action)
                }
            }
        }
        .opacity(state == .locked ? 0.74 : 1)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func stepButton(title: String, action: @escaping () -> Void) -> some View {
        if state == .current {
            Button(title, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        } else {
            Button(title, action: action)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

private struct CrowdedRescueExplanationRow: View {
    var body: some View {
        ClearGlassControlRow(
            systemImage: "exclamationmark.triangle",
            title: "Rescue Flow",
            subtitle: "When inline reveal may not fit, Second Bar opens first. Full Menu Bar Mode temporarily reveals items; if neither is available, Arrange and Apple menu bar settings are suggested.",
            iconTint: .orange
        )
    }
}

private struct FindRescueOverviewStrip: View {
    let scannedCount: Int
    let hiddenCount: Int
    let alwaysHiddenCount: Int
    let newItemCount: Int

    var body: some View {
        ClearGlassOverviewStrip([
            ClearGlassOverviewMetric(
                title: "Discovered",
                value: "\(scannedCount)",
                systemImage: "list.bullet",
                style: scannedCount > 0 ? .info : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Hidden",
                value: "\(hiddenCount)",
                systemImage: "eye.slash",
                style: hiddenCount > 0 ? .info : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Always Hidden",
                value: "\(alwaysHiddenCount)",
                systemImage: "lock",
                style: alwaysHiddenCount > 0 ? .warning : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "New Items",
                value: "\(newItemCount)",
                systemImage: "tray",
                style: newItemCount > 0 ? .warning : .secondary
            )
        ])
    }
}

private struct FindRescueFlowPreview: View {
    let findIconAvailable: Bool
    let secondBarAvailable: Bool

    private let sourceIcons = ["wifi", "battery.100", "cloud", "moon"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("Rescue Flow Preview", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                ClearGlassStatusValue(
                    text: findIconAvailable || secondBarAvailable ? "Ready" : "Waiting",
                    style: findIconAvailable || secondBarAvailable ? .success : .secondary
                )
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    sourceCluster
                    flowConnector
                    rescueNode("Find Icon", systemImage: "magnifyingglass", isAvailable: findIconAvailable)
                    flowConnector
                    rescueNode("Second Bar", systemImage: "rectangle.bottomthird.inset.filled", isAvailable: secondBarAvailable)
                }

                VStack(alignment: .leading, spacing: 9) {
                    sourceCluster
                    rescueNode("Find Icon", systemImage: "magnifyingglass", isAvailable: findIconAvailable)
                    rescueNode("Second Bar", systemImage: "rectangle.bottomthird.inset.filled", isAvailable: secondBarAvailable)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.62), lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Find and Rescue flow preview")
    }

    private var sourceCluster: some View {
        HStack(spacing: 7) {
            ForEach(sourceIcons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "eye.slash")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
    }

    private var flowConnector: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    private func rescueNode(
        _ title: String,
        systemImage: String,
        isAvailable: Bool
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(isAvailable ? Color.accentColor : .secondary)
                .frame(width: 18)

            Text(title)
                .font(.caption)
                .lineLimit(1)

            ClearGlassStatusValue(
                text: isAvailable ? "Ready" : "Waiting",
                style: isAvailable ? .success : .secondary
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
    }
}

private struct FindRescueCard<Action: View>: View {
    let title: String
    let status: FeatureStatus
    let systemImage: String
    let summary: String
    @ViewBuilder let action: Action

    var body: some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: summary,
            iconTint: status.tint
        ) {
            ClearGlassAccessoryCluster {
                ClearGlassBadge(style: ClearGlassBadgeStyle(featureStatus: status))
                action
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

#Preview {
    FindAndRescueSettingsView(settingsStore: SettingsStore())
}
