import SwiftUI

struct SpacerItemEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: SpacerItemModel
    let onSave: (SpacerItemModel) -> Void
    let onCancel: () -> Void

    init(
        item: SpacerItemModel,
        onSave: @escaping (SpacerItemModel) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _draft = State(initialValue: item)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Edit Spacer")
                .font(.title2.bold())

            Form {
                Picker("Type", selection: $draft.type) {
                    ForEach(SpacerItemType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                TextField("Title", text: $draft.title)
                TextField("SF Symbol", text: Binding(
                    get: { draft.systemImageName ?? "" },
                    set: { draft.systemImageName = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
                ))
                Slider(value: Binding(
                    get: { draft.length },
                    set: { draft.length = SpacerItemModel.clampLength($0) }
                ), in: SpacerItemModel.minLength...SpacerItemModel.maxLength)
                Toggle("Visible", isOn: $draft.isVisible)
                Toggle("Show Marker", isOn: $draft.showMarker)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                Button("Save") {
                    onSave(draft)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
        .frame(minHeight: 420)
    }
}
