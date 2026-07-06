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

    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        switch section {
        case .general:
            GeneralSettingsView(
                settingsStore: settingsStore,
                launchAtLoginService: launchAtLoginService,
                onResetLayout: actions.resetLayout,
                onResetAllSettings: actions.resetAllSettings,
                onShowOnboarding: actions.showOnboarding
            )
        case .hideReveal, .behavior:
            BehaviorSettingsView(settingsStore: settingsStore, onChange: actions.behaviorChanged)
        case .arrange:
            ArrangeSettingsView(
                settingsStore: settingsStore,
                liveStatus: liveStatus,
                permissionService: accessibilityPermissionService,
                newItemInboxStore: newItemInboxStore,
                itemMemoryStore: itemMemoryStore,
                placementPreferenceStore: placementPreferenceStore,
                onExpand: {
                    _ = routeSettingsCommand(MenuBarCommand(action: .expand, source: .settings))
                },
                onCollapse: {
                    _ = routeSettingsCommand(MenuBarCommand(action: .collapse, source: .settings))
                },
                onRevealAll: {
                    _ = routeSettingsCommand(MenuBarCommand(action: .revealAll, source: .settings))
                },
                onResetLayout: actions.resetLayout,
                onShowDragHint: actions.showDragHint,
                onOpenRecovery: {
                    navigationModel.selectedSection = .recovery
                },
                onOpenAdvanced: {
                    navigationModel.selectedSection = .advanced
                },
                onPlannerCommand: { action, itemID in
                    routeSettingsCommand(MenuBarCommand(
                        action: action,
                        target: .menuBarItem(id: itemID),
                        source: .settings
                    ))
                },
                onExecuteAssistedMove: actions.executeAssistedMove
            )
        case .findRescue:
            FindAndRescueSettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                liveStatus: liveStatus,
                findIconAvailability: commandSummary(for: MenuBarCommand(
                    action: .showFindIcon,
                    source: .settings
                )),
                secondBarAvailability: commandSummary(for: MenuBarCommand(
                    action: .showSecondBar,
                    target: .secondBar,
                    source: .settings
                )),
                newItemCount: liveStatus?.newMenuBarItemReviewCount ?? 0,
                newItemInboxStore: newItemInboxStore,
                placementPreferenceStore: placementPreferenceStore,
                workspaceSwitchingService: workspaceSwitchingService,
                groupStore: groupStore,
                onOpenFindIcon: {
                    _ = routeSettingsCommand(MenuBarCommand(
                        action: .showFindIcon,
                        source: .settings
                    ))
                },
                onOpenSecondBar: {
                    _ = routeSettingsCommand(MenuBarCommand(
                        action: .showSecondBar,
                        target: .secondBar,
                        source: .settings
                    ))
                },
                onOpenSearchSettings: {
                    navigationModel.selectedSection = .search
                },
                onOpenSecondBarSettings: {
                    navigationModel.selectedSection = .secondBar
                },
                onOpenMenuBarItems: {
                    navigationModel.selectedSection = .menuBarItems
                },
                onOpenGroups: {
                    navigationModel.selectedSection = .advanced
                },
                onOpenArrange: {
                    navigationModel.selectedSection = .arrange
                },
                onOpenPrivacy: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .menuBarItems:
            MenuBarItemsSettingsView(
                settingsStore: settingsStore,
                liveStatus: liveStatus,
                scanCoordinator: menuBarScanCoordinator,
                onOpenPrivacySettings: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .layout:
            if let layoutCoordinator {
                LayoutSettingsView(
                    settingsStore: settingsStore,
                    diagnosticsLogger: diagnosticsLogger,
                    liveStatus: liveStatus,
                    layoutCoordinator: layoutCoordinator
                )
            } else {
                LayoutSettingsView(
                    settingsStore: settingsStore,
                    diagnosticsLogger: diagnosticsLogger,
                    liveStatus: liveStatus
                )
            }
        case .search:
            SearchSettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                commandAvailability: commandSummary(for: MenuBarCommand(
                    action: .showFindIcon,
                    source: .statusMenu
                )),
                onChange: actions.searchChanged,
                onOpenPrivacySettings: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .secondBar:
            SecondBarSettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                screenCapturePermissionService: screenCapturePermissionService,
                iconCaptureCoordinator: iconCaptureCoordinator,
                scanCoordinator: menuBarScanCoordinator,
                commandAvailability: commandSummary(for: MenuBarCommand(
                    action: .showSecondBar,
                    target: .secondBar,
                    source: .statusMenu
                )),
                iconPanelAvailability: commandSummary(for: MenuBarCommand(
                    action: .showIconPanel,
                    target: .iconPanel,
                    source: .statusMenu
                )),
                onChange: actions.secondBarChanged,
                onOpenPrivacySettings: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .privateAccess:
            PrivateAccessSettingsView(
                settingsStore: settingsStore,
                coordinator: privateAccessCoordinator,
                commandAvailabilities: privateAccessCommandSummaries,
                onChange: actions.privacyChanged
            )
        case .groups:
            if let groupStore {
                IconGroupsSettingsView(
                    settingsStore: settingsStore,
                    groupStore: groupStore,
                    snapshots: liveStatus?.scannedMenuBarItems ?? [],
                    proModeAvailable: settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled,
                    onOpenPrivacySettings: {
                        navigationModel.selectedSection = .privacy
                    },
                    commandAvailability: { group in
                        commandSummary(for: MenuBarCommand(
                            action: .showGroupPanel,
                            target: .group(group.id),
                            source: .settings
                        ))
                    },
                    onOpenGroupPanel: { group in
                        routeSettingsCommand(MenuBarCommand(
                            action: .showGroupPanel,
                            target: .group(group.id),
                            source: .settings
                        ))
                    },
                    onRevealGroup: { group in
                        routeSettingsCommand(MenuBarCommand(
                            action: .revealGroup,
                            target: .group(group.id),
                            source: .settings
                        ))
                    },
                    onAssignGroupHotkey: { group, kind in
                        assignGroupHotkey(group, kind: kind)
                    },
                    onGroupsChanged: actions.groupsChanged
                )
            } else {
                ClearGlassSettingsPage("Groups", subtitle: "Group controls are available once group services are attached.") {
                    ClearGlassSection("Groups Unavailable") {
                        SettingsUnavailableGate(
                            .serviceUnavailable,
                            title: "Groups Unavailable",
                            message: "Group services are not attached in this build. Basic Mode remains available.",
                            systemImage: "person.2",
                            minHeight: 220
                        )
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
            }
        case .hotkeys:
            if let hotkeyBindingStore {
                DynamicHotkeysSettingsView(
                    settingsStore: settingsStore,
                    bindingStore: hotkeyBindingStore,
                    groups: groupStore?.groups ?? [],
                    profiles: profileStore?.profiles ?? [],
                    onHotkeysChanged: actions.dynamicHotkeysChanged
                )
            } else {
                ClearGlassSettingsPage("Hotkeys", subtitle: "Dynamic hotkeys are available once the hotkey store is attached.") {
                    ClearGlassSection("Hotkeys Unavailable") {
                        SettingsUnavailableGate(
                            .serviceUnavailable,
                            title: "Hotkeys Unavailable",
                            message: "The dynamic hotkey store is not attached in this build. The stable Basic hotkey is unchanged.",
                            systemImage: "keyboard",
                            minHeight: 220
                        )
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
            }
        case .profiles:
            if let profileStore,
               let triggerService,
               let liveStatus,
               let dryRunProfile = actions.profile.dryRun,
               let applyProfile = actions.profile.apply {
                ProfileListView(
                    profileStore: profileStore,
                    triggerService: triggerService,
                    settingsStore: settingsStore,
                    liveStatus: liveStatus,
                    onDryRun: dryRunProfile,
                    onApply: applyProfile,
                    commandAvailability: { profile in
                        commandSummary(for: MenuBarCommand(
                            action: .applyProfile,
                            target: .profileID(profile.id),
                            source: .settings
                        ))
                    },
                    onTriggersChanged: actions.triggersChanged ?? {}
                )
            } else {
                ClearGlassSettingsPage(
                    "Profiles",
                    subtitle: "Profile controls are available once profile services are attached."
                ) {
                    ClearGlassSection("Profiles Unavailable") {
                        SettingsUnavailableGate(
                            .serviceUnavailable,
                            title: "Profiles Unavailable",
                            message: "Profile services are not attached in this build. Existing Basic Mode controls remain available.",
                            systemImage: "person.crop.rectangle.stack",
                            minHeight: 220
                        )
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
            }
        case .privacy:
            PrivacySettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                screenCapturePermissionService: screenCapturePermissionService,
                iconCaptureCoordinator: iconCaptureCoordinator,
                scanCoordinator: menuBarScanCoordinator,
                onChange: actions.privacyChanged
            )
        case .recovery:
            RecoverySettingsView(
                settingsStore: settingsStore,
                diagnosticsLogger: diagnosticsLogger,
                appSupportPaths: appSupportPaths,
                diagnosticsExporter: diagnosticsExporter,
                liveStatus: liveStatus,
                onRunHealthCheck: actions.runHealthCheck,
                onFixHealthIssues: actions.fixHealthIssues,
                onExpand: actions.expand,
                onRevealAll: actions.revealAll,
                onRecreateStatusItems: actions.recreateStatusItems,
                onDisableAutoRehideTemporarily: actions.disableAutoRehideTemporarily,
                onDisableHoverRevealTemporarily: actions.disableHoverRevealTemporarily,
                onResetCurrentWorkspaceLayout: actions.resetCurrentWorkspaceLayout,
                onRemoveMissingWorkspaceGroupReferences: actions.removeMissingWorkspaceGroupReferences,
                onDiscardSetBuilderDraft: actions.discardSetBuilderDraft,
                onDisableFunctionBarPreview: actions.disableFunctionBarPreview,
                onDisableInfoStripPreview: actions.disableInfoStripPreview,
                onDisableSetBuilderPreview: actions.disableSetBuilderPreview,
                onResetLayout: actions.resetLayout,
                onResetAllSettings: actions.resetAllSettings,
                onResetBasicMode: actions.resetBasicMode,
                onDisableProMode: actions.disableProMode,
                onEnterSafeModeNextLaunch: actions.enterSafeModeNextLaunch,
                onOpenTroubleshootingGuide: actions.openTroubleshootingGuide,
                onOpenDiagnostics: {
                    navigationModel.selectedSection = .diagnostics
                },
                onOpenImportExport: {
                    navigationModel.selectedSection = .importExport
                }
            )
        case .automation:
            AutomationSettingsView(
                settingsStore: settingsStore,
                accessibilityPermissionService: accessibilityPermissionService,
                screenCapturePermissionService: screenCapturePermissionService,
                onChange: actions.automationSettingsChanged
            )
        case .importExport:
            MigrationAssistantRootView(
                settingsStore: settingsStore,
                appSupportPaths: appSupportPaths,
                diagnosticsLogger: diagnosticsLogger,
                profileStore: profileStore,
                groupStore: groupStore,
                hotkeyBindingStore: hotkeyBindingStore,
                spacerItemStore: layoutCoordinator?.spacerStore,
                workspaceSwitchingService: workspaceSwitchingService,
                onImportApplied: refreshAfterSettingsImport
            )
        case .diagnostics:
            DiagnosticsSettingsView(
                diagnosticsLogger: diagnosticsLogger,
                liveStatus: liveStatus,
                appSupportPaths: appSupportPaths,
                exporter: diagnosticsExporter,
                dogfoodStore: dogfoodStore,
                settingsStore: settingsStore,
                launchAtLoginService: launchAtLoginService,
                scanCoordinator: menuBarScanCoordinator,
                onRunHealthCheck: actions.runHealthCheck,
                onFixHealthIssues: actions.fixHealthIssues,
                onResetBasicMode: actions.resetBasicMode,
                onDisableProMode: actions.disableProMode,
                onEnterSafeModeNextLaunch: actions.enterSafeModeNextLaunch,
                secondBarReadinessDiagnosticsProvider: makeSecondBarReadinessDiagnosticsSnapshot,
                workspacePreviewDiagnosticsProvider: makeWorkspacePreviewDiagnosticsSnapshot
            )
        case .advanced:
            AdvancedSettingsView(
                settingsStore: settingsStore,
                appSupportPaths: appSupportPaths,
                onChange: actions.behaviorChanged,
                onAutomationChanged: actions.triggersChanged,
                onResetMovingWarnings: actions.resetMovingWarnings,
                onOpenSection: { section in
                    navigationModel.selectedSection = section
                }
            )
        case .workspacesPreview:
            if let workspaceSwitchingService,
               let setBuilderViewModel,
               let functionBarController,
               let infoStripController {
                WorkspacePreviewSettingsView(
                    settingsStore: settingsStore,
                    liveStatus: liveStatus,
                    switchingService: workspaceSwitchingService,
                    setBuilderViewModel: setBuilderViewModel,
                    functionBarController: functionBarController,
                    infoStripController: infoStripController,
                    knownGroupIDs: Set((groupStore?.groups ?? setBuilderViewModel.groups).map(\.id)),
                    protectedGroupIDs: Set((groupStore?.groups ?? setBuilderViewModel.groups).filter(\.isProtected).map(\.id)),
                    knownProfileIDs: Set(profileStore?.profiles.map(\.id) ?? []),
                    routeCommand: actions.routeCommand,
                    onOpenFindRescue: {
                        navigationModel.selectedSection = .findRescue
                    },
                    onOpenRecovery: {
                        navigationModel.selectedSection = .recovery
                    }
                )
            } else {
                ClearGlassSettingsPage(
                    "Workspaces",
                    subtitle: "Workspaces are available once preview services are attached.",
                    badges: [.experimental, .privacySafe]
                ) {
                    ClearGlassSection("Preview Unavailable") {
                        SettingsUnavailableGate(
                            .serviceUnavailable,
                            title: "Preview Unavailable",
                            message: "Workspace preview services are not attached in this build. Stable settings remain usable.",
                            systemImage: "rectangle.3.group",
                            minHeight: 220
                        )
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
            }
        }
    }

    private func commandSummary(for command: MenuBarCommand) -> MenuBarCommandAvailabilitySummary? {
        guard let availability = actions.commandAvailability?(command) else {
            return nil
        }
        return MenuBarCommandAvailabilitySummary(command: command, availability: availability)
    }

    private func makeWorkspacePreviewDiagnosticsSnapshot() -> DiagnosticsExporter.WorkspacePreviewDiagnosticsSnapshot? {
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

    private func makeSecondBarReadinessDiagnosticsSnapshot() -> DiagnosticsExporter.SecondBarReadinessDiagnosticsSnapshot? {
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

    private func routeSettingsCommand(_ command: MenuBarCommand) -> MenuBarCommandResult {
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

    private func assignGroupHotkey(
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

    private var privateAccessCommandSummaries: [MenuBarCommandAvailabilitySummary] {
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

    private func refreshAfterSettingsImport() {
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

enum ClearGlassSettingsPageStyle {
    case form
    case tool

    var maxContentWidth: CGFloat {
        rhythm.maxContentWidth
    }

    var contentSpacing: CGFloat {
        rhythm.contentSpacing
    }

    var horizontalPadding: CGFloat {
        rhythm.horizontalPadding
    }

    var topPadding: CGFloat {
        rhythm.topPadding
    }

    var bottomPadding: CGFloat {
        rhythm.bottomPadding
    }

    var headerInlineSpacing: CGFloat {
        rhythm.headerInlineSpacing
    }

    var headerStackSpacing: CGFloat {
        rhythm.headerStackSpacing
    }

    var sectionHeaderWidth: CGFloat {
        rhythm.sectionHeaderWidth
    }

    var sectionColumnSpacing: CGFloat {
        rhythm.sectionColumnSpacing
    }

    var sectionHeaderTopPadding: CGFloat {
        rhythm.sectionHeaderTopPadding
    }

    var sectionHeaderBodySpacing: CGFloat {
        rhythm.sectionHeaderBodySpacing
    }

    var nestedSectionSpacing: CGFloat {
        rhythm.nestedSectionSpacing
    }

    var sectionBodyHorizontalPadding: CGFloat {
        rhythm.sectionBodyHorizontalPadding
    }

    var sectionBodyVerticalPadding: CGFloat {
        rhythm.sectionBodyVerticalPadding
    }

    var nestedSectionBodyHorizontalPadding: CGFloat {
        rhythm.nestedSectionBodyHorizontalPadding
    }

    var nestedSectionBodyVerticalPadding: CGFloat {
        rhythm.nestedSectionBodyVerticalPadding
    }

    private var rhythm: ClearGlassSettingsPageRhythm {
        switch self {
        case .form:
            ClearGlassSettingsPageRhythm(
                maxContentWidth: 1040,
                horizontalPadding: 34,
                topPadding: 26,
                bottomPadding: 78,
                headerInlineSpacing: 18,
                headerStackSpacing: 13,
                contentSpacing: 28,
                sectionHeaderWidth: 190,
                sectionColumnSpacing: 24,
                sectionHeaderTopPadding: 10,
                sectionHeaderBodySpacing: 10,
                nestedSectionSpacing: 9,
                sectionBodyHorizontalPadding: 16,
                sectionBodyVerticalPadding: 9,
                nestedSectionBodyHorizontalPadding: 12,
                nestedSectionBodyVerticalPadding: 7
            )
        case .tool:
            ClearGlassSettingsPageRhythm(
                maxContentWidth: 1160,
                horizontalPadding: 34,
                topPadding: 24,
                bottomPadding: 82,
                headerInlineSpacing: 18,
                headerStackSpacing: 12,
                contentSpacing: 22,
                sectionHeaderWidth: 180,
                sectionColumnSpacing: 20,
                sectionHeaderTopPadding: 8,
                sectionHeaderBodySpacing: 11,
                nestedSectionSpacing: 9,
                sectionBodyHorizontalPadding: 16,
                sectionBodyVerticalPadding: 9,
                nestedSectionBodyHorizontalPadding: 12,
                nestedSectionBodyVerticalPadding: 7
            )
        }
    }
}

private struct ClearGlassSettingsPageRhythm {
    let maxContentWidth: CGFloat
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let headerInlineSpacing: CGFloat
    let headerStackSpacing: CGFloat
    let contentSpacing: CGFloat
    let sectionHeaderWidth: CGFloat
    let sectionColumnSpacing: CGFloat
    let sectionHeaderTopPadding: CGFloat
    let sectionHeaderBodySpacing: CGFloat
    let nestedSectionSpacing: CGFloat
    let sectionBodyHorizontalPadding: CGFloat
    let sectionBodyVerticalPadding: CGFloat
    let nestedSectionBodyHorizontalPadding: CGFloat
    let nestedSectionBodyVerticalPadding: CGFloat
}

private struct ClearGlassSettingsPageStyleKey: EnvironmentKey {
    static let defaultValue: ClearGlassSettingsPageStyle = .form
}

private extension EnvironmentValues {
    var clearGlassSettingsPageStyle: ClearGlassSettingsPageStyle {
        get { self[ClearGlassSettingsPageStyleKey.self] }
        set { self[ClearGlassSettingsPageStyleKey.self] = newValue }
    }
}

struct ClearGlassSettingsPage<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let badges: [ClearGlassBadgeStyle]
    private let style: ClearGlassSettingsPageStyle
    private let sectionAnchors: [ClearGlassPageAnchor]
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        badges: [ClearGlassBadgeStyle] = [],
        style: ClearGlassSettingsPageStyle = .form,
        sectionAnchors: [ClearGlassPageAnchor] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badges = badges
        self.style = style
        self.sectionAnchors = sectionAnchors
        self.content = content()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: style.contentSpacing) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .bottom, spacing: style.headerInlineSpacing) {
                            ClearGlassPageHeader(title: title, subtitle: subtitle, badges: badges)
                                .layoutPriority(1)

                            Spacer(minLength: style.headerInlineSpacing)

                            if sectionAnchors.count > 1 {
                                ClearGlassPageAnchorBar(anchors: sectionAnchors) { anchor in
                                    scroll(to: anchor, using: proxy)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: style.headerStackSpacing) {
                            ClearGlassPageHeader(title: title, subtitle: subtitle, badges: badges)

                            if sectionAnchors.count > 1 {
                                ClearGlassPageAnchorBar(anchors: sectionAnchors) { anchor in
                                    scroll(to: anchor, using: proxy)
                                }
                            }
                        }
                    }
                    .id(ClearGlassPageAnchor.top.targetID)

                    content
                        .environment(\.clearGlassSettingsPageStyle, style)
                }
                .padding(.horizontal, style.horizontalPadding)
                .padding(.top, style.topPadding)
                .padding(.bottom, style.bottomPadding)
                .frame(maxWidth: style.maxContentWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .accessibilityIdentifier("settings.page.scroll")
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private func scroll(to anchor: ClearGlassPageAnchor, using proxy: ScrollViewProxy) {
        if accessibilityReduceMotion {
            proxy.scrollTo(anchor.targetID, anchor: .top)
        } else {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(anchor.targetID, anchor: .top)
            }
        }
    }
}

struct ClearGlassPageAnchor: Identifiable, Hashable {
    let title: String
    let systemImage: String
    let targetID: String

    var id: String { targetID }

    init(_ title: String, systemImage: String, targetID: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.targetID = targetID ?? title
    }

    static let top = ClearGlassPageAnchor("Top", systemImage: "arrow.up", targetID: "settings.page.top")
}

struct ClearGlassPageAnchorBar: View {
    let anchors: [ClearGlassPageAnchor]
    let onSelect: (ClearGlassPageAnchor) -> Void

    private var allAnchors: [ClearGlassPageAnchor] {
        [ClearGlassPageAnchor.top] + anchors
    }

    var body: some View {
        if anchors.count > 1 {
            compactAnchorMenu
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Page sections")
        }
    }

    private var compactAnchorMenu: some View {
        Menu {
            ForEach(allAnchors) { anchor in
                Button {
                    onSelect(anchor)
                } label: {
                    Label(anchor.title, systemImage: anchor.systemImage)
                }
            }
        } label: {
            Label("Sections", systemImage: "list.bullet")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityLabel("Jump to page section")
        .accessibilityHint("Opens a menu of sections on this settings page.")
    }
}

private struct ClearGlassSectionDepthKey: EnvironmentKey {
    static let defaultValue = 0
}

private extension EnvironmentValues {
    var clearGlassSectionDepth: Int {
        get { self[ClearGlassSectionDepthKey.self] }
        set { self[ClearGlassSectionDepthKey.self] = newValue }
    }
}

struct ClearGlassSection<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let anchorID: String?
    @Environment(\.clearGlassSettingsPageStyle) private var pageStyle
    @Environment(\.clearGlassSectionDepth) private var sectionDepth
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        anchorID: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.anchorID = anchorID
        self.content = content()
    }

    var body: some View {
        sectionLayout
            .environment(\.clearGlassSectionDepth, sectionDepth + 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(anchorID ?? title)
    }

    @ViewBuilder
    private var sectionLayout: some View {
        if sectionDepth == 0 {
            switch pageStyle {
            case .form:
                formTopLevelSection
            case .tool:
                toolTopLevelSection
            }
        } else {
            nestedSection
        }
    }

    private var formTopLevelSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: pageStyle.sectionColumnSpacing) {
                sectionHeader
                    .frame(width: pageStyle.sectionHeaderWidth, alignment: .topLeading)
                    .padding(.top, pageStyle.sectionHeaderTopPadding)

                sectionBody()
                    .frame(minWidth: 360, maxWidth: .infinity, alignment: .topLeading)
            }

            verticalSection
        }
    }

    private var toolTopLevelSection: some View {
        VStack(alignment: .leading, spacing: pageStyle.sectionHeaderBodySpacing) {
            sectionHeader
                .padding(.horizontal, 2)

            sectionBody()
        }
    }

    private var verticalSection: some View {
        VStack(alignment: .leading, spacing: pageStyle.sectionHeaderBodySpacing) {
            sectionHeader
                .padding(.horizontal, 2)

            sectionBody()
        }
    }

    private var nestedSection: some View {
        VStack(alignment: .leading, spacing: pageStyle.nestedSectionSpacing) {
            sectionHeader
                .padding(.horizontal, 2)

            sectionBody(isNested: true)
        }
        .padding(.vertical, 4)
    }

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DesignTokens.Typography.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let subtitle {
                Text(subtitle)
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionBody(isNested: Bool = false) -> some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, isNested ? pageStyle.nestedSectionBodyHorizontalPadding : pageStyle.sectionBodyHorizontalPadding)
        .padding(.vertical, isNested ? pageStyle.nestedSectionBodyVerticalPadding : pageStyle.sectionBodyVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sectionFill(isNested: isNested), in: .rect(cornerRadius: DesignTokens.Radius.group))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.group)
                .strokeBorder(sectionBorder(isNested: isNested), lineWidth: DesignTokens.Stroke.hairline)
        }
    }

    private func sectionFill(isNested: Bool) -> Color {
        if isNested {
            return Color(nsColor: .quaternaryLabelColor).opacity(0.08)
        }

        return Color(nsColor: .controlBackgroundColor)
    }

    private func sectionBorder(isNested: Bool) -> Color {
        Color(nsColor: .separatorColor).opacity(isNested ? 0.38 : 0.58)
    }
}

struct ClearGlassToolSurface<Content: View>: View {
    private let horizontalPadding: CGFloat
    private let verticalPadding: CGFloat
    private let minHeight: CGFloat?
    @ViewBuilder private let content: Content

    init(
        horizontalPadding: CGFloat = 0,
        verticalPadding: CGFloat = 0,
        minHeight: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: DesignTokens.Radius.group))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.group)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: DesignTokens.Stroke.hairline)
            }
    }
}

