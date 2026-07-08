import AppKit
import SwiftUI

struct AutomationSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var accessibilityPermissionService: AccessibilityPermissionService?
    var screenCapturePermissionService: ScreenCapturePermissionService?
    var onChange: (() -> Void)?

    private var readyShortcutCount: Int {
        shortcutStatuses.filter { $0 == .ready }.count
    }

    private var reviewShortcutCount: Int {
        AutomationShortcutAction.allActions.count - readyShortcutCount
    }

    private var shortcutStatuses: [AutomationShortcutStatus] {
        AutomationShortcutAction.allActions.map(status)
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Automation",
            subtitle: "Configure App Shortcuts and automation boundaries.",
            badges: [.preview, .privacySafe],
            style: .tool,
            sectionAnchors: [
                ClearGlassPageAnchor("App Shortcuts", systemImage: "link"),
                ClearGlassPageAnchor("Shortcut Actions", systemImage: "list.bullet.rectangle"),
                ClearGlassPageAnchor("Safety", systemImage: "checkmark.shield")
            ]
        ) {
            AutomationOverviewStrip(
                appIntentsEnabled: settingsStore.appIntentsEnabled,
                canApplyProfiles: settingsStore.appIntentsCanApplyProfiles,
                canAccessLabs: settingsStore.appIntentsCanAccessLabs,
                readyActionCount: readyShortcutCount,
                reviewActionCount: reviewShortcutCount
            )

            ClearGlassSection("App Shortcuts", subtitle: "Expose privacy-safe app actions to Shortcuts.") {
                VStack(alignment: .leading, spacing: 12) {
                    FeatureGateNotice(
                        .preview,
                        text: "Preview in v0.1.3. Actions honor Safe Mode, pause, Pro, Private Access, and Labs gates."
                    )

                    AutomationControlsPanel(
                        appIntentsEnabled: $settingsStore.appIntentsEnabled,
                        canApplyProfiles: $settingsStore.appIntentsCanApplyProfiles,
                        canAccessLabs: $settingsStore.appIntentsCanAccessLabs,
                        onChange: notifyChange,
                        onOpenShortcuts: openShortcuts
                    )
                }
            }

            ClearGlassSection("Shortcut Actions", subtitle: "Review which App Shortcut commands are ready, gated, or disabled.") {
                AutomationShortcutActionList(
                    actions: AutomationShortcutAction.allActions,
                    appIntentsEnabled: settingsStore.appIntentsEnabled,
                    proModeEnabled: settingsStore.proModeEnabled,
                    accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
                    accessibilityGranted: accessibilityPermissionService?.status == .granted,
                    accurateIconsEnabled: settingsStore.renderedIconCaptureEnabled,
                    screenRecordingGranted: screenCapturePermissionService?.status == .granted,
                    canApplyProfiles: settingsStore.appIntentsCanApplyProfiles,
                    canAccessLabs: settingsStore.appIntentsCanAccessLabs,
                    spacingLabsEnabled: settingsStore.menuBarSpacingLabsEnabled
                )
            }

            ClearGlassSection("Safety") {
                AutomationSafetyChecklist()
            }
        }
    }

    private func status(for action: AutomationShortcutAction) -> AutomationShortcutStatus {
        action.status(
            appIntentsEnabled: settingsStore.appIntentsEnabled,
            proModeEnabled: settingsStore.proModeEnabled,
            accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
            accessibilityGranted: accessibilityPermissionService?.status == .granted,
            accurateIconsEnabled: settingsStore.renderedIconCaptureEnabled,
            screenRecordingGranted: screenCapturePermissionService?.status == .granted,
            canApplyProfiles: settingsStore.appIntentsCanApplyProfiles,
            canAccessLabs: settingsStore.appIntentsCanAccessLabs,
            spacingLabsEnabled: settingsStore.menuBarSpacingLabsEnabled
        )
    }

    private func notifyChange() {
        onChange?()
    }

    private func openShortcuts() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Shortcuts.app"))
    }
}

