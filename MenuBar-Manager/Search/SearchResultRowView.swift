import AppKit
import SwiftUI

struct SearchResultRowView: View {
    let result: MenuBarSearchResult
    let isSelected: Bool

    @MainActor
    init(
        result: MenuBarSearchResult,
        isSelected: Bool
    ) {
        self.result = result
        self.isSelected = isSelected
    }

    var body: some View {
        HStack(spacing: 10) {
            MenuBarItemIconView(snapshot: result.snapshot, size: 32, cornerRadius: 7)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(result.displayTitle)
                        .font(.body)
                        .bold()
                        .foregroundStyle(PanelSelectionTokens.primaryForeground(isSelected: isSelected))
                        .lineLimit(1)

                    SearchZoneBadge(
                        title: result.snapshot.zone.displayName,
                        color: zoneColor,
                        isSelected: isSelected
                    )

                    ForEach(Array(result.workspaceBadges.prefix(2)), id: \.rawValue) { badge in
                        SearchZoneBadge(
                            title: badge.title,
                            color: .blue,
                            isSelected: isSelected
                        )
                    }
                }

                HStack(spacing: 8) {
                    Text(result.matchReason.displayName)
                        .lineLimit(1)

                    Text(result.displaySubtitle)
                        .lineLimit(1)

                    Text(result.snapshot.scanTimestamp, format: Date.FormatStyle(date: .omitted, time: .standard))
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(PanelSelectionTokens.secondaryForeground(isSelected: isSelected))
            }

            Spacer(minLength: 8)

            Image(systemName: isSelected ? "return.left" : "ellipsis")
                .font(.callout)
                .foregroundStyle(PanelSelectionTokens.accessoryForeground(isSelected: isSelected))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelSelectableRowBackground(isSelected: isSelected)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.displayTitle), \(result.snapshot.zone.displayName), \(result.matchReason.displayName)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Press Return to reveal and highlight this menu bar item." : "Use the arrow keys to select this result.")
    }

    private var zoneColor: Color {
        switch result.snapshot.zone {
        case .visible:
            .green
        case .hidden:
            .accentColor
        case .alwaysHidden:
            .red
        case .unknown:
            .secondary
        }
    }
}

private struct SearchZoneBadge: View {
    let title: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.caption)
            .bold()
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(badgeFill, in: .capsule)
            .overlay {
                Capsule()
                    .stroke(badgeStroke, lineWidth: DesignTokens.Stroke.hairline)
            }
            .foregroundStyle(badgeForeground)
    }

    private var badgeFill: Color {
        PanelSelectionTokens.badgeFill(color, isSelected: isSelected)
    }

    private var badgeStroke: Color {
        PanelSelectionTokens.badgeStroke(color, isSelected: isSelected)
    }

    private var badgeForeground: Color {
        PanelSelectionTokens.badgeForeground(color, isSelected: isSelected)
    }
}

#Preview {
    let snapshot = MenuBarItemSnapshot(
        title: "Sync Complete",
        role: "AXMenuBarItem",
        subrole: nil,
        frame: .zero,
        owningProcessIdentifier: nil,
        owningApplicationName: "Example",
        bundleIdentifier: "com.example.app",
        zone: .hidden,
        isLikelySystemItem: false,
        scanTimestamp: Date()
    )
    SearchResultRowView(
        result: MenuBarSearchResult(snapshot: snapshot, score: 1000, matchReason: .prefix),
        isSelected: true
    )
    .padding()
    .frame(width: 480)
}
