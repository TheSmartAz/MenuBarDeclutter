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
    var onOpenArrange: (() -> Void)? = nil
    var onOpenPrivacy: (() -> Void)? = nil

    var body: some View {
        ClearGlassSettingsPage(
            "Find & Rescue",
            subtitle: "Find hidden icons, review new items, and recover when inline reveal is crowded.",
            badges: [.preview, .proMode, .accessibilityRequired]
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
            "Pro Discovery Requirements",
            subtitle: "Find & Rescue reads local Accessibility metadata only after explicit opt-in."
        ) {
            SearchRequirementRow(
                title: "Pro Mode",
                detail: "Find Icon, Second Bar, item actions, and New Items are Preview workflows behind Pro Mode.",
                status: settingsStore.proModeEnabled ? "Enabled" : "Disabled",
                isSatisfied: settingsStore.proModeEnabled,
                systemImage: "star"
            )

            ClearGlassDivider()

            SearchRequirementRow(
                title: "Accessibility Discovery",
                detail: "Discovery is local and does not use Screen Recording, screen capture, or network access.",
                status: settingsStore.accessibilityDiscoveryEnabled ? "Enabled" : "Disabled",
                isSatisfied: settingsStore.accessibilityDiscoveryEnabled,
                systemImage: "figure.circle"
            )

            ClearGlassDivider()

            SearchRequirementRow(
                title: "Accessibility Permission",
                detail: "Grant permission manually before item metadata can be read.",
                status: permissionService?.status.displayName ?? AccessibilityPermissionStatus.notRequested.displayName,
                isSatisfied: permissionService?.status == .granted,
                systemImage: "hand.raised",
                actionTitle: "Open Privacy",
                action: onOpenPrivacy
            )
        }
    }

    private var primaryWorkflowSection: some View {
        ClearGlassSection("Find Icon and Second Bar", subtitle: "The two main rescue surfaces now live together.") {
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
                    onOpenGroups?()
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
                ContentUnavailableView("Item Actions Unavailable", systemImage: "link")
                    .frame(maxWidth: .infinity, minHeight: 120)
            }
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
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle
        ) {
            Toggle(title, isOn: binding)
                .labelsHidden()
        }
    }
}

nonisolated struct WorkspaceAssignmentOption: Identifiable, Equatable, Sendable {
    var id: UUID
    var title: String
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

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            overviewPill("Discovered", value: "\(scannedCount)", systemImage: "list.bullet", style: scannedCount > 0 ? .info : .secondary)
            overviewPill("Hidden", value: "\(hiddenCount)", systemImage: "eye.slash", style: hiddenCount > 0 ? .info : .secondary)
            overviewPill("Always Hidden", value: "\(alwaysHiddenCount)", systemImage: "lock", style: alwaysHiddenCount > 0 ? .warning : .secondary)
            overviewPill("New Items", value: "\(newItemCount)", systemImage: "tray", style: newItemCount > 0 ? .warning : .secondary)
        }
    }

    private func overviewPill(
        _ title: String,
        value: String,
        systemImage: String,
        style: ClearGlassStatusStyle
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(style.tint)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.callout)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
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
            HStack(spacing: 8) {
                ClearGlassBadge(style: ClearGlassBadgeStyle(featureStatus: status))
                action
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}

#Preview {
    FindAndRescueSettingsView(settingsStore: SettingsStore())
}
