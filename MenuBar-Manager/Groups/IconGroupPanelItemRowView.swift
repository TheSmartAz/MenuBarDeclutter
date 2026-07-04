import SwiftUI

struct IconGroupPanelItemRowView: View {
    let snapshot: MenuBarItemSnapshot
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                MenuBarItemIconView(snapshot: snapshot, size: 30, cornerRadius: 7)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayTitle)
                        .foregroundStyle(PanelSelectionTokens.primaryForeground(isSelected: isSelected))
                        .lineLimit(1)

                    Text(snapshot.bundleIdentifier ?? snapshot.title ?? snapshot.zone.displayName)
                        .font(.caption)
                        .foregroundStyle(PanelSelectionTokens.secondaryForeground(isSelected: isSelected))
                        .lineLimit(1)
                }

                Spacer()

                ZoneTextBadge(title: snapshot.zone.displayName, color: zoneColor, isSelected: isSelected)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .panelSelectableRowBackground(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayTitle), \(snapshot.zone.displayName)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private var zoneColor: Color {
        switch snapshot.zone {
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

    private var displayTitle: String {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
    }
}

private struct ZoneTextBadge: View {
    let title: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.caption)
            .bold()
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(PanelSelectionTokens.badgeForeground(color, isSelected: isSelected))
            .background(PanelSelectionTokens.badgeFill(color, isSelected: isSelected), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(PanelSelectionTokens.badgeStroke(color, isSelected: isSelected), lineWidth: DesignTokens.Stroke.hairline)
            }
    }
}
