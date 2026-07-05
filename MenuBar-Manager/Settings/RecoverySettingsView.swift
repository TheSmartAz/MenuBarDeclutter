import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct RecoverySettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var diagnosticsLogger: DiagnosticsLogger?
    var appSupportPaths: AppSupportPaths?
    var diagnosticsExporter: DiagnosticsExporter?
    var liveStatus: LiveDiagnosticsStatus?
    var onRunHealthCheck: (() -> Void)? = nil
    var onFixHealthIssues: (() -> Void)? = nil
    var onExpand: (() -> Void)? = nil
    var onRevealAll: (() -> Void)? = nil
    var onRecreateStatusItems: (() -> Void)? = nil
    var onDisableAutoRehideTemporarily: (() -> Void)? = nil
    var onDisableHoverRevealTemporarily: (() -> Void)? = nil
    var onResetCurrentWorkspaceLayout: (() -> Void)? = nil
    var onRemoveMissingWorkspaceGroupReferences: (() -> Void)? = nil
    var onDiscardSetBuilderDraft: (() -> Void)? = nil
    var onDisableFunctionBarPreview: (() -> Void)? = nil
    var onDisableInfoStripPreview: (() -> Void)? = nil
    var onDisableSetBuilderPreview: (() -> Void)? = nil
    var onResetLayout: (() -> Void)? = nil
    var onResetAllSettings: (() -> Void)? = nil
    var onResetBasicMode: (() -> Void)? = nil
    var onDisableProMode: (() -> Void)? = nil
    var onEnterSafeModeNextLaunch: (() -> Void)? = nil
    var onOpenTroubleshootingGuide: (() -> Void)? = nil
    var onOpenDiagnostics: (() -> Void)? = nil
    var onOpenImportExport: (() -> Void)? = nil
    @State private var exportError: String?
    @State private var lastExportedURL: URL?
    @State private var confirmsMissingGroupReferenceRemoval = false

    var body: some View {
        ClearGlassSettingsPage(
            "Recovery",
            subtitle: "Repair layout, export diagnostics, and keep Basic Mode reachable when optional features fail.",
            badges: [.stable, .diagnostics, .privacySafe],
            sectionAnchors: [
                ClearGlassPageAnchor("Lost Icons", systemImage: "lifepreserver", targetID: "I can't find my icons"),
                ClearGlassPageAnchor("Health", systemImage: "stethoscope"),
                ClearGlassPageAnchor("Workspaces", systemImage: "rectangle.3.group", targetID: "Workspaces Recovery"),
                ClearGlassPageAnchor("Reset", systemImage: "arrow.counterclockwise"),
                ClearGlassPageAnchor("Backups", systemImage: "doc.badge.gearshape", targetID: "Diagnostics and Backups"),
                ClearGlassPageAnchor("Safe Mode", systemImage: "checkmark.shield")
            ]
        ) {
            RecoveryOverviewStrip(
                healthStatus: liveStatus?.healthReport?.status.displayName ?? "Unknown",
                issueCount: liveStatus?.healthReport?.sortedIssues.count ?? 0,
                safeModeActive: liveStatus?.safeModeActive ?? false,
                proModeEnabled: settingsStore.proModeEnabled
            )

            lostIconsSection
            healthSection
            workspacePreviewRecoverySection
            resetSection
            exportSection
            safeModeSection
        }
        .confirmationDialog(
            "Remove missing Workspace group references?",
            isPresented: $confirmsMissingGroupReferenceRemoval,
            titleVisibility: .visible
        ) {
            Button("Remove Missing References", role: .destructive) {
                onRemoveMissingWorkspaceGroupReferences?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes references to Groups that no longer exist. It does not delete Groups or move real menu bar icons.")
        }
    }

    private var healthSection: some View {
        ClearGlassSection("Health", subtitle: "Check and repair known local app state issues.") {
            ClearGlassActionStrip(
                "Health Actions",
                subtitle: "Refresh the local health report first, then apply automatic repairs when issues are detected.",
                systemImage: "stethoscope",
                statusText: liveStatus?.healthReport?.status.displayName ?? "Unknown",
                statusStyle: liveStatus?.healthReport?.isHealthy == false ? .warning : .secondary
            ) {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    onRunHealthCheck?()
                }
                .buttonStyle(.borderedProminent)

                Button("Fix Automatically", systemImage: "wrench.and.screwdriver") {
                    onFixHealthIssues?()
                }
                .disabled(liveStatus?.healthReport?.isHealthy != false)
            }

            ClearGlassInlineMessage(
                text: "Health checks stay local and do not upload diagnostics.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
    }

    private var workspacePreviewRecoverySection: some View {
        ClearGlassSection("Workspaces Recovery", subtitle: "Repair preview-only Workspace and Set Builder state.") {
            ClearGlassControlRow(
                systemImage: "rectangle.3.group",
                title: "Reset Current Workspace Layout",
                subtitle: "Restore the active Workspace's preview items to the safe default layout."
            ) {
                Button("Reset") {
                    onResetCurrentWorkspaceLayout?()
                }
                .controlSize(.small)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "link.badge.plus",
                title: "Remove Missing Group References",
                subtitle: "Clear Workspace entries that point at Groups no longer in the local group store."
            ) {
                Button("Remove") {
                    confirmsMissingGroupReferenceRemoval = true
                }
                .controlSize(.small)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "pencil.slash",
                title: "Discard Set Builder Draft",
                subtitle: "Drop unsaved Set Builder edits and return to the saved Workspace."
            ) {
                Button("Discard") {
                    onDiscardSetBuilderDraft?()
                }
                .controlSize(.small)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "rectangle.slash",
                title: "Disable Function Bar Preview",
                subtitle: "Turn off Function Bar Preview and primary-click preview routing."
            ) {
                Button("Disable") {
                    onDisableFunctionBarPreview?()
                }
                .controlSize(.small)
                .disabled(!settingsStore.functionBarPreviewEnabled && !settingsStore.functionBarPrimaryClickEnabled)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "info.circle",
                title: "Disable Info Strip Preview",
                subtitle: "Turn off Info Strip Preview and auto-show behavior."
            ) {
                Button("Disable") {
                    onDisableInfoStripPreview?()
                }
                .controlSize(.small)
                .disabled(!settingsStore.infoStripPreviewEnabled && !settingsStore.infoStripAutoShowEnabled)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "wrench.adjustable",
                title: "Disable Set Builder Preview",
                subtitle: "Turn off Set Builder Preview and discard the current preview draft."
            ) {
                Button("Disable") {
                    onDisableSetBuilderPreview?()
                }
                .controlSize(.small)
                .disabled(!settingsStore.setBuilderPreviewEnabled)
            }
        }
    }

    private var lostIconsSection: some View {
        ClearGlassSection("I can't find my icons", subtitle: "Start with visibility, then repair app-owned status items if needed.") {
            ClearGlassInlineMessage(
                text: "MenuBarDeclutter uses your menu bar layout. If items appear missing, start with Reveal All or Reset Layout.",
                systemImage: "lifepreserver",
                style: .info
            )

            ClearGlassActionStrip(
                "Visibility Recovery Actions",
                subtitle: "Try visibility commands first; keep layout repair and guidance in More.",
                systemImage: "lifepreserver",
                statusText: "Basic Mode",
                statusStyle: .success
            ) {
                Button("Expand", systemImage: "eye") {
                    onExpand?()
                }
                .buttonStyle(.borderedProminent)

                Button("Reveal All", systemImage: "rectangle.expand.vertical") {
                    onRevealAll?()
                }

                Menu("More", systemImage: "ellipsis.circle") {
                    Button("Reset Layout", systemImage: "arrow.counterclockwise") {
                        onResetLayout?()
                    }

                    Button("Open Guide", systemImage: "questionmark.circle") {
                        onOpenTroubleshootingGuide?()
                    }
                }
            }
            .accessibilityIdentifier("recovery.lostIcons.actions")
        }
    }

    private var resetSection: some View {
        ClearGlassSection("Reset", subtitle: "Recover from confusing placement or settings state.") {
            ClearGlassControlRow(
                systemImage: "arrow.counterclockwise",
                title: "Reset Layout",
                subtitle: "Reveal items and reset app-owned separator geometry."
            ) {
                Button("Reset Layout") {
                    onResetLayout?()
                }
                .controlSize(.small)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "menubar.rectangle",
                title: "Recreate Status Items",
                subtitle: "Reinstall the app-owned control item and separators if macOS dropped them."
            ) {
                Button("Recreate") {
                    onRecreateStatusItems?()
                }
                .controlSize(.small)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "timer",
                title: "Disable Auto-Rehide Temporarily",
                subtitle: "Cancel any countdown and keep the bar reachable for this run."
            ) {
                Button("Disable") {
                    onDisableAutoRehideTemporarily?()
                }
                .controlSize(.small)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "cursorarrow.motionlines",
                title: "Disable Hover Reveal Temporarily",
                subtitle: "Stop hover polling for this run if pointer behavior is confusing."
            ) {
                Button("Disable") {
                    onDisableHoverRevealTemporarily?()
                }
                .controlSize(.small)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "checkmark.shield",
                title: "Reset Basic Mode",
                subtitle: "Return to the safe default mode without enabling Pro features."
            ) {
                Button("Reset Basic Mode") {
                    onResetBasicMode?()
                }
                .controlSize(.small)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "trash",
                title: "Reset All Settings",
                subtitle: "Restore all local settings to defaults."
            ) {
                Button("Reset All Settings") {
                    onResetAllSettings?()
                }
                .controlSize(.small)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "star.slash",
                title: "Disable Optional Pro",
                subtitle: "Turn off Optional Pro discovery and optional features."
            ) {
                Button("Disable Optional Pro") {
                    onDisableProMode?()
                }
                .controlSize(.small)
                .disabled(!settingsStore.proModeEnabled)
            }
        }
    }

    private var exportSection: some View {
        ClearGlassSection("Diagnostics and Backups", subtitle: "Stable support actions stay here; migration complexity stays Advanced.") {
            ClearGlassActionStrip(
                "Support Package Actions",
                subtitle: "Export diagnostics locally or open the full import/export workflow.",
                systemImage: "doc.badge.gearshape",
                statusText: "Local",
                statusStyle: .success
            ) {
                Button("Export Diagnostics", systemImage: "square.and.arrow.up") {
                    exportDiagnostics()
                }
                .buttonStyle(.borderedProminent)

                Button("Import / Export", systemImage: "arrow.up.arrow.down") {
                    onOpenImportExport?()
                }
            }

            if let exportError {
                ClearGlassInlineMessage(
                    text: "Diagnostics export failed: \(exportError)",
                    systemImage: "exclamationmark.triangle",
                    style: .warning
                )
            }

            if let lastExportedURL {
                ClearGlassInlineMessage(
                    text: "Diagnostics exported to \(lastExportedURL.lastPathComponent).",
                    systemImage: "checkmark.circle",
                    style: .success
                )
            }

            ClearGlassInlineMessage(
                text: "Diagnostics export redacts protected metadata by default. Backups and migration tools remain nested away from normal setup.",
                systemImage: "doc.badge.gearshape",
                style: .info
            )
        }
    }

    private var safeModeSection: some View {
        ClearGlassSection("Safe Mode", subtitle: "Start expanded and suppress optional Pro or Labs behavior on next launch.") {
            ClearGlassInlineMessage(
                text: "Safe Mode starts expanded and disables optional behaviors.",
                systemImage: "checkmark.shield",
                style: .success
            )

            ClearGlassControlRow(
                systemImage: "lifepreserver",
                title: "Safe Mode Next Launch",
                subtitle: "Use this when layout looks wrong or optional features are interfering."
            ) {
                Button("Safe Mode Next Launch") {
                    onEnterSafeModeNextLaunch?()
                }
                .controlSize(.small)
            }
        }
    }

    private func exportDiagnostics() {
        guard let diagnosticsLogger,
              let appSupportPaths,
              let diagnosticsExporter else {
            onOpenDiagnostics?()
            return
        }

        let directory: URL
        do {
            try appSupportPaths.ensureDirectoriesExist()
            directory = appSupportPaths.diagnosticsDirectory
        } catch {
            exportError = "Could not prepare diagnostics directory: \(error.localizedDescription)"
            lastExportedURL = nil
            return
        }

        let panel = NSSavePanel()
        panel.title = "Export Diagnostics"
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "MenuBarDeclutter-diagnostics-\(Self.filenameTimestamp()).txt"
        panel.directoryURL = directory

        presentSavePanel(panel) { url in
            guard let url else { return }

            let snapshot = diagnosticsExporter.makeSnapshot(
                settingsStore: settingsStore,
                logger: diagnosticsLogger,
                events: diagnosticsLogger.events
            )

            do {
                let data = try diagnosticsExporter.serialize(
                    snapshot,
                    format: .txt,
                    includeAppSupportPath: false,
                    appSupportPath: nil
                )
                try data.write(to: url, options: .atomic)
                lastExportedURL = url
                exportError = nil
                diagnosticsLogger.log("Recovery diagnostics exported to \(url.lastPathComponent).", level: .info)
            } catch {
                exportError = error.localizedDescription
                lastExportedURL = nil
                diagnosticsLogger.log("Recovery diagnostics export failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    private func presentSavePanel(_ panel: NSSavePanel, completion: @escaping (URL?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
            let handler: (NSApplication.ModalResponse) -> Void = { response in
                completion(response == .OK ? panel.url : nil)
            }

            if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow {
                panel.beginSheetModal(for: window, completionHandler: handler)
            } else {
                panel.begin(completionHandler: handler)
            }
        }
    }

    private static func filenameTimestamp() -> String {
        filenameTimestampFormatter.string(from: Date())
    }

    @MainActor
    private static let filenameTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

private struct RecoveryOverviewStrip: View {
    let healthStatus: String
    let issueCount: Int
    let safeModeActive: Bool
    let proModeEnabled: Bool

    var body: some View {
        ClearGlassOverviewStrip([
            ClearGlassOverviewMetric(
                title: "Health",
                value: healthStatus,
                systemImage: "heart.text.square",
                style: issueCount == 0 ? .success : .warning
            ),
            ClearGlassOverviewMetric(
                title: "Issues",
                value: "\(issueCount)",
                systemImage: "exclamationmark.triangle",
                style: issueCount == 0 ? .success : .warning
            ),
            ClearGlassOverviewMetric(
                title: "Safe Mode",
                value: safeModeActive ? "Active" : "Off",
                systemImage: "lifepreserver",
                style: safeModeActive ? .warning : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Optional Pro",
                value: proModeEnabled ? "On" : "Off",
                systemImage: "star",
                style: proModeEnabled ? .info : .secondary
            )
        ])
    }
}

#Preview {
    RecoverySettingsView(settingsStore: SettingsStore())
}
