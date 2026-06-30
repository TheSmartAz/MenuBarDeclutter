import SwiftUI

struct IconGroupItemPickerView: View {
    let snapshots: [MenuBarItemSnapshot]
    let isAvailable: Bool
    let onAdd: (MenuBarItemSnapshot) -> Void

    @State private var query = ""

    private var filteredSnapshots: [MenuBarItemSnapshot] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = snapshots.sorted {
            displayTitle(for: $0).localizedStandardCompare(displayTitle(for: $1)) == .orderedAscending
        }
        guard !trimmed.isEmpty else { return sorted }
        return sorted.filter { snapshot in
            [
                snapshot.owningApplicationName,
                snapshot.title,
                snapshot.bundleIdentifier
            ]
            .compactMap { $0 }
            .joined(separator: " ")
            .localizedStandardContains(trimmed)
        }
    }

    var body: some View {
        DisclosureGroup {
            if !isAvailable {
                ClearGlassInlineMessage(
                    text: "Enable Pro Mode and Accessibility Discovery for the current menu bar item picker.",
                    systemImage: "star",
                    style: .info
                )
            } else if snapshots.isEmpty {
                ContentUnavailableView("No Snapshot Items", systemImage: "menubar.rectangle", description: Text("Refresh menu bar items after enabling Pro Mode."))
                    .frame(maxWidth: .infinity, minHeight: 110)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    SearchField("Search items", text: $query, width: nil)

                    if filteredSnapshots.isEmpty {
                        ContentUnavailableView("No Matching Items", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity, minHeight: 128)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(filteredSnapshots) { snapshot in
                                    IconGroupPickerSnapshotRow(
                                        snapshot: snapshot,
                                        title: displayTitle(for: snapshot),
                                        subtitle: displaySubtitle(for: snapshot),
                                        onAdd: {
                                            onAdd(snapshot)
                                        }
                                    )
                                }
                            }
                            .padding(6)
                        }
                        .frame(maxHeight: 220)
                        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
                        }
                    }
                }
                .padding(.top, 8)
            }
        } label: {
            Label("Current Menu Bar Items", systemImage: "menubar.rectangle")
                .font(.body)
        }
    }

    private func displayTitle(for snapshot: MenuBarItemSnapshot) -> String {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
    }

    private func displaySubtitle(for snapshot: MenuBarItemSnapshot) -> String {
        DisplayString.firstNonEmpty([
            snapshot.bundleIdentifier,
            snapshot.title,
            snapshot.zone.displayName
        ]) ?? snapshot.zone.displayName
    }
}

private struct IconGroupPickerSnapshotRow: View {
    let snapshot: MenuBarItemSnapshot
    let title: String
    let subtitle: String
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            AppIconView(snapshot: snapshot, size: 26, cornerRadius: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            PickerZoneBadge(title: snapshot.zone.displayName, color: zoneColor)

            Button("Add", systemImage: "plus") {
                onAdd()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Add Item")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.24), lineWidth: 0.5)
        }
    }

    private var zoneColor: Color {
        switch snapshot.zone {
        case .visible:
            .green
        case .hidden:
            .orange
        case .alwaysHidden:
            .red
        case .unknown:
            .secondary
        }
    }
}

private struct PickerZoneBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.caption)
            .bold()
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(color.opacity(0.24), lineWidth: 0.5)
            }
    }
}