struct ClearGlassPaneLayout<Primary: View, Detail: View>: View {
    private let primaryWidth: CGFloat
    private let spacing: CGFloat
    @ViewBuilder private let primary: Primary
    @ViewBuilder private let detail: Detail

    init(
        primaryWidth: CGFloat = 280,
        spacing: CGFloat = 14,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder detail: () -> Detail
    ) {
        self.primaryWidth = primaryWidth
        self.spacing = spacing
        self.primary = primary()
        self.detail = detail()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: spacing) {
                primary
                    .frame(width: primaryWidth)

                detail
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: spacing) {
                primary
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                detail
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct ClearGlassButtonGrid<Content: View>: View {
    private let minimumItemWidth: CGFloat
    private let spacing: CGFloat
    @ViewBuilder private let content: Content

    init(
        minimumItemWidth: CGFloat = 150,
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.minimumItemWidth = minimumItemWidth
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumItemWidth), spacing: spacing)],
            alignment: .leading,
            spacing: spacing
        ) {
            content
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum ClearGlassInteractionSurface {
    case row
    case surface
    case tile
    case token

    var cornerRadius: CGFloat {
        switch self {
        case .row:
            7
        case .surface:
            8
        case .tile:
            8
        case .token:
            6
        }
    }

    var hoverFill: Color {
        switch self {
        case .row:
            Color.accentColor.opacity(0.045)
        case .surface:
            Color.accentColor.opacity(0.035)
        case .tile:
            Color.accentColor.opacity(0.045)
        case .token:
            Color.accentColor.opacity(0.05)
        }
    }

    var hoverStroke: Color {
        Color.accentColor.opacity(0.18)
    }

    var disabledFill: Color {
        Color(nsColor: .quaternaryLabelColor).opacity(0.08)
    }

    var disabledStroke: Color {
        Color(nsColor: .separatorColor).opacity(0.42)
    }
}

private struct ClearGlassInteractionFeedback: ViewModifier {
    let surface: ClearGlassInteractionSurface
    let isDimmed: Bool
    let helpText: String?

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    private var isInteractive: Bool {
        isEnabled && !isDimmed
    }

    func body(content: Content) -> some View {
        content
            .contentShape(.rect(cornerRadius: surface.cornerRadius))
            .background {
                RoundedRectangle(cornerRadius: surface.cornerRadius)
                    .fill(backgroundFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: surface.cornerRadius)
                    .strokeBorder(strokeColor, style: strokeStyle)
            }
            .onHover { isHovered = $0 }
            .animation(accessibilityReduceMotion ? nil : .easeOut(duration: 0.16), value: isHovered)
            .clearGlassHelp(helpText)
    }

    private var backgroundFill: Color {
        if !isInteractive {
            return surface.disabledFill
        }

        return isHovered ? surface.hoverFill : .clear
    }

    private var strokeColor: Color {
        if !isInteractive {
            return surface.disabledStroke
        }

        return isHovered ? surface.hoverStroke : .clear
    }

    private var strokeStyle: StrokeStyle {
        StrokeStyle(
            lineWidth: isInteractive ? 0.75 : 0.5,
            dash: isInteractive ? [] : [3, 3]
        )
    }
}

extension View {
    func clearGlassInteractionFeedback(
        _ surface: ClearGlassInteractionSurface,
        isDimmed: Bool = false,
        help helpText: String? = nil
    ) -> some View {
        modifier(
            ClearGlassInteractionFeedback(
                surface: surface,
                isDimmed: isDimmed,
                helpText: helpText
            )
        )
    }

    @ViewBuilder
    func clearGlassHelp(_ helpText: String?) -> some View {
        if let helpText, !helpText.isEmpty {
            help(helpText)
        } else {
            self
        }
    }
}

struct ClearGlassOverviewMetric: Identifiable, Hashable {
    let id: String
    let title: String
    let value: String
    let systemImage: String
    let style: ClearGlassStatusStyle

    init(
        id: String? = nil,
        title: String,
        value: String,
        systemImage: String,
        style: ClearGlassStatusStyle = .secondary
    ) {
        self.id = id ?? title
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.style = style
    }
}

struct ClearGlassOverviewStrip: View {
    private let metrics: [ClearGlassOverviewMetric]
    private let minimumItemWidth: CGFloat
    private let maximumColumnCount: Int

    init(
        _ metrics: [ClearGlassOverviewMetric],
        minimumItemWidth: CGFloat = 120,
        maximumColumnCount: Int = 4
    ) {
        self.metrics = metrics
        self.minimumItemWidth = minimumItemWidth
        self.maximumColumnCount = max(1, maximumColumnCount)
    }

    var body: some View {
        LazyVGrid(
            columns: columns,
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(metrics) { metric in
                ClearGlassOverviewMetricTile(metric: metric)
            }
        }
    }

    private var columns: [GridItem] {
        if maximumColumnCount < metrics.count {
            return Array(
                repeating: GridItem(.flexible(minimum: minimumItemWidth), spacing: 10),
                count: maximumColumnCount
            )
        }

        return [
            GridItem(.adaptive(minimum: minimumItemWidth), spacing: 10)
        ]
    }
}

private struct ClearGlassOverviewMetricTile: View {
    let metric: ClearGlassOverviewMetric

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: metric.systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(metric.style.tint)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(metric.value)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
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
        .clearGlassInteractionFeedback(.tile, help: "\(metric.title): \(metric.value)")
    }
}

