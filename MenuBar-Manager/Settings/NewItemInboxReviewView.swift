import SwiftUI

struct NewItemInboxReviewView: View {
    let state: NewMenuBarItemInboxReviewState
    var onDismiss: (String) -> Void
    var onSetPreference: (String, PlacementItemPreference) -> Void = { _, _ in }
    var onReset: () -> Void
    var onOpenFindIcon: (() -> Void)?
    var onOpenSecondBar: (() -> Void)?
    var onOpenArrange: (() -> Void)?
    var onOpenGroups: (() -> Void)?
    var onOpenInspector: (() -> Void)?
    var onOpenPrivacy: (() -> Void)?

    var body: some View {
        switch state.status {
        case .unavailable:
            unavailableView
        case .empty:
            emptyView
        case .ready:
            readyView
        }
    }

    private var unavailableView: some View {
        ContentUnavailableView {
            Label("New Item Inbox Unavailable", systemImage: "tray")
        } description: {
            Text("Pro Discovery and Accessibility permission are required.")
        } actions: {
            Button("Open Privacy", systemImage: "hand.raised") {
                onOpenPrivacy?()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132)
        .accessibilityIdentifier("newItemInbox.unavailable")
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No New Items", systemImage: "tray")
        } description: {
            Text("Newly discovered menu bar items will appear here.")
        } actions: {
            Button("Open Arrange", systemImage: "arrow.up.left.and.arrow.down.right") {
                onOpenArrange?()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132)
        .accessibilityIdentifier("newItemInbox.empty")
    }

    private var readyView: some View {
        VStack(spacing: 0) {
            NewItemInboxHeader(
                count: state.rows.count,
                onOpenArrange: onOpenArrange,
                onReset: onReset
            )

            ClearGlassDivider()

            ForEach(Array(state.rows.enumerated()), id: \.element.id) { offset, row in
                NewItemInboxReviewRowView(
                    row: row,
                    onDismiss: onDismiss,
                    onSetPreference: onSetPreference,
                    onOpenFindIcon: onOpenFindIcon,
                    onOpenSecondBar: onOpenSecondBar,
                    onOpenArrange: onOpenArrange,
                    onOpenGroups: onOpenGroups,
                    onOpenInspector: onOpenInspector
                )

                if offset < state.rows.count - 1 {
                    ClearGlassDivider()
                }
            }
        }
        .accessibilityIdentifier("newItemInbox.ready")
    }
}

private struct NewItemInboxHeader: View {
    let count: Int
    var onOpenArrange: (() -> Void)?
    var onReset: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "tray.full")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.orange)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(count == 1 ? "1 item needs review" : "\(count) items need review")
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("Choose a placement path or dismiss items you already handled.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 16)

            HStack(spacing: 8) {
                Button("Open Arrange", systemImage: "arrow.up.left.and.arrow.down.right") {
                    onOpenArrange?()
                }

                Button(role: .destructive, action: onReset) {
                    Label("Reset Inbox", systemImage: "arrow.counterclockwise")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .fixedSize()
        }
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NewItemInboxReviewRowView: View {
    let row: NewMenuBarItemInboxReviewRow
    var onDismiss: (String) -> Void
    var onSetPreference: (String, PlacementItemPreference) -> Void
    var onOpenFindIcon: (() -> Void)?
    var onOpenSecondBar: (() -> Void)?
    var onOpenArrange: (() -> Void)?
    var onOpenGroups: (() -> Void)?
    var onOpenInspector: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.body)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text("First")
                    Text(row.firstSeenAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    Text("Last")
                    Text(row.lastSeenAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    Text(row.seenCountLabel)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 16)

            HStack(spacing: 8) {
                Button("Arrange", systemImage: "arrow.up.left.and.arrow.down.right") {
                    onOpenArrange?()
                }
                .accessibilityIdentifier("newItemInbox.row.openArrange")
                .accessibilityLabel("Open Arrange")

                Button("Find", systemImage: "magnifyingglass") {
                    onOpenFindIcon?()
                }
                .accessibilityIdentifier("newItemInbox.row.openFind")
                .accessibilityLabel("Open Find Icon")

                Menu("Review", systemImage: "checklist") {
                    ForEach(row.actions) { action in
                        reviewActionButton(action)
                    }
                }
                .accessibilityIdentifier("newItemInbox.row.reviewMenu")

                Button("Dismiss", systemImage: "checkmark.circle") {
                    onDismiss(row.id)
                }
                .accessibilityIdentifier("newItemInbox.row.dismiss")
                .accessibilityLabel("Dismiss New Item")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .fixedSize()
        }
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("newItemInbox.row")
    }

    @ViewBuilder
    private func reviewActionButton(_ action: NewMenuBarItemReviewAction) -> some View {
        switch action {
        case .keepVisible, .hideManually, .alwaysHideManually, .reviewLater:
            Button(action.title, systemImage: action.systemImage) {
                if let preference = action.placementPreference {
                    onSetPreference(row.id, preference)
                }
            }
        case .addToCollection:
            Button(action.title, systemImage: action.systemImage) {
                onOpenGroups?()
            }
        case .showInFindIcon:
            Button(action.title, systemImage: action.systemImage) {
                onOpenFindIcon?()
            }
        case .showInSecondBar:
            Button(action.title, systemImage: action.systemImage) {
                onOpenSecondBar?()
            }
        case .arrangeManually:
            Button(action.title, systemImage: action.systemImage) {
                onOpenArrange?()
            }
        case .dryRunAssistedMove:
            Button(action.title, systemImage: action.systemImage) {
                onOpenArrange?()
            }
        case .dismiss:
            Button(action.title, systemImage: action.systemImage) {
                onDismiss(row.id)
            }
        }
    }
}

#Preview {
    NewItemInboxReviewView(
        state: NewMenuBarItemInboxReviewState(
            inbox: NewMenuBarItemInbox(
                schemaVersion: 1,
                knownItemKeys: [],
                dismissedItemKeys: [],
                items: [
                    NewMenuBarItem(
                        id: "preview-1",
                        firstSeenAt: .now.addingTimeInterval(-3600),
                        lastSeenAt: .now,
                        seenCount: 2
                    )
                ]
            ),
            isAvailable: true
        ),
        onDismiss: { _ in },
        onSetPreference: { _, _ in },
        onReset: {}
    )
    .padding()
    .frame(width: 760)
}