private struct AutomationOverviewStrip: View {
    let appIntentsEnabled: Bool
    let canApplyProfiles: Bool
    let canAccessLabs: Bool
    let readyActionCount: Int
    let reviewActionCount: Int

    var body: some View {
        ClearGlassOverviewStrip([
            ClearGlassOverviewMetric(
                title: "App Intents",
                value: appIntentsEnabled ? "On" : "Off",
                systemImage: appIntentsEnabled ? "checkmark.circle" : "minus.circle",
                style: appIntentsEnabled ? .success : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Profiles",
                value: canApplyProfiles && appIntentsEnabled ? "Allowed" : "Gated",
                systemImage: "person.crop.rectangle.stack",
                style: canApplyProfiles && appIntentsEnabled ? .success : .warning
            ),
            ClearGlassOverviewMetric(
                title: "Labs",
                value: canAccessLabs && appIntentsEnabled ? "Allowed" : "Gated",
                systemImage: "testtube.2",
                style: canAccessLabs && appIntentsEnabled ? .success : .warning
            ),
            ClearGlassOverviewMetric(
                title: "Actions",
                value: reviewActionCount == 0 ? "\(readyActionCount) Ready" : "\(readyActionCount) / \(readyActionCount + reviewActionCount)",
                systemImage: reviewActionCount == 0 ? "checkmark.shield" : "exclamationmark.triangle",
                style: reviewActionCount == 0 ? .success : .warning
            )
        ])
    }
}

private struct AutomationControlsPanel: View {
    @Binding var appIntentsEnabled: Bool
    @Binding var canApplyProfiles: Bool
    @Binding var canAccessLabs: Bool

    let onChange: () -> Void
    let onOpenShortcuts: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ClearGlassGroupedList("Availability") {
                ClearGlassStatusControlRow(
                    systemImage: "link",
                    title: "Enable App Intents",
                    subtitle: "Expose MenuBarDeclutter actions to Shortcuts without Apple Events permission or other-app control.",
                    statusText: appIntentsEnabled ? "Enabled" : "Off",
                    statusStyle: appIntentsEnabled ? .success : .secondary,
                    isDimmed: false
                ) {
                    Toggle("Enable App Intents", isOn: $appIntentsEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .onChange(of: appIntentsEnabled) { _, _ in onChange() }
                }

                ClearGlassDivider()

                ClearGlassStatusControlRow(
                    systemImage: "person.crop.rectangle.stack",
                    title: "Allow Profile Apply",
                    subtitle: "Let App Shortcuts apply profiles when automation is not paused.",
                    statusText: profileStatusText,
                    statusStyle: profileStatusStyle,
                    isDimmed: !appIntentsEnabled
                ) {
                    Toggle("Allow Profile Apply", isOn: $canApplyProfiles)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .disabled(!appIntentsEnabled)
                        .onChange(of: canApplyProfiles) { _, _ in onChange() }
                }

                ClearGlassDivider()

                ClearGlassStatusControlRow(
                    systemImage: "testtube.2",
                    title: "Allow Labs Access",
                    subtitle: "Allow App Shortcuts to request Labs features. Labs settings remain gated.",
                    statusText: labsStatusText,
                    statusStyle: labsStatusStyle,
                    isDimmed: !appIntentsEnabled
                ) {
                    Toggle("Allow Labs Access", isOn: $canAccessLabs)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .disabled(!appIntentsEnabled)
                        .onChange(of: canAccessLabs) { _, _ in onChange() }
                }
            }

            ClearGlassGroupedList("Shortcuts App") {
                ClearGlassStatusControlRow(
                    systemImage: "arrow.up.right.square",
                    title: "Open Shortcuts",
                    subtitle: "Open Apple's Shortcuts app to inspect or run MenuBarDeclutter actions.",
                    statusText: appIntentsEnabled ? "Ready" : "Configure",
                    statusStyle: appIntentsEnabled ? .success : .secondary
                ) {
                    Button("Open Shortcuts", systemImage: "arrow.up.right.square", action: onOpenShortcuts)
                        .controlSize(.small)
                }
            }
        }
    }

    private var profileStatusText: String {
        guard appIntentsEnabled else { return "Off" }
        return canApplyProfiles ? "Allowed" : "Blocked"
    }

    private var profileStatusStyle: ClearGlassStatusStyle {
        guard appIntentsEnabled else { return .secondary }
        return canApplyProfiles ? .success : .warning
    }

    private var labsStatusText: String {
        guard appIntentsEnabled else { return "Off" }
        return canAccessLabs ? "Allowed" : "Blocked"
    }

    private var labsStatusStyle: ClearGlassStatusStyle {
        guard appIntentsEnabled else { return .secondary }
        return canAccessLabs ? .success : .warning
    }
}