struct ClearGlassMetricTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.36), lineWidth: 0.5)
        }
        .clearGlassInteractionFeedback(.tile, help: "\(label): \(value)")
    }
}

struct ClearGlassGroupedList<Content: View>: View {
    private let title: String
    private let subtitle: String?
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ClearGlassStatusControlRow<Accessory: View>: View {
    private let systemImage: String
    private let title: String
    private let subtitle: String
    private let iconTint: Color
    private let statusText: String?
    private let statusStyle: ClearGlassStatusStyle
    private let isDimmed: Bool
    @ViewBuilder private let accessory: Accessory

    init(
        systemImage: String,
        title: String,
        subtitle: String,
        iconTint: Color? = nil,
        statusText: String? = nil,
        statusStyle: ClearGlassStatusStyle = .secondary,
        isDimmed: Bool = false,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.iconTint = iconTint ?? statusStyle.tint
        self.statusText = statusText
        self.statusStyle = statusStyle
        self.isDimmed = isDimmed
        self.accessory = accessory()
    }

    var body: some View {
        ClearGlassRowAnatomy(
            systemImage: systemImage,
            iconTint: iconTint,
            title: title,
            subtitle: subtitle,
            statusText: statusText,
            statusStyle: statusStyle
        ) {
            accessory
        }
        .padding(.vertical, 8)
        .opacity(isDimmed ? 0.58 : 1)
        .clearGlassInteractionFeedback(.row, isDimmed: isDimmed, help: helpText)
        .accessibilityElement(children: .combine)
    }

    private var helpText: String {
        if let statusText {
            return "\(title). \(subtitle) Status: \(statusText)."
        }

        return "\(title). \(subtitle)"
    }
}

extension ClearGlassStatusControlRow where Accessory == EmptyView {
    init(
        systemImage: String,
        title: String,
        subtitle: String,
        iconTint: Color? = nil,
        statusText: String? = nil,
        statusStyle: ClearGlassStatusStyle = .secondary,
        isDimmed: Bool = false
    ) {
        self.init(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: iconTint,
            statusText: statusText,
            statusStyle: statusStyle,
            isDimmed: isDimmed
        ) {
            EmptyView()
        }
    }
}

enum ClearGlassAccessoryClusterAlignment {
    case leading
    case center
    case trailing
}

enum ClearGlassAccessoryClusterWidth {
    case compact
    case flexible
}

struct ClearGlassAccessoryCluster<Content: View>: View {
    private let alignment: ClearGlassAccessoryClusterAlignment
    private let spacing: CGFloat
    private let width: ClearGlassAccessoryClusterWidth
    private let appliesDefaultButtonStyle: Bool
    @ViewBuilder private let content: Content

