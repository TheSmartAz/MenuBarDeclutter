import SwiftUI

struct AssistedMoveFlowView: View {
    @Bindable var settingsStore: SettingsStore
    var liveStatus: LiveDiagnosticsStatus?
    var permissionService: AccessibilityPermissionService?
    var onOpenAdvanced: (() -> Void)?
    var onRevealAll: (() -> Void)?
    var onResetLayout: (() -> Void)?
    var onOpenRecovery: (() -> Void)?
    var onRouteCommand: ((MenuBarCommandAction, String) -> MenuBarCommandResult)?
    var onExecuteMove: ((MenuBarItemSnapshot, IconMoveCommand) async -> IconMoveResult)?

    @State private var viewModel = AssistedMoveViewModel()

    private var snapshots: [MenuBarItemSnapshot] {
        liveStatus?.scannedMenuBarItems ?? []
    }

    private var selectedSnapshot: MenuBarItemSnapshot? {
        viewModel.selectedSnapshot(in: snapshots)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AssistedMoveIntroView(
                settingsStore: settingsStore,
                snapshots: snapshots,
                selectedItemID: selectedItemIDBinding,
                targetZone: $viewModel.targetZone,
                onOpenAdvanced: onOpenAdvanced
            )

            if let selectedSnapshot {
                AssistedMoveConfirmationView(
                    firstUseAccepted: $viewModel.firstUseConfirmationAccepted,
                    perMoveAccepted: $viewModel.perMoveConfirmationAccepted,
                    commandTitle: IconMoveCommand.moveToZone(viewModel.targetZone.menuBarZone).displayName
                )

                assistedMoveActions(for: selectedSnapshot)

                if let plan = viewModel.lastDryRun {
                    AssistedMoveDryRunView(plan: plan)
                }

                if let result = viewModel.lastMoveResult {
                    AssistedMoveResultView(
                        result: result,
                        commandResult: viewModel.lastCommandResult,
                        recoveryActions: recoveryActions
                    )
                }
            } else {
                ContentUnavailableView(
                    "No Discovered Items",
                    systemImage: "menubar.rectangle",
                    description: Text("Run Pro Discovery before trying Assisted Move.")
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            }
        }
        .onAppear {
            viewModel.refreshSelection(from: snapshots)
        }
        .onChange(of: snapshots) { _, newValue in
            viewModel.refreshSelection(from: newValue)
        }
    }

    private var selectedItemIDBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedItemID ?? "" },
            set: { newValue in
                viewModel.selectedItemID = newValue.isEmpty ? nil : newValue
                viewModel.lastDryRun = nil
                viewModel.lastMoveResult = nil
            }
        )
    }

    private var assistedMoveContext: AssistedMoveFlowContext {
        AssistedMoveFlowContext(
            proModeEnabled: settingsStore.proModeEnabled,
            accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
            accessibilityPermissionGranted: permissionService?.status == .granted,
            iconMovingEnabled: settingsStore.iconMovingEnabled,
            safeModeActive: liveStatus?.safeModeActive == true,
            allowSystemItems: settingsStore.iconMovingAllowSystemItems,
            firstUseConfirmationAccepted: viewModel.firstUseConfirmationAccepted,
            perMoveConfirmationAccepted: viewModel.perMoveConfirmationAccepted,
            appBundleIdentifier: AppConstants.bundleIdentifier
        )
    }

    private var recoveryActions: AssistedMoveRecoveryActions {
        AssistedMoveRecoveryActions(
            revealAll: onRevealAll,
            resetLayout: onResetLayout,
            retryDryRun: {
                guard let selectedSnapshot else { return }
                dryRun(selectedSnapshot)
            },
            openManualArrange: onOpenRecovery
        )
    }

    @ViewBuilder
    private func assistedMoveActions(for snapshot: MenuBarItemSnapshot) -> some View {
        HStack(spacing: 8) {
            Button("Dry Run", systemImage: "doc.text.magnifyingglass") {
                dryRun(snapshot)
            }

            Button("Try One Move", systemImage: "arrow.up.left.and.arrow.down.right") {
                Task {
                    await executeMove(snapshot)
                }
            }
            .disabled(!canExecuteCurrentPlan || viewModel.isExecuting || onExecuteMove == nil)

            Button("Cancel", systemImage: "xmark.circle") {
                let result = onRouteCommand?(.cancelAssistedMove, snapshot.id)
                viewModel.cancel(commandResult: result)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)

        if viewModel.isExecuting {
            ClearGlassInlineMessage(
                text: "Move attempt in progress.",
                systemImage: "arrow.triangle.2.circlepath",
                style: .info
            )
        }
    }

    private var canExecuteCurrentPlan: Bool {
        if let plan = viewModel.lastDryRun,
           plan.targetZone == viewModel.targetZone,
           plan.itemID == viewModel.selectedItemID {
            return plan.canExecute
        }
        return false
    }

    private func dryRun(_ snapshot: MenuBarItemSnapshot) {
        let plan = viewModel.generateDryRun(
            snapshot: snapshot,
            context: assistedMoveContext
        )
        viewModel.lastCommandResult = onRouteCommand?(.dryRunMoveItem, plan.itemID)
    }

    private func executeMove(_ snapshot: MenuBarItemSnapshot) async {
        let plan = viewModel.generateDryRun(
            snapshot: snapshot,
            context: assistedMoveContext
        )
        guard plan.canExecute,
              let onExecuteMove else {
            return
        }

        viewModel.lastCommandResult = onRouteCommand?(.tryAssistedMoveItem, snapshot.id)
        viewModel.beginExecution()
        let result = await onExecuteMove(snapshot, plan.command)
        viewModel.finishExecution(result: result)
    }
}

struct AssistedMoveIntroView: View {
    @Bindable var settingsStore: SettingsStore
    let snapshots: [MenuBarItemSnapshot]
    @Binding var selectedItemID: String
    @Binding var targetZone: AssistedMoveTargetZone
    var onOpenAdvanced: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureGateNotice(
                .experimental,
                text: "Single-item only. Dry-run first, then confirmed attempt, verification, and recovery."
            )

            ClearGlassControlRow(
                systemImage: "arrow.up.left.and.arrow.down.right",
                title: "Experimental Icon Moving",
                subtitle: settingsStore.iconMovingEnabled
                    ? "Enabled for explicitly confirmed single-item attempts."
                    : "Off by default. Advanced settings contain the opt-in controls.",
                iconTint: settingsStore.iconMovingEnabled ? .orange : .secondary
            ) {
                Button("Open Advanced", systemImage: "slider.horizontal.3") {
                    onOpenAdvanced?()
                }
                .controlSize(.small)
            }

            if !snapshots.isEmpty {
                HStack(alignment: .center, spacing: 12) {
                    Picker("Item", selection: $selectedItemID) {
                        ForEach(snapshots) { snapshot in
                            Text(displayTitle(for: snapshot)).tag(snapshot.id)
                        }
                    }
                    .frame(minWidth: 220, maxWidth: 340)

                    Picker("Target", selection: $targetZone) {
                        ForEach(AssistedMoveTargetZone.allCases) { zone in
                            Text(zone.menuBarZone.displayName).tag(zone)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 360)
                }
            }
        }
    }

    private func displayTitle(for snapshot: MenuBarItemSnapshot) -> String {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier,
            snapshot.zone.displayName
        ]) ?? "Menu Bar Item"
    }
}
