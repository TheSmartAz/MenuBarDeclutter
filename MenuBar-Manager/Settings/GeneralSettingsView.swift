import AppKit
import SwiftUI

/// General settings: app identity, startup behavior, onboarding, and recovery actions.
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

    private var appLocationSummary: String {
        isRunningFromApplications ? "Installed in Applications" : "Not Installed"
    }

    var body: some View {
        ClearGlassSettingsPage(
            "General",
            subtitle: "App identity, startup behavior, setup state, and maintenance actions.",
            badges: [.stable, .basicMode, .privacySafe],
            sectionAnchors: [
                ClearGlassPageAnchor("About", systemImage: "info.circle"),
                ClearGlassPageAnchor("Startup", systemImage: "power"),
                ClearGlassPageAnchor("Location", systemImage: "folder", targetID: "App Location"),
                ClearGlassPageAnchor("Setup", systemImage: "play.circle"),
                ClearGlassPageAnchor("Maintenance", systemImage: "wrench.and.screwdriver"),
                ClearGlassPageAnchor("Version", systemImage: "number")
            ]
        ) {
            safeDefaultsNotice

            GeneralOverviewStrip(
                mode: settingsStore.appMode.displayName,
                launchStatus: launchStatusText,
                launchStyle: loginItemStatusStyle(launchStatusText),
                isRunningFromApplications: isRunningFromApplications,
                hasCompletedOnboarding: settingsStore.hasCompletedOnboarding
            )

            aboutSection
            startupSection
            appLocationSection
            setupSection
            maintenanceSection
            versionSection
        }
        .onAppear {
            launchAtLoginService?.refreshStatus()
        }
    }

    private var aboutSection: some View {
        ClearGlassSection("About", subtitle: "Local app identity and current operating mode.") {
            GeneralAppIdentityHeader(
                mode: settingsStore.appMode.displayName,
                version: AppConstants.appVersion,
                bundleIdentifier: AppConstants.bundleIdentifier
            )

            ClearGlassDivider()

            ClearGlassValueRow("App Mode", subtitle: "Basic Mode remains fully usable without sensitive permissions.") {
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

            ClearGlassDivider()

            ClearGlassInlineMessage(
                text: "General settings do not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
    }

    private var startupSection: some View {
        ClearGlassSection("Startup", subtitle: "Launch behavior and first-visible state.") {
            ClearGlassControlRow(
                systemImage: "power",
                title: "Launch at Login",
                subtitle: "Open MenuBarDeclutter automatically after signing in."
            ) {
                Toggle("Launch at Login", isOn: $settingsStore.launchAtLoginEnabled)
                    .labelsHidden()
                    .onChange(of: settingsStore.launchAtLoginEnabled) { _, newValue in
                        launchAtLoginService?.apply(enabled: newValue)
                    }
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "rectangle.compress.vertical",
                title: "Start Collapsed",
                subtitle: "Begin the next launch with hidden menu bar items collapsed."
            ) {
                Toggle("Start Collapsed", isOn: $settingsStore.startCollapsed)
                    .labelsHidden()
            }

            if let service = launchAtLoginService {
                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: loginStatusImage(service.statusDisplayName),
                    title: "Login Item Status",
                    subtitle: "macOS controls final approval in Login Items settings.",
                    iconTint: loginItemStatusStyle(service.statusDisplayName).foreground
                ) {
                    loginStatusActions(service)
                }

                if let result = service.lastRegistrationResult {
                    ClearGlassDivider()

                    ClearGlassValueRow("Last Login Item Action") {
                        Text(result.displayName)
                            .font(.callout)
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                }
            } else {
                ClearGlassDivider()

                ClearGlassInlineMessage(
                    text: "Launch at Login status is unavailable in this preview environment.",
                    systemImage: "power",
                    style: .secondary
                )
            }
        }
    }

    private var appLocationSection: some View {
        ClearGlassSection("App Location", subtitle: "Install location used for Login Items validation.") {
            ClearGlassControlRow(
                systemImage: isRunningFromApplications ? "checkmark.circle" : "exclamationmark.triangle",
                title: appLocationSummary,
                subtitle: Bundle.main.bundleURL.path,
                iconTint: isRunningFromApplications ? .green : .orange
            ) {
                Button("Reveal in Finder", systemImage: "folder") {
                    NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                }
                .controlSize(.small)
            }

            if !isRunningFromApplications {
                ClearGlassDivider()

                ClearGlassInlineMessage(
                    text: "Install the exported, signed app in /Applications before validating Launch at Login.",
                    systemImage: "info.circle",
                    style: .warning
                )
            }

            if let result = launchAtLoginService?.lastRegistrationResult, result.isFailure {
                ClearGlassDivider()

                ClearGlassInlineMessage(
                    text: "Launch at Login could not be configured. Open Login Items Settings, remove stale entries, then try again from the installed app.",
                    systemImage: "exclamationmark.triangle",
                    style: .warning
                )
            }
        }
    }

    private var setupSection: some View {
        ClearGlassSection("Setup", subtitle: "Onboarding progress and first-run education.") {
            ClearGlassControlRow(
                systemImage: settingsStore.hasCompletedOnboarding ? "checkmark.circle" : "circle",
                title: "Onboarding Completed",
                subtitle: "Tracks whether the first-run flow has already been completed.",
                iconTint: settingsStore.hasCompletedOnboarding ? .green : .secondary
            ) {
                Toggle("Onboarding Completed", isOn: $settingsStore.hasCompletedOnboarding)
                    .labelsHidden()
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "play.circle",
                title: "Show Onboarding Again",
                subtitle: "Reopen the setup tour and feature introduction."
            ) {
                Button("Show Onboarding", systemImage: "play.circle") {
                    onShowOnboarding?()
                }
                .disabled(!settingsStore.hasCompletedOnboarding)
            }
        }
    }

    private var maintenanceSection: some View {
        ClearGlassSection("Maintenance", subtitle: "Recovery actions for layout and preferences.") {
            ClearGlassControlRow(
                systemImage: "arrow.counterclockwise",
                title: "Reset App Layout",
                subtitle: "Reset separator placement and layout state without changing preferences."
            ) {
                Button("Reset Layout", systemImage: "arrow.counterclockwise") {
                    onResetLayout?()
                }
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "exclamationmark.arrow.triangle.2.circlepath",
                title: "Reset All Settings",
                subtitle: "Restore default preferences. Hidden icons and separator positions remain managed by macOS.",
                iconTint: .red
            ) {
                Button("Reset Settings", systemImage: "exclamationmark.arrow.triangle.2.circlepath", role: .destructive) {
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
                Text("This restores default app preferences. Hidden icons and separator position are managed by macOS and are not changed.")
            }
        }
    }

    private var versionSection: some View {
        ClearGlassSection("Version", subtitle: "Build and bundle metadata.") {
            metadataRow("Name", value: AppConstants.displayName)
            ClearGlassDivider()
            metadataRow("Marketing Version", value: versionOrDash(AppConstants.marketingVersion))
            ClearGlassDivider()
            metadataRow("Build Number", value: versionOrDash(AppConstants.buildNumber))
            ClearGlassDivider()
            metadataRow("App Version", value: AppConstants.appVersion)
            ClearGlassDivider()
            metadataRow("Bundle Identifier", value: AppConstants.bundleIdentifier, monospaced: true)
            ClearGlassDivider()
            metadataRow("Last Known App Version", value: settingsStore.lastKnownAppVersion)
        }
    }

    @ViewBuilder
    private var safeDefaultsNotice: some View {
        if settingsStore.v01SafeDefaultsNoticePending {
            ClearGlassSection("Update Notice") {
                ClearGlassControlRow(
                    systemImage: "checkmark.shield",
                    title: "Updated to v0.1 safe defaults",
                    subtitle: "Privacy-first defaults were applied during migration.",
                    iconTint: .green
                ) {
                    Button("Dismiss") {
                        settingsStore.v01SafeDefaultsNoticePending = false
                    }
                }
            }
        }
    }

    private var launchStatusText: String {
        if let launchAtLoginService {
            launchAtLoginService.statusDisplayName
        } else {
            settingsStore.launchAtLoginEnabled ? "Requested" : "Off"
        }
    }

    private func loginStatusActions(_ service: LaunchAtLoginService) -> some View {
        Group {
            ClearGlassStatusValue(
                text: service.statusDisplayName,
                style: loginItemStatusStyle(service.statusDisplayName)
            )

            Button("Refresh", systemImage: "arrow.clockwise") {
                service.refreshStatus()
            }
            .controlSize(.small)

            Button("Open Settings", systemImage: "arrow.up.forward.app") {
                _ = service.openLoginItemsSettings()
            }
            .controlSize(.small)
        }
    }

    private func metadataRow(_ title: String, value: String, monospaced: Bool = false) -> some View {
        ClearGlassValueRow(title) {
            Text(value)
                .font(monospaced ? .system(.caption, design: .monospaced) : .callout)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .frame(maxWidth: 420, alignment: .trailing)
        }
    }

    private func versionOrDash(_ value: String) -> String {
        value.isEmpty ? "-" : value
    }

    private func loginStatusImage(_ status: String) -> String {
        switch status {
        case "Enabled", "Registered":
            "checkmark.circle"
        case "Requires Approval":
            "exclamationmark.triangle"
        case "Not Found":
            "xmark.circle"
        default:
            "power"
        }
    }

    private func loginItemStatusStyle(_ status: String) -> ClearGlassStatusStyle {
        if status == "Enabled" || status == "Registered" {
            return .success
        }

        if status == "Requires Approval" || status == "Requested" {
            return .warning
        }

        if status == "Not Found" {
            return .danger
        }

        return .secondary
    }
}

private struct GeneralOverviewStrip: View {
    let mode: String
    let launchStatus: String
    let launchStyle: ClearGlassStatusStyle
    let isRunningFromApplications: Bool
    let hasCompletedOnboarding: Bool

    var body: some View {
        ClearGlassOverviewStrip([
            ClearGlassOverviewMetric(
                title: "Mode",
                value: mode,
                systemImage: "checkmark.shield",
                style: .success
            ),
            ClearGlassOverviewMetric(
                title: "Login Item",
                value: launchStatus,
                systemImage: "power",
                style: launchStyle
            ),
            ClearGlassOverviewMetric(
                title: "Location",
                value: isRunningFromApplications ? "Applications" : "Other",
                systemImage: isRunningFromApplications ? "checkmark.circle" : "exclamationmark.triangle",
                style: isRunningFromApplications ? .success : .warning
            ),
            ClearGlassOverviewMetric(
                title: "Onboarding",
                value: hasCompletedOnboarding ? "Done" : "Pending",
                systemImage: hasCompletedOnboarding ? "checkmark.circle" : "circle",
                style: hasCompletedOnboarding ? .success : .secondary
            )
        ])
    }
}

private struct GeneralAppIdentityHeader: View {
    let mode: String
    let version: String
    let bundleIdentifier: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 48, height: 48)
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(AppConstants.displayName)
                    .font(.title3)

                Text("\(version) - \(mode)")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(bundleIdentifier)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
            .layoutPriority(1)

            Spacer(minLength: 16)

            ClearGlassStatusValue(text: mode, style: .success)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    GeneralSettingsView(settingsStore: SettingsStore())
}