    init(
        alignment: ClearGlassAccessoryClusterAlignment = .trailing,
        spacing: CGFloat = 8,
        width: ClearGlassAccessoryClusterWidth = .compact,
        appliesDefaultButtonStyle: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.width = width
        self.appliesDefaultButtonStyle = appliesDefaultButtonStyle
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) {
                content
            }
            .frame(maxWidth: horizontalMaxWidth, alignment: horizontalFrameAlignment)

            VStack(alignment: stackAlignment, spacing: spacing) {
                content
            }
            .frame(maxWidth: .infinity, alignment: verticalFrameAlignment)
        }
        .modifier(ClearGlassAccessoryButtonStyle(appliesDefaultStyle: appliesDefaultButtonStyle))
    }

    private var horizontalMaxWidth: CGFloat? {
        switch width {
        case .compact:
            return nil
        case .flexible:
            return .infinity
        }
    }

    private var horizontalFrameAlignment: Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        default:
            return .trailing
        }
    }

    private var stackAlignment: HorizontalAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    private var verticalFrameAlignment: Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        default:
            return .trailing
        }
    }
}

private struct ClearGlassAccessoryButtonStyle: ViewModifier {
    let appliesDefaultStyle: Bool

    func body(content: Content) -> some View {
        if appliesDefaultStyle {
            content
                .buttonStyle(.bordered)
                .controlSize(.small)
        } else {
            content
        }
    }
}

