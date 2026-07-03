import SwiftUI

struct IconGroupPanelRootView: View {
    let group: IconGroup
    let snapshots: [MenuBarItemSnapshot]
    let onActivate: (MenuBarItemSnapshot) -> MenuItemActivationResult
    let onDismiss: () -> Void

    @State private var searchQuery = ""
    @State private var selectedID: MenuBarItemSnapshot.ID?
    @State private var statusMessage = "Ready"
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private let snapshotResolver = IconGroupSnapshotResolver()

    private var matchedSnapshots: [MenuBarItemSnapshot] {
        snapshotResolver.matchedSnapshots(
            for: group,
            snapshots: snapshots,
            searchQuery: searchQuery
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 560, height: 420)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("groupPanel.panel")
        .onAppear {
            selectedID = matchedSnapshots.first?.id
        }
        .onChange(of: matchedSnapshots) {
            if selectedID == nil || !matchedSnapshots.contains(where: { $0.id == selectedID }) {
                selectedID = matchedSnapshots.first?.id
            }
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
            activateSelected()
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: group.symbolName ?? "folder")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(group.name)
                            .font(.title3.bold())
                            .lineLimit(1)

                        if group.isProtected {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("\(matchedSnapshots.count) available item\(matchedSnapshots.count == 1 ? "" : "s")")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            SearchField(
                "Search group",
                text: $searchQuery,
                autoFocus: true,
                accessibilityIdentifier: "groupPanel.search"
            )
        }
        .controlSize(.small)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var content: some View {
        Group {
            if matchedSnapshots.isEmpty {
                UnavailablePanel(
                    title: emptyStateTitle,
                    message: emptyStateMessage,
                    systemImage: searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "menubar.rectangle" : "magnifyingglass"
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("groupPanel.empty")
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(matchedSnapshots) { snapshot in
                                IconGroupPanelItemRowView(
                                    snapshot: snapshot,
                                    isSelected: snapshot.id == selectedID
                                ) {
                                    selectedID = snapshot.id
                                    activate(snapshot)
                                }
                                .id(snapshot.id)
                            }
                        }
                        .padding(12)
                    }
                    .onChange(of: selectedID) { _, newValue in
                        guard let newValue else { return }
                        if accessibilityReduceMotion {
                            proxy.scrollTo(newValue, anchor: .center)
                        } else {
                            withAnimation(.snappy(duration: 0.15)) {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Label("Return reveals and highlights. Click original icon manually.", systemImage: "return")
                .foregroundStyle(.secondary)
            Spacer()
            Text(statusMessage)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var emptyStateTitle: String {
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No Matching Items"
        }

        return "No Group Items"
    }

    private var emptyStateMessage: String {
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Try another app name, item title, or bundle identifier."
        }

        if group.itemRefs.isEmpty {
            return "This group has no saved item rules yet. Add items from Find Icon, Second Bar, or Groups settings."
        }

        return "No current menu bar items match this group. Refresh discovery after the relevant apps are running."
    }

    private func moveSelection(by delta: Int) {
        let items = matchedSnapshots
        guard !items.isEmpty else {
            selectedID = nil
            return
        }
        let ids = items.map(\.id)
        let currentIndex = selectedID.flatMap { ids.firstIndex(of: $0) } ?? 0
        let nextIndex = min(max(currentIndex + delta, 0), ids.count - 1)
        selectedID = ids[nextIndex]
    }

    private func activateSelected() {
        guard let selectedID,
              let snapshot = matchedSnapshots.first(where: { $0.id == selectedID }) else {
            return
        }
        activate(snapshot)
    }

    private func activate(_ snapshot: MenuBarItemSnapshot) {
        let result = onActivate(snapshot)
        statusMessage = result.outcome.displayName
    }
}
