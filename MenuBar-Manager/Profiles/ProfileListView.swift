import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ProfileListView: View {
    @Bindable var profileStore: ProfileStore
    @Bindable var triggerService: TriggerService
    @Bindable var settingsStore: SettingsStore
    @Bindable var liveStatus: LiveDiagnosticsStatus

    let onDryRun: (ProfileModel) -> ProfileApplicationDryRun
    let onApply: (ProfileModel) -> ProfileApplicationDryRun
    let onTriggersChanged: () -> Void

    @State private var selectedProfileID: ProfileModel.ID?
    @State private var draftProfile: ProfileModel?
    @State private var dryRunSummary: ProfileApplicationDryRun?
    @State private var message: String?
    @State private var searchText = ""

    private var filteredProfiles: [ProfileModel] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return profileStore.profiles }
        return profileStore.profiles.filter { profile in
            profile.name.localizedStandardContains(query)
                || profile.notes.localizedStandardContains(query)
                || profile.targetZonesByBundleID.keys.contains { $0.localizedStandardContains(query) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    profileList
                        .frame(maxHeight: 300)

                    detail

                    triggerSection
                        .frame(minHeight: 150, maxHeight: 260)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .onAppear {
            profileStore.load()
            triggerService.load()
            selectFirstProfileIfNeeded()
        }
        .onChange(of: selectedProfileID) { _, _ in
            loadDraft()
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Text("Profiles")
                .font(.title2)
                .bold()

            Text(profileStore.profiles.count, format: .number)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: .capsule)

            Spacer()

            Button("Create", systemImage: "plus") {
                let profile = profileStore.createProfile()
                selectedProfileID = profile.id
                draftProfile = profile
            }

            Button("Import", systemImage: "square.and.arrow.down") {
                importProfile()
            }

            Divider()
                .frame(height: 20)

            Button("Duplicate", systemImage: "plus.square.on.square") {
                duplicateSelected()
            }
            .disabled(selectedProfile == nil)

            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteSelected()
            }
            .disabled(selectedProfile == nil)
        }
        .padding(14)
        .background(.regularMaterial, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5))
        }
        .padding([.horizontal, .top], 14)
        .padding(.bottom, 12)
    }

    private var profileList: some View {
        ProfileGlassPanel("Library", systemImage: "person.crop.rectangle.stack") {
            VStack(spacing: 10) {
                ProfileSearchField(text: $searchText)

                if filteredProfiles.isEmpty {
                    ContentUnavailableView(
                        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No Profiles" : "No Matching Profiles",
                        systemImage: "person.crop.rectangle.stack"
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(filteredProfiles) { profile in
                                ProfileListRow(
                                    profile: profile,
                                    isSelected: selectedProfileID == profile.id,
                                    isActive: liveStatus.activeProfileID == profile.id.uuidString
                                ) {
                                    selectedProfileID = profile.id
                                }
                            }
                        }
                        .padding(2)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let binding = draftBinding {
                ProfileGlassPanel("Editor", systemImage: "slider.horizontal.3") {
                    ProfileEditorView(profile: binding)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        profileActionButtons
                    }
                    .buttonStyle(.bordered)

                    if let dryRunSummary {
                        DryRunSummaryView(summary: dryRunSummary)
                    }
                }
                .padding(.bottom, 2)
            } else {
                ProfileGlassPanel("Editor", systemImage: "slider.horizontal.3") {
                    ContentUnavailableView("No Profile Selected", systemImage: "person.crop.rectangle.stack")
                        .frame(maxWidth: .infinity, minHeight: 260)
                }
            }

            if let message {
                Label(message, systemImage: "info.circle")
                    .font(.callout)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.blue.opacity(0.08), in: .rect(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private var profileActionButtons: some View {
        saveButton
        dryRunButton
        applyButton
        exportButton
    }

    private var saveButton: some View {
        Button("Save", systemImage: "checkmark") {
            saveDraft()
        }
        .buttonStyle(.borderedProminent)
    }

    private var dryRunButton: some View {
        Button("Dry Run", systemImage: "doc.text.magnifyingglass") {
            if let draftProfile {
                dryRunSummary = onDryRun(draftProfile)
            }
        }
    }

    private var applyButton: some View {
        Button("Apply", systemImage: "play") {
            if let draftProfile {
                saveDraft()
                dryRunSummary = onApply(draftProfile)
            }
        }
    }

    private var exportButton: some View {
        Button("Export", systemImage: "square.and.arrow.up") {
            if let draftProfile {
                export(profile: draftProfile)
            }
        }
    }

    private var triggerSection: some View {
        ProfileGlassPanel("Smart Triggers", systemImage: "bolt") {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    triggerToggles
                }

                TriggerDraftForm(isProfileSelected: selectedProfile != nil) { rule, name in
                    addTrigger(rule: rule, name: name)
                }

                if settingsStore.automationPaused {
                    Label("Automation is paused. Smart triggers will not apply profiles until resumed.", systemImage: "pause.circle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.orange.opacity(0.08), in: .rect(cornerRadius: 7))
                }

                if triggerService.triggers.isEmpty {
                    ContentUnavailableView("No Triggers", systemImage: "bolt.badge.xmark")
                        .frame(maxWidth: .infinity, minHeight: 92)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            TriggerTableHeader()

                            ForEach(triggerService.triggers) { trigger in
                                TriggerTableRow(
                                    trigger: trigger,
                                    profileName: profileName(for: trigger.profileID),
                                    onEnabledChanged: { isEnabled in
                                        var updated = trigger
                                        updated.isEnabled = isEnabled
                                        triggerService.update(updated)
                                        onTriggersChanged()
                                    },
                                    onDelete: {
                                        triggerService.delete(trigger)
                                        onTriggersChanged()
                                    }
                                )
                            }
                        }
                        .clipShape(.rect(cornerRadius: 7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.35))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var triggerToggles: some View {
        Toggle("Enable smart triggers", isOn: $settingsStore.smartTriggersEnabled)
            .onChange(of: settingsStore.smartTriggersEnabled) { _, _ in
                onTriggersChanged()
            }

        Toggle("Pause all automation", isOn: $settingsStore.automationPaused)
            .onChange(of: settingsStore.automationPaused) { _, _ in
                onTriggersChanged()
            }
    }

    private func profileName(for id: ProfileModel.ID) -> String {
        profileStore.profiles.first { $0.id == id }?.name ?? "Missing Profile"
    }

    private var selectedProfile: ProfileModel? {
        guard let selectedProfileID else { return nil }
        return profileStore.profiles.first { $0.id == selectedProfileID }
    }

    private var draftBinding: Binding<ProfileModel>? {
        guard draftProfile != nil else { return nil }
        return Binding(
            get: { draftProfile ?? ProfileModel.makeDefault() },
            set: { draftProfile = $0 }
        )
    }

    private func selectFirstProfileIfNeeded() {
        if selectedProfileID == nil {
            selectedProfileID = profileStore.profiles.first?.id
            loadDraft()
        }
    }

    private func loadDraft() {
        draftProfile = selectedProfile
        dryRunSummary = nil
    }

    private func saveDraft() {
        guard let draftProfile else { return }
        profileStore.update(draftProfile)
        selectedProfileID = draftProfile.id
        message = "Saved \(draftProfile.name)."
    }

    private func duplicateSelected() {
        guard let selectedProfile else { return }
        let copy = profileStore.duplicate(selectedProfile)
        selectedProfileID = copy.id
        draftProfile = copy
    }

    private func deleteSelected() {
        guard let selectedProfile else { return }
        profileStore.delete(selectedProfile)
        selectedProfileID = profileStore.profiles.first?.id
        loadDraft()
    }

    private func addTrigger(rule: TriggerRule, name: String) {
        guard let selectedProfile else { return }
        let trigger = TriggerModel(
            name: name,
            profileID: selectedProfile.id,
            rule: rule
        )
        triggerService.addTrigger(trigger)
        onTriggersChanged()
    }

    private func export(profile: ProfileModel) {
        let panel = NSSavePanel()
        panel.title = "Export Profile"
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "\(profile.name).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try profileStore.exportProfile(profile, to: url)
            message = "Exported \(profile.name)."
        } catch {
            message = "Export failed: \(error.localizedDescription)"
        }
    }

    private func importProfile() {
        let panel = NSOpenPanel()
        panel.title = "Import Profile"
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let profile = try profileStore.importProfile(from: url)
            selectedProfileID = profile.id
            draftProfile = profile
            message = "Imported \(profile.name)."
        } catch {
            message = "Import failed: \(error.localizedDescription)"
        }
    }
}

private struct ProfileGlassPanel<Accessory: View, Content: View>: View {
    let title: String
    let systemImage: String?
    let accessory: Accessory
    let content: Content

    init(
        _ title: String,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) where Accessory == EmptyView {
        self.title = title
        self.systemImage = systemImage
        self.accessory = EmptyView()
        self.content = content()
    }

    init(
        _ title: String,
        systemImage: String? = nil,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accessory = accessory()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                }

                Text(title)
                    .font(.headline)

                Spacer()

                accessory
            }

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.thinMaterial, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.45))
        }
    }
}

