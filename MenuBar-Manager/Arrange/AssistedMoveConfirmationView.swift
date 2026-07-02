import SwiftUI

struct AssistedMoveConfirmationView: View {
    @Binding var firstUseAccepted: Bool
    @Binding var perMoveAccepted: Bool
    let commandTitle: String

    var body: some View {
        VStack(spacing: 0) {
            ClearGlassControlRow(
                systemImage: "hand.raised",
                title: "First-use confirmation",
                subtitle: "I understand automated menu bar movement is experimental."
            ) {
                Toggle("First-use confirmation", isOn: $firstUseAccepted)
                    .labelsHidden()
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "checkmark.shield",
                title: "Confirm this move",
                subtitle: "\(commandTitle) will run once for the selected item."
            ) {
                Toggle("Confirm this move", isOn: $perMoveAccepted)
                    .labelsHidden()
            }
        }
    }
}
