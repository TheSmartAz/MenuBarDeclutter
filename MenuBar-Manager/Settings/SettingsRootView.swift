import AppKit
import Observation
import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
    case hideReveal
    case arrange
    case findRescue
    case menuBarItems
    case behavior
    case layout
    case search
    case secondBar
    case privateAccess
    case groups
    case hotkeys
    case profiles
    case automation
    case importExport
    case privacy
    case recovery
    case diagnostics
    case advanced
    case workspacesPreview

    var id: String { rawValue }

    static let visibleSidebarSections: [SettingsSection] = [
        .general,
        .hideReveal,
        .arrange,
        .findRescue,
        .workspacesPreview,
        .privacy,
        .recovery,
        .advanced
    ]

    static let moreSidebarGroups: [SettingsSidebarNavigationGroup] = [
        SettingsSidebarNavigationGroup(
            id: "surfaces",
            title: "Surfaces",
            systemImage: "rectangle.on.rectangle",
            helpText: "Inspect and open secondary menu bar surfaces.",
            sections: [
                .menuBarItems,
                .search,
                .secondBar,
                .groups
            ]
        ),
        SettingsSidebarNavigationGroup(
            id: "control",
            title: "Control",
            systemImage: "slider.horizontal.3",
            helpText: "Configure shortcuts, profiles, automation, and protected access.",
            sections: [
                .hotkeys,
                .profiles,
                .privateAccess,
                .automation
            ]
        ),
        SettingsSidebarNavigationGroup(
            id: "system",
            title: "System",
            systemImage: "wrench.and.screwdriver",
            helpText: "Review import/export, diagnostics, and layout maintenance tools.",
            sections: [
                .importExport,
                .diagnostics,
                .layout
            ]
        )
    ]

    static let moreSidebarSections: [SettingsSection] = moreSidebarGroups.flatMap(\.sections)

    var title: String {
        switch self {
        case .general:
            "General"
        case .hideReveal:
            "Hide & Reveal"
        case .arrange:
            "Arrange"
        case .findRescue:
            "Find & Rescue"
        case .menuBarItems:
            "Menu Bar Items"
        case .behavior:
            "Behavior"
        case .layout:
            "Layout"
        case .search:
            "Search"
        case .secondBar:
            "Second Bar"
        case .privateAccess:
            "Private Access"
        case .groups:
            "Groups"
        case .hotkeys:
            "Hotkeys"
        case .profiles:
            "Profiles"
        case .automation:
            "Automation"
        case .importExport:
            "Import / Export"
        case .privacy:
            "Privacy"
        case .recovery:
            "Recovery"
        case .diagnostics:
            "Diagnostics"
        case .advanced:
            "Advanced"
        case .workspacesPreview:
            "Workspaces"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            "gearshape"
        case .hideReveal:
            "eye"
        case .arrange:
            "arrow.up.left.and.arrow.down.right"
        case .findRescue:
            "lifepreserver"
        case .menuBarItems:
            "list.bullet.rectangle"
        case .behavior:
            "slider.horizontal.3"
        case .layout:
            "rectangle.split.3x1"
        case .search:
            "magnifyingglass"
        case .secondBar:
            "menubar.rectangle"
        case .privateAccess:
            "lock.fill"
        case .groups:
            "person.2"
        case .hotkeys:
            "keyboard"
        case .profiles:
            "person.crop.rectangle.stack"
        case .automation:
            "link"
        case .importExport:
            "arrow.up.arrow.down"
        case .privacy:
            "shield.lefthalf.filled"
        case .recovery:
            "cross.case"
        case .diagnostics:
            "waveform.path.ecg"
        case .advanced:
            "chevron.left.forwardslash.chevron.right"
        case .workspacesPreview:
            "rectangle.3.group"
        }
    }
}

struct SettingsSidebarNavigationGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let systemImage: String
    let helpText: String
    let sections: [SettingsSection]

    func contains(_ section: SettingsSection) -> Bool {
        sections.contains(section)
    }
}