enum ClearGlassRowIconStyle {
    case plain
    case tile

    var frameSize: CGFloat {
        switch self {
        case .plain:
            22
        case .tile:
            30
        }
    }

    var imageSize: CGFloat {
        switch self {
        case .plain:
            15
        case .tile:
            15
        }
    }

    var imageWeight: Font.Weight {
        switch self {
        case .plain:
            .regular
        case .tile:
            .medium
        }
    }
}

struct ClearGlassRowAnatomy<Accessory: View>: View {
    private let systemImage: String?
    private let iconTint: Color
    private let iconStyle: ClearGlassRowIconStyle
    private let title: String
    private let subtitle: String?
    private let titleFont: Font
    private let subtitleFont: Font
    private let subtitleLineLimit: Int
    private let statusText: String?
    private let statusStyle: ClearGlassStatusStyle
    private let accessoryAlignment: ClearGlassAccessoryClusterAlignment
    private let accessoryWidth: ClearGlassAccessoryClusterWidth
    private let accessorySpacing: CGFloat
    @ViewBuilder private let accessory: Accessory

    init(
        systemImage: String? = nil,
        iconTint: Color = .secondary,
        iconStyle: ClearGlassRowIconStyle = .plain,
        title: String,
        subtitle: String? = nil,
        titleFont: Font = .body,
        subtitleFont: Font = .callout,
        subtitleLineLimit: Int = 3,
        statusText: String? = nil,
        statusStyle: ClearGlassStatusStyle = .secondary,
        accessoryAlignment: ClearGlassAccessoryClusterAlignment = .trailing,
        accessoryWidth: ClearGlassAccessoryClusterWidth = .compact,
        accessorySpacing: CGFloat = 10,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.systemImage = systemImage
        self.iconTint = iconTint
        self.iconStyle = iconStyle
        self.title = title
        self.subtitle = subtitle
        self.titleFont = titleFont
        self.subtitleFont = subtitleFont
        self.subtitleLineLimit = subtitleLineLimit
        self.statusText = statusText
        self.statusStyle = statusStyle
        self.accessoryAlignment = accessoryAlignment
        self.accessoryWidth = accessoryWidth
        self.accessorySpacing = accessorySpacing
        self.accessory = accessory()
    }

