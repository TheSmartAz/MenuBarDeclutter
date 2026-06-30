import SwiftUI

struct SecondBarRootView: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var permissionService: AccessibilityPermissionService
    @Bindable var liveStatus: LiveDiagnosticsStatus
    @Bindable var itemMemoryStore: MenuBarItemMemoryStore

    let onRefresh: () -> Void
    let onCommand: (MenuBarCommand) -> MenuBarCommandResult
    let onMove: (@MainActor (MenuBarItemSnapshot, IconMoveCommand) async -> IconMoveResult)?
    let groupsProvider: () -> [IconGroup]
    let onSettingsChanged: () -> Void
    let onOpenPrivacySettings: () -> Void
    let onDismiss: () -> Void

    @State private var viewModel = SecondBarViewModel()
    @State private var statusMessage: String?
    @State private var searchQuery = ""
    @State private var selectedFilter: MenuBarItemCollectionFilter = .all
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
            if unavailableState == nil {
                filterBar
            }
            Divider()
                .overlay(.primary.opacity(0.10))

            if let unavailableState {
                SecondBarUnavailableView(state: unavailableState)
            } else if items.isEmpty {
                ContentUnavailableView(
                    emptyStateTitle,
                    systemImage: searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? selectedFilter.systemImage : "magnifyingglass",
                    description: Text(emptyStateDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }

            Divider()
                .overlay(.primary.opacity(0.10))
            footer
        }
        .frame(width: 760, height: panelHeight)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.primary.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 18, y: 10)
        .onAppear {
            onRefresh()
            refreshItems()
            searchFocused = true
        }
        .onChange(of: searchQuery) {
            refreshItems()
        }
        .onChange(of: selectedFilter) {
            refreshItems()
        }
        .onChange(of: itemMemoryStore.recentCount) {
            refreshItems()
        }
        .onChange(of: itemMemoryStore.favoriteCount) {
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

    private var panelHeight: CGFloat {
        settingsStore.secondBarShowLabels ? 274 : 228
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "menubar.rectangle")
                .font(.system(size: 28, weight: .light))
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Second Bar")
                        .font(.title2)
                        .bold()

                    Text(items.count, format: .number)
                        .font(.callout)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: .capsule)
                }

                Text("Hidden menu bar items in a secondary bar.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 7) {
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
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(width: 260)
            .background(.quaternary, in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.primary.opacity(0.10), lineWidth: 1)
            }

            Button("Refresh", systemImage: "arrow.clockwise") {
                onRefresh()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Refresh Menu Bar Items")

            Button("Close", systemImage: "xmark") {
                onDismiss()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Close Second Bar")
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(MenuBarItemCollectionFilter.secondBarFilters) { filter in
                    Text(filter.shortDisplayName)
                        .tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 420)

            secondBarFilterResetButton

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var secondBarFilterResetButton: some View {
        switch selectedFilter {
        case .recent where itemMemoryStore.recentCount > 0:
            Button("Clear Recent Items", systemImage: "clock.arrow.circlepath") {
                itemMemoryStore.resetRecents()
                statusMessage = "Recent items cleared."
                refreshItems()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Clear Recent Items")
        case .favorites where itemMemoryStore.favoriteCount > 0:
            Button("Clear Favorites", systemImage: "star.slash") {
                itemMemoryStore.resetFavorites()
                statusMessage = "Favorites cleared."
                refreshItems()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Clear Favorites")
        default:
            EmptyView()
        }
    }

    private var content: some View {
        VStack(spacing: 7) {
            SecondBarSectionHeader(
                showsHidden: !hiddenItems.isEmpty,
                showsAlwaysHidden: !alwaysHiddenItems.isEmpty
            )

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 8) {
                        ForEach(hiddenItems) { snapshot in
                            itemButton(snapshot)
                        }

                        if !hiddenItems.isEmpty, !alwaysHiddenItems.isEmpty {
                            Divider()
                                .frame(height: settingsStore.secondBarShowLabels ? 82 : 52)
                                .padding(.horizontal, 4)
                        }

                        ForEach(alwaysHiddenItems) { snapshot in
                            itemButton(snapshot)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 9)
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
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Image(systemName: "return")
                .foregroundStyle(.secondary)

            Text(liveStatus.iconMoveInProgress ? "Icon move in progress..." : "Return reveals and highlights. Click original icon manually.")
                .foregroundStyle(.secondary)

            Spacer()

            if let statusMessage {
                Text(statusMessage)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            } else {
                Label("Ready", systemImage: "checkmark.shield")
                    .foregroundStyle(.green)
            }
        }
        .font(.caption)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private var emptyStateTitle: String {
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No Matching Items"
        }

        switch selectedFilter {
        case .all:
            return "No Hidden Items"
        case .recent:
            return "No Recent Items"
        case .favorites:
            return "No Favorites"
        case .hidden:
            return "No Hidden Items"
        case .alwaysHidden:
            return "No Always Hidden Items"
        case .visible:
            return "No Visible Items"
        }
    }

    private var emptyStateDescription: String {
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Try another app name, menu title, or bundle identifier."
        }

        switch selectedFilter {
        case .recent:
            return "Recent hidden items appear after you reveal, highlight, move, or open them."
        case .favorites:
            return "Favorite a hidden item from its context menu to keep it here."
        default:
            return "Refresh menu bar items after hiding icons with the separators."
        }
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
            Button("Reveal", systemImage: "eye") {
                route(.revealItem, snapshot: snapshot)
            }
            Button("Highlight", systemImage: "scope") {
                route(.highlightItem, snapshot: snapshot)
            }
            Button("Open Owning App", systemImage: "app.badge") {
                route(.openOwningApp, snapshot: snapshot)
            }
            Divider()
            Button(favoriteButtonTitle(for: snapshot), systemImage: favoriteButtonImage(for: snapshot)) {
                toggleFavorite(snapshot)
            }
            groupContextMenu(for: snapshot)
            Divider()
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
        let result = route(.revealItem, snapshot: snapshot)
        liveStatus.lastSecondBarSelectedItem = displayTitle(for: snapshot)

        if settingsStore.secondBarActivateOwningAppOnSelection {
            let openResult = route(.openOwningApp, snapshot: snapshot)
            if !openResult.didRun {
                statusMessage = result.message
            }
        }

        if settingsStore.secondBarAutoCloseAfterSelection {
            onDismiss()
        }
    }

    @discardableResult
    private func route(
        _ action: MenuBarCommandAction,
        snapshot: MenuBarItemSnapshot
    ) -> MenuBarCommandResult {
        viewModel.selectedID = snapshot.id
        let result = onCommand(MenuBarCommand(
            action: action,
            target: .menuBarItem(id: snapshot.id),
            source: .secondBar
        ))
        statusMessage = result.message
        remember(snapshot)
        return result
    }

    private func move(_ snapshot: MenuBarItemSnapshot, command: IconMoveCommand) {
        guard let onMove else { return }
        viewModel.selectedID = snapshot.id
        remember(snapshot)
        statusMessage = "\(command.displayName) in progress..."
        Task { @MainActor in
            let result = await onMove(snapshot, command)
            statusMessage = result.summary
        }
    }

    private func toggleFavorite(_ snapshot: MenuBarItemSnapshot) {
        viewModel.selectedID = snapshot.id
        let isFavorite = itemMemoryStore.toggleFavorite(snapshot)
        let title = displayTitle(for: snapshot)
        statusMessage = isFavorite
            ? "Added \(title) to favorites."
            : "Removed \(title) from favorites."
        refreshItems()
    }

    private func favoriteButtonTitle(for snapshot: MenuBarItemSnapshot) -> String {
        itemMemoryStore.isFavorite(snapshot) ? "Remove Favorite" : "Favorite"
    }

    private func favoriteButtonImage(for snapshot: MenuBarItemSnapshot) -> String {
        itemMemoryStore.isFavorite(snapshot) ? "star.slash" : "star"
    }

    private func remember(_ snapshot: MenuBarItemSnapshot) {
        itemMemoryStore.recordSelection(snapshot)
        refreshItems()
    }

    @ViewBuilder
    private func groupContextMenu(for snapshot: MenuBarItemSnapshot) -> some View {
        if settingsStore.groupsEnabled {
            Divider()
            Menu("Groups", systemImage: "person.2") {
                Button("Create Group from Item", systemImage: "plus") {
                    createGroup(from: snapshot)
                }

                let groups = groupsProvider()
                if groups.isEmpty {
                    Button("No Existing Groups", systemImage: "person.2") {}
                        .disabled(true)
                } else {
                    Divider()
                    ForEach(groups) { group in
                        Button("Add to \(group.name)", systemImage: group.symbolName ?? "folder") {
                            add(snapshot, to: group)
                        }
                    }
                }
            }
        }
    }

    private func createGroup(from snapshot: MenuBarItemSnapshot) {
        viewModel.selectedID = snapshot.id
        let result = onCommand(MenuBarCommand(
            action: .createGroupFromItem,
            target: .menuBarItem(id: snapshot.id),
            source: .secondBar
        ))
        statusMessage = result.message
        remember(snapshot)
    }

    private func add(_ snapshot: MenuBarItemSnapshot, to group: IconGroup) {
        viewModel.selectedID = snapshot.id
        let result = onCommand(MenuBarCommand(
            action: .addItemToGroup,
            target: .groupItem(groupID: group.id, itemID: snapshot.id),
            source: .secondBar
        ))
        statusMessage = result.message
        remember(snapshot)
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
            query: searchQuery,
            filter: selectedFilter,
            memoryStore: itemMemoryStore
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

private struct SecondBarSectionHeader: View {
    let showsHidden: Bool
    let showsAlwaysHidden: Bool

    var body: some View {
        HStack(spacing: 14) {
            if showsHidden {
                sectionTitle("Hidden")
            }

            if showsHidden, showsAlwaysHidden {
                Divider()
                    .frame(height: 18)
            }

            if showsAlwaysHidden {
                sectionTitle("Always Hidden")
            }
        }
        .font(.caption)
        .bold()
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }

    private func sectionTitle(_ title: String) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(.primary.opacity(0.12))
                .frame(height: 1)

            Text(title)
                .lineLimit(1)

            Rectangle()
                .fill(.primary.opacity(0.12))
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SecondBarUnavailableView: View {
    let state: SecondBarUnavailableState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: state.systemImage)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.orange)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 6) {
                    Text(state.title)
                        .font(.title3)
                        .bold()

                    Text(state.message)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button(state.primaryButtonTitle, action: state.primaryAction)
                    .buttonStyle(.borderedProminent)

                if let secondaryButtonTitle = state.secondaryButtonTitle,
                   let secondaryAction = state.secondaryAction {
                    Button(secondaryButtonTitle, action: secondaryAction)
                }
            }

            ClearGlassInlineMessage(
                text: "Second Bar is optional Pro UI. Basic Mode hiding stays available when this panel is disabled or permissions are missing.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
        .padding(22)
        .frame(maxWidth: 620, alignment: .leading)
        .background(.quaternary.opacity(0.58), in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.primary.opacity(0.12), lineWidth: 1)
        }
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
        itemMemoryStore: MenuBarItemMemoryStore(fileURL: nil),
        onRefresh: {},
        onCommand: { command in
            MenuBarCommandResult.success(command, message: "Preview")
        },
        onMove: nil,
        groupsProvider: { [] },
        onSettingsChanged: {},
        onOpenPrivacySettings: {},
        onDismiss: {}
    )
}
