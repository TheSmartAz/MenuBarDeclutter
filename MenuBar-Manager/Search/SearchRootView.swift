import SwiftUI

struct SearchRootView: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var permissionService: AccessibilityPermissionService
    @Bindable var liveStatus: LiveDiagnosticsStatus

    let searchService: SearchService
    let onRefresh: () -> Void
    let onActivate: (MenuBarSearchResult) -> MenuItemActivationResult
    let onMove: @MainActor (MenuBarSearchResult, IconMoveCommand) async -> IconMoveResult
    let onSettingsChanged: () -> Void
    let onOpenPrivacySettings: () -> Void
    let onDismiss: () -> Void

    @State private var query = ""
    @State private var selectedID: MenuBarSearchResult.ID?
    @State private var activationMessage: String?
    @FocusState private var searchFieldFocused: Bool

    private var results: [MenuBarSearchResult] {
        guard searchIsAvailable else { return [] }
        return searchService.results(
            from: liveStatus.scannedMenuBarItems,
            query: query
        )
    }

    private var resultIDs: [MenuBarSearchResult.ID] {
        results.map(\.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchHeader
            Divider()

            if let unavailableState {
                SearchUnavailableView(
                    state: unavailableState
                )
            } else {
                resultList
            }

            Divider()
            searchFooter
        }
        .frame(width: 560, height: 420)
        .background(.regularMaterial)
        .onAppear {
            onRefresh()
            updateSearchDiagnostics()
            selectFirstResultIfNeeded()
            searchFieldFocused = true
        }
        .onChange(of: query) {
            updateSearchDiagnostics()
            selectFirstResultIfNeeded()
        }
        .onChange(of: resultIDs) {
            updateSearchDiagnostics()
            selectFirstResultIfNeeded()
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
    }

    private var searchHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Find menu bar icon", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFieldFocused)
                .onSubmit(activateSelectedResult)

            if !query.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") {
                    query = ""
                    searchFieldFocused = true
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var resultList: some View {
        Group {
            if results.isEmpty {
                ContentUnavailableView(
                    query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No Menu Bar Items" : "No Results",
                    systemImage: "magnifyingglass",
                    description: Text(emptyResultsDescription)
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
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
                        .padding(8)
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
                Text("Select an item to reveal and highlight it. No clicking is automated.")
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
        if let selectedID, resultIDs.contains(selectedID) {
            return
        }
        selectedID = resultIDs.first
    }

    private func moveSelection(by delta: Int) {
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
        let activationResult = onActivate(result)
        activationMessage = activationResult.message
        liveStatus.lastSearchSelectedItem = result.displayTitle
        liveStatus.lastSearchActivationOutcome = activationResult.outcome.displayName
    }

    private func move(_ result: MenuBarSearchResult, command: IconMoveCommand) {
        selectedID = result.id
        activationMessage = "\(command.displayName) in progress..."
        Task { @MainActor in
            let moveResult = await onMove(result, command)
            activationMessage = moveResult.summary
        }
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
                .frame(maxWidth: 400)

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
        onActivate: { _ in
            MenuItemActivationResult(outcome: .selectedWithoutHighlight, message: "Preview activation")
        },
        onMove: { result, command in
            IconMoveResult.skipped(command: command, itemName: result.displayTitle, error: .disabled)
        },
        onSettingsChanged: {},
        onOpenPrivacySettings: {},
        onDismiss: {}
    )
}
