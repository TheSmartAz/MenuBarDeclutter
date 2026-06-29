import SwiftUI

struct DragHintPopoverView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 34, height: 34)
                    .background(.blue.opacity(0.12), in: .rect(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Position the separator")
                        .font(.headline)

                    Text(AppConstants.dragHintMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                DragHintStep(index: 1, title: "Hold Command", systemImage: "command")
                DragHintStep(index: 2, title: "Drag the separator", systemImage: "arrow.left.and.right")
            }
        }
        .padding(14)
        .frame(width: 356, alignment: .leading)
        .background(.regularMaterial, in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.primary.opacity(0.12), lineWidth: 1)
        }
        .accessibilityIdentifier("dragHint.popover")
    }
}

private struct DragHintStep: View {
    let index: Int
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
                .background(.secondary.opacity(0.12), in: Circle())

            Image(systemName: systemImage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(title)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.10), lineWidth: 1)
        }
    }
}
