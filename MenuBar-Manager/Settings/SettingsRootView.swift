import Observation
import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general
    case behavior
    case search
    case secondBar
    case profiles
    case privacy
    case diagnostics
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            "General"
        case .behavior:
            "Behavior"
        case .search:
            "Search"
        case .secondBar:
            "Second Bar"
        case .profiles:
            "Profiles"
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
        case .behavior:
            "wand.and.rays"
        case .search:
            "magnifyingglass"
        case .secondBar:
            "menubar.rectangle"
        case .profiles:
            "person.crop.rectangle.stack"
        case .privacy:
            "hand.raised"
        case .diagnostics:
            "stethoscope"
        case .advanced:
            "wrench.and.screwdriver"
        }
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
    var accessibilityPermissionService: AccessibilityPermissionService?
    var menuBarScanCoordinator: MenuBarScanCoordinator?
    var profileStore: ProfileStore?
    var triggerService: TriggerService?
    var onBehaviorChanged: (() -> Void)? = nil
    var onSearchChanged: (() -> Void)? = nil
    var onSecondBarChanged: (() -> Void)? = nil
    var onPrivacyChanged: (() -> Void)? = nil
    var onProfileDryRun: ((ProfileModel) -> ProfileApplicationDryRun)? = nil
    var onProfileApply: ((ProfileModel) -> ProfileApplicationDryRun)? = nil
    var onTriggersChanged: (() -> Void)? = nil
    var onResetLayout: (() -> Void)? = nil
    var onResetAllSettings: (() -> Void)? = nil
    var onResetMovingWarnings: (() -> Void)? = nil
    var onShowOnboarding: (() -> Void)? = nil
    var onRunHealthCheck: (() -> Void)? = nil
    var onFixHealthIssues: (() -> Void)? = nil
    var onResetBasicMode: (() -> Void)? = nil
    var onDisableProMode: (() -> Void)? = nil
    var onEnterSafeModeNextLaunch: (() -> Void)? = nil

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $navigationModel.selectedSection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Settings")
            .frame(minWidth: 180)
        } detail: {
            detailView(for: navigationModel.selectedSection ?? .general)
                .navigationTitle((navigationModel.selectedSection ?? .general).title)
        }
        .frame(minWidth: 720, minHeight: 480)
    }

    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        switch section {
        case .general:
            GeneralSettingsView(
                settingsStore: settingsStore,
                launchAtLoginService: launchAtLoginService,
                onResetLayout: onResetLayout,
                onResetAllSettings: onResetAllSettings,
                onShowOnboarding: onShowOnboarding
            )
        case .behavior:
            BehaviorSettingsView(settingsStore: settingsStore, onChange: onBehaviorChanged)
        case .search:
            SearchSettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                onChange: onSearchChanged,
                onOpenPrivacySettings: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .secondBar:
            SecondBarSettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                onChange: onSecondBarChanged,
                onOpenPrivacySettings: {
                    navigationModel.selectedSection = .privacy
                }
            )
        case .profiles:
            if let profileStore,
               let triggerService,
               let liveStatus,
               let onProfileDryRun,
               let onProfileApply {
                ProfileListView(
                    profileStore: profileStore,
                    triggerService: triggerService,
                    settingsStore: settingsStore,
                    liveStatus: liveStatus,
                    onDryRun: onProfileDryRun,
                    onApply: onProfileApply,
                    onTriggersChanged: onTriggersChanged ?? {}
                )
            } else {
                ContentUnavailableView("Profiles Unavailable", systemImage: "person.crop.rectangle.stack")
            }
        case .privacy:
            PrivacySettingsView(
                settingsStore: settingsStore,
                permissionService: accessibilityPermissionService,
                scanCoordinator: menuBarScanCoordinator,
                onChange: onPrivacyChanged
            )
        case .diagnostics:
            DiagnosticsSettingsView(
                diagnosticsLogger: diagnosticsLogger,
                liveStatus: liveStatus,
                appSupportPaths: appSupportPaths,
                exporter: diagnosticsExporter,
                settingsStore: settingsStore,
                launchAtLoginService: launchAtLoginService,
                scanCoordinator: menuBarScanCoordinator,
                onRunHealthCheck: onRunHealthCheck,
                onFixHealthIssues: onFixHealthIssues,
                onResetBasicMode: onResetBasicMode,
                onDisableProMode: onDisableProMode,
                onEnterSafeModeNextLaunch: onEnterSafeModeNextLaunch
            )
        case .advanced:
            AdvancedSettingsView(
                settingsStore: settingsStore,
                appSupportPaths: appSupportPaths,
                onChange: onBehaviorChanged,
                onAutomationChanged: onTriggersChanged,
                onResetMovingWarnings: onResetMovingWarnings
            )
        }
    }
}

#Preview {
    SettingsRootView(
        navigationModel: SettingsNavigationModel(),
        settingsStore: SettingsStore(),
        diagnosticsLogger: DiagnosticsLogger(),
        liveStatus: nil,
        appSupportPaths: AppSupportPaths(),
        diagnosticsExporter: DiagnosticsExporter()
    )
}