private struct SettingsSidebarGroup: Identifiable {
    let title: String
    let sections: [SettingsSection]

    var id: String { title }

    static let all: [SettingsSidebarGroup] = [
        SettingsSidebarGroup(
            title: "MenuBarDeclutter",
            sections: SettingsSection.visibleSidebarSections
        ),
        SettingsSidebarGroup(
            title: "More",
            sections: SettingsSection.moreSidebarSections
        )
    ]
}

private struct SettingsSidebarSectionRow: View {
    let section: SettingsSection

    var body: some View {
        Label(section.title, systemImage: section.systemImage)
            .tag(section)
            .help(section.helpText)
            .accessibilityIdentifier(section.sidebarAccessibilityIdentifier)
    }
}

private struct SettingsSidebarNavigationGroupLabel: View {
    let group: SettingsSidebarNavigationGroup

    var body: some View {
        Label {
            HStack(spacing: 8) {
                Text(group.title)

                Spacer(minLength: 8)

                Text(group.sections.count.formatted())
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        } icon: {
            Image(systemName: group.systemImage)
        }
        .foregroundStyle(.secondary)
        .help(group.helpText)
    }
}

extension SettingsSection {
    var helpText: String {
        switch self {
        case .general:
            "Startup, onboarding, app mode, and app identity."
        case .hideReveal:
            "Collapse, expand, reveal all, auto-rehide, hover reveal, always-hidden zone, and the Basic hotkey."
        case .arrange:
            "Command-drag guide, control and separator placement, placement test, Planner Preview, and Assisted Move."
        case .findRescue:
            "Find Icon, Second Bar, crowded menu rescue, New Items, and lightweight collections."
        case .menuBarItems:
            "Inspect discovered menu bar items, owners, zones, and geometry."
        case .behavior:
            "Auto-rehide, hover reveal, separators, click behavior, and the global hotkey."
        case .layout:
            "Capacity, layout suggestions, Full Menu Bar Mode, spacers, and spacing labs."
        case .search:
            "Find Icon and search hotkey settings."
        case .secondBar:
            "Second Bar behavior, requirements, and presentation."
        case .privateAccess:
            "Authentication boundaries for protected app surfaces."
        case .groups:
            "Create and manage item groups."
        case .hotkeys:
            "Dynamic shortcut bindings for commands, groups, and profiles."
        case .profiles:
            "Profiles and automatic triggers."
        case .automation:
            "App Shortcuts and URL command settings."
        case .importExport:
            "Privacy-safe import, export, backups, and migration."
        case .privacy:
            "Basic Mode, Optional Pro, permissions, and local data policy."
        case .recovery:
            "Safe Mode, reset layout, repair actions, diagnostics export, and health report."
        case .diagnostics:
            "Health checks, logs, live status, and diagnostics export."
        case .advanced:
            "Developer-oriented recovery and Labs controls."
        case .workspacesPreview:
            "Local-only Workspaces, Function Bar, Set Builder, and Info Strip previews."
        }
    }

    var searchKeywords: String {
        "\(title) \(helpText)"
    }
}

@Observable
@MainActor
final class SettingsNavigationModel {
    var selectedSection: SettingsSection? = .general
    var searchText = ""
}

struct SettingsRootView: View {
    @Bindable var navigationModel: SettingsNavigationModel
    @Bindable var settingsStore: SettingsStore
    let diagnosticsLogger: DiagnosticsLogger
    var liveStatus: LiveDiagnosticsStatus?
    var launchAtLoginService: LaunchAtLoginService?
    var appSupportPaths: AppSupportPaths
    var diagnosticsExporter: DiagnosticsExporter
    @Bindable var dogfoodStore: DogfoodStore
    var newItemInboxStore: NewMenuBarItemInboxStore? = nil
    var itemMemoryStore: MenuBarItemMemoryStore? = nil
    var placementPreferenceStore: PlacementItemPreferenceStore? = nil
    var accessibilityPermissionService: AccessibilityPermissionService?
    var screenCapturePermissionService: ScreenCapturePermissionService? = nil
    var iconCaptureCoordinator: MenuBarIconCaptureCoordinator? = nil
    var menuBarScanCoordinator: MenuBarScanCoordinator?
    var profileStore: ProfileStore?
    var triggerService: TriggerService?
    var layoutCoordinator: LayoutCoordinator?
    var groupStore: IconGroupStore?
    var hotkeyBindingStore: HotkeyBindingStore?
    var privateAccessCoordinator: PrivateAccessCoordinator?
    var workspaceSwitchingService: WorkspaceSwitchingService?
    var setBuilderViewModel: SetBuilderViewModel?
    var functionBarController: FunctionBarController?
    var infoStripController: InfoStripController?
    var actions: SettingsActions = .empty
    @State private var isCommandPalettePresented = false
    @State private var isMoreSettingsExpanded = false
    @State private var expandedMoreGroupIDs: Set<String> = []

