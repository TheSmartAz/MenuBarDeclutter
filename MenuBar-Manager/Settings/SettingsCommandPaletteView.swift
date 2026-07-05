import SwiftUI

struct SettingsCommandPaletteView: View {
    @Environment(\.dismiss) private var dismiss
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
                resultCount: results.count,
                onSubmit: activateSelectedEntry
            )

            Divider()

            SettingsCommandPaletteResultsList(
                entries: results,
                selectedEntryID: selectedEntryID,
                onSelect: selectEntry,
                onActivate: activateEntry
            )

            Divider()

            SettingsCommandPaletteFooter(
                resultCount: results.count,
                selectedEntry: selectedEntry
            )
        }
        .frame(width: 580, height: 486)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            selectedEntryID = results.first?.id
        }
        .onChange(of: results.map(\.id)) { _, ids in
            if let selectedEntryID, ids.contains(selectedEntryID) {
                return
            }
            selectedEntryID = ids.first
        }
        .onMoveCommand(perform: moveSelection)
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.return) {
            activateSelectedEntry()
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .accessibilityIdentifier("settings.commandPalette")
    }

    private var selectedEntry: SettingsCommandPaletteEntry? {
        guard let selectedEntryID else { return results.first }
        return results.first { $0.id == selectedEntryID } ?? results.first
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

    private func moveSelection(by delta: Int) {
        guard !results.isEmpty else { return }

        let currentIndex = selectedEntryID.flatMap { selectedEntryID in
            results.firstIndex { $0.id == selectedEntryID }
        } ?? 0

        let nextIndex = min(max(currentIndex + delta, 0), results.count - 1)
        selectedEntryID = results[nextIndex].id
    }

    private func moveSelection(_ direction: MoveCommandDirection) {
        switch direction {
        case .up:
            moveSelection(by: -1)
        case .down:
            moveSelection(by: 1)
        default:
            break
        }
    }
}

private struct SettingsCommandPaletteSearchField: View {
    @Binding var query: String
    let resultCount: Int
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            IntegratedSearchField(
                "Find a setting or action",
                text: $query,
                autoFocus: true,
                accessibilityIdentifier: "settings.commandPalette.search",
                clearAccessibilityIdentifier: "settings.commandPalette.clearSearch",
                onSubmit: onSubmit
            )

            HStack(spacing: 8) {
                Label(resultCount == 1 ? "1 result" : "\(resultCount) results", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("settings.commandPalette.resultCount")

                Text("Arrows select. Return opens.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

private struct SettingsCommandPaletteResultsList: View {
    let entries: [SettingsCommandPaletteEntry]
    let selectedEntryID: SettingsCommandPaletteEntry.ID?
    let onSelect: (SettingsCommandPaletteEntry) -> Void
    let onActivate: (SettingsCommandPaletteEntry) -> Void
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private var groups: [SettingsCommandPaletteResultGroup] {
        SettingsCommandPaletteIndex.resultGroups(for: entries)
    }

    var body: some View {
        if entries.isEmpty {
            UnavailablePanel(
                title: "No Results",
                message: "Try another setting, page name, recovery action, or privacy keyword.",
                systemImage: "magnifyingglass"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("settings.commandPalette.empty")
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(groups) { group in
                            SettingsCommandPaletteResultGroupHeader(group: group)

                            ForEach(group.entries) { entry in
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
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
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

private struct SettingsCommandPaletteResultGroupHeader: View {
    let group: SettingsCommandPaletteResultGroup

    var body: some View {
        HStack(spacing: 8) {
            Label(group.title, systemImage: group.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Text(group.entries.count.formatted())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 6)
        .padding(.top, 5)
        .padding(.bottom, 1)
        .help(group.helpText)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(group.title), \(group.entries.count.formatted()) results")
        .accessibilityIdentifier("settings.commandPalette.group.\(group.id)")
    }
}

private struct SettingsCommandPaletteRow: View {
    let entry: SettingsCommandPaletteEntry
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(PanelSelectionTokens.badgeFill(entry.tint, isSelected: isSelected || isHovered))

                Image(systemName: entry.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(entry.tint)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PanelSelectionTokens.primaryForeground(isSelected: isSelected))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(entry.subtitle)
                    .font(.caption)
                    .foregroundStyle(PanelSelectionTokens.secondaryForeground(isSelected: isSelected))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                CommandPaletteEntryBadge(entry: entry, isSelected: isSelected)

                Label(entry.kind == .action ? "Run" : "Open", systemImage: entry.kind == .action ? "return" : "arrow.right")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PanelSelectionTokens.accessoryForeground(isSelected: isSelected))
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .panelSelectableRowBackground(isSelected: isSelected, isHovered: isHovered)
        .contentShape(.rect)
        .onHover { isHovered = $0 }
        .help(helpText)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Press Return to open this setting or action." : "Use the arrow keys to select this result.")
        .accessibilityIdentifier("settings.commandPalette.row.\(entry.id)")
    }

    private var accessibilityLabel: String {
        "\(entry.title), \(entry.subtitle)"
    }

    private var helpText: String {
        entry.kind == .action
            ? "\(entry.title). \(entry.subtitle) Press Return to run."
            : "\(entry.title). \(entry.subtitle) Press Return to open."
    }
}

private struct CommandPaletteEntryBadge: View {
    let entry: SettingsCommandPaletteEntry
    let isSelected: Bool

    var body: some View {
        Text(entry.badgeText)
            .font(.caption2)
            .bold()
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(PanelSelectionTokens.badgeFill(entry.tint, isSelected: isSelected), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(PanelSelectionTokens.badgeStroke(entry.tint, isSelected: isSelected), lineWidth: DesignTokens.Stroke.hairline)
            }
            .foregroundStyle(PanelSelectionTokens.badgeForeground(entry.tint, isSelected: isSelected))
    }
}

private struct SettingsCommandPaletteFooter: View {
    let resultCount: Int
    let selectedEntry: SettingsCommandPaletteEntry?

    var body: some View {
        HStack(spacing: 10) {
            Label("Local settings only", systemImage: "checkmark.shield")
                .foregroundStyle(.secondary)

            Spacer()

            if let selectedEntry {
                Text(selectedEntry.kind == .action ? "Return runs selected action" : "Return opens selected page")
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            } else {
                Text(resultCount == 0 ? "No matching commands" : "Choose a command")
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("settings.commandPalette.footer")
    }
}

private extension SettingsCommandPaletteEntry {
    var tint: Color {
        switch kind {
        case .action:
            .orange
        case .setting:
            switch resultGroupKind {
            case .primarySettings:
                .accentColor
            case .moreSettings, .advancedMatches:
                .purple
            case .legacyRoutes:
                .secondary
            case .localActions:
                .orange
            }
        }
    }

    var badgeText: String {
        switch resultGroupKind {
        case .primarySettings:
            "Primary"
        case .moreSettings:
            "More"
        case .legacyRoutes:
            "Route"
        case .advancedMatches:
            "Advanced"
        case .localActions:
            "Action"
        }
    }
}