private struct ProfileSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search Profiles", text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button("Clear Search", systemImage: "xmark.circle.fill") {
                    text = ""
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.3))
        }
    }
}

private struct ProfileListRow: View {
    let profile: ProfileModel
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "briefcase")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name)
                        .font(.callout)
                        .lineLimit(1)

                    Text(profile.updatedAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                }

                Spacer(minLength: 8)

                Circle()
                    .fill(isActive ? Color.green : Color.secondary.opacity(0.35))
                    .frame(width: 8, height: 8)
                    .accessibilityLabel(isActive ? "Active profile" : "Inactive profile")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor).opacity(0.35), in: .rect(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(isSelected ? Color.white.opacity(0.12) : Color(nsColor: .separatorColor).opacity(0.25))
            }
        }
        .buttonStyle(.plain)
    }
}

private struct TriggerTableHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Trigger")
                .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
            Text("Condition")
                .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
            Text("Profile")
                .frame(width: 140, alignment: .leading)
            Text("Status")
                .frame(width: 96, alignment: .leading)
            Text("")
                .frame(width: 32)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary)
    }
}

private struct TriggerTableRow: View {
    let trigger: TriggerModel
    let profileName: String
    let onEnabledChanged: (Bool) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(trigger.name)
                .lineLimit(1)
                .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)

            Text(trigger.rule.displayName)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)

            Text(profileName)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)

            Toggle(
                trigger.isEnabled ? "Enabled" : "Disabled",
                isOn: Binding(
                    get: { trigger.isEnabled },
                    set: { isEnabled in
                        onEnabledChanged(isEnabled)
                    }
                )
            )
            .labelsHidden()
            .frame(width: 96, alignment: .leading)

            Button("Delete Trigger", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .frame(width: 32)
        }
        .font(.callout)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.28))
        Divider()
    }
}