    var body: some View {
        NavigationSplitView {
            List(selection: $navigationModel.selectedSection) {
                if isFilteringSidebar {
                    ForEach(filteredSidebarGroups) { group in
                        Section(group.title) {
                            ForEach(group.sections) { section in
                                SettingsSidebarSectionRow(section: section)
                            }
                        }
                    }
                } else {
                    Section("MenuBarDeclutter") {
                        ForEach(SettingsSection.visibleSidebarSections) { section in
                            SettingsSidebarSectionRow(section: section)
                        }
                    }

                    DisclosureGroup(isExpanded: $isMoreSettingsExpanded) {
                        ForEach(SettingsSection.moreSidebarGroups) { group in
                            DisclosureGroup(isExpanded: moreGroupExpansionBinding(for: group)) {
                                ForEach(group.sections) { section in
                                    SettingsSidebarSectionRow(section: section)
                                }
                            } label: {
                                SettingsSidebarNavigationGroupLabel(group: group)
                            }
                            .accessibilityIdentifier("settings.sidebar.more.\(group.id)")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                            .help("Show deeper settings surfaces.")
                    }
                    .accessibilityIdentifier("settings.sidebar.more")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
            .searchable(text: $navigationModel.searchText, prompt: "Search Settings")
            .navigationSplitViewColumnWidth(min: 200, ideal: 226, max: 270)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isCommandPalettePresented = true
                    } label: {
                        Label("Find Setting or Action", systemImage: "magnifyingglass")
                    }
                    .keyboardShortcut("k", modifiers: [.command])
                    .help("Find a setting or action")
                    .accessibilityIdentifier("settings.commandPalette.open")
                }
            }
        } detail: {
            detailView(for: selectedSection)
                .accessibilityIdentifier(selectedSection.pageAccessibilityIdentifier)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 820, minHeight: 700)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $isCommandPalettePresented) {
            SettingsCommandPaletteView(
                index: commandPaletteIndex,
                onActivate: activateCommandPaletteEntry
            )
        }
        .onAppear {
            navigationModel.selectedSection = navigationModel.selectedSection ?? .general
            expandMoreSettingsIfNeeded(for: selectedSection)
        }
        .onChange(of: navigationModel.selectedSection) { _, newValue in
            guard let newValue else { return }
            expandMoreSettingsIfNeeded(for: newValue)
        }
    }

    private var selectedSection: SettingsSection {
        navigationModel.selectedSection ?? .general
    }

