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
        DisclosureGroup("Add from Current Menu Bar Items") {
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

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredSnapshots) { snapshot in
                                HStack(spacing: 10) {
                                    AppIconView(snapshot: snapshot, size: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(displayTitle(for: snapshot))
                                            .lineLimit(1)
                                        Text(snapshot.bundleIdentifier ?? snapshot.zone.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text(snapshot.zone.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Button("Add", systemImage: "plus") {
                                        onAdd(snapshot)
                                    }
                                    .labelStyle(.iconOnly)
                                    .help("Add Item")
                                }
                                .padding(.vertical, 6)

                                ClearGlassDivider()
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                }
            }
        }
    }

    private func displayTitle(for snapshot: MenuBarItemSnapshot) -> String {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
    }
}
