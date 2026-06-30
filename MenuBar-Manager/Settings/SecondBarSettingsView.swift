import SwiftUI

struct SecondBarSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var commandAvailability: MenuBarCommandAvailabilitySummary?
    var iconPanelAvailability: MenuBarCommandAvailabilitySummary?
    var onChange: (() -> Void)? = nil
    var onOpenPrivacySettings: (() -> Void)? = nil

    var body: some View {
        ClearGlassSettingsPage(
            "Second Bar",
            subtitle: "Configure the optional secondary bar for hidden menu bar items.",
            badges: [.stable, .proMode, .accessibilityRequired]
        ) {
            ClearGlassSection("Second Bar", subtitle: "Feature controls for the secondary item surface.") {
                FeatureGateNotice(
                    .stable,
                    text: "Second Bar metadata and icon browsing are supported in v0.1.1 when Pro discovery requirements are satisfied."
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "menubar.rectangle",
                    title: "Enable Second Bar",
                    subtitle: "Show hidden menu bar items in a secondary bar.",
                    iconTint: .blue
                ) {
                    Toggle("Enable Second Bar", isOn: $settingsStore.secondBarEnabled)
                        .labelsHidden()
                }

                ClearGlassDivider()

                secondBarToggleRow(
                    title: "Show hidden items",
                    subtitle: "Show items that are hidden in the menu bar.",
                    systemImage: "checkmark.circle",
                    binding: $settingsStore.secondBarShowHiddenItems
                )

                ClearGlassDivider()

                secondBarToggleRow(
                    title: "Show always-hidden items",
                    subtitle: "Show items from the Always-Hidden zone.",
                    systemImage: "checkmark.circle",
                    binding: $settingsStore.secondBarShowAlwaysHiddenItems
                )

                ClearGlassDivider()

                secondBarToggleRow(
                    title: "Auto-close after selection",
                    subtitle: "Close the Second Bar after an item is selected.",
                    systemImage: "checkmark.circle",
                    binding: $settingsStore.secondBarAutoCloseAfterSelection
                )

                ClearGlassDivider()

                secondBarToggleRow(
                    title: "Close when clicking outside",
                    subtitle: "Close the Second Bar when clicking outside of it.",
                    systemImage: "checkmark.circle",
                    binding: $settingsStore.secondBarCloseOnOutsideClick
                )

                ClearGlassDivider()

                secondBarToggleRow(
                    title: "Bring owning app to front",
                    subtitle: "Bring the app that owns the selected item to the front.",
                    systemImage: "app.connected.to.app.below.fill",
                    binding: $settingsStore.secondBarActivateOwningAppOnSelection
                )

                ClearGlassInlineMessage(
                    text: "Second Bar uses Accessibility snapshots and app bundle icons. It does not use Screen Recording or captured menu bar pixels.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }

            if commandAvailability != nil || iconPanelAvailability != nil {
                ClearGlassSection("Command Center", subtitle: "Shared routing status for Second Bar and the deferred Icon Panel mode.") {
                    if let commandAvailability {
                        CommandAvailabilityRow(summary: commandAvailability)
                    }

                    if commandAvailability != nil, iconPanelAvailability != nil {
                        ClearGlassDivider()
                    }

                    if let iconPanelAvailability {
                        CommandAvailabilityRow(summary: iconPanelAvailability)
                    }
                }
            }

            ClearGlassSection("Position & Appearance", subtitle: "Placement and visual density for the Second Bar.") {
                ClearGlassValueRow("Position", subtitle: "Where the Second Bar appears.") {
                    Picker("Position", selection: $settingsStore.secondBarPositionModeRaw) {
                        ForEach(SecondBarPositionMode.allCases) { mode in
                            Text(mode.displayName)
                                .tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 320)
                    .disabled(!settingsStore.secondBarEnabled)
                }
                .opacity(settingsStore.secondBarEnabled ? 1 : 0.55)

                ClearGlassDivider()

                ClearGlassSliderRow(
                    "Icon size",
                    value: $settingsStore.secondBarIconSize,
                    in: AppConstants.minSecondBarIconSize...AppConstants.maxSecondBarIconSize,
                    step: 2,
                    valueSuffix: "pt",
                    valueFractionLength: 0
                )
                .disabled(!settingsStore.secondBarEnabled)
                .opacity(settingsStore.secondBarEnabled ? 1 : 0.55)

                ClearGlassDivider()

                secondBarToggleRow(
                    title: "Show labels",
                    subtitle: "Show item names below icons.",
                    systemImage: "textformat",
                    binding: $settingsStore.secondBarShowLabels
                )
            }

            ClearGlassSection("Preview", subtitle: "Example of the Second Bar with hidden items.") {
                SecondBarPreviewStrip(showLabels: settingsStore.secondBarShowLabels)
            }

            ClearGlassSection("Requirements", subtitle: "Second Bar remains unavailable until all Pro requirements are satisfied.") {
                SearchRequirementRow(
                    title: "Pro Mode",
                    detail: "Second Bar is available only in opt-in Pro Mode.",
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
        .onSecondBarSettingsChanges(from: settingsStore, perform: onChange)
    }

    private func secondBarToggleRow(
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
                .disabled(!settingsStore.secondBarEnabled)
        }
        .opacity(settingsStore.secondBarEnabled ? 1 : 0.55)
    }
}

private struct SecondBarPreviewStrip: View {
    let showLabels: Bool

    private let hiddenIcons = ["wifi", "battery.100", "cloud", "shield", "a.square", "bubble.left"]
    private let alwaysHiddenIcons = ["paperplane", "moon", "headphones", "printer", "info.circle"]

    var body: some View {
        VStack(spacing: 10) {
            previewGroup("Hidden", icons: hiddenIcons)

            ClearGlassDivider()

            previewGroup("Always Hidden", icons: alwaysHiddenIcons)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
        }
    }

    private func previewGroup(_ title: String, icons: [String]) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 22) {
                ForEach(icons, id: \.self) { icon in
                    VStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(.primary)

                        if showLabels {
                            Text(iconLabel(icon))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .frame(minWidth: 38)
                }
            }
        }
    }

    private func iconLabel(_ icon: String) -> String {
        icon
            .replacingOccurrences(of: ".100", with: "")
            .replacingOccurrences(of: ".", with: " ")
            .capitalized
    }
}

#Preview {
    SecondBarSettingsView(settingsStore: SettingsStore())
}