    var body: some View {
        horizontalLayout
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: 12) {
            iconView

            labelContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Spacer(minLength: 16)

            trailingContent
                .fixedSize(horizontal: usesCompactAccessoryWidth, vertical: false)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let systemImage {
            switch iconStyle {
            case .plain:
                Image(systemName: systemImage)
                    .font(.system(size: iconStyle.imageSize, weight: iconStyle.imageWeight))
                    .foregroundStyle(iconTint)
                    .frame(width: iconStyle.frameSize, height: iconStyle.frameSize)
            case .tile:
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(iconTint.opacity(0.12))

                    Image(systemName: systemImage)
                        .font(.system(size: iconStyle.imageSize, weight: iconStyle.imageWeight))
                        .foregroundStyle(iconTint)
                }
                .frame(width: iconStyle.frameSize, height: iconStyle.frameSize)
            }
        }
    }

    private var labelContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(titleFont)
                .foregroundStyle(.primary)
                .lineLimit(2)

            if let subtitle {
                Text(subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(subtitleLineLimit)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var trailingContent: some View {
        ClearGlassAccessoryCluster(
            alignment: accessoryAlignment,
            spacing: accessorySpacing,
            width: accessoryWidth
        ) {
            if let statusText {
                ClearGlassStatusValue(text: statusText, style: statusStyle)
            }

            accessory
        }
    }

    private var usesCompactAccessoryWidth: Bool {
        switch accessoryWidth {
        case .compact:
            true
        case .flexible:
            false
        }
    }
}

extension ClearGlassRowAnatomy where Accessory == EmptyView {
    init(
        systemImage: String? = nil,
        iconTint: Color = .secondary,
        iconStyle: ClearGlassRowIconStyle = .plain,
        title: String,
        subtitle: String? = nil,
        titleFont: Font = .body,
        subtitleFont: Font = .callout,
        subtitleLineLimit: Int = 3,
        statusText: String? = nil,
        statusStyle: ClearGlassStatusStyle = .secondary
    ) {
        self.init(
            systemImage: systemImage,
            iconTint: iconTint,
            iconStyle: iconStyle,
            title: title,
            subtitle: subtitle,
            titleFont: titleFont,
            subtitleFont: subtitleFont,
            subtitleLineLimit: subtitleLineLimit,
            statusText: statusText,
            statusStyle: statusStyle
        ) {
            EmptyView()
        }
    }
}

struct ClearGlassActionStrip<Actions: View>: View {
    private let title: String
    private let subtitle: String?
    private let systemImage: String
    private let iconTint: Color
    private let statusText: String?
    private let statusStyle: ClearGlassStatusStyle
    @ViewBuilder private let actions: Actions

    init(
        _ title: String,
        subtitle: String? = nil,
        systemImage: String = "bolt",
        iconTint: Color = .accentColor,
        statusText: String? = nil,
        statusStyle: ClearGlassStatusStyle = .secondary,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconTint = iconTint
        self.statusText = statusText
        self.statusStyle = statusStyle
        self.actions = actions()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            verticalLayout
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .shadow(color: .black.opacity(0.035), radius: 5, x: 0, y: 1)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
        }
        .clearGlassInteractionFeedback(.surface, help: helpText)
    }

    private var helpText: String {
        let detail = subtitle.map { "\(title). \($0)" } ?? title
        if let statusText {
            return "\(detail) Status: \(statusText)."
        }

        return detail
    }

    private var horizontalLayout: some View {
        ClearGlassRowAnatomy(
            systemImage: systemImage,
            iconTint: iconTint,
            iconStyle: .tile,
            title: title,
            subtitle: subtitle,
            titleFont: .body.weight(.semibold),
            statusText: statusText,
            statusStyle: statusStyle,
            accessoryAlignment: .leading,
            accessoryWidth: .flexible
        ) {
            actionRow
        }
    }

    private var verticalLayout: some View {
        ClearGlassRowAnatomy(
            systemImage: systemImage,
            iconTint: iconTint,
            iconStyle: .tile,
            title: title,
            subtitle: subtitle,
            titleFont: .body.weight(.semibold),
            statusText: statusText,
            statusStyle: statusStyle,
            accessoryAlignment: .leading,
            accessoryWidth: .flexible
        ) {
            actionRow
        }
    }

    private var actionRow: some View {
        ClearGlassAccessoryCluster(
            alignment: .leading,
            width: .flexible,
            appliesDefaultButtonStyle: true
        ) {
            actions
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.26), lineWidth: 0.5)
        }
    }
}

