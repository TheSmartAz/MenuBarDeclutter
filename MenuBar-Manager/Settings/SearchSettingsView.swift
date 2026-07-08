import SwiftUI

struct SearchSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var commandAvailability: MenuBarCommandAvailabilitySummary?
    var onChange: (() -> Void)? = nil
    var onOpenPrivacySettings: (() -> Void)? = nil

    private var pageSectionAnchors: [ClearGlassPageAnchor] {
        var anchors = [
            ClearGlassPageAnchor("Find Icon", systemImage: "magnifyingglass")
        ]

        if commandAvailability != nil {
            anchors.append(ClearGlassPageAnchor("Item Action Status", systemImage: "checkmark.seal"))
        }

        anchors.append(contentsOf: [
            ClearGlassPageAnchor("Search Hotkey", systemImage: "keyboard"),
            ClearGlassPageAnchor("Requirements", systemImage: "checklist")
        ])

        return anchors
    }

    private var accessibilityPermissionStatus: AccessibilityPermissionStatus {
        permissionService?.status ?? .notRequested
    }

    private var proModeRequirementStatus: String {
        settingsStore.proModeEnabled ? "On" : "Off"
    }

    private var discoveryRequirementStatus: String {
        settingsStore.accessibilityDiscoveryEnabled ? "On" : "Off"
    }

    private var permissionRequirementStatus: String {
        accessibilityPermissionStatus == .granted ? "Granted" : accessibilityPermissionStatus.displayName
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Search",
            subtitle: "Find Icon preferences for locating menu bar items with Optional Pro local discovery.",
            badges: [.preview],
            sectionAnchors: pageSectionAnchors
        ) {
            ClearGlassSection("Find Icon", subtitle: "Status menu entry point and selection behavior.") {
                FeatureGateNotice(
                    .preview,
                    text: "Preview in v0.1.3. The panel can open from Basic Mode; results stay gated until Optional Pro discovery and Accessibility permission are ready."
                )

                ClearGlassDivider()

                ClearGlassRowStack {
                    ClearGlassToggleRow(
                        systemImage: "magnifyingglass",
                        title: "Show in status menu",
                        subtitle: "Keep the Find Icon shortcut visible in the status menu. Direct links and automation still open the gated panel.",
                        iconTint: .blue,
                        isOn: $settingsStore.searchEnabled
                    )

                    ClearGlassToggleRow(
                        systemImage: "eye",
                        title: "Reveal item when selected",
                        subtitle: "Temporarily reveal the selected menu bar item.",
                        isOn: $settingsStore.searchRevealOnSelection
                    )

                    ClearGlassToggleRow(
                        systemImage: "square.dashed",
                        title: "Highlight selected item",
                        subtitle: "Visually highlight the selected result in the list.",
                        isOn: $settingsStore.searchHighlightOnSelection
                    )
                }

                ClearGlassInlineMessage(
                    text: "Basic Mode keeps Find Icon visibility and hotkey settings local. Optional Pro discovery can read menu bar labels and frames after private access is granted; it does not click, drag, record the screen, or use the network.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }

            if let commandAvailability {
                ClearGlassSection("Item Action Status", subtitle: "Checks whether Find Icon can open from the current gates.") {
                    CommandAvailabilityRow(summary: commandAvailability)
                }
            }

            ClearGlassSection("Search Hotkey", subtitle: "Keyboard access for the Find Icon panel.") {
                ClearGlassToggleRow(
                    systemImage: "keyboard",
                    title: "Enable Find Icon hotkey",
                    subtitle: "Default: Option + Command + F. The hotkey is disabled until you turn it on.",
                    isOn: $settingsStore.searchHotkeyEnabled
                )

                if settingsStore.searchHotkeyEnabled {
                    ClearGlassDivider()

                    ClearGlassValueRow("Current Hotkey") {
                        HStack(spacing: 10) {
                            KeyboardShortcutToken(text: settingsStore.effectiveSearchHotkey().displayName)

                            Button("Reset to Default") {
                                settingsStore.resetSearchHotkeyToDefault()
                                onChange?()
                            }
                            .controlSize(.small)
                        }
                    }
                }
            }

            ClearGlassSection("Optional Pro Requirements", subtitle: "Find Icon results stay gated until these private-access requirements are satisfied.") {
                SearchRequirementRow(
                    title: "Optional Pro",
                    detail: "Private menu bar item discovery is available only after opt-in.",
                    status: proModeRequirementStatus,
                    isSatisfied: settingsStore.proModeEnabled,
                    systemImage: "star"
                )

                ClearGlassDivider()

                SearchRequirementRow(
                    title: "Accessibility Discovery",
                    detail: "Allow the app to discover menu bar items locally.",
                    status: discoveryRequirementStatus,
                    isSatisfied: settingsStore.accessibilityDiscoveryEnabled,
                    systemImage: "figure.circle"
                )

                ClearGlassDivider()

                SearchRequirementRow(
                    title: "Accessibility Permission",
                    detail: "Grant permission before the app can read menu bar item labels and frames.",
                    status: permissionRequirementStatus,
                    isSatisfied: accessibilityPermissionStatus == .granted,
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
        ClearGlassStepRow(
            systemImage: systemImage,
            title: title,
            subtitle: detail,
            iconTint: isSatisfied ? .green : .orange,
            statusText: status,
            statusStyle: isSatisfied ? .success : .warning
        ) {
            if let actionTitle, let action {
                Button(actionTitle) {
                    action()
                }
                .controlSize(.small)
            }
        }
    }
}

#Preview {
    SearchSettingsView(settingsStore: SettingsStore())
}
