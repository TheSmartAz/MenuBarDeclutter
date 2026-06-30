import SwiftUI

struct IconGroupRowView: View {
    let group: IconGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color.opacity(isSelected ? 0.18 : 0.11))

                    Image(systemName: group.symbolName ?? "folder")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(color)
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(group.name)
                            .font(.body)
                            .lineLimit(1)

                        if group.isProtected {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 6) {
                        Text("\(group.itemCount) item\(group.itemCount == 1 ? "" : "s")")
                            .lineLimit(1)

                        if !group.isEnabled {
                            GroupRowBadge("Off", systemImage: "pause.circle")
                        }

                        if group.showInSecondBar {
                            GroupRowBadge("Second Bar", systemImage: "rectangle.bottomthird.inset.filled")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                if group.showAsStatusItem {
                    Image(systemName: "menubar.rectangle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .help("Shown as a menu bar status item")
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .background(rowBackground, in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(rowStroke, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var color: Color {
        switch group.colorName {
        case "blue":
            .blue
        case "green":
            .green
        case "orange":
            .orange
        case "purple":
            .purple
        case "red":
            .red
        default:
            .secondary
        }
    }

    private var rowBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        }
        return Color(nsColor: .controlBackgroundColor).opacity(0.35)
    }

    private var rowStroke: Color {
        if isSelected {
            return Color.accentColor.opacity(0.42)
        }
        return Color(nsColor: .separatorColor).opacity(0.24)
    }
}

private struct GroupRowBadge: View {
    let text: String
    let systemImage: String

    init(_ text: String, systemImage: String) {
        self.text = text
        self.systemImage = systemImage
    }

    var body: some View {
        Label(text, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(nsColor: .quaternaryLabelColor).opacity(0.12), in: .capsule)
    }
}
