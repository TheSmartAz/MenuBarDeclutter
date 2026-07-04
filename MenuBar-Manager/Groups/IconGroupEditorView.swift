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

    private let matcher = IconGroupMatcher()

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
        VStack(spacing: 0) {
            editorHeader

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    identitySection
                    behaviorSection
                    itemReferencesSection
                    addItemsSection
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            Divider()

            editorFooter
        }
        .frame(width: 760)
        .frame(minHeight: 680, maxHeight: 760)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var editorHeader: some View {
        HStack(spacing: 12) {
            GroupEditorSymbol(symbolName: draft.symbolName, colorName: draft.colorName)

            VStack(alignment: .leading, spacing: 2) {
                Text(isNewGroup ? "New Group" : "Edit Group")
                    .font(.title3)

                Text(headerSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if draft.isProtected {
                Label("Protected", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .quaternaryLabelColor).opacity(0.12), in: .capsule)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var identitySection: some View {
        editorSection("Identity") {
            editorRow(title: "Name", systemImage: "textformat") {
                TextField("Name", text: $draft.name)
                    .textFieldStyle(.roundedBorder)
            }

            editorDivider

            editorRow(title: "SF Symbol", systemImage: "square.grid.2x2") {
                TextField("folder", text: optionalString($draft.symbolName, defaultValue: "folder"))
                    .textFieldStyle(.roundedBorder)
            }

            editorDivider

            editorRow(title: "Color", systemImage: "paintpalette") {
                HStack(spacing: 8) {
                    GroupEditorColorSwatch(colorName: draft.colorName)

                    Picker("Color", selection: optionalString($draft.colorName, defaultValue: "none")) {
                        Text("None").tag("none")
                        Text("Blue").tag("blue")
                        Text("Green").tag("green")
                        Text("Orange").tag("orange")
                        Text("Purple").tag("purple")
                        Text("Red").tag("red")
                    }
                    .labelsHidden()
                    .frame(width: 160)
                }
            }

            editorDivider

            editorRow(title: "Notes", systemImage: "note.text") {
                TextField("Optional note", text: optionalString($draft.notes, defaultValue: ""), axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }
        }
    }

    private var behaviorSection: some View {
        editorSection("Behavior", subtitle: "All group behavior is local. Status items are app-owned and optional.") {
            editorRow(title: "Enabled", systemImage: "checkmark.circle") {
                Toggle("Enabled", isOn: $draft.isEnabled)
                    .labelsHidden()
            }

            editorDivider

            editorRow(title: "Show in Second Bar", systemImage: "rectangle.bottomthird.inset.filled") {
                Toggle("Show in Second Bar", isOn: $draft.showInSecondBar)
                    .labelsHidden()
            }

            editorDivider

            editorRow(title: "Show as Status Item", systemImage: "menubar.rectangle") {
                Toggle("Show as Status Item", isOn: $draft.showAsStatusItem)
                    .labelsHidden()
            }

            editorDivider

            editorRow(title: "Protected Group", systemImage: "lock") {
                Toggle("Protected Group", isOn: $draft.isProtected)
                    .labelsHidden()
            }
        }
    }

    @ViewBuilder
    private var itemReferencesSection: some View {
        let matchCounts = matchedCountsByRefID

        editorSection("Item References", subtitle: "References can match by bundle ID, app name, title, snapshot ID, or zone.") {
            if draft.itemRefs.isEmpty {
                ContentUnavailableView("No Items", systemImage: "menubar.rectangle", description: Text("Add at least one item reference before saving."))
                    .frame(maxWidth: .infinity, minHeight: 136)
            } else {
                ForEach(Array(draft.itemRefs.enumerated()), id: \.element.id) { index, ref in
                    IconGroupEditorItemRow(
                        ref: ref,
                        matchedCount: matchCounts[ref.id, default: 0],
                        onRemove: {
                            draft.itemRefs.removeAll { $0.id == ref.id }
                        }
                    )

                    if index != draft.itemRefs.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
        }
    }

    private var addItemsSection: some View {
        editorSection("Add Items", subtitle: "Use Basic Mode manual criteria or Optional Pro snapshots.") {
            ManualReferenceEntryRow(
                title: "Bundle ID",
                placeholder: "com.example.App",
                text: $manualBundleID,
                onAdd: {
                    addManual(bundleID: manualBundleID)
                }
            )

            editorDivider

            ManualReferenceEntryRow(
                title: "App Name",
                placeholder: "App name",
                text: $manualAppName,
                onAdd: {
                    addManual(appName: manualAppName)
                }
            )

            editorDivider

            ManualReferenceEntryRow(
                title: "Title Contains",
                placeholder: "Menu bar title",
                text: $manualTitleContains,
                onAdd: {
                    addManual(titleContains: manualTitleContains)
                }
            )

            editorDivider

            IconGroupItemPickerView(
                snapshots: snapshots,
                isAvailable: proModeAvailable,
                onAdd: addSnapshot
            )
            .padding(.vertical, 8)
        }
    }

    private var editorFooter: some View {
        HStack(alignment: .center, spacing: 12) {
            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Label("Saved groups stay local to this Mac.", systemImage: "checkmark.shield")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 20)

            Button("Cancel") {
                onCancel()
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Button("Save") {
                onSave(draft)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(!validationErrors.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func editorSection<Content: View>(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func editorRow<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(title)
                .frame(width: 136, alignment: .leading)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }

    private var editorDivider: some View {
        Divider()
            .padding(.leading, 34)
    }

    private var validationErrors: [IconGroupValidation.ValidationError] {
        IconGroupValidation.validateSingle(draft, existingGroups: existingGroups)
    }

    private var validationMessage: String? {
        guard !validationErrors.isEmpty else { return nil }
        return validationErrors.map(\.displayText).joined(separator: " ")
    }

    private var matchedCountsByRefID: [IconGroupItemRef.ID: Int] {
        Dictionary(uniqueKeysWithValues: draft.itemRefs.map { ref in
            (ref.id, matcher.match(ref: ref, snapshots: snapshots).count)
        })
    }

    private var isNewGroup: Bool {
        !existingGroups.contains { $0.id == draft.id }
    }

    private var headerSummary: String {
        let itemText = "\(draft.itemRefs.count) item\(draft.itemRefs.count == 1 ? "" : "s")"
        let stateText = draft.isEnabled ? "Enabled" : "Disabled"
        return "\(itemText) - \(stateText)"
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

    private func addSnapshot(_ snapshot: MenuBarItemSnapshot) {
        let result = IconGroupItemActionPlanner.adding(snapshot: snapshot, to: draft)
        draft = result.group
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

private struct GroupEditorSymbol: View {
    let symbolName: String?
    let colorName: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(color.opacity(0.12))

            Image(systemName: symbolName?.isEmpty == false ? symbolName ?? "folder" : "folder")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
        }
        .frame(width: 42, height: 42)
    }

    private var color: Color {
        GroupEditorColorSwatch.color(for: colorName)
    }
}

private struct GroupEditorColorSwatch: View {
    let colorName: String?

    var body: some View {
        Circle()
            .fill(Self.color(for: colorName))
            .frame(width: 14, height: 14)
            .overlay {
                Circle()
                    .stroke(Color(nsColor: .separatorColor).opacity(0.65), lineWidth: 0.5)
            }
    }

    static func color(for colorName: String?) -> Color {
        switch colorName {
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

private struct ManualReferenceEntryRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let onAdd: () -> Void

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(title)
                .frame(width: 136, alignment: .leading)

            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)

            Button("Add", systemImage: "plus") {
                onAdd()
            }
            .disabled(trimmedText.isEmpty)
        }
        .padding(.vertical, 8)
    }
}

private struct IconGroupEditorItemRow: View {
    let ref: IconGroupItemRef
    let matchedCount: Int
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            AppIconView(
                bundleIdentifier: ref.bundleIdentifier,
                applicationName: ref.appName,
                size: 26,
                cornerRadius: 6
            )

            VStack(alignment: .leading, spacing: 1) {
                Text(ref.displayLabel)
                    .lineLimit(1)

                Text(criteriaText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Label(statusText, systemImage: statusImage)
                .font(.caption)
                .foregroundStyle(statusColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.10), in: .capsule)

            Button("Remove", systemImage: "minus.circle", role: .destructive) {
                onRemove()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Remove Item")
        }
        .padding(.vertical, 8)
    }

    private var criteriaText: String {
        if !ref.hasMatchableCriteria {
            return "No match criteria"
        }

        var parts: [String] = []
        if ref.bundleIdentifier?.isEmpty == false {
            parts.append("Bundle ID")
        }
        if ref.appName?.isEmpty == false {
            parts.append("App")
        }
        if ref.titleContains?.isEmpty == false {
            parts.append("Title")
        }
        if ref.snapshotStableID?.isEmpty == false {
            parts.append("Snapshot")
        }
        if let zone = ref.zone {
            parts.append(zone.displayName)
        }
        return parts.joined(separator: ", ")
    }

    private var statusText: String {
        if !ref.hasMatchableCriteria {
            return "Needs Criteria"
        }
        return matchedCount == 0 ? "Unavailable" : "Matched"
    }

    private var statusImage: String {
        if !ref.hasMatchableCriteria {
            return "exclamationmark.triangle"
        }
        return matchedCount == 0 ? "minus.circle" : "checkmark.circle"
    }

    private var statusColor: Color {
        if !ref.hasMatchableCriteria {
            return .orange
        }
        return matchedCount == 0 ? .secondary : .green
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
