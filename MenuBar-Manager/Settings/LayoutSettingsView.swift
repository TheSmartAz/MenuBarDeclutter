import Observation
import SwiftUI

/// Phase 10 Layout settings view.
///
/// Shows capacity, suggestions, Full Menu Bar Mode, Crowded Reveal Rescue,
/// Spacer Items, and Menu Bar Spacing Labs sections.
struct LayoutSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    let diagnosticsLogger: DiagnosticsLogger
    var liveStatus: LiveDiagnosticsStatus?

    var body: some View {
        ClearGlassSettingsPage(
            "Layout",
            subtitle: "Manage menu bar capacity, layout suggestions, spacers, and experimental spacing.",
            badges: [.basicMode, .privacySafe]
        ) {
            CapacitySection(settingsStore: settingsStore, liveStatus: liveStatus)

            FullMenuBarModeSection(settingsStore: settingsStore)

            CrowdedRevealSection(settingsStore: settingsStore)

            SpacerItemsSection(settingsStore: settingsStore)

            MenuBarSpacingLabsSection(settingsStore: settingsStore)
        }
    }
}

// MARK: - Capacity Section

private struct CapacitySection: View {
    @Bindable var settingsStore: SettingsStore
    var liveStatus: LiveDiagnosticsStatus?

    var body: some View {
        ClearGlassSection("Capacity", subtitle: "Estimate how crowded your menu bar is.") {
            ClearGlassControlRow(
                systemImage: "chart.bar.fill",
                title: "Show Capacity Warnings",
                subtitle: "Show warnings when the menu bar appears crowded."
            ) {
                Toggle("", isOn: $settingsStore.showCapacityWarnings)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "lightbulb",
                title: "Layout Suggestions",
                subtitle: "Receive non-invasive suggestions for improving layout."
            ) {
                Toggle("", isOn: $settingsStore.layoutSuggestionsEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if let liveStatus, let scanTime = liveStatus.lastMenuBarScanTime {
                ClearGlassValueRow("Last AX Scan", subtitle: "Pro Mode snapshot timestamp") {
                    Text(scanTime, style: .time)
                }
            }

            ClearGlassInlineMessage(
                text: "Capacity estimates are more accurate with Pro Mode and Accessibility. Basic Mode uses approximate geometry.",
                systemImage: "info.circle"
            )
        }
    }
}

// MARK: - Full Menu Bar Mode Section

private struct FullMenuBarModeSection: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        ClearGlassSection("Full Menu Bar Mode", subtitle: "Temporarily reveal all items for easier access.") {
            ClearGlassControlRow(
                systemImage: "rectangle.expand.vertical",
                title: "Enable Full Menu Bar Mode",
                subtitle: "Allow entering a temporary full reveal mode."
            ) {
                Toggle("", isOn: $settingsStore.fullMenuBarModeEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "clock",
                title: "Auto-Exit",
                subtitle: "Automatically exit Full Menu Bar Mode after a timeout."
            ) {
                Toggle("", isOn: $settingsStore.fullMenuBarModeAutoExitEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if settingsStore.fullMenuBarModeAutoExitEnabled {
                ClearGlassSliderRow(
                    "Auto-Exit Delay",
                    subtitle: "Seconds before auto-exit.",
                    value: $settingsStore.fullMenuBarModeAutoExitSeconds,
                    in: AppConstants.minFullMenuBarModeAutoExitSeconds...AppConstants.maxFullMenuBarModeAutoExitSeconds,
                    step: 5,
                    valueSuffix: "s"
                )
            }

            ClearGlassControlRow(
                systemImage: "menubar.rectangle",
                title: "Show Second Bar",
                subtitle: "Open Second Bar when entering Full Menu Bar Mode."
            ) {
                Toggle("", isOn: $settingsStore.fullMenuBarModeShowsSecondBar)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "pause.circle",
                title: "Suspend Auto-Rehide",
                subtitle: "Prevent auto-rehide while Full Menu Bar Mode is active."
            ) {
                Toggle("", isOn: $settingsStore.fullMenuBarModeSuspendsAutoRehide)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "line.vertical",
                title: "Show Spacer Markers",
                subtitle: "Show spacer markers while in Full Menu Bar Mode."
            ) {
                Toggle("", isOn: $settingsStore.fullMenuBarModeShowsSpacerMarkers)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
    }
}

// MARK: - Crowded Reveal Section

private struct CrowdedRevealSection: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        ClearGlassSection("Crowded Reveal Rescue", subtitle: "Open Second Bar instead of a bad inline reveal.") {
            ClearGlassControlRow(
                systemImage: "shield.lefthalf.filled",
                title: "Enable Crowded Reveal Rescue",
                subtitle: "Intercept reveals when the menu bar is crowded."
            ) {
                Toggle("", isOn: $settingsStore.crowdedRevealRescueEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "menubar.rectangle",
                title: "Auto-Open Second Bar",
                subtitle: "Automatically open Second Bar when crowded."
            ) {
                Toggle("", isOn: $settingsStore.crowdedRevealAutoOpenSecondBar)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassSliderRow(
                "Crowded Threshold",
                subtitle: "Capacity ratio above which the menu bar is considered crowded.",
                value: $settingsStore.crowdedRevealThresholdRatio,
                in: AppConstants.minCrowdedRevealThresholdRatio...AppConstants.maxCrowdedRevealThresholdRatio,
                step: 0.05,
                valueSuffix: "",
                valueFractionLength: 2
            )

            ClearGlassControlRow(
                systemImage: "star",
                title: "Require Pro Estimate",
                subtitle: "Only trigger rescue when a Pro AX estimate is available."
            ) {
                Toggle("", isOn: $settingsStore.crowdedRevealRequireProEstimate)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
    }
}

// MARK: - Spacer Items Section

private struct SpacerItemsSection: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        ClearGlassSection("Spacer & Divider Items", subtitle: "Add app-owned spacer and divider items to organize your menu bar.") {
            ClearGlassControlRow(
                systemImage: "line.vertical",
                title: "Enable Spacer Items",
                subtitle: "Allow adding app-owned spacer/divider status items."
            ) {
                Toggle("", isOn: $settingsStore.spacerItemsEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "eye",
                title: "Show Spacer Markers",
                subtitle: "Show visual markers on spacer items."
            ) {
                Toggle("", isOn: $settingsStore.showSpacerMarkers)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassInlineMessage(
                text: "Spacer items are app-owned NSStatusItem instances. You can Command-drag them like other menu bar items.",
                systemImage: "info.circle"
            )
        }
    }
}

// MARK: - Menu Bar Spacing Labs Section

private struct MenuBarSpacingLabsSection: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        ClearGlassSection(
            "Menu Bar Spacing Labs",
            subtitle: "Experimental: adjust global menu bar item spacing."
        ) {
            ClearGlassControlRow(
                systemImage: "testtube.2",
                title: "Enable Spacing Labs",
                subtitle: "Enable the experimental spacing manager. Off by default."
            ) {
                Toggle("", isOn: $settingsStore.menuBarSpacingLabsEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if settingsStore.menuBarSpacingLabsEnabled {
                ClearGlassControlRow(
                    systemImage: "slider.horizontal.3",
                    title: "Preset",
                    subtitle: "Current spacing preset."
                ) {
                    Picker("", selection: $settingsStore.menuBarSpacingPreset) {
                        ForEach(MenuBarSpacingPreset.allCases) { preset in
                            Text(preset.displayName).tag(preset.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)
                }

                if settingsStore.menuBarSpacingPreset == MenuBarSpacingPreset.custom.rawValue {
                    ClearGlassSliderRow(
                        "Custom Item Spacing",
                        value: Binding(
                            get: { Double(settingsStore.menuBarSpacingCustomItemSpacing) },
                            set: { settingsStore.menuBarSpacingCustomItemSpacing = Int($0) }
                        ),
                        in: Double(AppConstants.minMenuBarSpacingCustomItemSpacing)...Double(AppConstants.maxMenuBarSpacingCustomItemSpacing),
                        step: 1,
                        valueSuffix: "pt"
                    )

                    ClearGlassSliderRow(
                        "Custom Selection Padding",
                        value: Binding(
                            get: { Double(settingsStore.menuBarSpacingCustomSelectionPadding) },
                            set: { settingsStore.menuBarSpacingCustomSelectionPadding = Int($0) }
                        ),
                        in: Double(AppConstants.minMenuBarSpacingCustomSelectionPadding)...Double(AppConstants.maxMenuBarSpacingCustomSelectionPadding),
                        step: 1,
                        valueSuffix: "pt"
                    )
                }

                if settingsStore.menuBarSpacingHasBackup {
                    ClearGlassInlineMessage(
                        text: "A backup of your previous spacing values exists. You can restore it.",
                        systemImage: "checkmark.circle",
                        style: .success
                    )
                }

                if let status = settingsStore.menuBarSpacingLastApplyStatus {
                    ClearGlassValueRow("Last Apply Status") {
                        Text(status)
                    }
                }

                ClearGlassInlineMessage(
                    text: "This is experimental. Menu bar apps, SystemUIServer, ControlCenter, logout, or reboot may be needed for full effect. Never automatically restarts system processes.",
                    systemImage: "exclamationmark.triangle",
                    style: .warning
                )
            }
        }
    }
}