private struct AutomationShortcutActionList: View {
    let actions: [AutomationShortcutAction]
    let appIntentsEnabled: Bool
    let proModeEnabled: Bool
    let accessibilityDiscoveryEnabled: Bool
    let accessibilityGranted: Bool
    let accurateIconsEnabled: Bool
    let screenRecordingGranted: Bool
    let canApplyProfiles: Bool
    let canAccessLabs: Bool
    let spacingLabsEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Label("Available Actions", systemImage: "list.bullet.rectangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                ClearGlassStatusValue(text: actionSummaryText, style: actionSummaryStyle)
            }

            VStack(spacing: 0) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    AutomationShortcutActionRow(
                        action: action,
                        status: action.status(
                            appIntentsEnabled: appIntentsEnabled,
                            proModeEnabled: proModeEnabled,
                            accessibilityDiscoveryEnabled: accessibilityDiscoveryEnabled,
                            accessibilityGranted: accessibilityGranted,
                            accurateIconsEnabled: accurateIconsEnabled,
                            screenRecordingGranted: screenRecordingGranted,
                            canApplyProfiles: canApplyProfiles,
                            canAccessLabs: canAccessLabs,
                            spacingLabsEnabled: spacingLabsEnabled
                        )
                    )

                    if index != actions.count - 1 {
                        ClearGlassDivider()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
            }
        }
    }

    private var readyCount: Int {
        actions.filter {
            $0.status(
                appIntentsEnabled: appIntentsEnabled,
                proModeEnabled: proModeEnabled,
                accessibilityDiscoveryEnabled: accessibilityDiscoveryEnabled,
                accessibilityGranted: accessibilityGranted,
                accurateIconsEnabled: accurateIconsEnabled,
                screenRecordingGranted: screenRecordingGranted,
                canApplyProfiles: canApplyProfiles,
                canAccessLabs: canAccessLabs,
                spacingLabsEnabled: spacingLabsEnabled
            ) == .ready
        }
        .count
    }

    private var actionSummaryText: String {
        appIntentsEnabled ? "\(readyCount) Ready" : "Disabled"
    }

    private var actionSummaryStyle: ClearGlassStatusStyle {
        guard appIntentsEnabled else { return .secondary }
        return readyCount == actions.count ? .success : .warning
    }
}

private struct AutomationShortcutActionRow: View {
    let action: AutomationShortcutAction
    let status: AutomationShortcutStatus

    var body: some View {
        ClearGlassRowAnatomy(
            systemImage: action.systemImage,
            iconTint: status.clearGlassStyle.tint,
            iconStyle: .tile,
            title: action.title,
            subtitle: action.detailText,
            subtitleFont: .caption,
            subtitleLineLimit: 2,
            statusText: status.displayName,
            statusStyle: status.clearGlassStyle
        )
        .padding(.vertical, 8)
        .opacity(status == .disabled ? 0.62 : 1)
    }
}

