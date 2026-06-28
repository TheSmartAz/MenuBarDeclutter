import SwiftUI

/// Phase 3 "General" settings: identity, startup, onboarding, layout resets,
/// and app version metadata.
struct GeneralSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var launchAtLoginService: LaunchAtLoginService?
    var onResetLayout: (() -> Void)? = nil
    var onResetAllSettings: (() -> Void)? = nil
    var onShowOnboarding: (() -> Void)? = nil

    @State private var showResetAllConfirmation = false

    var body: some View {
        Form {
            Section("Mode") {
                LabeledContent("Current Mode") {
                    Text(settingsStore.appMode.displayName)
                }

                Picker("App Mode", selection: $settingsStore.appMode) {
                    ForEach(SettingsStore.AppMode.allCases) { mode in
                        Text(mode.displayName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: $settingsStore.launchAtLoginEnabled)
                    .onChange(of: settingsStore.launchAtLoginEnabled) { _, newValue in
                        launchAtLoginService?.apply(enabled: newValue)
                    }

                if let service = launchAtLoginService {
                    LabeledContent("SMAppService Status", value: service.statusDisplayName)

                    if let result = service.lastRegistrationResult {
                        LabeledContent("Last Login Item Action", value: result.displayName)
                    }

                    HStack {
                        Button("Refresh Login Item Status", systemImage: "arrow.clockwise") {
                            service.refreshStatus()
                        }

                        Button("Open Login Items Settings", systemImage: "gearshape") {
                            _ = service.openLoginItemsSettings()
                        }
                    }

                    Text("Launch at Login must be validated from an installed, signed app. Xcode runs can report a different SMAppService status.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let result = service.lastRegistrationResult, result.isFailure {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text("Launch at Login could not be configured. Open Login Items Settings, remove stale entries, then try again from the installed app.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Toggle("Start collapsed", isOn: $settingsStore.startCollapsed)
                LabeledContent("Last Known App Version", value: settingsStore.lastKnownAppVersion)
            }

            Section("Layout") {
                Text("Reset the separator if the menu bar no longer hides your icons after a display change or an override.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Reset App Layout") {
                    onResetLayout?()
                }

                Button("Reset All Settings", role: .destructive) {
                    showResetAllConfirmation = true
                }
                .confirmationDialog(
                    "Reset all settings to their defaults?",
                    isPresented: $showResetAllConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset", role: .destructive) {
                        onResetAllSettings?()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This restores default app preferences. Your hidden icons and separator position are managed by macOS and are not changed.")
                }
            }

            Section("Onboarding") {
                Toggle("Onboarding Completed", isOn: $settingsStore.hasCompletedOnboarding)
                Button("Show Onboarding Again") {
                    onShowOnboarding?()
                }
                .disabled(!settingsStore.hasCompletedOnboarding)
            }

            Section("App") {
                LabeledContent("Name", value: AppConstants.displayName)
                LabeledContent("Marketing Version", value: AppConstants.marketingVersion.isEmpty ? "—" : AppConstants.marketingVersion)
                LabeledContent("Build Number", value: AppConstants.buildNumber.isEmpty ? "—" : AppConstants.buildNumber)
                LabeledContent("App Version", value: AppConstants.appVersion)
                LabeledContent("Bundle Identifier", value: AppConstants.bundleIdentifier)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            launchAtLoginService?.refreshStatus()
        }
    }
}

#Preview {
    GeneralSettingsView(settingsStore: SettingsStore())
}
