import SwiftUI

struct SearchRootView: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var permissionService: AccessibilityPermissionService
    @Bindable var liveStatus: LiveDiagnosticsStatus

    let searchService: SearchService
    let onRefresh: () -> Void
    let onCommand: (MenuBarCommand) -> MenuBarCommandResult
    let onMove: @MainActor (MenuBarSearchResult, IconMoveCommand) async -> IconMoveResult
    let onSettingsChanged: () -> Void
    let onOpenPrivacySettings: () -> Void
    let onDismiss: () -> Void

    @State private var query = ""
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

    var body: some View {
        VStack(spacing: 0) {
            searchHeader
            Divider()
                .overlay(.primary.opacity(0.10))

            if let unavailableState {
                SearchUnavailableView(
                    state: unavailableState
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    searchInputBar

                    Text("Results")
                        .font(.headline)

                    resultList
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }

            Divider()
                .overlay(.primary.opacity(0.10))
            searchFooter
        }
        .frame(width: 640, height: 460)
        .background(.regularMaterial, in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.primary.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 18, y: 10)
        .onAppear {
            onRefresh()
            searchIndex = SearchIndex(snapshots: liveStatus.scannedMenuBarItems)
            refreshResults()
            searchFieldFocused = true
        }
        .onChange(of: query) {
            scheduleSearch()
        }
        .onChange(of: liveStatus.scannedMenuBarItems) { _, newSnapshots in
            searchIndex = SearchIndex(snapshots: newSnapshots)
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
        .onKeyPress(.return) {
            activateSelectedResult()
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
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.primary)
                .frame(width: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("Find Icon")
                    .font(.title2)
                    .bold()

                Text("Search and reveal menu bar items instantly.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            ClearGlassBadge(style: .privacySafe)

            Button("Refresh", systemImage: "arrow.clockwise") {
                onRefresh()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Refresh Menu Bar Items")
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var searchInputBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Find menu bar icon", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFieldFocused)
                .onSubmit(activateSelectedResult)

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
        .padding(.vertical, 9)
        .background(.quaternary, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.10), lineWidth: 1)
        }
    }

    private var resultList: some View {
        Group {
            if results.isEmpty {
                ContentUnavailableView(
                    query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No Menu Bar Items" : "No Results",
                    systemImage: "magnifyingglass",
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
                                    Button("Move to Visible", systemImage: "arrow.right.to.line") {
                                        move(result, command: .moveToZone(.visible))
                                    }
                                    Button("Move to Hidden", systemImage: "arrow.left.and.right") {
                                        move(result, command: .moveToZone(.hidden))
                                    }
                                    Button("Move to Always Hidden", systemImage: "eye.slash") {
                                        move(result, command: .moveToZone(.alwaysHidden))
                                    }
                                    Divider()
                                    Button("Move Left", systemImage: "arrow.left") {
                                        move(result, command: .moveLeft)
                                    }
                                    Button("Move Right", systemImage: "arrow.right") {
                                        move(result, command: .moveRight)
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
            Text("\(results.count) results")
                .foregroundStyle(.secondary)

            Spacer()

            if let activationMessage {
                Text(activationMessage)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 4) {
                    Text("Select an item to reveal and highlight it.")
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

    private var emptyResultsDescription: String {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            "Refresh menu bar items after enabling Pro Mode and Accessibility."
        } else {
            "Try an app name, item title, or bundle identifier."
        }
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
                    settingsStore.proModeEnabled = true
                    settingsStore.accessibilityDiscoveryEnabled = true
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

    private func activateSelectedResult() {
        guard let selectedID,
              let result = results.first(where: { $0.id == selectedID }) else {
            return
        }

        activate(result)
    }

    private func activate(_ result: MenuBarSearchResult) {
        let commandResult = route(.revealItem, result: result)
        liveStatus.lastSearchSelectedItem = result.displayTitle
        liveStatus.lastSearchActivationOutcome = commandResult.status.displayName
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
        return commandResult
    }

    private func move(_ result: MenuBarSearchResult, command: IconMoveCommand) {
        selectedID = result.id
        activationMessage = "\(command.displayName) in progress..."
        Task { @MainActor in
            let moveResult = await onMove(result, command)
            activationMessage = moveResult.summary
        }
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

    /// Re-evaluates `results` against the current `searchIndex` and `query`, then
    /// propagates diagnostics state and reselects the first result as needed.
    private func refreshResults() {
        guard searchIsAvailable else {
            results = []
            return
        }
        results = searchService.results(
            from: searchIndex,
            query: query
        )
        updateSearchDiagnostics()
        selectFirstResultIfNeeded()
    }

    private func updateSearchDiagnostics() {
        liveStatus.searchIndexItemCount = liveStatus.scannedMenuBarItems.count
        liveStatus.lastSearchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
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
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: state.systemImage)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.orange)
                    .frame(width: 46)

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
        .padding(28)
        .frame(maxWidth: 440, alignment: .leading)
        .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: 10))
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
        onRefresh: {},
        onCommand: { command in
            MenuBarCommandResult.success(command, message: "Preview command")
        },
        onMove: { result, command in
            IconMoveResult.skipped(command: command, itemName: result.displayTitle, error: .disabled)
        },
        onSettingsChanged: {},
        onOpenPrivacySettings: {},
        onDismiss: {}
    )
}