private struct AutomationSafetyChecklist: View {
    var body: some View {
        ClearGlassGroupedList("Privacy Boundary") {
            ClearGlassStatusControlRow(
                systemImage: "checkmark.shield",
                title: "No Apple Events Permission",
                subtitle: "App Shortcuts use App Intents and do not script or control other apps.",
                iconTint: ClearGlassStatusStyle.success.tint,
                statusStyle: .success
            )

            ClearGlassDivider()

            ClearGlassStatusControlRow(
                systemImage: "network.slash",
                title: "No Network Access",
                subtitle: "Automation settings stay local and do not add network behavior.",
                iconTint: ClearGlassStatusStyle.success.tint,
                statusStyle: .success
            )

            ClearGlassDivider()

            ClearGlassStatusControlRow(
                systemImage: "lock.circle",
                title: "Gate-aware Execution",
                subtitle: "Safe Mode, automation pause, Private Access, Pro requirements, and Labs requirements are still enforced.",
                iconTint: ClearGlassStatusStyle.info.tint,
                statusStyle: .info
            )
        }
    }
}

struct AutomationShortcutAction: Identifiable, Equatable, Sendable {
    enum Gate: Equatable, Sendable {
        case none
        case findIcon
        case proDiscovery
        case secondBarReadiness
        case profileApply
        case spacingLabs
    }

    let title: String
    let gate: Gate

    var id: String { title }

    static let expandMenuBarItems = AutomationShortcutAction(title: "Expand Menu Bar Items", gate: .none)
    static let collapseMenuBarItems = AutomationShortcutAction(title: "Collapse Menu Bar Items", gate: .none)
    static let revealAllMenuBarItems = AutomationShortcutAction(title: "Reveal All Menu Bar Items", gate: .none)
    static let showFindIcon = AutomationShortcutAction(title: "Show Find Icon", gate: .findIcon)
    static let showSecondBar = AutomationShortcutAction(title: "Show Second Bar", gate: .secondBarReadiness)
    static let hideSecondBar = AutomationShortcutAction(title: "Hide Second Bar", gate: .none)
    static let enterFullMenuBarMode = AutomationShortcutAction(title: "Enter Full Menu Bar Mode", gate: .none)
    static let exitFullMenuBarMode = AutomationShortcutAction(title: "Exit Full Menu Bar Mode", gate: .none)
    static let applyProfile = AutomationShortcutAction(title: "Apply Profile", gate: .profileApply)
    static let pauseAutomation = AutomationShortcutAction(title: "Pause Automation", gate: .none)
    static let resumeAutomation = AutomationShortcutAction(title: "Resume Automation", gate: .none)
    static let previewLayoutSpacingPreset = AutomationShortcutAction(title: "Preview Layout Spacing Preset", gate: .spacingLabs)

    static let allActions: [AutomationShortcutAction] = [
        .expandMenuBarItems,
        .collapseMenuBarItems,
        .revealAllMenuBarItems,
        .showFindIcon,
        .showSecondBar,
        .hideSecondBar,
        .enterFullMenuBarMode,
        .exitFullMenuBarMode,
        .applyProfile,
        .pauseAutomation,
        .resumeAutomation,
        .previewLayoutSpacingPreset
    ]

