import AppKit
import Observation
import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
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
    case diagnostics
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            "General"
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
        case .diagnostics:
            "Diagnostics"
        case .advanced:
            "Advanced"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            "gearshape"
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
        case .diagnostics:
            "waveform.path.ecg"
        case .advanced:
            "chevron.left.forwardslash.chevron.right"
        }
    }
}

private struct SettingsSidebarGroup: Identifiable {
    let title: String
    let sections: [SettingsSection]

    var id: String { title }

    static let all: [SettingsSidebarGroup] = [
        SettingsSidebarGroup(title: "General", sections: [.general, .menuBarItems, .behavior, .layout]),
        SettingsSidebarGroup(title: "Pro Features", sections: [.search, .secondBar, .groups, .hotkeys, .profiles, .automation]),
        SettingsSidebarGroup(title: "Privacy", sections: [.privacy, .privateAccess]),
        SettingsSidebarGroup(title: "System", sections: [.importExport, .diagnostics, .advanced])
    ]
}

private extension SettingsSection {
    var helpText: String {
        switch self {
        case .general:
            "Startup, onboarding, app mode, and app identity."
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
            "Basic Mode, Pro Mode, permissions, and local data policy."
        case .diagnostics:
            "Health checks, logs, live status, and diagnostics export."
        case .advanced:
            "Developer-oriented recovery and experimental controls."
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
    var accessibilityPermissionService: AccessibilityPermissionService?
    var menuBarScanCoordinator: MenuBarScanCoordinator?
    var profileStore: ProfileStore?
    var triggerService: TriggerService?
    var layoutCoordinator: LayoutCoordinator?
    var groupStore: IconGroupStore?
    var hotkeyBindingStore: HotkeyBindingStore?
    var privateAccessCoordinator: PrivateAccessCoordinator?
    var actions: SettingsActions = .empty
    @State private var settingsSearchText = ""

    var body: some View {
        NavigationSplitView {
            List(selection: $navigationModel.selectedSection) {
                ForEach(filteredSidebarGroups) { group in
                    Section(group.title) {
                        ForEach(group.sections) { section in
                            Label(section.title, systemImage: section.systemImage)
                                .tag(section)
                                .help(section.helpText)
                                .accessibilityIdentifier(section.sidebarAccessibilityIdentifier)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
            .searchable(text: $settingsSearchText, prompt: "Search Settings")
            .navigationSplitViewColumnWidth(min: 220, ideal: 246, max: 290)
        } detail: {
            detailView(for: selectedSection)
                .accessibilityIdentifier(selectedSection.pageAccessibilityIdentifier)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 980, minHeight: 620)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            navigationModel.selectedSection = navigationModel.selectedSection ?? .general
        }
    }

    private var selectedSection: SettingsSection {
        navigationModel.selectedSection ?? .general
    }

    private var filteredSidebarGroups: [SettingsSidebarGroup] {
        let query = settingsSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SettingsSidebarGroup.all }

        return SettingsSidebarGroup.all.compactMap { group in
            let sections = group.sections.filter { section in
                section.title.localizedStandardContains(query)
                    || section.searchKeywords.localizedStandardContains(query)
            }
            guard !sections.isEmpty else { return nil }
            return SettingsSidebarGroup(title: group.title, sections: sections)
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
        case .menuBarItems:
            MenuBarItemsSettingsView(
                settingsStore: settingsStore,
                liveStatus: liveStatus,
                scanCoordinator: menuBarScanCoordinator,
                onOpenPrivacySettings: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .behavior:
            BehaviorSettingsView(settingsStore: settingsStore, onChange: actions.behaviorChanged)
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
                        ContentUnavailableView("Groups Unavailable", systemImage: "person.2")
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
                        ContentUnavailableView("Hotkeys Unavailable", systemImage: "keyboard")
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
                        ContentUnavailableView("Profiles Unavailable", systemImage: "person.crop.rectangle.stack")
                            .frame(maxWidth: .infinity, minHeight: 220)
                    }
                }
            }
        case .privacy:
            PrivacySettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                scanCoordinator: menuBarScanCoordinator,
                onChange: actions.privacyChanged
            )
        case .automation:
            AutomationSettingsView(
                settingsStore: settingsStore,
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
                onEnterSafeModeNextLaunch: actions.enterSafeModeNextLaunch
            )
        case .advanced:
            AdvancedSettingsView(
                settingsStore: settingsStore,
                appSupportPaths: appSupportPaths,
                onChange: actions.behaviorChanged,
                onAutomationChanged: actions.triggersChanged,
                onResetMovingWarnings: actions.resetMovingWarnings
            )
        }
    }

    private func commandSummary(for command: MenuBarCommand) -> MenuBarCommandAvailabilitySummary? {
        guard let availability = actions.commandAvailability?(command) else {
            return nil
        }
        return MenuBarCommandAvailabilitySummary(command: command, availability: availability)
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

private extension SettingsSection {
    var pageAccessibilityIdentifier: String {
        "settings.page.\(rawValue)"
    }

    var sidebarAccessibilityIdentifier: String {
        "settings.sidebar.\(rawValue)"
    }
}

struct ClearGlassSettingsPage<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let badges: [ClearGlassBadgeStyle]
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        badges: [ClearGlassBadgeStyle] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badges = badges
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ClearGlassPageHeader(title: title, subtitle: subtitle, badges: badges)
                content
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 36)
            .frame(maxWidth: 980, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .accessibilityIdentifier("settings.page.scroll")
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct ClearGlassSection<Content: View>: View {
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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

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
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(iconTint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 16)

            accessory
                .fixedSize()
                .layoutPriority(1)
        }
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 16)

            value
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)

