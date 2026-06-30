import SwiftUI

struct AutomationSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var onChange: (() -> Void)?

    var body: some View {
        ClearGlassSettingsPage(
            "Automation",
            subtitle: "Configure App Shortcuts and automation boundaries.",
            badges: [.preview, .privacySafe]
        ) {
            ClearGlassSection("App Shortcuts") {
                FeatureGateNotice(
                    .preview,
                    text: "Preview in v0.1.1. Actions honor Safe Mode, pause, Pro, Private Access, and Labs gates."
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "link",
                    title: "Enable App Intents",
                    subtitle: "Expose MenuBarDeclutter actions to Shortcuts. Apple Events are not used."
                ) {
                    Toggle("Enable App Intents", isOn: $settingsStore.appIntentsEnabled)
                        .labelsHidden()
                        .onChange(of: settingsStore.appIntentsEnabled) { _, _ in onChange?() }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "person.crop.rectangle.stack",
                    title: "Allow Profile Apply",
                    subtitle: "Let App Shortcuts apply profiles when automation is not paused."
                ) {
                    Toggle("Allow Profile Apply", isOn: $settingsStore.appIntentsCanApplyProfiles)
                        .labelsHidden()
                        .disabled(!settingsStore.appIntentsEnabled)
                        .onChange(of: settingsStore.appIntentsCanApplyProfiles) { _, _ in onChange?() }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "testtube.2",
                    title: "Allow Labs Access",
                    subtitle: "Allow App Shortcuts to request Labs features. Labs settings remain gated."
                ) {
                    Toggle("Allow Labs Access", isOn: $settingsStore.appIntentsCanAccessLabs)
                        .labelsHidden()
                        .disabled(!settingsStore.appIntentsEnabled)
                        .onChange(of: settingsStore.appIntentsCanAccessLabs) { _, _ in onChange?() }
                }

                ClearGlassDivider()

                Button("Open Shortcuts", systemImage: "arrow.up.right.square") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Shortcuts.app"))
                }
            }

            ClearGlassSection("Shortcut Actions") {
                shortcutActionRows
            }

            ClearGlassSection("Safety") {
                ClearGlassInlineMessage(
                    text: "App Intents honor Safe Mode, automation pause, Private Access, Pro requirements, and Labs requirements. They do not add Apple Events or network access.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }
        }
    }

    @ViewBuilder
    private var shortcutActionRows: some View {
        shortcutActionRow(.expandMenuBarItems)
        ClearGlassDivider()
        shortcutActionRow(.collapseMenuBarItems)
        ClearGlassDivider()
        shortcutActionRow(.revealAllMenuBarItems)
        ClearGlassDivider()
        shortcutActionRow(.showSecondBar)
        ClearGlassDivider()
        shortcutActionRow(.hideSecondBar)
        ClearGlassDivider()
        shortcutActionRow(.enterFullMenuBarMode)
        ClearGlassDivider()
        shortcutActionRow(.exitFullMenuBarMode)
        ClearGlassDivider()
        shortcutActionRow(.applyProfile)
        ClearGlassDivider()
        shortcutActionRow(.pauseAutomation)
        ClearGlassDivider()
        shortcutActionRow(.resumeAutomation)
        ClearGlassDivider()
        shortcutActionRow(.setLayoutSpacingPreset)
    }

    private func shortcutActionRow(_ action: AutomationShortcutAction) -> some View {
        let status = action.status(
            appIntentsEnabled: settingsStore.appIntentsEnabled,
            canApplyProfiles: settingsStore.appIntentsCanApplyProfiles,
            canAccessLabs: settingsStore.appIntentsCanAccessLabs,
            spacingLabsEnabled: settingsStore.menuBarSpacingLabsEnabled
        )

        return ClearGlassControlRow(systemImage: "sparkles", title: action.title) {
            Text(status.displayName)
                .foregroundStyle(status == .ready ? Color.secondary : Color.orange)
        }
    }
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
    static let setLayoutSpacingPreset = AutomationShortcutAction(title: "Set Layout Spacing Preset", gate: .spacingLabs)

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
        .setLayoutSpacingPreset
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
}