    func status(
        appIntentsEnabled: Bool,
        proModeEnabled: Bool = true,
        accessibilityDiscoveryEnabled: Bool = true,
        accessibilityGranted: Bool = true,
        accurateIconsEnabled: Bool = true,
        screenRecordingGranted: Bool = true,
        canApplyProfiles: Bool,
        canAccessLabs: Bool,
        spacingLabsEnabled: Bool
    ) -> AutomationShortcutStatus {
        guard appIntentsEnabled else {
            return .disabled
        }

        switch gate {
        case .none:
            return .ready
        case .findIcon:
            guard proModeEnabled else {
                return .proGated
            }
            guard accessibilityDiscoveryEnabled else {
                return .discoveryGated
            }
            return .ready
        case .proDiscovery:
            guard proModeEnabled else {
                return .proGated
            }
            return accessibilityDiscoveryEnabled ? .ready : .discoveryGated
        case .secondBarReadiness:
            guard proModeEnabled else {
                return .proGated
            }
            guard accessibilityDiscoveryEnabled else {
                return .discoveryGated
            }
            guard accessibilityGranted else {
                return .accessibilityPermissionGated
            }
            guard accurateIconsEnabled else {
                return .accurateIconsGated
            }
            return screenRecordingGranted ? .ready : .screenRecordingGated
        case .profileApply:
            return canApplyProfiles ? .ready : .profileGated
        case .spacingLabs:
            guard canAccessLabs else {
                return .labsGated
            }
            return spacingLabsEnabled ? .ready : .requiresLabs
        }
    }
}

private extension AutomationShortcutAction {
    var systemImage: String {
        switch title {
        case Self.expandMenuBarItems.title:
            "arrow.up.left.and.arrow.down.right"
        case Self.collapseMenuBarItems.title:
            "arrow.down.right.and.arrow.up.left"
        case Self.revealAllMenuBarItems.title:
            "eye"
        case Self.showFindIcon.title:
            "magnifyingglass"
        case Self.showSecondBar.title:
            "rectangle.bottomthird.inset.filled"
        case Self.hideSecondBar.title:
            "rectangle.compress.vertical"
        case Self.enterFullMenuBarMode.title:
            "menubar.rectangle"
        case Self.exitFullMenuBarMode.title:
            "menubar.dock.rectangle"
        case Self.applyProfile.title:
            "person.crop.rectangle.stack"
        case Self.pauseAutomation.title:
            "pause.circle"
        case Self.resumeAutomation.title:
            "play.circle"
        case Self.previewLayoutSpacingPreset.title:
            "testtube.2"
        default:
            "sparkles"
        }
    }

    var detailText: String {
        switch gate {
        case .none:
            "Available when App Intents are enabled and global safety gates permit execution."
        case .findIcon:
            "Requires Optional Pro Discovery; status-menu visibility does not block the shortcut."
        case .proDiscovery:
            "Requires Optional Pro Discovery; Accessibility permission is checked when the shortcut runs."
        case .secondBarReadiness:
            "Requires Optional Pro, Accessibility Discovery, Accessibility permission, Accurate Icons, and Screen Recording when the shortcut runs."
        case .profileApply:
            "Requires profile apply access and still respects automation pause and Private Access."
        case .spacingLabs:
            "Requires Labs access and the Menu Bar Spacing Labs feature to be enabled."
        }
    }
}

enum AutomationShortcutStatus: Equatable, Sendable {
    case ready
    case disabled
    case proGated
    case discoveryGated
    case accessibilityPermissionGated
    case accurateIconsGated
    case screenRecordingGated
    case profileGated
    case labsGated
    case requiresLabs

    var displayName: String {
        switch self {
        case .ready:
            "Ready"
        case .disabled:
            "Disabled"
        case .proGated:
            "Pro Gate"
        case .discoveryGated:
            "Discovery Gate"
        case .accessibilityPermissionGated:
            "Accessibility Gate"
        case .accurateIconsGated:
            "Accurate Icons Gate"
        case .screenRecordingGated:
            "Screen Recording Gate"
        case .profileGated:
            "Profile Gate"
        case .labsGated:
            "Labs Gate"
        case .requiresLabs:
            "Requires Labs"
        }
    }

    var clearGlassStyle: ClearGlassStatusStyle {
        switch self {
        case .ready:
            .success
        case .disabled:
            .secondary
        case .proGated, .discoveryGated, .accessibilityPermissionGated,
             .accurateIconsGated, .screenRecordingGated,
             .profileGated, .labsGated, .requiresLabs:
            .warning
        }
    }
}