    private var sidebarSearchQuery: String {
        navigationModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isFilteringSidebar: Bool {
        !sidebarSearchQuery.isEmpty
    }

    private var filteredSidebarGroups: [SettingsSidebarGroup] {
        let query = sidebarSearchQuery
        guard !query.isEmpty else { return SettingsSidebarGroup.all }

        return SettingsSidebarGroup.all.compactMap { group in
            let sections = group.title.localizedStandardContains(query)
                ? group.sections
                : group.sections.filter { section in
                    section.title.localizedStandardContains(query)
                        || section.searchKeywords.localizedStandardContains(query)
                }
            guard !sections.isEmpty else { return nil }
            return SettingsSidebarGroup(title: group.title, sections: sections)
        }
    }

    private var commandPaletteIndex: SettingsCommandPaletteIndex {
        SettingsCommandPaletteIndex.make(
            includeDogfood: settingsStore.dogfoodModeEnabled || settingsStore.dogfoodRunID != nil,
            availableActions: availableCommandPaletteActions
        )
    }

    private var availableCommandPaletteActions: Set<SettingsCommandPaletteAction> {
        var availableActions = Set<SettingsCommandPaletteAction>()

        if actions.showOnboarding != nil {
            availableActions.insert(.showOnboarding)
        }
        if actions.showDragHint != nil {
            availableActions.insert(.showDragHint)
        }
        if actions.runHealthCheck != nil {
            availableActions.insert(.runHealthCheck)
        }
        if actions.fixHealthIssues != nil {
            availableActions.insert(.fixHealthIssues)
        }
        if actions.expand != nil {
            availableActions.insert(.expand)
        }
        if actions.revealAll != nil {
            availableActions.insert(.revealAll)
        }
        if actions.recreateStatusItems != nil {
            availableActions.insert(.recreateStatusItems)
        }
        if actions.disableAutoRehideTemporarily != nil {
            availableActions.insert(.disableAutoRehideTemporarily)
        }
        if actions.disableHoverRevealTemporarily != nil {
            availableActions.insert(.disableHoverRevealTemporarily)
        }
        if actions.openTroubleshootingGuide != nil {
            availableActions.insert(.openTroubleshootingGuide)
        }

        return availableActions
    }

    private func activateCommandPaletteEntry(_ entry: SettingsCommandPaletteEntry) {
        if let destination = entry.destination {
            navigationModel.selectedSection = destination
            return
        }

        if let action = entry.action {
            performCommandPaletteAction(action)
        }
    }

    private func performCommandPaletteAction(_ action: SettingsCommandPaletteAction) {
        switch action {
        case .showOnboarding:
            actions.showOnboarding?()
        case .showDragHint:
            actions.showDragHint?()
        case .runHealthCheck:
            actions.runHealthCheck?()
        case .fixHealthIssues:
            actions.fixHealthIssues?()
        case .expand:
            actions.expand?()
        case .revealAll:
            actions.revealAll?()
        case .recreateStatusItems:
            actions.recreateStatusItems?()
        case .disableAutoRehideTemporarily:
            actions.disableAutoRehideTemporarily?()
        case .disableHoverRevealTemporarily:
            actions.disableHoverRevealTemporarily?()
        case .openTroubleshootingGuide:
            actions.openTroubleshootingGuide?()
        }
    }

    private func expandMoreSettingsIfNeeded(for section: SettingsSection) {
        if SettingsSection.moreSidebarSections.contains(section) {
            isMoreSettingsExpanded = true
            expandMoreGroupIfNeeded(for: section)
        }
    }

    private func expandMoreGroupIfNeeded(for section: SettingsSection) {
        guard let group = SettingsSection.moreSidebarGroups.first(where: { $0.contains(section) }) else {
            return
        }

        expandedMoreGroupIDs.insert(group.id)
    }

    private func moreGroupExpansionBinding(for group: SettingsSidebarNavigationGroup) -> Binding<Bool> {
        Binding {
            expandedMoreGroupIDs.contains(group.id) || group.contains(selectedSection)
        } set: { isExpanded in
            if isExpanded {
                expandedMoreGroupIDs.insert(group.id)
            } else {
                expandedMoreGroupIDs.remove(group.id)
            }
        }
    }

    func commandSummary(for command: MenuBarCommand) -> MenuBarCommandAvailabilitySummary? {
        guard let availability = actions.commandAvailability?(command) else {
            return nil
        }
        return MenuBarCommandAvailabilitySummary(command: command, availability: availability)
    }

    func makeWorkspacePreviewDiagnosticsSnapshot() -> DiagnosticsExporter.WorkspacePreviewDiagnosticsSnapshot? {
        guard let workspaceSwitchingService,
              let setBuilderViewModel,
              let functionBarController,
              let infoStripController else {
            return nil
        }

        let snapshot = workspaceSwitchingService.currentSnapshot()
        let active = workspaceSwitchingService.activeWorkspace()
        let knownGroups = groupStore?.groups ?? setBuilderViewModel.groups
        let workspaceDiagnostics = WorkspaceDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            snapshot: snapshot,
            validationIssues: [],
            lastLoadStatus: .loaded,
            knownGroupIDs: Set(knownGroups.map(\.id)),
            protectedGroupIDs: Set(knownGroups.filter(\.isProtected).map(\.id)),
            knownProfileIDs: Set(profileStore?.profiles.map(\.id) ?? []),
            availableMenuBarItemHashes: availableMenuBarItemHashesForWorkspaceDiagnostics()
        )
        let functionDiagnostics = FunctionBarDiagnosticsSnapshot.make(
            settingsStore: settingsStore,
            controller: functionBarController
        )
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

        return DiagnosticsExporter.WorkspacePreviewDiagnosticsSnapshot(
            workspaces: workspaceDiagnostics,
            functionBar: functionDiagnostics,
            setBuilder: setBuilderViewModel.diagnosticsSnapshot,
            infoStrip: infoDiagnostics
        )
    }

