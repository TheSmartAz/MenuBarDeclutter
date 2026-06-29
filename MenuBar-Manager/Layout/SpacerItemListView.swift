import SwiftUI

struct SpacerItemListView: View {
    let store: SpacerItemStore
    let controller: SpacerStatusItemController?
    var onChange: (() -> Void)?

    @State private var revision = 0
    @State private var editingItem: SpacerItemModel?

    private var items: [SpacerItemModel] {
        _ = revision
        return store.items.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("Add Divider", systemImage: "line.vertical") { add(.divider) }
                Button("Add Thin Spacer", systemImage: "arrow.left.and.right") { add(.thinSpacer) }
                Button("Add Wide Spacer", systemImage: "arrow.left.and.right.square") { add(.wideSpacer) }
                Button("Add Label", systemImage: "textformat") { add(.label) }
                Button("Add Icon", systemImage: "circle") { add(.icon) }
                Spacer()
            }

            if items.isEmpty {
                ContentUnavailableView("No Spacers", systemImage: "line.vertical")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.systemImageName ?? item.type.defaultSystemImageName ?? "line.horizontal.3")
                                .frame(width: 24)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title.isEmpty ? item.type.displayName : item.title)
                                Text("\(item.type.displayName), \(item.length, format: .number.precision(.fractionLength(0)))pt")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("Visible", isOn: Binding(
                                get: { item.isVisible },
                                set: { value in
                                    store.update(id: item.id) { $0.isVisible = value }
                                    rebuild()
                                }
                            ))
                            .labelsHidden()
                            Button("Edit", systemImage: "pencil") {
                                editingItem = item
                            }
                            .labelStyle(.iconOnly)
                            Button("Remove", systemImage: "trash", role: .destructive) {
                                controller?.remove(id: item.id)
                                rebuild()
                            }
                            .labelStyle(.iconOnly)
                        }
                        .padding(.vertical, 7)

                        if item.id != items.last?.id {
                            ClearGlassDivider()
                        }
                    }
                }
            }

            HStack {
                Button("Hide All Spacer Markers", systemImage: "eye.slash") {
                    controller?.setMarkersVisible(false)
                    rebuild()
                }
                Button("Reset Spacers", systemImage: "arrow.counterclockwise", role: .destructive) {
                    controller?.reset()
                    rebuild()
                }
            }
        }
        .onAppear {
            store.load()
            revision += 1
        }
        .sheet(item: $editingItem) { item in
            SpacerItemEditorView(item: item) { updated in
                store.update(id: updated.id) { stored in
                    stored.type = updated.type
                    stored.title = updated.title
                    stored.systemImageName = updated.systemImageName
                    stored.length = updated.length
                    stored.isVisible = updated.isVisible
                    stored.showMarker = updated.showMarker
                }
                editingItem = nil
                rebuild()
            } onCancel: {
                editingItem = nil
            }
        }
    }

    private func add(_ type: SpacerItemType) {
        if let controller {
            _ = controller.add(type: type, title: type == .label ? "Label" : "")
        } else {
            _ = store.add(type: type, title: type == .label ? "Label" : "")
        }
        rebuild()
    }

    private func rebuild() {
        controller?.rebuildItems()
        revision += 1
        onChange?()
    }
}
