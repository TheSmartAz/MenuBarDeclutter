import SwiftUI

struct SettingsCommandPaletteView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFieldFocused: Bool
    @State private var query = ""
    @State private var selectedEntryID: SettingsCommandPaletteEntry.ID?

    let index: SettingsCommandPaletteIndex
    let onActivate: (SettingsCommandPaletteEntry) -> Void

    private var results: [SettingsCommandPaletteEntry] {
        index.search(query, limit: 14)
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsCommandPaletteSearchField(
                query: $query,
                searchFieldFocused: $searchFieldFocused,
                onSubmit: activateSelectedEntry
            )

            Divider()

            SettingsCommandPaletteResultsList(
                entries: results,
                selectedEntryID: selectedEntryID,
                onSelect: selectEntry,
                onActivate: activateEntry
            )
        }
        .frame(width: 560, height: 460)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            selectedEntryID = results.first?.id
            searchFieldFocused = true
        }
        .onChange(of: results.map(\.id)) { _, ids in
            if let selectedEntryID, ids.contains(selectedEntryID) {
                return
            }
            selectedEntryID = ids.first
        }
        .onMoveCommand(perform: moveSelection)
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .accessibilityIdentifier("settings.commandPalette")
    }

    private func selectEntry(_ entry: SettingsCommandPaletteEntry) {
        selectedEntryID = entry.id
    }

    private func activateSelectedEntry() {
        guard let selectedEntryID,
              let entry = results.first(where: { $0.id == selectedEntryID }) ?? results.first else {
            return
        }
        activateEntry(entry)
    }

    private func activateEntry(_ entry: SettingsCommandPaletteEntry) {
        onActivate(entry)
        dismiss()
    }

    private func moveSelection(_ direction: MoveCommandDirection) {
        guard !results.isEmpty else { return }

        let currentIndex = selectedEntryID.flatMap { selectedEntryID in
            results.firstIndex { $0.id == selectedEntryID }
        } ?? 0

        switch direction {
        case .up:
            selectedEntryID = results[max(currentIndex - 1, 0)].id
        case .down:
            selectedEntryID = results[min(currentIndex + 1, results.count - 1)].id
        default:
            break
        }
    }
}

private struct SettingsCommandPaletteSearchField: View {
    @Binding var query: String
    var searchFieldFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)

            TextField("Find a setting or action", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .regular))
                .focused(searchFieldFocused)
                .onSubmit(onSubmit)
                .accessibilityLabel("Find a setting or action")
                .accessibilityIdentifier("settings.commandPalette.search")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
    }
}

private struct SettingsCommandPaletteResultsList: View {
    let entries: [SettingsCommandPaletteEntry]
    let selectedEntryID: SettingsCommandPaletteEntry.ID?
    let onSelect: (SettingsCommandPaletteEntry) -> Void
    let onActivate: (SettingsCommandPaletteEntry) -> Void
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        if entries.isEmpty {
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass",
                description: Text("Try another setting or action.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("settings.commandPalette.empty")
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(entries) { entry in
                            Button {
                                onActivate(entry)
                            } label: {
                                SettingsCommandPaletteRow(
                                    entry: entry,
                                    isSelected: selectedEntryID == entry.id
                                )
                            }
                            .buttonStyle(.plain)
                            .id(entry.id)
                            .onHover { isHovered in
                                if isHovered {
                                    onSelect(entry)
                                }
                            }
                        }
                    }
                    .padding(8)
                }
                .onChange(of: selectedEntryID) { _, id in
                    guard let id else { return }
                    if accessibilityReduceMotion {
                        proxy.scrollTo(id, anchor: .center)
                    } else {
                        withAnimation(.snappy(duration: 0.12)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
            .accessibilityIdentifier("settings.commandPalette.results")
        }
    }
}

private struct SettingsCommandPaletteRow: View {
    let entry: SettingsCommandPaletteEntry
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: entry.systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(entry.subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: entry.kind == .action ? "return" : "arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white.opacity(0.82) : Color.secondary.opacity(0.65))
                .frame(width: 18, height: 18)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(rowBackground, in: .rect(cornerRadius: 7))
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Press Return to open this setting or action." : "Use the arrow keys to select this result.")
        .accessibilityIdentifier("settings.commandPalette.row.\(entry.id)")
    }

    private var rowBackground: Color {
        isSelected ? .accentColor : .clear
    }

    private var accessibilityLabel: String {
        "\(entry.title), \(entry.subtitle)"
    }
}
