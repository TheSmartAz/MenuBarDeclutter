import SwiftUI

struct IconGroupPanelItemRowView: View {
    let snapshot: MenuBarItemSnapshot
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                AppIconView(snapshot: snapshot, size: 30, cornerRadius: 7)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayTitle)
                        .lineLimit(1)

                    Text(snapshot.bundleIdentifier ?? snapshot.title ?? snapshot.zone.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                ZoneTextBadge(title: snapshot.zone.displayName, color: zoneColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(rowBackground, in: .rect(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(rowStroke, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayTitle), \(snapshot.zone.displayName)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private var rowBackground: Color {
        isSelected ? Color.accentColor.opacity(0.16) : Color(nsColor: .controlBackgroundColor).opacity(0.45)
    }

    private var rowStroke: Color {
        isSelected ? Color.accentColor.opacity(0.55) : Color(nsColor: .separatorColor).opacity(0.24)
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
