import SwiftUI

struct SecondBarRootView: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var permissionService: AccessibilityPermissionService
    @Bindable var liveStatus: LiveDiagnosticsStatus

    let onRefresh: () -> Void
    let onActivate: (MenuBarItemSnapshot) -> MenuItemActivationResult
    let onMove: (@MainActor (MenuBarItemSnapshot, IconMoveCommand) async -> IconMoveResult)?
    let onSettingsChanged: () -> Void
    let onOpenPrivacySettings: () -> Void
    let onDismiss: () -> Void

    @State private var viewModel = SecondBarViewModel()
    @State private var statusMessage: String?
    @State private var searchQuery = ""
    @FocusState private var searchFocused: Bool

    /// Cached filtered+sorted item list. The previous implementation recomputed `items`
    /// on every body evaluation, and `hiddenItems`/`alwaysHiddenItems`/`itemIDs` each
    /// re-invoked the underlying `viewModel.items(...)` filter+sort — so a single
    /// SwiftUI invalidation paid five to seven full passes over the snapshot list.
    /// Caching once per (snapshots, settings, query) collapse that to a single pass.
    @State private var items: [MenuBarItemSnapshot] = []

    private var hiddenItems: [MenuBarItemSnapshot] {
        items.filter { $0.zone == .hidden }
    }

    private var alwaysHiddenItems: [MenuBarItemSnapshot] {
        items.filter { $0.zone == .alwaysHidden }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if let unavailableState {
                SecondBarUnavailableView(state: unavailableState)
            } else if items.isEmpty {
                ContentUnavailableView(
                    searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No Hidden Items" : "No Matching Items",
                    systemImage: searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "menubar.rectangle" : "magnifyingglass",
                    description: Text(
                        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? "Refresh menu bar items after hiding icons with the separators."
                            : "Try another app name, menu title, or bundle identifier."
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }

            Divider()
            footer
        }
        .frame(width: 640, height: settingsStore.secondBarShowLabels ? 190 : 132)
        .background(.regularMaterial)
        .onAppear {
            onRefresh()
            refreshItems()
            searchFocused = true
        }
        .onChange(of: searchQuery) {
            refreshItems()
        }
        .onChange(of: liveStatus.scannedMenuBarItems) { _, _ in
            refreshItems()
        }
        .onChange(of: settingsStore.secondBarShowHiddenItems) {
            refreshItems()
        }
        .onChange(of: settingsStore.secondBarShowAlwaysHiddenItems) {
            refreshItems()
        }
        .onKeyPress(.leftArrow) {
            viewModel.moveSelection(by: -1, in: items)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            viewModel.moveSelection(by: 1, in: items)
            return .handled
        }
        .onKeyPress(.return) {
            activateSelected()
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Label("Second Bar", systemImage: "menubar.rectangle")
                .font(.headline)

            Text(items.count, format: .number)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search hidden items", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)

                if !searchQuery.isEmpty {
                    Button("Clear Search", systemImage: "xmark.circle.fill") {
                        searchQuery = ""
                        searchFocused = true
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Clear Search")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(width: 220)
            .background(.quaternary, in: .rect(cornerRadius: 7))

            Button("Refresh", systemImage: "arrow.clockwise") {
                onRefresh()
            }
            .buttonStyle(.borderless)

            Button("Close", systemImage: "xmark") {
                onDismiss()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Close Second Bar")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 6) {
                    ForEach(hiddenItems) { snapshot in
                        itemButton(snapshot)
                    }

                    if !hiddenItems.isEmpty, !alwaysHiddenItems.isEmpty {
                        Divider()
                            .frame(height: settingsStore.secondBarShowLabels ? 88 : 44)
                            .padding(.horizontal, 2)
                    }

                    ForEach(alwaysHiddenItems) { snapshot in
                        itemButton(snapshot)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .onChange(of: viewModel.selectedID) { _, newValue in
                guard let newValue else { return }
                withAnimation(.snappy(duration: 0.15)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Text(liveStatus.iconMoveInProgress ? "Icon move in progress..." : "Return reveals and highlights. Click original icon manually.")
                .foregroundStyle(.secondary)

            Spacer()

            if let statusMessage {
                Text(statusMessage)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var unavailableState: SecondBarUnavailableState? {
        if !settingsStore.secondBarEnabled {
            return SecondBarUnavailableState(
                title: "Second Bar Disabled",
                systemImage: "menubar.rectangle",
                message: "Enable Second Bar in settings to show hidden menu bar items here.",
                primaryButtonTitle: "Enable Second Bar",
                primaryAction: {
                    settingsStore.secondBarEnabled = true
                    onSettingsChanged()
                },
                secondaryButtonTitle: nil,
                secondaryAction: nil
            )
        }

        if !settingsStore.proModeEnabled {
            return SecondBarUnavailableState(
                title: "Pro Mode Required",
                systemImage: "lock",
                message: "Second Bar uses the optional Accessibility discovery index. Basic Mode still works without permissions.",
                primaryButtonTitle: "Enable Pro Mode",
                primaryAction: {
                    settingsStore.proModeEnabled = true
                    settingsStore.accessibilityDiscoveryEnabled = true
                    onSettingsChanged()
                },
                secondaryButtonTitle: "Open Privacy Settings",
                secondaryAction: onOpenPrivacySettings
            )
        }

        if !settingsStore.accessibilityDiscoveryEnabled {
            return SecondBarUnavailableState(
                title: "Accessibility Discovery Off",
                systemImage: "hand.raised",
                message: "Turn on Accessibility Discovery to populate hidden menu bar items.",
                primaryButtonTitle: "Enable Discovery",
                primaryAction: {
                    settingsStore.accessibilityDiscoveryEnabled = true
                    onSettingsChanged()
                },
                secondaryButtonTitle: "Open Privacy Settings",
                secondaryAction: onOpenPrivacySettings
            )
        }

        if permissionService.status != .granted {
            return SecondBarUnavailableState(
                title: "Accessibility Permission Needed",
                systemImage: "hand.raised.slash",
                message: "Grant Accessibility permission to read menu bar item labels and frames. No screen recording is used.",
                primaryButtonTitle: "Request Permission",
                primaryAction: {
                    permissionService.requestPromptFromUserAction()
                    onSettingsChanged()
                },
                secondaryButtonTitle: "Open System Settings",
                secondaryAction: {
                    permissionService.openSystemSettingsPrivacyPane()
                }
            )
        }

        return nil
    }

    private func itemButton(_ snapshot: MenuBarItemSnapshot) -> some View {
        Button {
            viewModel.selectedID = snapshot.id
            activate(snapshot)
        } label: {
            SecondBarItemView(
                snapshot: snapshot,
                iconSize: settingsStore.secondBarIconSize,
                showLabels: settingsStore.secondBarShowLabels,
                isSelected: snapshot.id == viewModel.selectedID
            )
        }
        .buttonStyle(.plain)
        .id(snapshot.id)
        .disabled(liveStatus.iconMoveInProgress)
        .contextMenu {
            Button("Move to Visible", systemImage: "arrow.right.to.line") {
                move(snapshot, command: .moveToZone(.visible))
            }
            Button("Move to Hidden", systemImage: "arrow.left.and.right") {
                move(snapshot, command: .moveToZone(.hidden))
            }
            Button("Move to Always Hidden", systemImage: "eye.slash") {
                move(snapshot, command: .moveToZone(.alwaysHidden))
            }
            Divider()
            Button("Move Left", systemImage: "arrow.left") {
                move(snapshot, command: .moveLeft)
            }
            Button("Move Right", systemImage: "arrow.right") {
                move(snapshot, command: .moveRight)
            }
        }
    }

    private func activateSelected() {
        guard let selectedID = viewModel.selectedID,
              let snapshot = items.first(where: { $0.id == selectedID }) else {
            return
        }
        activate(snapshot)
    }

    private func activate(_ snapshot: MenuBarItemSnapshot) {
        let result = onActivate(snapshot)
        liveStatus.lastSecondBarSelectedItem = displayTitle(for: snapshot)
        statusMessage = result.outcome.displayName

        if settingsStore.secondBarAutoCloseAfterSelection {
            onDismiss()
        }
    }

    private func move(_ snapshot: MenuBarItemSnapshot, command: IconMoveCommand) {
        guard let onMove else { return }
        viewModel.selectedID = snapshot.id
        statusMessage = "\(command.displayName) in progress..."
        Task { @MainActor in
            let result = await onMove(snapshot, command)
            statusMessage = result.summary
        }
    }

    private func synchronizeDiagnostics() {
        liveStatus.secondBarItemCount = items.count
    }

    /// Re-evaluates the cached `items` against the current `(snapshots, settings,
    /// searchQuery)` inputs and notifies the view-model of the new list. Replaces
    /// several redundant `viewModel.items(...)` recomputations per SwiftUI body
    /// evaluation with a single pass driven by explicit input changes.
    private func refreshItems() {
        guard unavailableState == nil else {
            if !items.isEmpty { items = [] }
            return
        }
        items = viewModel.items(
            from: liveStatus.scannedMenuBarItems,
            settingsStore: settingsStore,
            query: searchQuery
        )
        synchronizeDiagnostics()
        viewModel.selectFirstItemIfNeeded(items)
    }

    private func displayTitle(for snapshot: MenuBarItemSnapshot) -> String {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
    }
}

private struct SecondBarUnavailableState {
    let title: String
    let systemImage: String
    let message: String
    let primaryButtonTitle: String
    let primaryAction: () -> Void
    let secondaryButtonTitle: String?
    let secondaryAction: (() -> Void)?
}

private struct SecondBarUnavailableView: View {
    let state: SecondBarUnavailableState

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: state.systemImage)
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            Text(state.title)
                .font(.title3)
                .bold()

            Text(state.message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)

            HStack {
                Button(state.primaryButtonTitle, action: state.primaryAction)
                    .buttonStyle(.borderedProminent)

                if let secondaryButtonTitle = state.secondaryButtonTitle,
                   let secondaryAction = state.secondaryAction {
                    Button(secondaryButtonTitle, action: secondaryAction)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let store = SettingsStore()
    let logger = DiagnosticsLogger()
    let permission = AccessibilityPermissionService(
        settingsStore: store,
        diagnosticsLogger: logger,
        trustProvider: { true },
        promptTrustProvider: { true },
        systemSettingsOpener: { true }
    )
    let live = LiveDiagnosticsStatus()
    store.secondBarEnabled = true
    store.proModeEnabled = true
    store.accessibilityDiscoveryEnabled = true
    live.scannedMenuBarItems = [
        MenuBarItemSnapshot(
            title: "Sync",
            role: "AXMenuBarItem",
            subrole: nil,
            frame: .zero,
            owningProcessIdentifier: nil,
            owningApplicationName: "Example",
            bundleIdentifier: "com.example.app",
            zone: .hidden,
            isLikelySystemItem: false,
            scanTimestamp: Date()
        )
    ]
    return SecondBarRootView(
        settingsStore: store,
        permissionService: permission,
        liveStatus: live,
        onRefresh: {},
        onActivate: { _ in
            MenuItemActivationResult(outcome: .hiddenRevealed, message: "Preview")
        },
        onMove: nil,
        onSettingsChanged: {},
        onOpenPrivacySettings: {},
        onDismiss: {}
    )
}
