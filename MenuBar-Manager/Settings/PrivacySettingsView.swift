import SwiftUI

struct PrivacySettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var screenCapturePermissionService: ScreenCapturePermissionService?
    var iconCaptureCoordinator: MenuBarIconCaptureCoordinator?
    var scanCoordinator: MenuBarScanCoordinator?
    var onChange: (() -> Void)? = nil

    @State private var accurateIconCacheMessage: String?

    var body: some View {
        ClearGlassSettingsPage(
            "Privacy",
            subtitle: "Basic Mode stays permission-free. Optional capabilities are explicit and local-first when you enable them.",
            badges: [.stable, .privacySafe, .basicMode]
        ) {
            PrivacyStatusOverview(
                proModeEnabled: settingsStore.proModeEnabled,
                accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
                accessibilityStatusText: accessibilityStatusText,
                accessibilityStatusStyle: accessibilityStatusStyle,
                accurateIconsStatusText: accurateIconsStatusText,
                accurateIconsStatusStyle: accurateIconsStatusStyle,
                screenCaptureStatusText: screenCaptureStatusText,
                screenCaptureStatusStyle: screenCaptureStatusStyle
            )

            ProSecondBarSetupChecklistView(
                settingsStore: settingsStore,
                permissionService: permissionService,
                screenCapturePermissionService: screenCapturePermissionService,
                iconCaptureCoordinator: iconCaptureCoordinator,
                scanCoordinator: scanCoordinator,
                onChange: onChange
            )

            PrivacyTrustBoundarySummary(accessibilityIdentifier: "privacy.modeBoundary")
            basicModeSection
            proModeSection
            accurateIconsSection
            localDataSection
            diagnosticsSection
        }
    }

    private var basicModeSection: some View {
        ClearGlassSection("Basic Mode Privacy", subtitle: "Default mode. Fully usable without elevated permissions or network access.") {
            PrivacyPermissionRow(
                systemImage: "hand.raised",
                title: "Accessibility",
                subtitle: "Basic Mode never asks to inspect other apps or menu bar item metadata.",
                status: "Basic Mode",
                style: .success
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "rectangle.on.rectangle",
                title: "Screen Recording",
                subtitle: "Basic Mode never captures screen contents. Accurate Icons is a separate opt-in below.",
                status: "Basic Mode",
                style: .success
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "apple.terminal",
                title: "Apple Events",
                subtitle: "MenuBarDeclutter does not control other applications in Basic Mode.",
                status: "Basic Mode",
                style: .success
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "keyboard",
                title: "Input Monitoring",
                subtitle: "The global shortcut path does not require keyboard monitoring permission.",
                status: "Basic Mode",
                style: .success
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "network.slash",
                title: "Network Access",
                subtitle: "No telemetry, sync, analytics, or remote lookup is performed.",
                status: "Basic Mode",
                style: .success
            )

            ClearGlassDivider()

            ClearGlassInlineMessage(
                text: "Basic Mode continues to work when Optional Pro is off, unavailable, or denied.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
        .accessibilityIdentifier("privacy.basicMode.section")
    }

    private var proModeSection: some View {
        ClearGlassSection("Optional Pro Discovery", subtitle: "Optional local menu bar metadata stays behind explicit controls.") {
            PrivacyProModeRow(
                isEnabled: settingsStore.proModeEnabled,
                enableAction: enableProMode
            )

            ClearGlassDivider()

            ClearGlassInlineMessage(
                text: "Setup is explicit: enable Optional Pro, turn on Accessibility Discovery, request Accessibility permission from your own button press, then rescan.",
                systemImage: "list.bullet.rectangle",
                style: .info
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "figure.circle",
                title: "Accessibility Discovery",
                subtitle: "Read menu bar item frames and labels locally for Optional Pro surfaces.",
                status: settingsStore.accessibilityDiscoveryEnabled ? "Optional Pro" : "Unavailable",
                style: settingsStore.accessibilityDiscoveryEnabled ? .info : .secondary
            ) {
                Toggle("Accessibility Discovery", isOn: $settingsStore.accessibilityDiscoveryEnabled)
                    .labelsHidden()
                    .disabled(!settingsStore.proModeEnabled)
                    .onChange(of: settingsStore.accessibilityDiscoveryEnabled) {
                        notifyPrivacyChanged()
                    }
            }
            .opacity(settingsStore.proModeEnabled ? 1 : 0.72)

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "hand.raised",
                title: "Accessibility Permission",
                subtitle: "Required only when Optional Pro discovery is enabled. The prompt is shown only from an explicit Request Permission button.",
                status: accessibilityStatusText,
                style: accessibilityStatusStyle
            ) {
                accessibilityButtons
            }
            .opacity(settingsStore.proModeEnabled ? 1 : 0.72)

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "arrow.clockwise",
                title: "Rescan",
                subtitle: "Refresh local menu bar metadata after changing Optional Pro or Accessibility settings.",
                status: canRequestRescan ? "Optional Pro" : "Unavailable",
                style: canRequestRescan ? .info : .secondary
            ) {
                Button("Rescan", systemImage: "arrow.clockwise") {
                    scanCoordinator?.requestManualRefresh()
                }
                .controlSize(.small)
                .disabled(!canRequestRescan)
            }
            .opacity(settingsStore.proModeEnabled ? 1 : 0.72)

            ClearGlassDivider()

            PrivacyScanThrottleRow(
                value: $settingsStore.menuBarScanIntervalSeconds,
                isEnabled: settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled
            )
            .onChange(of: settingsStore.menuBarScanIntervalSeconds) {
                notifyPrivacyChanged()
            }

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "lock",
                title: "Return to Basic Mode",
                subtitle: "Turns off Optional Pro and Accessibility Discovery. Basic Mode remains available.",
                status: settingsStore.proModeEnabled ? "Optional Pro" : "Basic Mode",
                style: settingsStore.proModeEnabled ? .warning : .secondary
            ) {
                Button("Return to Basic Mode", systemImage: "lock", role: .destructive) {
                    PrivacyProSetupActions.disableProMode(settingsStore: settingsStore)
                    notifyPrivacyChanged()
                }
                .disabled(!settingsStore.proModeEnabled)
            }

            if showsProModeMessage {
                ClearGlassDivider()
                proModeMessage
            }
        }
        .accessibilityIdentifier("privacy.proDiscovery.section")
    }

    private var accurateIconsSection: some View {
        ClearGlassSection("Accurate Icons", subtitle: "Optional local rendered thumbnails for item surfaces.") {
            ClearGlassInlineMessage(
                text: "Accurate Icons captures small menu bar item thumbnails locally after you enable it and grant Screen Recording. Full screenshots are not exported.",
                systemImage: "menubar.rectangle",
                style: .info
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "sparkle.magnifyingglass",
                title: "Rendered Icon Capture",
                subtitle: "Use cropped rendered pixels before falling back to app bundle icons.",
                status: accurateIconsStatusText,
                style: accurateIconsStatusStyle
            ) {
                Toggle("Rendered Icon Capture", isOn: $settingsStore.renderedIconCaptureEnabled)
                    .labelsHidden()
                    .onChange(of: settingsStore.renderedIconCaptureEnabled) {
                        if !settingsStore.renderedIconCaptureEnabled {
                            settingsStore.renderedIconRevealSweepEnabled = false
                        }
                        screenCapturePermissionService?.refreshStatus()
                        notifyPrivacyChanged()
                    }
            }

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "rectangle.on.rectangle",
                title: "Screen Recording Permission",
                subtitle: "Required only for Accurate Icons. The request is shown from your button press.",
                status: screenCaptureStatusText,
                style: screenCaptureStatusStyle
            ) {
                screenCaptureButtons
            }
            .opacity(settingsStore.renderedIconCaptureEnabled ? 1 : 0.72)

            if showsScreenCaptureRecoveryInstruction,
               let instruction = screenCapturePermissionService?.status.recoveryInstruction {
                ClearGlassDivider()
                ClearGlassInlineMessage(
                    text: instruction,
                    systemImage: "plus.app",
                    style: .info
                )
            }

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "arrow.triangle.2.circlepath",
                title: "Reveal Sweep",
                subtitle: "Temporarily reveals our hidden items during user interaction, captures thumbnails, then restores visibility.",
                status: settingsStore.renderedIconRevealSweepEnabled ? "On" : "Off",
                style: settingsStore.renderedIconRevealSweepEnabled ? .info : .secondary
            ) {
                Toggle("Reveal Sweep", isOn: $settingsStore.renderedIconRevealSweepEnabled)
                    .labelsHidden()
                    .disabled(!settingsStore.renderedIconCaptureEnabled)
                    .onChange(of: settingsStore.renderedIconRevealSweepEnabled) {
                        notifyPrivacyChanged()
                    }
            }
            .opacity(settingsStore.renderedIconCaptureEnabled ? 1 : 0.72)

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "trash",
                title: "Rendered Icon Cache",
                subtitle: "Deletes local thumbnail files and in-memory rendered icon images.",
                status: "Local",
                style: .secondary
            ) {
                Button("Clear Cache", systemImage: "trash") {
                    let success = iconCaptureCoordinator?.clearCache() ?? false
                    accurateIconCacheMessage = success ? "Cache cleared." : "Cache unavailable."
                }
                .controlSize(.small)
                .disabled(iconCaptureCoordinator == nil)
            }

            if let accurateIconCacheMessage {
                ClearGlassDivider()
                ClearGlassInlineMessage(
                    text: accurateIconCacheMessage,
                    systemImage: "checkmark.circle",
                    style: .success
                )
            }
        }
        .accessibilityIdentifier("privacy.accurateIcons.section")
    }

    private var accessibilityButtons: some View {
        Group {
            Button("Request Permission", systemImage: "hand.raised") {
                requestAccessibilityPermission()
                notifyPrivacyChanged()
            }
            .disabled(!canUseAccessibilityPermissionControls || permissionService?.status == .granted)
            .accessibilityIdentifier("privacy.action.requestPermission")

            Button("Open Settings", systemImage: "gearshape") {
                permissionService?.openSystemSettingsPrivacyPane()
            }
            .disabled(!canUseAccessibilityPermissionControls)
            .accessibilityIdentifier("privacy.action.openAccessibilitySettings")
        }
        .controlSize(.small)
    }

    private var screenCaptureButtons: some View {
        Group {
            Button("Request Permission", systemImage: "rectangle.on.rectangle") {
                requestScreenCapturePermission()
                notifyPrivacyChanged()
            }
            .disabled(!canUseScreenCapturePermissionControls || screenCapturePermissionService?.status == .granted)
            .accessibilityIdentifier("privacy.action.requestScreenCapturePermission")

            Button("Open Settings", systemImage: "gearshape") {
                screenCapturePermissionService?.openSystemSettingsPrivacyPane()
                screenCapturePermissionService?.refreshStatus()
            }
            .disabled(!canUseScreenCapturePermissionControls)
            .accessibilityIdentifier("privacy.action.openScreenCaptureSettings")
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private var proModeMessage: some View {
        if !settingsStore.proModeEnabled {
            ClearGlassInlineMessage(
                text: "Basic Mode is active. Optional Pro controls are inactive, and no Accessibility prompt is requested.",
                systemImage: "lock",
                style: .secondary
            )
        } else if !settingsStore.accessibilityDiscoveryEnabled {
            ClearGlassInlineMessage(
                text: "Optional Pro is on, but local discovery is off. Optional Pro surfaces show Unavailable until discovery is enabled.",
                systemImage: "pause.circle",
                style: .warning
            )
        } else if permissionService?.status == .denied {
            ClearGlassInlineMessage(
                text: "Accessibility is denied in System Settings. Optional Pro discovery remains unavailable, but Basic Mode keeps working.",
                systemImage: "exclamationmark.triangle",
                style: .warning
            )
        } else if permissionService?.status == .granted {
            ClearGlassInlineMessage(
                text: "Accessibility is granted for local Optional Pro discovery. Screen Recording, Apple Events, Input Monitoring, and network access are still not used here.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
    }

    private var showsProModeMessage: Bool {
        !settingsStore.proModeEnabled
            || !settingsStore.accessibilityDiscoveryEnabled
            || permissionService?.status == .denied
            || permissionService?.status == .granted
    }

    private var canRequestRescan: Bool {
        settingsStore.proModeEnabled
            && settingsStore.accessibilityDiscoveryEnabled
            && permissionService?.status == .granted
            && scanCoordinator != nil
    }

    private var canUseAccessibilityPermissionControls: Bool {
        settingsStore.proModeEnabled
            && settingsStore.accessibilityDiscoveryEnabled
            && permissionService != nil
    }

    private var canUseScreenCapturePermissionControls: Bool {
        settingsStore.renderedIconCaptureEnabled
            && screenCapturePermissionService != nil
    }

    private var showsScreenCaptureRecoveryInstruction: Bool {
        settingsStore.renderedIconCaptureEnabled
            && screenCapturePermissionService?.status != .granted
    }

    private var localDataSection: some View {
        ClearGlassSection("Local Data Path", subtitle: "The app keeps its processing path on this Mac.") {
            PrivacyLocalDataFlow()

            ClearGlassDivider()

            ClearGlassInlineMessage(
                text: "MenuBarDeclutter does not collect, store, or transmit personal data. Local settings and diagnostics stay on disk unless you export them.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
    }

    private var diagnosticsSection: some View {
        ClearGlassSection("Diagnostics Export", subtitle: "Support bundles avoid sensitive visual or network data.") {
            PrivacyPermissionRow(
                systemImage: "doc.zipper",
                title: "Export Contents",
                subtitle: "Includes app version, macOS version, architecture, screen frames, current settings, and recent log messages.",
                status: "Local File",
                style: .info
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "eye.slash",
                title: "Excluded Data",
                subtitle: "Screenshots, screen contents, rendered icon thumbnails, personal file paths, and network payloads are excluded.",
                status: "Excluded",
                style: .success
            )
        }
    }

    private var accessibilityStatusText: String {
        permissionService?.status.displayName
            ?? AccessibilityPermissionStatus.notRequested.displayName
    }

    private var accessibilityStatusStyle: ClearGlassStatusStyle {
        guard settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled else {
            return .secondary
        }

        switch permissionService?.status ?? .notRequested {
        case .granted:
            return .success
        case .denied:
            return .danger
        case .notRequested:
            return .warning
        case .unknown:
            return .secondary
        }
    }

    private var accurateIconsStatusText: String {
        guard settingsStore.renderedIconCaptureEnabled else { return "Off" }
        return screenCapturePermissionService?.status == .granted ? "Ready" : "Needs Permission"
    }

    private var accurateIconsStatusStyle: ClearGlassStatusStyle {
        guard settingsStore.renderedIconCaptureEnabled else { return .secondary }
        return screenCapturePermissionService?.status == .granted ? .success : .warning
    }

    private var screenCaptureStatusText: String {
        screenCapturePermissionService?.status.displayName
            ?? ScreenCapturePermissionStatus.notGranted.displayName
    }

    private var screenCaptureStatusStyle: ClearGlassStatusStyle {
        guard settingsStore.renderedIconCaptureEnabled else { return .secondary }
        return screenCapturePermissionService?.status == .granted ? .success : .warning
    }


    private func enableProMode() {
        PrivacyProSetupActions.enableProMode(
            settingsStore: settingsStore,
            permissionService: permissionService
        )
        notifyPrivacyChanged()
    }

    private func requestAccessibilityPermission() {
        guard let permissionService else { return }
        let status = permissionService.requestPromptFromUserAction()
        if status != .granted {
            permissionService.openSystemSettingsPrivacyPane()
        }
    }

    private func requestScreenCapturePermission() {
        guard let screenCapturePermissionService else { return }
        let status = screenCapturePermissionService.requestPermissionFromUserAction()
        if status != .granted {
            screenCapturePermissionService.openSystemSettingsPrivacyPane()
        }
    }

    private func notifyPrivacyChanged() {
        screenCapturePermissionService?.refreshStatus()
        if let onChange {
            onChange()
        } else {
            scanCoordinator?.refreshAfterSettingsChanged()
        }
    }
}

@MainActor
enum PrivacyProSetupActions {
    static func enableProMode(
        settingsStore: SettingsStore,
        permissionService: AccessibilityPermissionService?
    ) {
        settingsStore.proModeEnabled = true
        permissionService?.refreshStatus()
    }

    static func disableProMode(settingsStore: SettingsStore) {
        settingsStore.proModeEnabled = false
        settingsStore.accessibilityDiscoveryEnabled = false
        settingsStore.secondBarPrimaryClickEnabled = false
    }
}

private struct PrivacyStatusOverview: View {
    let proModeEnabled: Bool
    let accessibilityDiscoveryEnabled: Bool
    let accessibilityStatusText: String
    let accessibilityStatusStyle: ClearGlassStatusStyle
    let accurateIconsStatusText: String
    let accurateIconsStatusStyle: ClearGlassStatusStyle
    let screenCaptureStatusText: String
    let screenCaptureStatusStyle: ClearGlassStatusStyle

    var body: some View {
        ClearGlassOverviewStrip([
            ClearGlassOverviewMetric(
                title: "Basic Mode",
                value: "Ready",
                systemImage: "checkmark.shield",
                style: .success
            ),
            ClearGlassOverviewMetric(
                title: "Optional Pro",
                value: proModeEnabled ? "Optional Pro" : "Basic Mode",
                systemImage: "star",
                style: proModeEnabled ? .info : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Discovery",
                value: accessibilityDiscoveryEnabled ? "Optional Pro" : "Unavailable",
                systemImage: "figure.circle",
                style: accessibilityDiscoveryEnabled ? .info : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Accessibility",
                value: accessibilityStatusText,
                systemImage: "hand.raised",
                style: accessibilityStatusStyle
            ),
            ClearGlassOverviewMetric(
                title: "Accurate Icons",
                value: accurateIconsStatusText,
                systemImage: "sparkle.magnifyingglass",
                style: accurateIconsStatusStyle
            ),
            ClearGlassOverviewMetric(
                title: "Screen Recording",
                value: screenCaptureStatusText,
                systemImage: "rectangle.on.rectangle",
                style: screenCaptureStatusStyle
            )
        ], maximumColumnCount: 3)
    }
}

private struct PrivacyProModeRow: View {
    let isEnabled: Bool
    let enableAction: () -> Void

    var body: some View {
        PrivacyPermissionRow(
            systemImage: isEnabled ? "lock.open" : "star",
            title: "Optional Pro",
            subtitle: isEnabled
                ? "Advanced features can use local Accessibility discovery when discovery and permission are available."
                : "Enable only when you want optional features that inspect menu bar metadata locally.",
            status: isEnabled ? "Optional Pro" : "Basic Mode",
            style: isEnabled ? .info : .secondary
        ) {
            if !isEnabled {
                Button("Enable Optional Pro", systemImage: "lock.open", action: enableAction)
                    .controlSize(.small)
                    .accessibilityIdentifier("privacy.action.enableProMode")
            }
        }
    }
}

private struct PrivacyPermissionRow<Accessory: View>: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let status: String
    let style: ClearGlassStatusStyle
    @ViewBuilder let accessory: Accessory

    init(
        systemImage: String,
        title: String,
        subtitle: String,
        status: String,
        style: ClearGlassStatusStyle = .secondary,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.status = status
        self.style = style
        self.accessory = accessory()
    }

    var body: some View {
        ClearGlassStatusControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: style.tint,
            statusText: status,
            statusStyle: style
        ) {
            accessory
        }
    }
}

private extension PrivacyPermissionRow where Accessory == EmptyView {
    init(
        systemImage: String,
        title: String,
        subtitle: String,
        status: String,
        style: ClearGlassStatusStyle = .secondary
    ) {
        self.init(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            status: status,
            style: style
        ) {
            EmptyView()
        }
    }
}

private struct PrivacyScanThrottleRow: View {
    @Binding var value: Double
    let isEnabled: Bool

    var body: some View {
        ClearGlassStatusControlRow(
            systemImage: "clock",
            title: "Scan Throttle",
            subtitle: "Slow local discovery scans to reduce system impact.",
            iconTint: .secondary,
            statusText: isEnabled ? "Active" : "Off",
            statusStyle: isEnabled ? .info : .secondary
        ) {
            HStack(spacing: 10) {
                Text(value, format: .number.precision(.fractionLength(1)))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .trailing)

                Text("s")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Stepper(
                    "Scan Throttle",
                    value: $value,
                    in: AppConstants.minMenuBarScanIntervalSeconds...AppConstants.maxMenuBarScanIntervalSeconds,
                    step: 0.5
                )
                .labelsHidden()
            }
            .disabled(!isEnabled)
        }
        .opacity(isEnabled ? 1 : 0.72)
    }
}

private struct PrivacyLocalDataFlow: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                dataNode(systemImage: "macbook", title: "Your Mac", detail: "Settings")
                flowArrow
                dataNode(systemImage: "internaldrive", title: "Local Index", detail: "On disk")
                flowArrow
                dataNode(systemImage: "network.slash", title: "No Network", detail: "No telemetry")
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 8) {
                dataNode(systemImage: "macbook", title: "Your Mac", detail: "Settings")
                dataNode(systemImage: "internaldrive", title: "Local Index", detail: "On disk")
                dataNode(systemImage: "network.slash", title: "No Network", detail: "No telemetry")
            }
        }
        .padding(.vertical, 8)
    }

    private var flowArrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    private func dataNode(systemImage: String, title: String, detail: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(nsColor: .textBackgroundColor))

                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(minWidth: 170, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
        }
    }
}

#Preview {
    PrivacySettingsPreviewFactory.make()
}

private enum PrivacySettingsPreviewFactory {
    @MainActor
    static func make() -> PrivacySettingsView {
        let store = SettingsStore()
        let logger = DiagnosticsLogger()
        let permissionService = AccessibilityPermissionService(
            settingsStore: store,
            diagnosticsLogger: logger,
            trustProvider: { false },
            promptTrustProvider: { false },
            systemSettingsOpener: { true }
        )
        let screenCaptureService = ScreenCapturePermissionService(
            preflightAccess: { false },
            requestAccess: { false },
            systemSettingsOpener: { true }
        )
        return PrivacySettingsView(
            settingsStore: store,
            permissionService: permissionService,
            screenCapturePermissionService: screenCaptureService,
            scanCoordinator: nil
        )
    }
}
