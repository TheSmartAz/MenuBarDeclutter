import SwiftUI

struct SecondBarItemView: View {
    let snapshot: MenuBarItemSnapshot
    let iconSize: Double
    let showLabels: Bool
    let isSelected: Bool

    @MainActor
    init(
        snapshot: MenuBarItemSnapshot,
        iconSize: Double,
        showLabels: Bool,
        isSelected: Bool
    ) {
        self.snapshot = snapshot
        self.iconSize = iconSize
        self.showLabels = showLabels
        self.isSelected = isSelected
    }

    var body: some View {
        VStack(spacing: 6) {
            MenuBarItemIconView(
                snapshot: snapshot,
                size: CGFloat(iconSize),
                cornerRadius: CGFloat(min(8, iconSize / 4))
            )
                .overlay(alignment: .topTrailing) {
                    ZoneBadge(zone: snapshot.zone, isSelected: isSelected)
                        .offset(x: 5, y: -5)
                }

            if showLabels {
                VStack(spacing: 1) {
                    Text(displayTitle)
                        .font(.caption)
                        .foregroundStyle(PanelSelectionTokens.primaryForeground(isSelected: isSelected))
                        .lineLimit(1)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundStyle(PanelSelectionTokens.secondaryForeground(isSelected: isSelected))
                    }
                }
                .frame(width: max(72, iconSize + 36))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: max(72, iconSize + 28), minHeight: showLabels ? 92 : iconSize + 22)
        .panelSelectableRowBackground(isSelected: isSelected)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayTitle), \(snapshot.zone.displayName)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Press Return to reveal and highlight this item." : "Use the left and right arrow keys to select this item.")
    }

    private var displayTitle: String {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
    }

    private var subtitle: String? {
        DisplayString.firstNonEmpty([
            snapshot.title,
            snapshot.bundleIdentifier
        ].filter { $0 != displayTitle })
    }
}

private struct ZoneBadge: View {
    let zone: MenuBarZone
    let isSelected: Bool

    var body: some View {
        Text(badgeText)
            .font(.caption2)
            .bold()
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(PanelSelectionTokens.badgeFill(zoneColor, isSelected: isSelected), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(PanelSelectionTokens.badgeStroke(zoneColor, isSelected: isSelected), lineWidth: DesignTokens.Stroke.hairline)
            }
            .foregroundStyle(PanelSelectionTokens.badgeForeground(zoneColor, isSelected: isSelected))
    }

    private var badgeText: String {
        switch zone {
        case .hidden:
            "H"
        case .alwaysHidden:
            "A"
        case .visible:
            "V"
        case .unknown:
            "?"
        }
    }

    private var zoneColor: Color {
        switch zone {
        case .hidden:
            .accentColor
        case .alwaysHidden:
            .red
        case .visible:
            .green
        case .unknown:
            .secondary
        }
    }
}

#Preview {
    SecondBarItemView(
        snapshot: MenuBarItemSnapshot(
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
        ),
        iconSize: 32,
        showLabels: true,
        isSelected: true
    )
    .padding()
}
