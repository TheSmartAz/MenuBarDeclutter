import SwiftUI

struct SearchSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var commandAvailability: MenuBarCommandAvailabilitySummary?
    var onChange: (() -> Void)? = nil
    var onOpenPrivacySettings: (() -> Void)? = nil

    var body: some View {
        ClearGlassSettingsPage(
            "Search",
            subtitle: "Find Icon controls for locating menu bar items from the local discovery index.",
            badges: [.stable, .proMode, .accessibilityRequired]
        ) {
            ClearGlassSection("Find Icon", subtitle: "Enable the floating search surface and selection behavior.") {
                FeatureGateNotice(
                    .stable,
                    text: "Stable in v0.1.1 when Pro Mode, discovery, and Accessibility permission are enabled."
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "magnifyingglass",
                    title: "Enable Find Icon",
                    subtitle: "Show the Find Icon button in the status menu and floating panel.",
                    iconTint: .blue
                ) {
                    Toggle("Enable Find Icon", isOn: $settingsStore.searchEnabled)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "eye",
                    title: "Reveal item when selected",
                    subtitle: "Temporarily reveal the selected menu bar item."
                ) {
                    Toggle("Reveal item when selected", isOn: $settingsStore.searchRevealOnSelection)
                        .labelsHidden()
                        .disabled(!settingsStore.searchEnabled)
                }
                .opacity(settingsStore.searchEnabled ? 1 : 0.55)

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "square.dashed",
                    title: "Highlight selected item",
                    subtitle: "Visually highlight the selected result in the list."
                ) {
                    Toggle("Highlight selected item", isOn: $settingsStore.searchHighlightOnSelection)
                        .labelsHidden()
                        .disabled(!settingsStore.searchEnabled)
                }
                .opacity(settingsStore.searchEnabled ? 1 : 0.55)

                ClearGlassInlineMessage(
                    text: "Find Icon uses the local Accessibility discovery index only after Pro Mode is enabled. It does not click, drag, record the screen, or use the network.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }

            if let commandAvailability {
                ClearGlassSection("Command Center", subtitle: "Shared routing status for opening Find Icon.") {
                    CommandAvailabilityRow(summary: commandAvailability)
                }
            }

            ClearGlassSection("Search Hotkey", subtitle: "Keyboard access for the Find Icon panel.") {
                ClearGlassControlRow(
                    systemImage: "keyboard",
                    title: "Enable Find Icon hotkey",
                    subtitle: "Default: Option + Command + F. The hotkey is disabled until you turn it on."
                ) {
                    Toggle("Enable Find Icon hotkey", isOn: $settingsStore.searchHotkeyEnabled)
                        .labelsHidden()
                        .disabled(!settingsStore.searchEnabled)
                }
                .opacity(settingsStore.searchEnabled ? 1 : 0.55)

                if settingsStore.searchHotkeyEnabled {
                    ClearGlassDivider()

                    ClearGlassValueRow("Current Hotkey") {
                        HStack(spacing: 10) {
                            KeyboardShortcutToken(text: settingsStore.effectiveSearchHotkey().displayName)

                            Button("Reset to Default") {
                                settingsStore.resetSearchHotkeyToDefault()
                                onChange?()
                            }
                        }
                    }
                }
            }

            ClearGlassSection("Requirements", subtitle: "Find Icon remains unavailable until all Pro requirements are satisfied.") {
                SearchRequirementRow(
                    title: "Pro Mode",
                    detail: "Find Icon is available only in opt-in Pro Mode.",
                    status: settingsStore.proModeEnabled ? "Enabled" : "Disabled",
                    isSatisfied: settingsStore.proModeEnabled,
                    systemImage: "star"
                )

                ClearGlassDivider()

                SearchRequirementRow(
                    title: "Accessibility Discovery",
                    detail: "Allow the app to discover menu bar items locally.",
                    status: settingsStore.accessibilityDiscoveryEnabled ? "Enabled" : "Disabled",
                    isSatisfied: settingsStore.accessibilityDiscoveryEnabled,
                    systemImage: "figure.circle"
                )

                ClearGlassDivider()

                SearchRequirementRow(
                    title: "Accessibility Permission",
                    detail: "Grant permission before the app can read menu bar item labels and frames.",
                    status: permissionService?.status.displayName ?? AccessibilityPermissionStatus.notRequested.displayName,
                    isSatisfied: permissionService?.status == .granted,
                    systemImage: "hand.raised",
                    actionTitle: "Open Privacy Settings",
                    action: onOpenPrivacySettings
                )
            }
        }
        .onSearchSettingsChanges(from: settingsStore, perform: onChange)
    }
}

struct SearchRequirementRow: View {
    let title: String
    var detail: String? = nil
    let status: String
    let isSatisfied: Bool
    var systemImage: String = "checkmark.circle"
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: detail,
            iconTint: isSatisfied ? .green : .orange
        ) {
            HStack(spacing: 12) {
                ClearGlassStatusValue(
                    text: status,
                    style: isSatisfied ? .success : .warning
                )

                if let actionTitle, let action {
                    Button(actionTitle) {
                        action()
                    }
                }
            }
        }
    }
}

#Preview {
    SearchSettingsView(settingsStore: SettingsStore())
}
