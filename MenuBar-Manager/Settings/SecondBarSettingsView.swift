import SwiftUI

struct SecondBarSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var screenCapturePermissionService: ScreenCapturePermissionService?
    var iconCaptureCoordinator: MenuBarIconCaptureCoordinator?
    var scanCoordinator: MenuBarScanCoordinator?
    var commandAvailability: MenuBarCommandAvailabilitySummary?
    var iconPanelAvailability: MenuBarCommandAvailabilitySummary?
    var onChange: (() -> Void)? = nil
    var onOpenPrivacySettings: (() -> Void)? = nil

    private var pageSectionAnchors: [ClearGlassPageAnchor] {
        var anchors = [
            ClearGlassPageAnchor("Pro Second Bar Setup", systemImage: "checklist"),
            ClearGlassPageAnchor("Second Bar", systemImage: "menubar.rectangle")
        ]

        if commandAvailability != nil || iconPanelAvailability != nil {
            anchors.append(ClearGlassPageAnchor("Panel Action Status", systemImage: "checkmark.seal"))
        }

        anchors.append(ClearGlassPageAnchor("Position & Appearance", systemImage: "slider.horizontal.3"))
        anchors.append(ClearGlassPageAnchor("Preview", systemImage: "eye"))

        return anchors
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Second Bar",
            subtitle: "Configure the Optional Pro secondary bar for hidden menu bar items.",
            badges: [.preview],
            sectionAnchors: pageSectionAnchors
        ) {
            ProSecondBarSetupChecklistView(
                settingsStore: settingsStore,
                permissionService: permissionService,
                screenCapturePermissionService: screenCapturePermissionService,
                iconCaptureCoordinator: iconCaptureCoordinator,
                scanCoordinator: scanCoordinator,
                onChange: onChange
            )

            ClearGlassSection("Second Bar", subtitle: "Status menu entry point and panel behavior.") {
                FeatureGateNotice(
                    .preview,
                    text: "Second Bar is a Preview surface. The panel can open from Basic Mode; hidden-item metadata stays gated until Optional Pro discovery and Accessibility permission are ready."
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "menubar.rectangle",
                    title: "Show in status menu",
                    subtitle: "Keep the Second Bar shortcut visible in the status menu. Direct links and automation still open the gated panel.",
                    iconTint: .blue
                ) {
                    Toggle("Show Second Bar in status menu", isOn: $settingsStore.secondBarEnabled)
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
                    text: "Basic Mode hiding stays available without this panel. Optional Pro Second Bar uses Accessibility snapshots and can use Accurate Icons thumbnails only when you enable that separate permission path.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }

            if commandAvailability != nil || iconPanelAvailability != nil {
                ClearGlassSection("Panel Action Status", subtitle: "Checks whether Second Bar actions are available from the current gates.") {
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
                }

                ClearGlassDivider()

                ClearGlassSliderRow(
                    "Icon size",
                    value: $settingsStore.secondBarIconSize,
                    in: AppConstants.minSecondBarIconSize...AppConstants.maxSecondBarIconSize,
                    step: 2,
                    valueSuffix: "pt",
                    valueFractionLength: 0
                )

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
        }
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
