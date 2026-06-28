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
        Form {
            Section("Separator Geometry") {
                LabeledSlider(
                    "Expanded separator length",
                    value: $settingsStore.expandedSeparatorLength,
                    in: 1...200,
                    step: 1,
                    sliderWidth: 200,
                    valueLabelWidth: 40,
                    valueFractionLength: 0
                )

                Toggle("Use custom collapsed separator length", isOn: $showCollapsedOverride)
                    .onChange(of: showCollapsedOverride) { _, newValue in
                        if newValue {
                            settingsStore.collapsedSeparatorLengthOverride = 2000
                        } else {
                            settingsStore.collapsedSeparatorLengthOverride = nil
                        }
                        onChange?()
                    }

                if showCollapsedOverride {
                    LabeledSlider(
                        "Custom collapsed length",
                        value: Binding(
                            get: { settingsStore.collapsedSeparatorLengthOverride ?? 2000 },
                            set: { settingsStore.collapsedSeparatorLengthOverride = $0 }
                        ),
                        in: AppConstants.collapsedSeparatorMinimumLength...AppConstants.collapsedSeparatorMaximumLength,
                        step: 50,
                        sliderWidth: 200,
                        valueLabelWidth: 60,
                        valueFractionLength: 0
                    )
                    .onChange(of: settingsStore.collapsedSeparatorLengthOverride) { _, _ in onChange?() }
                }

                Text("When disabled, the collapsed length recomputes from the widest screen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Labs / Experimental") {
                Label("Experimental Pro features", systemImage: "testtube.2")
                    .font(.headline)

                Text("Experimental: uses simulated Command-drag and may fail depending on macOS, display layout, and third-party menu bar apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Pause all automation", isOn: $settingsStore.automationPaused)
                    .onChange(of: settingsStore.automationPaused) { _, _ in onAutomationChanged?() }

                Toggle("Enable icon moving", isOn: iconMovingEnabledBinding)

                Toggle("Require confirmation before moving", isOn: $settingsStore.iconMovingRequireConfirmation)
                    .disabled(!settingsStore.iconMovingEnabled)

                Stepper(
                    value: $settingsStore.iconMovingMaxRetries,
                    in: AppConstants.minIconMovingMaxRetries...AppConstants.maxIconMovingMaxRetries
                ) {
                    Text("Max retries: \(settingsStore.iconMovingMaxRetries)")
                }
                .disabled(!settingsStore.iconMovingEnabled)

                LabeledSlider(
                    "Drag duration",
                    value: $settingsStore.iconMovingDragDuration,
                    in: AppConstants.minIconMovingDragDuration...AppConstants.maxIconMovingDragDuration,
                    step: 0.05,
                    valueLabelWidth: 46,
                    valueFractionLength: 2
                )
                .disabled(!settingsStore.iconMovingEnabled)

                Toggle("Allow moving system items", isOn: $settingsStore.iconMovingAllowSystemItems)
                    .disabled(!settingsStore.iconMovingEnabled)

                Button("Reset moving warnings") {
                    onResetMovingWarnings?()
                }

                Text("Icon moving is Pro-only and only runs after an explicit menu action. It simulates Command-drag and may fail for some apps or system items.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Application Support") {
                LabeledContent("Diagnostics Directory") {
                    Text(appSupportPaths.diagnosticsDirectory.path)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
                Button("Reveal Diagnostics Folder in Finder") {
                    revealInFinder(appSupportPaths.diagnosticsDirectory)
                }
            }

            Section("Diagnostics") {
                LabeledContent("Ring Buffer Capacity", value: "\(AppConstants.diagnosticsRingBufferLimit) events")
                LabeledContent("Bundle Identifier", value: AppConstants.bundleIdentifier)
            }
        }
        .formStyle(.grouped)
        .padding()
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

#Preview {
    AdvancedSettingsView(
        settingsStore: SettingsStore(),
        appSupportPaths: AppSupportPaths()
    )
}
