import SwiftUI

struct PrivateAccessSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    let coordinator: PrivateAccessCoordinator?
    var commandAvailabilities: [MenuBarCommandAvailabilitySummary] = []
    var onChange: (() -> Void)?

    @State private var testStatus: String?

    var body: some View {
        ClearGlassSettingsPage(
            "Private Access",
            subtitle: "Use LocalAuthentication to gate sensitive app actions. No biometric data is stored.",
            badges: [.preview, .privacySafe]
        ) {
            ClearGlassSection("Lock", subtitle: "Authentication options and current lock state.") {
                FeatureGateNotice(
                    .preview,
                    text: "Preview in v0.1.1. Gates app actions only; not encryption or system icon hiding."
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "lock.fill",
                    title: "Enable Private Access",
                    subtitle: "Require Touch ID or device password for protected surfaces."
                ) {
                    Toggle("Enable Private Access", isOn: $settingsStore.privateAccessEnabled)
                        .labelsHidden()
                        .onChange(of: settingsStore.privateAccessEnabled) { _, _ in onChange?() }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "key.fill",
                    title: "Allow Device Password Fallback",
                    subtitle: "Use device-owner authentication when Touch ID is unavailable."
                ) {
                    Toggle("Allow Password Fallback", isOn: $settingsStore.privateAccessAllowDevicePasswordFallback)
                        .labelsHidden()
                        .onChange(of: settingsStore.privateAccessAllowDevicePasswordFallback) { _, _ in onChange?() }
                }

                ClearGlassDivider()

                ClearGlassSliderRow(
                    "Unlock Duration",
                    subtitle: "How long a successful unlock remains active.",
                    value: $settingsStore.privateAccessUnlockDurationSeconds,
                    in: AppConstants.minPrivateAccessUnlockDurationSeconds...AppConstants.maxPrivateAccessUnlockDurationSeconds,
                    step: 30,
                    valueSuffix: "s"
                )

                lockActionControls

                if let testStatus {
                    ClearGlassInlineMessage(text: testStatus, systemImage: "info.circle")
                }
            }

            ClearGlassSection("Protected Surfaces", subtitle: "Choose which app surfaces require authentication.") {
                protectedToggle(
                    title: "Always Hidden Reveal",
                    subtitle: "Require auth before revealing the always-hidden zone.",
                    systemImage: "eye.slash",
                    isOn: $settingsStore.privateAccessProtectAlwaysHidden
                )

                ClearGlassDivider()

                protectedToggle(
                    title: "Second Bar",
                    subtitle: "Require auth before opening Second Bar.",
                    systemImage: "menubar.rectangle",
                    isOn: $settingsStore.privateAccessProtectSecondBar
                )

                ClearGlassDivider()

                protectedToggle(
                    title: "Find Icon",
                    subtitle: "Require auth before opening Find Icon.",
                    systemImage: "magnifyingglass",
                    isOn: $settingsStore.privateAccessProtectFindIcon
                )

                ClearGlassDivider()

                protectedToggle(
                    title: "Icon Moving",
                    subtitle: "Icon moving is protected by default because it changes menu bar organization.",
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    isOn: $settingsStore.privateAccessProtectIconMoving
                )

                ClearGlassDivider()

                protectedToggle(
                    title: "Spacing Labs",
                    subtitle: "Protect spacing commands if Labs apply, restore, or reset operations are enabled.",
                    systemImage: "testtube.2",
                    isOn: $settingsStore.privateAccessProtectSpacingLabs
                )

                ClearGlassDivider()

                protectedToggle(
                    title: "Profile Apply",
                    subtitle: "Require auth before applying a local profile.",
                    systemImage: "person.crop.rectangle.stack",
                    isOn: $settingsStore.privateAccessProtectProfileApply
                )

                ClearGlassDivider()

                protectedToggle(
                    title: "Automation Commands",
                    subtitle: "Require an active unlock before App Intents or URL automation can run protected commands.",
                    systemImage: "sparkles.rectangle.stack",
                    isOn: $settingsStore.privateAccessProtectAutomationCommands
                )
            }

            if !commandAvailabilities.isEmpty {
                ClearGlassSection("Command Center", subtitle: "Shared routing status for protected app actions.") {
                    ForEach(Array(commandAvailabilities.enumerated()), id: \.offset) { index, summary in
                        CommandAvailabilityRow(summary: summary)

                        if index < commandAvailabilities.count - 1 {
                            ClearGlassDivider()
                        }
                    }
                }
            }

            ClearGlassSection("Privacy Boundary", subtitle: "What Private Access does and does not protect.") {
                ClearGlassInlineMessage(
                    text: "Private Access gates MenuBarDeclutter actions. It is not encryption and does not hide third-party menu bar items that are already visible outside the app.",
                    systemImage: "lock.shield",
                    style: .info
                )
            }
        }
    }

    private var lockActionControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                lockButtons
                lockStatus
            }

            VStack(alignment: .leading, spacing: 8) {
                lockButtons
                lockStatus
            }
        }
        .controlSize(.small)
    }

    private var lockButtons: some View {
        HStack(spacing: 10) {
            Button("Test Authentication", systemImage: "touchid") {
                Task { @MainActor in
                    guard let coordinator else {
                        testStatus = "Authentication service unavailable."
                        return
                    }
                    let result = await coordinator.testAuthentication()
                    testStatus = "Authentication \(result.statusString)."
                }
            }
            .disabled(!settingsStore.privateAccessEnabled)

            Button("Clear Unlock Session", systemImage: "lock") {
                coordinator?.clearUnlock()
                testStatus = "Unlock session cleared."
            }
            .disabled(coordinator == nil)
        }
    }

    @ViewBuilder
    private var lockStatus: some View {
        if let coordinator {
            ClearGlassStatusValue(
                text: coordinator.isUnlocked ? "Unlocked" : "Locked",
                style: coordinator.isUnlocked ? .success : .secondary
            )
        }
    }

    private func protectedToggle(
        title: String,
        subtitle: String,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        ClearGlassControlRow(systemImage: systemImage, title: title, subtitle: subtitle) {
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .disabled(!settingsStore.privateAccessEnabled)
                .onChange(of: isOn.wrappedValue) { _, _ in onChange?() }
        }
        .opacity(settingsStore.privateAccessEnabled ? 1 : 0.55)
    }
}
