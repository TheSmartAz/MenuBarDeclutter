import AppKit
import SwiftUI

struct AutomationSettingsView: View {
    @Bindable var settingsStore: SettingsStore
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
            badges: [.preview, .privacySafe]
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
                        text: "Preview in v0.1.1. Actions honor Safe Mode, pause, Pro, Private Access, and Labs gates."
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

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            AutomationOverviewPill(
                title: "App Intents",
                value: appIntentsEnabled ? "On" : "Off",
                systemImage: appIntentsEnabled ? "checkmark.circle" : "minus.circle",
                style: appIntentsEnabled ? .success : .secondary
            )

            AutomationOverviewPill(
                title: "Profiles",
                value: canApplyProfiles && appIntentsEnabled ? "Allowed" : "Gated",
                systemImage: "person.crop.rectangle.stack",
                style: canApplyProfiles && appIntentsEnabled ? .success : .warning
            )

            AutomationOverviewPill(
                title: "Labs",
                value: canAccessLabs && appIntentsEnabled ? "Allowed" : "Gated",
                systemImage: "testtube.2",
                style: canAccessLabs && appIntentsEnabled ? .success : .warning
            )

            AutomationOverviewPill(
                title: "Actions",
                value: reviewActionCount == 0 ? "\(readyActionCount) Ready" : "\(readyActionCount) / \(readyActionCount + reviewActionCount)",
                systemImage: reviewActionCount == 0 ? "checkmark.shield" : "exclamationmark.triangle",
                style: reviewActionCount == 0 ? .success : .warning
            )
        }
    }
}

private struct AutomationOverviewPill: View {
    let title: String
    let value: String
    let systemImage: String
    let style: ClearGlassStatusStyle

    var body: some View {
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
            AutomationGroupedBox("Availability") {
                AutomationToggleRow(
                    title: "Enable App Intents",
                    subtitle: "Expose MenuBarDeclutter actions to Shortcuts. Apple Events are not used.",
                    systemImage: "link",
                    statusText: appIntentsEnabled ? "Enabled" : "Off",
                    statusStyle: appIntentsEnabled ? .success : .secondary,
                    isDisabled: false,
                    isOn: $appIntentsEnabled,
                    onChange: onChange
                )

                automationDivider

                AutomationToggleRow(
                    title: "Allow Profile Apply",
                    subtitle: "Let App Shortcuts apply profiles when automation is not paused.",
                    systemImage: "person.crop.rectangle.stack",
                    statusText: profileStatusText,
                    statusStyle: profileStatusStyle,
                    isDisabled: !appIntentsEnabled,
                    isOn: $canApplyProfiles,
                    onChange: onChange
                )

                automationDivider

                AutomationToggleRow(
                    title: "Allow Labs Access",
                    subtitle: "Allow App Shortcuts to request Labs features. Labs settings remain gated.",
                    systemImage: "testtube.2",
                    statusText: labsStatusText,
                    statusStyle: labsStatusStyle,
                    isDisabled: !appIntentsEnabled,
                    isOn: $canAccessLabs,
                    onChange: onChange
                )
            }

            AutomationGroupedBox("Shortcuts App") {
                AutomationActionRow(
                    title: "Open Shortcuts",
                    subtitle: "Open Apple's Shortcuts app to inspect or run MenuBarDeclutter actions.",
                    systemImage: "arrow.up.right.square",
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
        guard appIntentsEnabled else { return "Unavailable" }
        return canApplyProfiles ? "Allowed" : "Blocked"
    }

    private var profileStatusStyle: ClearGlassStatusStyle {
        guard appIntentsEnabled else { return .secondary }
        return canApplyProfiles ? .success : .warning
    }

    private var labsStatusText: String {
        guard appIntentsEnabled else { return "Unavailable" }
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
                            canApplyProfiles: canApplyProfiles,
                            canAccessLabs: canAccessLabs,
                            spacingLabsEnabled: spacingLabsEnabled
                        )
                    )

                    if index != actions.count - 1 {
                        automationDivider
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
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(status.clearGlassStyle.tint.opacity(0.12))

                Image(systemName: action.systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(status.clearGlassStyle.tint)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(action.title)
                    .font(.body)
                    .lineLimit(1)

                Text(action.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearGlassStatusValue(
                text: status.displayName,
                style: status.clearGlassStyle
            )
            .fixedSize()
            .padding(.top, 5)
        }
        .padding(.vertical, 8)
        .opacity(status == .disabled ? 0.62 : 1)
    }
}

private struct AutomationSafetyChecklist: View {
    var body: some View {
        AutomationGroupedBox("Privacy Boundary") {
            AutomationSafetyItem(
                title: "No Apple Events",
                subtitle: "App Shortcuts use App Intents and do not request Apple Events access.",
                systemImage: "checkmark.shield",
                style: .success
            )

            automationDivider

            AutomationSafetyItem(
                title: "No Network Access",
                subtitle: "Automation settings stay local and do not add network behavior.",
                systemImage: "network.slash",
                style: .success
            )

            automationDivider

            AutomationSafetyItem(
                title: "Gate-aware Execution",
                subtitle: "Safe Mode, automation pause, Private Access, Pro requirements, and Labs requirements are still enforced.",
                systemImage: "lock.circle",
                style: .info
            )
        }
    }
}

private struct AutomationSafetyItem: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let style: ClearGlassStatusStyle

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15))
                .foregroundStyle(style.tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}

