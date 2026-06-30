import AppKit
import SwiftUI

/// Phase 3 "Advanced" settings: separator geometry tweaks, App Support
/// discovery, and read-only build/diagnostics metadata. Most users should not
/// need to touch this surface, which is why it lives behind its own tab.
struct AdvancedSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    let appSupportPaths: AppSupportPaths
    var onChange: (() -> Void)? = nil
    var onAutomationChanged: (() -> Void)? = nil
    var onResetMovingWarnings: (() -> Void)? = nil

    @State private var showCollapsedOverride: Bool
    @State private var showIconMovingConfirmation = false

    init(
        settingsStore: SettingsStore,
        appSupportPaths: AppSupportPaths,
        onChange: (() -> Void)? = nil,
        onAutomationChanged: (() -> Void)? = nil,
        onResetMovingWarnings: (() -> Void)? = nil
    ) {
        self.settingsStore = settingsStore
        self.appSupportPaths = appSupportPaths
        self.onChange = onChange
        self.onAutomationChanged = onAutomationChanged
        self.onResetMovingWarnings = onResetMovingWarnings
        _showCollapsedOverride = State(initialValue: settingsStore.collapsedSeparatorLengthOverride != nil)
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Advanced",
            subtitle: "Low-level layout, diagnostics, and experimental automation controls.",
            badges: [.privacySafe, .diagnostics, .labs, .experimental]
        ) {
            ClearGlassSection("Separator Geometry", subtitle: "Fine-tune how separators are rendered in the menu bar.") {
                ClearGlassSliderRow(
                    "Expanded separator length",
                    value: $settingsStore.expandedSeparatorLength,
                    in: 1...200,
                    step: 1,
                    valueSuffix: "pt",
                    valueFractionLength: 0
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "ruler",
                    title: "Use custom collapsed separator length",
                    subtitle: "Override the automatic collapsed length computed from the widest screen."
                ) {
                    Toggle("Use custom collapsed separator length", isOn: $showCollapsedOverride)
                        .labelsHidden()
                        .onChange(of: showCollapsedOverride) { _, newValue in
                            if newValue {
                                settingsStore.collapsedSeparatorLengthOverride = 2000
                            } else {
                                settingsStore.collapsedSeparatorLengthOverride = nil
                            }
                            onChange?()
                        }
                }

                if showCollapsedOverride {
                    ClearGlassDivider()

                    ClearGlassSliderRow(
                        "Custom collapsed length",
                        value: Binding(
                            get: { settingsStore.collapsedSeparatorLengthOverride ?? 2000 },
                            set: { settingsStore.collapsedSeparatorLengthOverride = $0 }
                        ),
                        in: AppConstants.collapsedSeparatorMinimumLength...AppConstants.collapsedSeparatorMaximumLength,
                        step: 50,
                        valueSuffix: "pt",
                        valueFractionLength: 0,
                        valueWidth: 78
                    )
                    .onChange(of: settingsStore.collapsedSeparatorLengthOverride) { _, _ in onChange?() }
                }

                ClearGlassDivider()

                SeparatorGeometryPreview(
                    expandedLength: settingsStore.expandedSeparatorLength,
                    collapsedLength: settingsStore.collapsedSeparatorLengthOverride
                )

                ClearGlassInlineMessage(
                    text: "When the override is disabled, the collapsed length recomputes from the widest screen.",
                    systemImage: "info.circle",
                    style: .secondary
                )
            }

            ClearGlassSection("Application Support", subtitle: "File system locations used by the app.") {
                ClearGlassValueRow("Diagnostics Directory") {
                    Text(appSupportPaths.diagnosticsDirectory.path)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                        .frame(maxWidth: 360, alignment: .trailing)
                }

                ClearGlassDivider()

                Button("Reveal Diagnostics Folder", systemImage: "folder") {
                    revealInFinder(appSupportPaths.diagnosticsDirectory)
                }
            }

            ClearGlassSection("Diagnostics", subtitle: "Low-level diagnostics and logging options.") {
                ClearGlassValueRow("Ring Buffer Capacity", subtitle: "Maximum number of log events kept in memory.") {
                    Text("\(AppConstants.diagnosticsRingBufferLimit) events")
                        .font(.system(.body, design: .monospaced))
                }

                ClearGlassDivider()

                ClearGlassValueRow("Bundle Identifier", subtitle: "Used in logs and diagnostics.") {
                    Text(AppConstants.bundleIdentifier)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            ClearGlassSection("Labs / Experimental", subtitle: "Automation features that may fail depending on system state.") {
                FeatureGateNotice(
                    .experimental,
                    text: "Icon Moving is Experimental in v0.1.1. It is disabled by default and only runs from explicit user action after confirmation."
                )

                ClearGlassDivider()

                ClearGlassInlineMessage(
                    text: "These features are experimental and may change or break in future updates. Use at your own risk.",
                    systemImage: "testtube.2",
                    style: .warning
                )

                ClearGlassControlRow(
                    systemImage: "pause.circle",
                    title: "Pause all automation",
                    subtitle: "Temporarily stop all automation actions."
                ) {
                    Toggle("Pause all automation", isOn: $settingsStore.automationPaused)
                        .labelsHidden()
                        .onChange(of: settingsStore.automationPaused) { _, _ in onAutomationChanged?() }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    title: "Enable icon moving",
                    subtitle: "Allow explicit simulated Command-drag moves between menu bar locations.",
                    iconTint: .orange
                ) {
                    Toggle("Enable icon moving", isOn: iconMovingEnabledBinding)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "checkmark.shield",
                    title: "Require confirmation before moving",
                    subtitle: "Ask before completing a move."
                ) {
                    Toggle("Require confirmation before moving", isOn: $settingsStore.iconMovingRequireConfirmation)
                        .labelsHidden()
                        .disabled(!settingsStore.iconMovingEnabled)
                }
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.55)

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "arrow.clockwise",
                    title: "Max retries",
                    subtitle: "Attempts to complete a move before giving up."
                ) {
                    HStack(spacing: 10) {
                        Text("\(settingsStore.iconMovingMaxRetries)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)

                        Stepper(
                            "Max retries",
                            value: $settingsStore.iconMovingMaxRetries,
                            in: AppConstants.minIconMovingMaxRetries...AppConstants.maxIconMovingMaxRetries
                        )
                        .labelsHidden()
                    }
                    .disabled(!settingsStore.iconMovingEnabled)
                }
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.55)

                ClearGlassDivider()

                ClearGlassSliderRow(
                    "Drag duration",
                    subtitle: "Duration of the drag animation.",
                    value: $settingsStore.iconMovingDragDuration,
                    in: AppConstants.minIconMovingDragDuration...AppConstants.maxIconMovingDragDuration,
                    step: 0.05,
                    valueSuffix: "s",
                    valueFractionLength: 2
                )
                .disabled(!settingsStore.iconMovingEnabled)
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.55)

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "apple.logo",
                    title: "Allow moving system items",
                    subtitle: "Allow moving menu bar items provided by macOS."
                ) {
                    Toggle("Allow moving system items", isOn: $settingsStore.iconMovingAllowSystemItems)
                        .labelsHidden()
                        .disabled(!settingsStore.iconMovingEnabled)
                }
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.55)

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "arrow.counterclockwise",
                    title: "Reset moving warnings",
                    subtitle: "Clear all icon-moving warning suppressions."
                ) {
                    Button("Reset moving warnings") {
                        onResetMovingWarnings?()
                    }
                }
            }

            ClearGlassSection("Developer Notes", subtitle: "Advanced settings are intended for advanced users and developers.") {
                ClearGlassInlineMessage(
                    text: "Icon moving is Pro-only and only runs after an explicit menu action. It simulates Command-drag and may fail for some apps or system items.",
                    systemImage: "exclamationmark.triangle",
                    style: .warning
                )
            }
        }
        .onIconMovingSettingsChanges(from: settingsStore, perform: onChange)
        .confirmationDialog(
            "Enable experimental icon moving?",
            isPresented: $showIconMovingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Enable Experimental Icon Moving") {
                settingsStore.iconMovingEnabled = true
                onChange?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Experimental: uses simulated Command-drag and may fail depending on macOS, display layout, and third-party menu bar apps.")
        }
    }

    private var iconMovingEnabledBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.iconMovingEnabled },
            set: { newValue in
                if newValue {
                    showIconMovingConfirmation = true
                } else {
                    settingsStore.iconMovingEnabled = false
                    onChange?()
                }
            }
        )
    }

    private func revealInFinder(_ url: URL) {
        do {
            try appSupportPaths.ensureDirectoriesExist()
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            NSWorkspace.shared.open(url.deletingLastPathComponent())
        }
    }
}

private struct SeparatorGeometryPreview: View {
    let expandedLength: Double
    let collapsedLength: Double?

    private let icons = ["wifi", "battery.100", "cloud", "magnifyingglass"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Measured in menu bar points")
                .font(.caption)
                .foregroundStyle(.secondary)

            geometryLine("Expanded", length: expandedLength, icons: icons)
            geometryLine("Collapsed", length: collapsedLength ?? AppConstants.collapsedSeparatorMinimumLength, icons: Array(icons.prefix(3)))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
        }
    }

    private func geometryLine(_ title: String, length: Double, icons: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(icons, id: \.self) { icon in
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                }

                Rectangle()
                    .fill(.blue)
                    .frame(width: 2, height: 22)

                Text("\(length, format: .number.precision(.fractionLength(0)))pt")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    AdvancedSettingsView(
        settingsStore: SettingsStore(),
        appSupportPaths: AppSupportPaths()
    )
}