    func makeSecondBarReadinessDiagnosticsSnapshot() -> DiagnosticsExporter.SecondBarReadinessDiagnosticsSnapshot? {
        let accessibilityPermission = accessibilityPermissionService?.currentStatus
            ?? settingsStore.lastAccessibilityPermissionStatus.flatMap(AccessibilityPermissionStatus.init(rawValue:))
            ?? .notRequested
        let screenCapturePermission = screenCapturePermissionService?.refreshStatus() ?? .unknown
        let input = ProSecondBarReadinessInput(
            entitlement: settingsStore.proModeEnabled ? .licensed : .basic,
            accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
            accessibilityPermission: accessibilityPermission,
            accurateIconsEnabled: settingsStore.renderedIconCaptureEnabled,
            screenCapturePermission: screenCapturePermission
        )
        return DiagnosticsExporter.SecondBarReadinessDiagnosticsSnapshot(
            input: input,
            readiness: ProSecondBarReadiness.evaluate(input),
            primaryClickOptIn: settingsStore.secondBarPrimaryClickEnabled,
            safeModeActive: liveStatus?.safeModeActive ?? false
        )
    }

    func makeSecondBarRuntimeDiagnosticsSnapshot() -> DiagnosticsExporter.SecondBarRuntimeDiagnosticsSnapshot? {
        guard let liveStatus else { return nil }
        return DiagnosticsExporter.SecondBarRuntimeDiagnosticsSnapshot(
            visible: liveStatus.secondBarVisible,
            itemCount: liveStatus.secondBarItemCount,
            currentScreen: liveStatus.secondBarCurrentScreen,
            lastPosition: liveStatus.secondBarLastPosition,
            iconWarmUpInProgress: liveStatus.secondBarIconWarmUpInProgress,
            lastIconWarmUpResult: liveStatus.secondBarLastIconWarmUpResult,
            lastCompactVisibleItemCount: liveStatus.secondBarLastCompactVisibleItemCount,
            lastCompactOverflowItemCount: liveStatus.secondBarLastCompactOverflowItemCount,
            lastCompactFallbackIconCount: liveStatus.secondBarLastCompactFallbackIconCount,
            lastCompactScanState: liveStatus.secondBarLastCompactScanState,
            lastCompactAvoidedNotch: liveStatus.secondBarLastCompactAvoidedNotch,
            lastActivationResult: liveStatus.secondBarLastActivationResult,
            lastActivationMatrixResult: liveStatus.secondBarLastActivationMatrixResult,
            lastActivationTargetZone: liveStatus.secondBarLastActivationTargetZone,
            lastActivationVisitedElementCount: liveStatus.secondBarLastActivationVisitedElementCount,
            lastActivationAXError: liveStatus.secondBarLastActivationAXError
        )
    }