private struct AutomationGroupedBox<Content: View>: View {
    private let title: String
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

private struct AutomationToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let statusText: String
    let statusStyle: ClearGlassStatusStyle
    let isDisabled: Bool
    @Binding var isOn: Bool
    let onChange: () -> Void

    var body: some View {
        AutomationActionRow(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            statusText: statusText,
            statusStyle: statusStyle,
            isDimmed: isDisabled
        ) {
            HStack(spacing: 10) {
                ClearGlassStatusValue(text: statusText, style: statusStyle)

                Toggle(title, isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(isDisabled)
                    .onChange(of: isOn) { _, _ in onChange() }
            }
        }
    }
}

private struct AutomationActionRow<Accessory: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let statusText: String
    let statusStyle: ClearGlassStatusStyle
    var isDimmed = false
    @ViewBuilder let accessory: Accessory

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        statusText: String,
        statusStyle: ClearGlassStatusStyle,
        isDimmed: Bool = false,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.statusText = statusText
        self.statusStyle = statusStyle
        self.isDimmed = isDimmed
        self.accessory = accessory()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                rowLabel
                    .frame(maxWidth: .infinity, alignment: .leading)

                accessory
                    .fixedSize()
            }

            VStack(alignment: .leading, spacing: 8) {
                rowLabel
                accessory
                    .fixedSize()
            }
        }
        .padding(.vertical, 8)
        .opacity(isDimmed ? 0.58 : 1)
    }

    private var rowLabel: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15))
                .foregroundStyle(statusStyle.tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private var automationDivider: some View {
    Divider()
        .padding(.leading, 34)
}

struct AutomationShortcutAction: Identifiable, Equatable, Sendable {
    enum Gate: Equatable, Sendable {
        case none
        case profileApply
        case spacingLabs
    }

    let title: String
    let gate: Gate

    var id: String { title }

    static let expandMenuBarItems = AutomationShortcutAction(title: "Expand Menu Bar Items", gate: .none)
    static let collapseMenuBarItems = AutomationShortcutAction(title: "Collapse Menu Bar Items", gate: .none)
    static let revealAllMenuBarItems = AutomationShortcutAction(title: "Reveal All Menu Bar Items", gate: .none)
    static let showSecondBar = AutomationShortcutAction(title: "Show Second Bar", gate: .none)
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
    case profileGated
    case labsGated
    case requiresLabs

    var displayName: String {
        switch self {
        case .ready:
            "Ready"
        case .disabled:
            "Disabled"
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
        case .profileGated, .labsGated, .requiresLabs:
            .warning
        }
    }
}