private enum TriggerDraftKind: String, CaseIterable, Identifiable {
    case externalDisplay
    case appLaunched
    case frontmostApp
    case batteryLow
    case timeOfDay

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .externalDisplay:
            "Display"
        case .appLaunched:
            "App Launch"
        case .frontmostApp:
            "Frontmost App"
        case .batteryLow:
            "Battery"
        case .timeOfDay:
            "Time"
        }
    }

    var requiresBundleIdentifier: Bool {
        switch self {
        case .appLaunched, .frontmostApp:
            true
        case .externalDisplay, .batteryLow, .timeOfDay:
            false
        }
    }
}

private struct TriggerDraft {
    var kind: TriggerDraftKind
    var bundleIdentifier: String
    var minimumDisplayCount: Int
    var batteryThreshold: Int
    var time: Date

    var canAdd: Bool {
        switch kind {
        case .appLaunched, .frontmostApp:
            normalizedBundleIdentifier != nil
        case .externalDisplay, .batteryLow, .timeOfDay:
            true
        }
    }

    var rule: TriggerRule? {
        switch kind {
        case .externalDisplay:
            .externalDisplayConnected(minimumDisplayCount: minimumDisplayCount)
        case .appLaunched:
            normalizedBundleIdentifier.map { .appLaunched(bundleIdentifier: $0) }
        case .frontmostApp:
            normalizedBundleIdentifier.map { .frontmostApp(bundleIdentifier: $0) }
        case .batteryLow:
            .batteryLow(thresholdPercent: batteryThreshold)
        case .timeOfDay:
            .timeOfDay(
                hour: Calendar.current.component(.hour, from: time),
                minute: Calendar.current.component(.minute, from: time)
            )
        }
    }

    var name: String {
        switch kind {
        case .externalDisplay:
            "External Display"
        case .appLaunched:
            "App Launched"
        case .frontmostApp:
            "Frontmost App"
        case .batteryLow:
            "Battery Low"
        case .timeOfDay:
            "Time of Day"
        }
    }

