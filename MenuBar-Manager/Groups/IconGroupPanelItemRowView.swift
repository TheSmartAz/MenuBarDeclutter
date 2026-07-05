import SwiftUI

struct IconGroupPanelItemRowView: View {
    let snapshot: MenuBarItemSnapshot
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                MenuBarItemIconView(snapshot: snapshot, size: 32, cornerRadius: 7)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(displayTitle)
                            .font(.body)
                            .bold()
                            .foregroundStyle(PanelSelectionTokens.primaryForeground(isSelected: isSelected))
                            .lineLimit(1)

                        ZoneTextBadge(title: snapshot.zone.displayName, color: zoneColor, isSelected: isSelected)
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(PanelSelectionTokens.secondaryForeground(isSelected: isSelected))
                        .lineLimit(1)
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
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayTitle), \(snapshot.zone.displayName)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Press Return to reveal and highlight this menu bar item." : "Use the arrow keys to select this result.")
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

    private var subtitle: String {
        DisplayString.firstNonEmpty([
            snapshot.bundleIdentifier,
            snapshot.title,
            snapshot.role,
            snapshot.zone.displayName
        ]) ?? snapshot.zone.displayName
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
