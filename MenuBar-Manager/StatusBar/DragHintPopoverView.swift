import SwiftUI

struct DragHintPopoverView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position the separator")
                .font(.headline)

            Text(AppConstants.dragHintMessage)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 320, alignment: .leading)
    }
}