struct ClearGlassControlRow<Accessory: View>: View {
    private let systemImage: String
    private let title: String
    private let subtitle: String?
    private let iconTint: Color
    @ViewBuilder private let accessory: Accessory

    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        iconTint: Color = .secondary,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.iconTint = iconTint
        self.accessory = accessory()
    }

    var body: some View {
        ClearGlassRowAnatomy(
            systemImage: systemImage,
            iconTint: iconTint,
            title: title,
            subtitle: subtitle
        ) {
            accessory
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clearGlassInteractionFeedback(.row, help: helpText)
    }

    private var helpText: String {
        subtitle.map { "\(title). \($0)" } ?? title
    }
}

extension ClearGlassControlRow where Accessory == EmptyView {
    init(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        iconTint: Color = .secondary
    ) {
        self.init(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: iconTint
        ) {
            EmptyView()
        }
    }
}

struct ClearGlassValueRow<ValueContent: View>: View {
    private let title: String
    private let subtitle: String?
    @ViewBuilder private let value: ValueContent

    init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder value: () -> ValueContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value()
    }

    var body: some View {
        ClearGlassRowAnatomy(
            title: title,
            subtitle: subtitle
        ) {
            value
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clearGlassInteractionFeedback(.row, help: helpText)
    }

    private var helpText: String {
        subtitle.map { "\(title). \($0)" } ?? title
    }
}

struct ClearGlassSliderRow: View {
    private let title: String
    private let subtitle: String?
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let valueSuffix: String
    private let valueFractionLength: Int
    private let valueWidth: CGFloat

    init(
        _ title: String,
        subtitle: String? = nil,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        valueSuffix: String = "",
        valueFractionLength: Int = 0,
        valueWidth: CGFloat = 58
    ) {
        self.title = title
        self.subtitle = subtitle
        _value = value
        self.range = range
        self.step = step
        self.valueSuffix = valueSuffix
        self.valueFractionLength = valueFractionLength
        self.valueWidth = valueWidth
    }

    var body: some View {
        ClearGlassRowAnatomy(
            title: title,
            subtitle: subtitle,
            accessoryAlignment: .leading
        ) {
            HStack(spacing: 12) {
                Slider(value: $value, in: range, step: step)
                    .frame(minWidth: 220, idealWidth: 300, maxWidth: 320)

                valueText
            }
        }
        .padding(.vertical, 7)
        .clearGlassInteractionFeedback(.row, help: helpText)
    }

    private var helpText: String {
        if let subtitle {
            return "\(title). \(subtitle) Current value: \(formattedValue)."
        }

        return "\(title). Current value: \(formattedValue)."
    }

    private var formattedValue: String {
        value.formatted(.number.precision(.fractionLength(valueFractionLength))) + valueSuffix
    }
    private var valueText: some View {
        Text(formattedValue)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: valueWidth, alignment: .trailing)
    }
}

struct ClearGlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.55))
            .frame(height: 0.5)
            .padding(.leading, 34)
    }
}

struct ClearGlassInlineMessage: View {
    let text: String
    var systemImage: String = "info.circle"
    var style: ClearGlassStatusStyle = .secondary

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(style.tint)
                .frame(width: 18)

            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.background, in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(style.border, lineWidth: 0.5)
        }
        .help(text)
    }
}

struct ClearGlassStatusValue: View {
    let text: String
    var style: ClearGlassStatusStyle = .secondary

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(style.tint)
                .frame(width: 8, height: 8)

            Text(text)
                .font(.callout)
                .foregroundStyle(style.foreground)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
        .help("Status: \(text)")
    }
}

struct KeyboardShortcutToken: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
            }
            .clearGlassInteractionFeedback(.token, help: "Keyboard shortcut: \(text)")
            .accessibilityLabel("Keyboard shortcut \(text)")
    }
}

struct CommandAvailabilityRow: View {
    let summary: MenuBarCommandAvailabilitySummary

    var body: some View {
        ClearGlassRowAnatomy(
            systemImage: summary.systemImage,
            iconTint: summary.tone.clearGlassTint,
            iconStyle: .tile,
            title: summary.title,
            subtitle: summary.detail,
            statusText: summary.statusText,
            statusStyle: summary.tone.clearGlassStyle
        )
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clearGlassInteractionFeedback(.row, help: "\(summary.title). \(summary.detail) Status: \(summary.statusText).")
    }
}

private extension MenuBarCommandAvailabilityTone {
    var clearGlassStyle: ClearGlassStatusStyle {
        switch self {
        case .success:
            .success
        case .warning:
            .warning
        case .danger:
            .danger
        case .info:
            .info
        case .secondary:
            .secondary
        }
    }

    var clearGlassTint: Color {
        clearGlassStyle.tint
    }
}

enum ClearGlassStatusStyle {
    case success
    case warning
    case danger
    case info
    case secondary

    var tint: Color {
        switch self {
        case .success:
            .green
        case .warning:
            .orange
        case .danger:
            .red
        case .info:
            .blue
        case .secondary:
            .secondary
        }
    }

    var foreground: Color {
        switch self {
        case .success:
            .green
        case .warning:
            .orange
        case .danger:
            .red
        case .info:
            .blue
        case .secondary:
            .secondary
        }
    }

    var background: Color {
        switch self {
        case .success:
            Color.green.opacity(0.08)
        case .warning:
            Color.orange.opacity(0.10)
        case .danger:
            Color.red.opacity(0.08)
        case .info:
            Color.accentColor.opacity(0.08)
        case .secondary:
            Color(nsColor: .quaternaryLabelColor).opacity(0.10)
        }
    }

    var border: Color {
        switch self {
        case .success:
            Color.green.opacity(0.22)
        case .warning:
            Color.orange.opacity(0.26)
        case .danger:
            Color.red.opacity(0.22)
        case .info:
            Color.accentColor.opacity(0.20)
        case .secondary:
            Color(nsColor: .separatorColor).opacity(0.45)
        }
    }
}

struct ClearGlassBadge: View {
    let style: ClearGlassBadgeStyle

    var body: some View {
        Label(style.title, systemImage: style.systemImage)
            .font(.caption)
            .foregroundStyle(style.tint)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(style.tint.opacity(0.08), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(style.tint.opacity(0.18), lineWidth: 0.5)
            }
            .help(style.helpText)
    }
}