    func routeSettingsCommand(_ command: MenuBarCommand) -> MenuBarCommandResult {
        actions.routeCommand?(command)
            ?? MenuBarCommandResult.stopped(
                command,
                status: .failed,
                message: "Command router is unavailable.",
                diagnosticReason: "routerUnavailable"
            )
    }

    private func availableMenuBarItemHashesForWorkspaceDiagnostics() -> Set<String>? {
        guard settingsStore.proModeEnabled,
              settingsStore.accessibilityDiscoveryEnabled,
              settingsStore.lastAccessibilityPermissionStatus == AccessibilityPermissionStatus.granted.rawValue,
              liveStatus?.lastMenuBarScanTime != nil else {
            return nil
        }
        return Set(liveStatus?.scannedMenuBarItems.map(\.id) ?? [])
    }

    func assignGroupHotkey(
        _ group: IconGroup,
        kind: GroupHotkeyAssignmentKind
    ) -> GroupHotkeyAssignmentResult {
        guard let hotkeyBindingStore else {
            return GroupHotkeyAssignmentResult(
                status: .unavailable,
                message: "Hotkey store is unavailable."
            )
        }

        hotkeyBindingStore.load()
        let plan = GroupHotkeyAssignmentPlanner().plan(
            groupID: group.id,
            kind: kind,
            existingBindings: hotkeyBindingStore.bindings
        )

        switch plan.operation {
        case .add(let binding):
            hotkeyBindingStore.add(binding: binding)
            actions.dynamicHotkeysChanged?()
        case .enableExisting(let id):
            hotkeyBindingStore.update(id: id) { binding in
                binding.isEnabled = true
            }
            actions.dynamicHotkeysChanged?()
        case .none:
            break
        }

        return plan.result
    }

    var privateAccessCommandSummaries: [MenuBarCommandAvailabilitySummary] {
        privateAccessCommands.compactMap(commandSummary)
    }

    private var privateAccessCommands: [MenuBarCommand] {
        [
            MenuBarCommand(
                action: .revealAlwaysHiddenZone,
                target: .globalVisibility,
                source: .settings
            ),
            MenuBarCommand(
                action: .showFindIcon,
                source: .statusMenu
            ),
            MenuBarCommand(
                action: .showSecondBar,
                target: .secondBar,
                source: .statusMenu
            ),
            MenuBarCommand(
                action: .showIconPanel,
                target: .iconPanel,
                source: .statusMenu
            ),
            MenuBarCommand(
                action: .experimentalActivateItem,
                target: .menuBarItem(id: "private-access-settings-preview"),
                source: .settings
            ),
            MenuBarCommand(
                action: .spacingPresetApply,
                target: .spacingPreset("private-access-settings-preview"),
                source: .settings
            )
        ]
    }

    func refreshAfterSettingsImport() {
        actions.behaviorChanged?()
        actions.searchChanged?()
        actions.secondBarChanged?()
        actions.privacyChanged?()
        actions.groupsChanged?()
        actions.dynamicHotkeysChanged?()
        actions.automationSettingsChanged?()
        actions.triggersChanged?()
    }
}

extension SettingsSection {
    var pageAccessibilityIdentifier: String {
        "settings.page.\(rawValue)"
    }

    var sidebarAccessibilityIdentifier: String {
        "settings.sidebar.\(rawValue)"
    }
}

#Preview {
    SettingsRootView(
        navigationModel: SettingsNavigationModel(),
        settingsStore: SettingsStore(),
        diagnosticsLogger: DiagnosticsLogger(),
        liveStatus: nil,
        appSupportPaths: AppSupportPaths(),
        diagnosticsExporter: DiagnosticsExporter(),
        dogfoodStore: DogfoodStore(appSupportPaths: AppSupportPaths())
    )
}