    private var normalizedBundleIdentifier: String? {
        let trimmed = bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct TriggerDraftForm: View {
    let isProfileSelected: Bool
    let frontmostBundleIdentifier: @MainActor () -> String?
    let onAdd: (TriggerRule, String) -> Void

    @State private var draft: TriggerDraft
    @State private var didSeedDefaultBundleIdentifier = false

    init(
        isProfileSelected: Bool,
        frontmostBundleIdentifier: @escaping @MainActor () -> String? = Self.currentFrontmostBundleIdentifier,
        onAdd: @escaping (TriggerRule, String) -> Void
    ) {
        self.isProfileSelected = isProfileSelected
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
        self.onAdd = onAdd
        self._draft = State(initialValue: TriggerDraft(
            kind: .externalDisplay,
            bundleIdentifier: Self.fallbackBundleIdentifier,
            minimumDisplayCount: 2,
            batteryThreshold: 20,
            time: Self.defaultTriggerTime
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            triggerPicker
            draftControls
            Button("Add Trigger", systemImage: "plus") {
                addTrigger()
            }
            .disabled(!isProfileSelected || !draft.canAdd)
        }
        .buttonStyle(.bordered)
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.25))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            seedDefaultBundleIdentifierIfNeeded()
        }
        .onChange(of: draft.kind) { _, _ in
            seedDefaultBundleIdentifierIfNeeded()
        }
    }

    private var triggerPicker: some View {
        Picker("Trigger", selection: $draft.kind) {
            ForEach(TriggerDraftKind.allCases) { kind in
                Text(kind.displayName).tag(kind)
            }
        }
        .labelsHidden()
        .frame(minWidth: 130, idealWidth: 170, maxWidth: 220)
    }

    private var draftControls: some View {
        Group {
            switch draft.kind {
            case .externalDisplay:
                Stepper(
                    "Displays: \(draft.minimumDisplayCount)",
                    value: $draft.minimumDisplayCount,
                    in: 2...8
                )
                .frame(minWidth: 110, idealWidth: 130, maxWidth: 170)
            case .appLaunched, .frontmostApp:
                TextField("Bundle ID", text: $draft.bundleIdentifier)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 140, idealWidth: 220, maxWidth: 280)
            case .batteryLow:
                Stepper(
                    "Battery: \(draft.batteryThreshold)%",
                    value: $draft.batteryThreshold,
                    in: 1...100
                )
                .frame(minWidth: 110, idealWidth: 150, maxWidth: 180)
            case .timeOfDay:
                DatePicker(
                    "Time",
                    selection: $draft.time,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .frame(minWidth: 90, idealWidth: 110, maxWidth: 160)
            }
        }
    }

    private static let fallbackBundleIdentifier = "com.apple.finder"

    private static func currentFrontmostBundleIdentifier() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private static var defaultTriggerTime: Date {
        Calendar.current.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    private func addTrigger() {
        guard let rule = draft.rule else { return }
        onAdd(rule, draft.name)
    }

    private func seedDefaultBundleIdentifierIfNeeded() {
        guard draft.kind.requiresBundleIdentifier, !didSeedDefaultBundleIdentifier else { return }
        didSeedDefaultBundleIdentifier = true

        let currentValue = draft.bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard currentValue.isEmpty || currentValue == Self.fallbackBundleIdentifier else { return }

        let frontmostIdentifier = frontmostBundleIdentifier()?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let frontmostIdentifier, !frontmostIdentifier.isEmpty {
            draft.bundleIdentifier = frontmostIdentifier
        } else {
            draft.bundleIdentifier = Self.fallbackBundleIdentifier
        }
    }
}

private struct DryRunSummaryView: View {
    let summary: ProfileApplicationDryRun

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Dry Run", systemImage: summary.isEmpty ? "checkmark.circle" : "doc.text.magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(summary.isEmpty ? .green : .primary)

                Spacer()
            }

            Text(summary.summary)
                .foregroundStyle(.secondary)

            ForEach(Array(summary.itemsToReveal.enumerated()), id: \.offset) { _, item in
                Label(item, systemImage: "eye")
            }

            ForEach(summary.itemsToMove, id: \.bundleIdentifier) { item in
                Label(
                    "\(item.displayName): \(item.currentZone.displayName) -> \(item.targetZone.displayName)",
                    systemImage: "arrow.left.and.right"
                )
            }

            ForEach(Array(summary.unavailableItems.enumerated()), id: \.offset) { _, item in
                Label(item, systemImage: "questionmark.circle")
                    .foregroundStyle(.orange)
            }

            ForEach(Array(summary.permissionRequirements.enumerated()), id: \.offset) { _, requirement in
                Label(requirement, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.3))
        }
    }
}
