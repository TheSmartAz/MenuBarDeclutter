import AppKit
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

    private var isRunningFromApplications: Bool {
        Bundle.main.bundleURL.path.hasPrefix("/Applications/")
    }

    var body: some View {
        ClearGlassSettingsPage(
            "General",
            subtitle: "Startup, layout, onboarding, and app identity.",
            badges: [.basicMode, .privacySafe]
        ) {
            if settingsStore.v01SafeDefaultsNoticePending {
                ClearGlassInlineMessage(
                    text: "Updated to v0.1 safe defaults.",
                    systemImage: "checkmark.shield",
                    style: .success
                )

                Button("Dismiss Notice") {
                    settingsStore.v01SafeDefaultsNoticePending = false
                }
            }

            ClearGlassSection("Mode", subtitle: "Choose the feature set that fits your needs.") {
                ClearGlassControlRow(
                    systemImage: "checkmark.shield",
                    title: "Current Mode",
                    subtitle: "Basic Mode stays fully usable without sensitive permissions.",
                    iconTint: .green
                ) {
                    Text(settingsStore.appMode.displayName)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                ClearGlassDivider()

                ClearGlassValueRow("App Mode") {
                    Picker("App Mode", selection: $settingsStore.appMode) {
                        ForEach(SettingsStore.AppMode.allCases) { mode in
                            Text(mode.displayName)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 260)
                }
            }

            ClearGlassSection("Startup", subtitle: "Launch behavior and Login Items status.") {
                ClearGlassControlRow(
                    systemImage: "power",
                    title: "Launch at Login",
                    subtitle: "Automatically launch MenuBarDeclutter when you log in to macOS."
                ) {
                    Toggle("Launch at Login", isOn: $settingsStore.launchAtLoginEnabled)
                        .labelsHidden()
                        .onChange(of: settingsStore.launchAtLoginEnabled) { _, newValue in
                            launchAtLoginService?.apply(enabled: newValue)
                        }
                }

                if let service = launchAtLoginService {
                    ClearGlassDivider()

                    ClearGlassControlRow(
                        systemImage: "checkmark.circle",
                        title: "SMAppService Status",
                        subtitle: "Helper tool status for reliable menu bar management.",
                        iconTint: loginItemStatusStyle(service.statusDisplayName).tint
                    ) {
                        HStack(spacing: 10) {
                            ClearGlassStatusValue(
                                text: service.statusDisplayName,
                                style: loginItemStatusStyle(service.statusDisplayName)
                            )

                            Button("Refresh", systemImage: "arrow.clockwise") {
                                service.refreshStatus()
                            }

                            Button("Open Settings", systemImage: "arrow.up.forward.app") {
                                _ = service.openLoginItemsSettings()
                            }
                        }
                    }

                    ClearGlassDivider()

                    ClearGlassValueRow("Running From", subtitle: "Current app bundle location.") {
                        Text(Bundle.main.bundleURL.path)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                            .frame(maxWidth: 360, alignment: .trailing)
                    }

                    if let result = service.lastRegistrationResult {
                        ClearGlassDivider()

                        ClearGlassValueRow("Last Login Item Action") {
                            Text(result.displayName)
                                .font(.callout)
                                .lineLimit(2)
                                .truncationMode(.middle)
                        }
                    }

                    HStack(spacing: 10) {
                        Button("Open Installed App Location", systemImage: "folder") {
                            NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                        }

                        Spacer()
                    }

                    ClearGlassInlineMessage(
                        text: "Launch at Login must be validated from an installed, signed app. Xcode runs can report a different SMAppService status.",
                        systemImage: "info.circle",
                        style: .secondary
                    )

                    if !isRunningFromApplications {
                        ClearGlassInlineMessage(
                            text: "You are not running from /Applications. Install the exported app before validating Launch at Login.",
                            systemImage: "exclamationmark.triangle",
                            style: .warning
                        )
                    }

                    if let result = service.lastRegistrationResult, result.isFailure {
                        ClearGlassInlineMessage(
                            text: "Launch at Login could not be configured. Open Login Items Settings, remove stale entries, then try again from the installed app.",
                            systemImage: "exclamationmark.triangle",
                            style: .warning
                        )
                    }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "rectangle.compress.vertical",
                    title: "Start collapsed",
                    subtitle: "Open with menu bar items hidden on next launch."
                ) {
                    Toggle("Start collapsed", isOn: $settingsStore.startCollapsed)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassValueRow("Last Known App Version") {
                    Text(settingsStore.lastKnownAppVersion)
                        .font(.callout)
                }
            }

            ClearGlassSection("Layout", subtitle: "Reset app layout and preference state when needed.") {
                ClearGlassControlRow(
                    systemImage: "arrow.counterclockwise",
                    title: "Reset App Layout",
                    subtitle: "Reset separator placement and layout state without changing app preferences."
                ) {
                    Button("Reset App Layout") {
                        onResetLayout?()
                    }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "exclamationmark.arrow.triangle.2.circlepath",
                    title: "Reset All Settings",
                    subtitle: "Restore default app preferences. Hidden icons and separator positions remain managed by macOS.",
                    iconTint: .red
                ) {
                    Button("Reset All Settings", role: .destructive) {
                        showResetAllConfirmation = true
                    }
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

            ClearGlassSection("Onboarding", subtitle: "First-run education and completion state.") {
                ClearGlassControlRow(
                    systemImage: "checkmark.circle",
                    title: "Onboarding Completed",
                    subtitle: "Tracks whether the first-run flow has already been completed."
                ) {
                    Toggle("Onboarding Completed", isOn: $settingsStore.hasCompletedOnboarding)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "sparkles",
                    title: "Show Onboarding Again",
                    subtitle: "View the onboarding tour and feature introduction again."
                ) {
                    Button("Show Onboarding Again") {
                        onShowOnboarding?()
                    }
                    .disabled(!settingsStore.hasCompletedOnboarding)
                }
            }

            ClearGlassSection("App", subtitle: "Build and bundle metadata.") {
                metadataRow("Name", value: AppConstants.displayName)
                ClearGlassDivider()
                metadataRow("Marketing Version", value: versionOrDash(AppConstants.marketingVersion))
                ClearGlassDivider()
                metadataRow("Build Number", value: versionOrDash(AppConstants.buildNumber))
                ClearGlassDivider()
                metadataRow("App Version", value: AppConstants.appVersion)
                ClearGlassDivider()
                metadataRow("Bundle Identifier", value: AppConstants.bundleIdentifier, monospaced: true)
            }
        }
        .onAppear {
            launchAtLoginService?.refreshStatus()
        }
    }

    private func metadataRow(_ title: String, value: String, monospaced: Bool = false) -> some View {
        ClearGlassValueRow(title) {
            Text(value)
                .font(monospaced ? .system(.caption, design: .monospaced) : .callout)
                .textSelection(.enabled)
        }
    }

    private func versionOrDash(_ value: String) -> String {
        value.isEmpty ? "-" : value
    }

    private func loginItemStatusStyle(_ status: String) -> ClearGlassStatusStyle {
        if status == "Enabled" || status == "Registered" {
            return .success
        }

        if status == "Requires Approval" {
            return .warning
        }

        if status == "Not Found" {
            return .danger
        }

        return .secondary
    }
}

#Preview {
    GeneralSettingsView(settingsStore: SettingsStore())
}
