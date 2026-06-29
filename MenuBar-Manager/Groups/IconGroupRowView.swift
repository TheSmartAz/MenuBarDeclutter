import SwiftUI

struct IconGroupRowView: View {
    let group: IconGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: group.symbolName ?? "folder")
                    .foregroundStyle(color)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(group.name)
                            .lineLimit(1)

                        if group.isProtected {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("\(group.itemCount) item ref\(group.itemCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if group.showAsStatusItem {
                    Image(systemName: "menubar.rectangle")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.16) : Color.clear, in: .rect(cornerRadius: 7))
        }
        .buttonStyle(.plain)
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
}
