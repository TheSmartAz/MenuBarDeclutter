import SwiftUI

struct SearchRootView: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var permissionService: AccessibilityPermissionService
    @Bindable var liveStatus: LiveDiagnosticsStatus

    let searchService: SearchService
    @Bindable var itemMemoryStore: MenuBarItemMemoryStore
    let diagnosticsLogger: DiagnosticsLogger
    let newItemStorageKeysProvider: () -> Set<String>
    let workspaceUsageProvider: () -> WorkspaceUsageIndexSnapshot?
    let onRefresh: () -> Void
    let onCommand: (MenuBarCommand) -> MenuBarCommandResult
    let onMove: @MainActor (MenuBarSearchResult, IconMoveCommand) async -> IconMoveResult
    let groupsProvider: () -> [IconGroup]
    let onSettingsChanged: () -> Void
    let onOpenPrivacySettings: () -> Void
    let onDismiss: () -> Void

    @State private var query = ""
    @State private var selectedFilter: MenuBarItemCollectionFilter = .all
    @State private var selectedID: MenuBarSearchResult.ID?
    @State private var activationMessage: String?
    @FocusState private var searchFieldFocused: Bool

    /// Cached search results. The previous design recomputed `results` on every
    /// accessing property read, which is read from `resultList`, `searchFooter`,
    /// `selectFirstResultIfNeeded`, `moveSelection`, `activateSelectedResult`, and
    /// the `onChange(of: resultIDs)` modifier — so a single SwiftUI invalidation
    /// triggered five or six filter+sort passes. Caching once per query and
    /// refreshing in a debounced `onChange(of: query)` collapses those redundant
    /// passes and lets a fast typist skip work between keystrokes.
    @State private var results: [MenuBarSearchResult] = []

    /// Pre-built normalized index. Rebuilt only when `liveStatus.scannedMenuBarItems`
    /// changes (i.e. on a new accessibility scan), so the per-keystroke `String.folding`
    /// allocations in `SearchService.normalize` are paid once per scan rather than
    /// once per character.
    @State private var searchIndex: SearchIndex = .init()

    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var latestIndexRebuildDurationMilliseconds: Double?

    private let keyboardRouter = SearchKeyboardActionRouter()

    var body: some View {
        VStack(spacing: 0) {
            searchHeader
            Divider()

            if let unavailableState {
                SearchUnavailableView(
                    state: unavailableState
                )
            } else {
                resultContent
            }

            Divider()
            searchFooter
        }
        .frame(width: 620, height: 440)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            onRefresh()
            rebuildSearchIndex(from: liveStatus.scannedMenuBarItems)
            refreshResults()
            searchFieldFocused = true
        }
        .onChange(of: query) {
            scheduleSearch()
        }
        .onChange(of: selectedFilter) {
            refreshResults()
        }
        .onChange(of: itemMemoryStore.recentCount) {
            refreshResults()
        }
        .onChange(of: itemMemoryStore.favoriteCount) {
            refreshResults()
        }
        .onChange(of: liveStatus.scannedMenuBarItems) { _, newSnapshots in
            rebuildSearchIndex(from: newSnapshots)
            scheduleSearch()
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress { keyPress in
            guard keyPress.key == .return else { return .ignored }
            activateSelectedResult(
                keyboardRouter.returnAction(for: searchKeyboardModifiers(from: keyPress.modifiers))
            )
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
        .onDisappear {
            searchDebounceTask?.cancel()
        }
    }

    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                searchInputBar

                Button("Refresh", systemImage: "arrow.clockwise") {
                    onRefresh()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)
                .help("Refresh Menu Bar Items")
                .disabled(!searchIsAvailable)

                ClearGlassBadge(style: .privacySafe)
            }

            if searchIsAvailable {
                searchFilterBar
            }
        }
        .controlSize(.small)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var searchInputBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Find menu bar icon", text: $query)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($searchFieldFocused)
                .onSubmit {
                    activateSelectedResult()
                }

            if !query.isEmpty {
                Button("Clear Search", systemImage: "xmark.circle.fill") {
                    query = ""
                    searchFieldFocused = true
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Clear Search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(searchFieldFocused ? Color.accentColor.opacity(0.45) : Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
    }

    private var searchFilterBar: some View {
        HStack(spacing: 10) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(MenuBarItemCollectionFilter.searchFilters) { filter in
                    Text(filter.shortDisplayName)
                        .tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            filterResetButton
        }
    }

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Results")
                    .font(.headline)

                Spacer()

                if selectedFilter != .all {
                    Label(selectedFilter.displayName, systemImage: selectedFilter.systemImage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            resultList
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var filterResetButton: some View {
        switch selectedFilter {
        case .recent where itemMemoryStore.recentCount > 0:
            Button("Clear Recent Items", systemImage: "clock.arrow.circlepath") {
                itemMemoryStore.resetRecents()
                activationMessage = "Recent items cleared."
                refreshResults()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Clear Recent Items")
        case .favorites where itemMemoryStore.favoriteCount > 0:
            Button("Clear Favorites", systemImage: "star.slash") {
                itemMemoryStore.resetFavorites()
                activationMessage = "Favorites cleared."
                refreshResults()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Clear Favorites")
        default:
            EmptyView()
        }
    }

    private var resultList: some View {
        Group {
            if results.isEmpty {
                ContentUnavailableView(
                    emptyResultsTitle,
                    systemImage: selectedFilter == .all ? "magnifyingglass" : selectedFilter.systemImage,
                    description: Text(emptyResultsDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(results) { result in
                                Button {
                                    selectedID = result.id
                                    activate(result)
                                } label: {
                                    SearchResultRowView(
                                        result: result,
                                        isSelected: result.id == selectedID
                                    )
                                }
                                .buttonStyle(.plain)
                                .id(result.id)
                                .contextMenu {
                                    Button("Reveal", systemImage: "eye") {
                                        route(.revealItem, result: result)
                                    }
                                    Button("Highlight", systemImage: "scope") {
                                        route(.highlightItem, result: result)
                                    }
                                    Button("Show in Second Bar", systemImage: "menubar.rectangle") {
                                        route(.showItemInSecondBar, result: result)
                                    }
                                    Button("Open Owning App", systemImage: "app.badge") {
                                        route(.openOwningApp, result: result)
                                    }
                                    Divider()
                                    Button(favoriteButtonTitle(for: result), systemImage: favoriteButtonImage(for: result)) {
                                        toggleFavorite(result)
                                    }
                                    groupContextMenu(for: result)
                                    Divider()
                                    if settingsStore.iconMovingEnabled {
                                        Button("Experimental: Move to Visible", systemImage: "arrow.right.to.line") {
                                            move(result, command: .moveToZone(.visible))
                                        }
                                        Button("Experimental: Move to Hidden", systemImage: "arrow.left.and.right") {
                                            move(result, command: .moveToZone(.hidden))
                                        }
                                        Button("Experimental: Move to Always Hidden", systemImage: "eye.slash") {
                                            move(result, command: .moveToZone(.alwaysHidden))
                                        }
                                        Divider()
                                        Button("Experimental: Move Left", systemImage: "arrow.left") {
                                            move(result, command: .moveLeft)
                                        }
                                        Button("Experimental: Move Right", systemImage: "arrow.right") {
                                            move(result, command: .moveRight)
                                        }
                                    } else {
                                        Button("Experimental Move Disabled", systemImage: "exclamationmark.triangle") {}
                                            .disabled(true)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onChange(of: selectedID) { _, newValue in
                        guard let newValue else { return }
                        withAnimation(.snappy(duration: 0.15)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchFooter: some View {
        HStack(spacing: 12) {
            Text(searchIsAvailable ? "\(results.count) results" : "Unavailable")
                .foregroundStyle(.secondary)

            Spacer()

            if !searchIsAvailable {
                Text("Enable the requirements above to use local menu bar search.")
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            } else if let activationMessage {
                Text(activationMessage)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 4) {
                    Text("Use arrows to choose, Return to reveal, Command-Return for Second Bar.")
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    Text("No clicking is automated.")
                        .lineLimit(1)
                        .foregroundStyle(.blue)
                }
            }
        }
        .font(.caption)
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
    }

    private var emptyResultsTitle: String {
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No Results"
        }

        switch selectedFilter {
        case .all:
            return "No Menu Bar Items"
        case .recent:
            return "No Recent Items"
        case .favorites:
            return "No Favorites"
        case .currentWorkspace:
            return "No Current Workspace Items"
        case .anyWorkspace:
            return "No Workspace Items"
        case .unassigned:
            return "No Unassigned Items"
        case .usedInOtherWorkspace:
            return "No Other Workspace Items"
        case .groups:
            return "No Group Items"
        case .newItems:
            return "No New Items"
        case .visible:
            return "No Visible Items"
        case .hidden:
            return "No Hidden Items"
        case .alwaysHidden:
            return "No Always Hidden Items"
        case .stale:
            return "No Stale Items"
        }
    }

    private var emptyResultsDescription: String {
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Try an app name, item title, or bundle identifier."
        }

        if selectedFilter == .recent {
            return "Recent items appear after you reveal, highlight, move, or open an item."
        }

        if selectedFilter == .favorites {
            return "Favorite an item from its context menu to keep it here."
        }

        return "Refresh menu bar items after enabling Pro Mode and Accessibility."
    }

    private var searchIsAvailable: Bool {
        unavailableState == nil
    }

    private var unavailableState: SearchUnavailableState? {
        if !settingsStore.searchEnabled {
            return SearchUnavailableState(
                title: "Find Icon Disabled",
                systemImage: "magnifyingglass.circle",
                message: "Enable Find Icon in Search settings to use the panel.",
                primaryButtonTitle: "Enable Find Icon",
                primaryAction: {
                    settingsStore.searchEnabled = true
                    onSettingsChanged()
                },
                secondaryButtonTitle: nil,
                secondaryAction: nil
            )
        }

        if !settingsStore.proModeEnabled {
            return SearchUnavailableState(
                title: "Pro Mode Required",
                systemImage: "lock",
                message: "Find Icon uses the optional Accessibility discovery index. Basic Mode remains available without permissions.",
                primaryButtonTitle: "Enable Pro Mode",
                primaryAction: {
                    PrivacyProSetupActions.enableProMode(
                        settingsStore: settingsStore,
                        permissionService: permissionService
                    )
                    onSettingsChanged()
                },
                secondaryButtonTitle: "Open Privacy Settings",
                secondaryAction: onOpenPrivacySettings
            )
        }

        if !settingsStore.accessibilityDiscoveryEnabled {
            return SearchUnavailableState(
                title: "Accessibility Discovery Off",
                systemImage: "hand.raised",
                message: "Turn on Accessibility Discovery to build the local menu bar item index.",
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
            return SearchUnavailableState(
                title: "Accessibility Permission Needed",
                systemImage: "hand.raised.slash",
                message: "Grant Accessibility permission to let MenuBarDeclutter read menu bar item labels and frames. No screen recording or clicking is used.",
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

    private func selectFirstResultIfNeeded() {
        let resultIDs = results.map(\.id)
        if let selectedID, resultIDs.contains(selectedID) {
            return
        }
        selectedID = resultIDs.first
    }

    private func moveSelection(by delta: Int) {
        let resultIDs = results.map(\.id)
        guard !resultIDs.isEmpty else { return }

        let currentIndex = selectedID.flatMap { resultIDs.firstIndex(of: $0) } ?? -1
        let proposedIndex = currentIndex + delta
        let clampedIndex = min(max(proposedIndex, 0), resultIDs.count - 1)
        selectedID = resultIDs[clampedIndex]
    }

    private func activateSelectedResult(_ keyboardAction: SearchKeyboardAction = .revealSelected) {
        guard let selectedID,
              let result = results.first(where: { $0.id == selectedID }) else {
            return
        }

        activate(result, keyboardAction: keyboardAction)
    }

    private func activate(_ result: MenuBarSearchResult, keyboardAction: SearchKeyboardAction = .revealSelected) {
        let commandResult = route(commandAction(for: keyboardAction, result: result), result: result)
        liveStatus.lastSearchActivationOutcome = commandResult.status.displayName
    }

    private func commandAction(
        for keyboardAction: SearchKeyboardAction,
        result: MenuBarSearchResult
    ) -> MenuBarCommandAction {
        switch keyboardAction {
        case .revealSelected:
            return .revealItem
        case .showSelectedInSecondBar:
            return .showItemInSecondBar
        case .openOwningApp:
            return .openOwningApp
        case .revealRelevantZone:
            switch result.snapshot.zone {
            case .hidden:
                return .revealHiddenZone
            case .alwaysHidden:
                return .revealAlwaysHiddenZone
            case .visible, .unknown:
                return .revealItem
            }
        }
    }

    @discardableResult
    private func route(
        _ action: MenuBarCommandAction,
        result: MenuBarSearchResult
    ) -> MenuBarCommandResult {
        selectedID = result.id
        let commandResult = onCommand(MenuBarCommand(
            action: action,
            target: .menuBarItem(id: result.id),
            source: .findIcon
        ))
        activationMessage = commandResult.message
        remember(result)
        return commandResult
    }

    private func move(_ result: MenuBarSearchResult, command: IconMoveCommand) {
        selectedID = result.id
        remember(result)
        activationMessage = "\(command.displayName) in progress..."
        Task { @MainActor in
            let moveResult = await onMove(result, command)
            activationMessage = moveResult.summary
        }
    }

    private func toggleFavorite(_ result: MenuBarSearchResult) {
        selectedID = result.id
        let isFavorite = itemMemoryStore.toggleFavorite(result.snapshot)
        activationMessage = isFavorite
            ? "Added \(result.displayTitle) to favorites."
            : "Removed \(result.displayTitle) from favorites."
        refreshResults()
    }

    private func favoriteButtonTitle(for result: MenuBarSearchResult) -> String {
        itemMemoryStore.isFavorite(result.snapshot) ? "Remove Favorite" : "Favorite"
    }

    private func favoriteButtonImage(for result: MenuBarSearchResult) -> String {
        itemMemoryStore.isFavorite(result.snapshot) ? "star.slash" : "star"
    }

    private func remember(_ result: MenuBarSearchResult) {
        itemMemoryStore.recordSelection(result.snapshot)
        refreshResults()
    }

    @ViewBuilder
    private func groupContextMenu(for result: MenuBarSearchResult) -> some View {
        if settingsStore.groupsEnabled {
            Divider()
            Menu("Groups", systemImage: "person.2") {
                Button("Create Group from Item", systemImage: "plus") {
                    createGroup(from: result)
                }

                let groups = groupsProvider()
                if groups.isEmpty {
                    Button("No Existing Groups", systemImage: "person.2") {}
                        .disabled(true)
                } else {
                    Divider()
                    ForEach(groups) { group in
                        Button("Add to \(group.name)", systemImage: group.symbolName ?? "folder") {
                            add(result, to: group)
                        }
                    }
                }
            }
        }
    }

    private func createGroup(from result: MenuBarSearchResult) {
        selectedID = result.id
        let commandResult = onCommand(MenuBarCommand(
            action: .createGroupFromItem,
            target: .menuBarItem(id: result.id),
            source: .findIcon
        ))
        activationMessage = commandResult.message
        remember(result)
    }

    private func add(_ result: MenuBarSearchResult, to group: IconGroup) {
        selectedID = result.id
        let commandResult = onCommand(MenuBarCommand(
            action: .addItemToGroup,
            target: .groupItem(groupID: group.id, itemID: result.id),
            source: .findIcon
        ))
        activationMessage = commandResult.message
        remember(result)
    }

    /// Schedules a debounced result refresh ~100 ms in the future. Fast typists
    /// would otherwise pay one full `filter + sort + MenuBarSearchResult` allocation
    /// churn per keystroke; the debounce coalesces a burst of typing into a single
    /// snapshot evaluation while preserving the perception of immediate feedback.
    private func scheduleSearch() {
        searchDebounceTask?.cancel()
        let snapshotQuery = query
        searchDebounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            if Task.isCancelled { return }
            _ = snapshotQuery
            refreshResults()
        }
    }

    private func rebuildSearchIndex(from snapshots: [MenuBarItemSnapshot]) {
        let start = Date()
        searchIndex = SearchIndex(snapshots: snapshots)
        latestIndexRebuildDurationMilliseconds = Date().timeIntervalSince(start) * 1000
    }

    /// Re-evaluates `results` against the current `searchIndex` and `query`, then
    /// propagates diagnostics state and reselects the first result as needed.
    private func refreshResults() {
        guard searchIsAvailable else {
            results = []
            return
        }
        let start = Date()
        results = searchService.results(
            from: searchIndex,
            query: query,
            filter: selectedFilter,
            memoryStore: itemMemoryStore,
            rankingContext: rankingContext()
        )
        let rankingDurationMilliseconds = Date().timeIntervalSince(start) * 1000
        updateSearchDiagnostics(rankingDurationMilliseconds: rankingDurationMilliseconds)
        selectFirstResultIfNeeded()
    }

    private func updateSearchDiagnostics(rankingDurationMilliseconds: Double) {
        let latestScanAgeSeconds = liveStatus.lastMenuBarScanTime.map { Date().timeIntervalSince($0) }
        liveStatus.updateSearchPerformance(SearchPerformanceDiagnostics(
            indexItemCount: searchIndex.count,
            resultCount: results.count,
            indexRebuildDurationMilliseconds: latestIndexRebuildDurationMilliseconds,
            rankingDurationMilliseconds: rankingDurationMilliseconds,
            latestScanAgeSeconds: latestScanAgeSeconds
        ))
        diagnosticsLogger.log(
            "Find Icon search refreshed.",
            level: .debug,
            metadata: [
                "indexItemCount": "\(searchIndex.count)",
                "resultCount": "\(results.count)",
                "indexRebuildMilliseconds": formatMilliseconds(latestIndexRebuildDurationMilliseconds),
                "rankingMilliseconds": formatMilliseconds(rankingDurationMilliseconds),
                "latestScanAgeBucket": scanAgeBucket(latestScanAgeSeconds)
            ]
        )
    }

    private func rankingContext() -> SearchRankingContext {
        SearchRankingContext(
            newItemStorageKeys: newItemStorageKeysProvider(),
            staleBefore: Date().addingTimeInterval(-300),
            workspaceUsageSnapshot: workspaceUsageProvider()
        )
    }

    private func searchKeyboardModifiers(from modifiers: EventModifiers) -> SearchKeyboardModifiers {
        var result: SearchKeyboardModifiers = []
        if modifiers.contains(.command) {
            result.insert(.command)
        }
        if modifiers.contains(.option) {
            result.insert(.option)
        }
        if modifiers.contains(.shift) {
            result.insert(.shift)
        }
        return result
    }

    private func formatMilliseconds(_ value: Double?) -> String {
        guard let value else { return "unavailable" }
        return value.formatted(.number.precision(.fractionLength(2)))
    }

    private func scanAgeBucket(_ age: TimeInterval?) -> String {
        guard let age else { return "noScan" }
        switch age {
        case ..<60:
            return "under1m"
        case ..<300:
            return "under5m"
        case ..<900:
            return "under15m"
        default:
            return "stale"
        }
    }
}

private struct SearchUnavailableState {
    let title: String
    let systemImage: String
    let message: String
    let primaryButtonTitle: String
    let primaryAction: () -> Void
    let secondaryButtonTitle: String?
    let secondaryAction: (() -> Void)?
}

private struct SearchUnavailableView: View {
    let state: SearchUnavailableState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: state.systemImage)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.orange)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 7) {
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
                    .accessibilityLabel(Text(state.primaryButtonTitle))
                    .accessibilityIdentifier("search.unavailable.primary")

                if let secondaryButtonTitle = state.secondaryButtonTitle,
                   let secondaryAction = state.secondaryAction {
                    Button(secondaryButtonTitle, action: secondaryAction)
                }
            }

            ClearGlassInlineMessage(
                text: "Basic Mode remains usable without Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.",
                systemImage: "lock.shield",
                style: .success
            )
        }
        .padding(24)
        .frame(maxWidth: 440, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
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
        trustProvider: { false },
        promptTrustProvider: { false },
        systemSettingsOpener: { true }
    )
    let live = LiveDiagnosticsStatus()
    return SearchRootView(
        settingsStore: store,
        permissionService: permission,
        liveStatus: live,
        searchService: SearchService(),
        itemMemoryStore: MenuBarItemMemoryStore(fileURL: nil),
        diagnosticsLogger: logger,
        newItemStorageKeysProvider: { [] },
        workspaceUsageProvider: { nil },
        onRefresh: {},
        onCommand: { command in
            MenuBarCommandResult.success(command, message: "Preview command")
        },
        onMove: { result, command in
            IconMoveResult.skipped(command: command, itemName: result.displayTitle, error: .disabled)
        },
        groupsProvider: { [] },
        onSettingsChanged: {},
        onOpenPrivacySettings: {},
        onDismiss: {}
    )
}