enum ClearGlassBadgeStyle: Hashable {
    case basicMode
    case privacySafe
    case proMode
    case accessibilityRequired
    case optionalProOff
    case discoveryOff
    case permissionNeeded
    case ready
    case diagnostics
    case stable
    case preview
    case labs
    case experimental
    case unavailable
    case deferred
    case actionNeeded

    init(featureStatus: FeatureStatus) {
        switch featureStatus {
        case .stable:
            self = .stable
        case .preview:
            self = .preview
        case .labs:
            self = .labs
        case .experimental:
            self = .experimental
        case .disabled, .unavailable:
            self = .unavailable
        case .deferred:
            self = .deferred
        }
    }

    var title: String {
        switch self {
        case .basicMode:
            "Basic Mode"
        case .privacySafe:
            "Privacy Safe"
        case .proMode:
            "Optional Pro"
        case .accessibilityRequired:
            "Accessibility"
        case .optionalProOff:
            "Optional Pro Off"
        case .discoveryOff:
            "Discovery Off"
        case .permissionNeeded:
            "Needs Permission"
        case .ready:
            "Ready"
        case .diagnostics:
            "Diagnostics"
        case .stable:
            FeatureStatus.stable.title
        case .preview:
            FeatureStatus.preview.title
        case .labs:
            FeatureStatus.labs.title
        case .experimental:
            FeatureStatus.labs.title
        case .unavailable:
            FeatureStatus.unavailable.title
        case .deferred:
            FeatureStatus.deferred.title
        case .actionNeeded:
            "Action Needed"
        }
    }

    var systemImage: String {
        switch self {
        case .basicMode:
            "checkmark.shield"
        case .privacySafe:
            "shield.lefthalf.filled"
        case .proMode:
            "star"
        case .accessibilityRequired:
            "figure.circle"
        case .optionalProOff:
            "star.slash"
        case .discoveryOff:
            "eye.slash"
        case .permissionNeeded:
            "hand.raised"
        case .ready:
            "checkmark.circle"
        case .diagnostics:
            "waveform.path.ecg"
        case .stable:
            FeatureStatus.stable.systemImage
        case .preview:
            FeatureStatus.preview.systemImage
        case .labs:
            FeatureStatus.labs.systemImage
        case .experimental:
            FeatureStatus.labs.systemImage
        case .unavailable:
            FeatureStatus.unavailable.systemImage
        case .deferred:
            FeatureStatus.deferred.systemImage
        case .actionNeeded:
            "exclamationmark.circle"
        }
    }

    var tint: Color {
        switch self {
        case .basicMode, .privacySafe:
            .green
        case .proMode:
            .accentColor
        case .accessibilityRequired:
            DesignTokens.SemanticTone.permissionRequired.foregroundStyle
        case .optionalProOff:
            .secondary
        case .discoveryOff:
            .orange
        case .permissionNeeded:
            DesignTokens.SemanticTone.permissionRequired.foregroundStyle
        case .ready:
            .green
        case .diagnostics:
            .secondary
        case .stable:
            FeatureStatus.stable.tint
        case .preview:
            FeatureStatus.preview.tint
        case .labs:
            FeatureStatus.labs.tint
        case .experimental:
            FeatureStatus.labs.tint
        case .unavailable:
            FeatureStatus.unavailable.tint
        case .deferred:
            FeatureStatus.deferred.tint
        case .actionNeeded:
            .red
        }
    }

    var helpText: String {
        switch self {
        case .basicMode:
            "Basic Mode: available without elevated permissions."
        case .privacySafe:
            "Privacy Safe: local-first behavior without network access."
        case .proMode:
            "Optional Pro capability."
        case .accessibilityRequired:
            "Requires Accessibility permission before use."
        case .optionalProOff:
            "Optional Pro is off."
        case .discoveryOff:
            "Discovery is off."
        case .permissionNeeded:
            "Permission is needed before this capability can run."
        case .ready:
            "Ready to use."
        case .diagnostics:
            "Diagnostics information."
        case .stable:
            FeatureStatus.stable.summary
        case .preview:
            FeatureStatus.preview.summary
        case .labs:
            FeatureStatus.labs.summary
        case .experimental:
            FeatureStatus.labs.summary
        case .unavailable:
            FeatureStatus.unavailable.summary
        case .deferred:
            FeatureStatus.deferred.summary
        case .actionNeeded:
            "Action is needed before this item is ready."
        }
    }
}

private struct ClearGlassPageHeader: View {
    let title: String
    let subtitle: String?
    let badges: [ClearGlassBadgeStyle]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    titleText
                    badgeStrip
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 6) {
                    titleText
                    badgeStrip
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var titleText: some View {
        Text(title)
            .font(.largeTitle)
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var badgeStrip: some View {
        if !visibleBadges.isEmpty {
            HStack(spacing: 7) {
                ForEach(visibleBadges, id: \.self) { badge in
                    ClearGlassBadge(style: badge)
                }
            }
        }
    }

    private var visibleBadges: [ClearGlassBadgeStyle] {
        let actionable = badges
            .filter { !$0.isQuietHeaderBadge }
            .sorted { $0.headerPriority < $1.headerPriority }

        if !actionable.isEmpty {
            return Array(actionable.prefix(1))
        }

        for preferred in [ClearGlassBadgeStyle.basicMode, .privacySafe, .stable] where badges.contains(preferred) {
            return [preferred]
        }

        return Array(badges.prefix(1))
    }
}

private extension ClearGlassBadgeStyle {
    var isQuietHeaderBadge: Bool {
        switch self {
        case .basicMode, .privacySafe, .stable:
            true
        case .proMode,
             .accessibilityRequired,
             .optionalProOff,
             .discoveryOff,
             .permissionNeeded,
             .ready,
             .diagnostics,
             .preview,
             .labs,
             .experimental,
             .unavailable,
             .deferred,
             .actionNeeded:
            false
        }
    }

    var headerPriority: Int {
        switch self {
        case .actionNeeded:
            0
        case .permissionNeeded:
            1
        case .discoveryOff:
            2
        case .optionalProOff:
            3
        case .accessibilityRequired:
            4
        case .proMode:
            5
        case .labs:
            6
        case .experimental:
            7
        case .preview:
            8
        case .ready:
            9
        case .unavailable:
            10
        case .deferred:
            11
        case .diagnostics:
            12
        case .basicMode, .privacySafe, .stable:
            20
        }
    }
}

extension ClearGlassBadgeStyle {
    static func optionalProDiscovery(
        proModeEnabled: Bool,
        accessibilityDiscoveryEnabled: Bool,
        accessibilityPermissionStatus: AccessibilityPermissionStatus?
    ) -> ClearGlassBadgeStyle {
        guard proModeEnabled else {
            return .optionalProOff
        }

        guard accessibilityDiscoveryEnabled else {
            return .discoveryOff
        }

        guard accessibilityPermissionStatus == .granted else {
            return .permissionNeeded
        }

        return .ready
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