                if let subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 180, alignment: .leading)

            Spacer(minLength: 16)

            Slider(value: $value, in: range, step: step)
                .frame(maxWidth: 320)

            Text(formattedValue)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: valueWidth, alignment: .trailing)
        }
        .padding(.vertical, 9)
    }

    private var formattedValue: String {
        value.formatted(.number.precision(.fractionLength(valueFractionLength))) + valueSuffix
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
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.background, in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(style.border, lineWidth: 0.5)
        }
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
    }
}

struct CommandAvailabilityRow: View {
    let summary: MenuBarCommandAvailabilitySummary

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: summary.systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(summary.tone.clearGlassTint)
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 5) {
                Text(summary.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ClearGlassStatusValue(
                    text: summary.statusText,
                    style: summary.tone.clearGlassStyle
                )

                Text(summary.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
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
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(style.tint.opacity(0.08), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(style.tint.opacity(0.18), lineWidth: 0.5)
            }
    }
}

enum ClearGlassBadgeStyle: Hashable {
    case basicMode
    case privacySafe
    case proMode
    case accessibilityRequired
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
            "Pro Mode"
        case .accessibilityRequired:
            "Accessibility Required"
        case .diagnostics:
            "Diagnostics"
        case .stable:
            FeatureStatus.stable.title
        case .preview:
            FeatureStatus.preview.title
        case .labs:
            FeatureStatus.labs.title
        case .experimental:
            FeatureStatus.experimental.title
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
        case .diagnostics:
            "waveform.path.ecg"
        case .stable:
            FeatureStatus.stable.systemImage
        case .preview:
            FeatureStatus.preview.systemImage
        case .labs:
            FeatureStatus.labs.systemImage
        case .experimental:
            FeatureStatus.experimental.systemImage
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
            .primary
        case .accessibilityRequired:
            .orange
        case .diagnostics:
            .secondary
        case .stable:
            FeatureStatus.stable.tint
        case .preview:
            FeatureStatus.preview.tint
        case .labs:
            FeatureStatus.labs.tint
        case .experimental:
            FeatureStatus.experimental.tint
        case .unavailable:
            FeatureStatus.unavailable.tint
        case .deferred:
            FeatureStatus.deferred.tint
        case .actionNeeded:
            .red
        }
    }
}

private struct ClearGlassPageHeader: View {
    let title: String
    let subtitle: String?
    let badges: [ClearGlassBadgeStyle]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle)
                .foregroundStyle(.primary)

            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !badges.isEmpty {
                HStack(spacing: 8) {
                    ForEach(badges, id: \.self) { badge in
                        ClearGlassBadge(style: badge)
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
