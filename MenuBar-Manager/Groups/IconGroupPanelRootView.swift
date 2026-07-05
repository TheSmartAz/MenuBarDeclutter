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

    init(
        group: IconGroup,
        snapshots: [MenuBarItemSnapshot],
        onActivate: @escaping (MenuBarItemSnapshot) -> MenuItemActivationResult,
        onDismiss: @escaping () -> Void,
        initialQuery: String = ""
    ) {
        self.group = group
        self.snapshots = snapshots
        self.onActivate = onActivate
        self.onDismiss = onDismiss
        _searchQuery = State(initialValue: initialQuery)
    }

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
        .menuBarDeclutterFloatingPanelChrome()
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
        .onKeyPress(.rightArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.leftArrow) {
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
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(groupTint.opacity(0.12))

                    Image(systemName: group.symbolName ?? "folder")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(groupTint)
                }
                .frame(width: 34, height: 34)

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

                HStack(spacing: 6) {
                    groupHeaderBadge(
                        "\(group.itemRefs.count) Rules",
                        systemImage: "checklist",
                        accessibilityLabel: "\(group.itemRefs.count) group rule\(group.itemRefs.count == 1 ? "" : "s")"
                    )

                    if group.isProtected {
                        groupHeaderBadge(
                            "Protected",
                            systemImage: "lock.fill",
                            accessibilityLabel: "Protected group"
                        )
                    }
                }
            }

            IntegratedSearchField(
                "Search group",
                text: $searchQuery,
                font: .system(size: 15, weight: .regular),
                autoFocus: true,
                accessibilityIdentifier: "groupPanel.search",
                clearAccessibilityIdentifier: "groupPanel.clearSearch"
            )
        }
        .controlSize(.small)
        .padding(.horizontal, DesignTokens.Spacing.panelInset)
        .padding(.vertical, 14)
    }

    private func groupHeaderBadge(
        _ title: String,
        systemImage: String,
        accessibilityLabel: String? = nil
    ) -> some View {
        FloatingPanelToolbarBadge(
            title,
            systemImage: systemImage,
            accessibilityLabel: accessibilityLabel
        )
    }

    private var groupTint: Color {
        switch group.colorName {
        case "blue":
            .blue
        case "green":
            .green
        case "orange":
            .orange
        case "purple":
            .purple
        case "red":
            .red
        default:
            .accentColor
        }
    }

    private var content: some View {
        Group {
            if matchedSnapshots.isEmpty {
                UnavailablePanel(
                    title: emptyStateTitle,
                    message: emptyStateMessage,
                    systemImage: searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "menubar.rectangle" : "magnifyingglass",
                    primaryAction: emptyStatePrimaryAction
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
                                .onHover { isHovered in
                                    if isHovered {
                                        selectedID = snapshot.id
                                    }
                                }
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
                    .accessibilityIdentifier("groupPanel.items")
                }
            }
        }
    }

    private var footer: some View {
        FloatingPanelFooter(
            leadingTitle: "Return reveals the original item. Click it in the menu bar to open.",
            leadingSystemImage: "return",
            trailingTitle: statusMessage
        )
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

    private var emptyStatePrimaryAction: UnavailablePanel.Action? {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return UnavailablePanel.Action(title: "Clear Search", systemImage: "xmark.circle") {
            searchQuery = ""
        }
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
