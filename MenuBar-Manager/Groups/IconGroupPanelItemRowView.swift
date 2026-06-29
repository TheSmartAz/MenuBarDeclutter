import SwiftUI

struct IconGroupPanelItemRowView: View {
    let snapshot: MenuBarItemSnapshot
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AppIconView(snapshot: snapshot, size: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayTitle)
                        .lineLimit(1)

                    Text(snapshot.bundleIdentifier ?? snapshot.title ?? snapshot.zone.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(snapshot.zone.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.16) : Color.clear, in: .rect(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private var displayTitle: String {
        DisplayString.firstNonEmpty([
            snapshot.owningApplicationName,
            snapshot.title,
            snapshot.bundleIdentifier
        ]) ?? "Menu Bar Item"
    }
}
