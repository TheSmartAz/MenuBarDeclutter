import SwiftUI

struct IconGroupEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let existingGroups: [IconGroup]
    let snapshots: [MenuBarItemSnapshot]
    let proModeAvailable: Bool
    let onSave: (IconGroup) -> Void
    let onCancel: () -> Void

    @State private var draft: IconGroup
    @State private var manualBundleID = ""
    @State private var manualAppName = ""
    @State private var manualTitleContains = ""

    init(
        group: IconGroup,
        existingGroups: [IconGroup],
        snapshots: [MenuBarItemSnapshot],
        proModeAvailable: Bool,
        onSave: @escaping (IconGroup) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.existingGroups = existingGroups
        self.snapshots = snapshots
        self.proModeAvailable = proModeAvailable
        self.onSave = onSave
        self.onCancel = onCancel
        _draft = State(initialValue: group)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Edit Group")
                .font(.title2.bold())

            Form {
                TextField("Name", text: $draft.name)
                TextField("SF Symbol", text: optionalString($draft.symbolName, defaultValue: "folder"))
                Picker("Color", selection: optionalString($draft.colorName, defaultValue: "none")) {
                    Text("None").tag("none")
                    Text("Blue").tag("blue")
                    Text("Green").tag("green")
                    Text("Orange").tag("orange")
                    Text("Purple").tag("purple")
                    Text("Red").tag("red")
                }
                TextField("Notes", text: optionalString($draft.notes, defaultValue: ""), axis: .vertical)

                Toggle("Enabled", isOn: $draft.isEnabled)
                Toggle("Show in Second Bar", isOn: $draft.showInSecondBar)
                Toggle("Show as Status Item", isOn: $draft.showAsStatusItem)
                Toggle("Protected Group", isOn: $draft.isProtected)
            }
            .formStyle(.grouped)

            VStack(alignment: .leading, spacing: 10) {
                Text("Items")
                    .font(.headline)

                if draft.itemRefs.isEmpty {
                    ContentUnavailableView("No Items", systemImage: "menubar.rectangle")
                        .frame(maxWidth: .infinity, minHeight: 90)
                } else {
                    ForEach(draft.itemRefs) { ref in
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundStyle(.secondary)
                            Text(ref.displayLabel)
                            Spacer()
                            Button("Remove", systemImage: "minus.circle", role: .destructive) {
                                draft.itemRefs.removeAll { $0.id == ref.id }
                            }
                            .labelStyle(.iconOnly)
                            .help("Remove Item")
                        }
                    }
                }

                DisclosureGroup("Add Manually") {
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                        GridRow {
                            Text("Bundle ID")
                            TextField("com.example.App", text: $manualBundleID)
                            Button("Add") {
                                addManual(bundleID: manualBundleID)
                            }
                            .disabled(manualBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        GridRow {
                            Text("App Name")
                            TextField("App name", text: $manualAppName)
                            Button("Add") {
                                addManual(appName: manualAppName)
                            }
                            .disabled(manualAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        GridRow {
                            Text("Title")
                            TextField("Title contains", text: $manualTitleContains)
                            Button("Add") {
                                addManual(titleContains: manualTitleContains)
                            }
                            .disabled(manualTitleContains.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(.top, 8)
                }

                IconGroupItemPickerView(
                    snapshots: snapshots,
                    isAvailable: proModeAvailable,
                    onAdd: { snapshot in
                        draft.itemRefs.append(
                            IconGroupItemRef(
                                bundleIdentifier: snapshot.bundleIdentifier,
                                appName: snapshot.owningApplicationName,
                                snapshotStableID: snapshot.id,
                                titleContains: snapshot.title,
                                zone: snapshot.zone,
                                manualLabel: DisplayString.firstNonEmpty([
                                    snapshot.owningApplicationName,
                                    snapshot.title,
                                    snapshot.bundleIdentifier
                                ])
                            )
                        )
                    }
                )
            }

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
                .disabled(!validationErrors.isEmpty)
            }

            if !validationErrors.isEmpty {
                ClearGlassInlineMessage(
                    text: validationErrors.map(\.displayText).joined(separator: " "),
                    systemImage: "exclamationmark.triangle",
                    style: .warning
                )
            }
        }
        .padding(24)
        .frame(width: 680)
        .frame(minHeight: 640)
    }

    private var validationErrors: [IconGroupValidation.ValidationError] {
        IconGroupValidation.validateSingle(draft, existingGroups: existingGroups)
    }

    private func optionalString(_ binding: Binding<String?>, defaultValue: String) -> Binding<String> {
        Binding(
            get: { binding.wrappedValue ?? defaultValue },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                binding.wrappedValue = trimmed.isEmpty || trimmed == "none" ? nil : trimmed
            }
        )
    }

    private func addManual(bundleID: String? = nil, appName: String? = nil, titleContains: String? = nil) {
        let ref = IconGroupItemRef(
            bundleIdentifier: cleaned(bundleID),
            appName: cleaned(appName),
            titleContains: cleaned(titleContains),
            manualLabel: cleaned(bundleID) ?? cleaned(appName) ?? cleaned(titleContains)
        )
        draft.itemRefs.append(ref)
        manualBundleID = ""
        manualAppName = ""
        manualTitleContains = ""
    }

    private func cleaned(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}

private extension IconGroupValidation.ValidationError {
    var displayText: String {
        switch self {
        case .emptyName:
            "Group name is required."
        case .duplicateName:
            "Another group already uses this name."
        case .noMatchableItems:
            "At least one item needs match criteria."
        }
    }
}
