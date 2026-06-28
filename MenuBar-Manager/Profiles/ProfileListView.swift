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

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            HSplitView {
                profileList
                    .frame(minWidth: 220, idealWidth: 260)

                Divider()

                detail
                    .frame(minWidth: 420)
            }

            Divider()
            triggerSection
                .frame(minHeight: 150)
        }
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
        HStack {
            Text("Profiles")
                .font(.title3)
                .bold()

            Spacer()

            Button("Create", systemImage: "plus") {
                let profile = profileStore.createProfile()
                selectedProfileID = profile.id
                draftProfile = profile
            }

            Button("Import", systemImage: "square.and.arrow.down") {
                importProfile()
            }
        }
        .padding()
    }

    private var profileList: some View {
        VStack(spacing: 0) {
            List(profileStore.profiles, selection: $selectedProfileID) { profile in
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name)
                        .lineLimit(1)
                    Text(profile.updatedAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(profile.id)
            }

            HStack {
                Button("Duplicate", systemImage: "plus.square.on.square") {
                    duplicateSelected()
                }
                .disabled(selectedProfile == nil)

                Button("Delete", systemImage: "trash", role: .destructive) {
                    deleteSelected()
                }
                .disabled(selectedProfile == nil)
            }
            .padding(10)
        }
    }

    private var detail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let binding = draftBinding {
                    ProfileEditorView(profile: binding)

                    HStack {
                        Button("Save", systemImage: "checkmark") {
                            saveDraft()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Dry Run", systemImage: "doc.text.magnifyingglass") {
                            if let draftProfile {
                                dryRunSummary = onDryRun(draftProfile)
                            }
                        }

                        Button("Apply", systemImage: "play") {
                            if let draftProfile {
                                saveDraft()
                                dryRunSummary = onApply(draftProfile)
                            }
                        }

                        Button("Export", systemImage: "square.and.arrow.up") {
                            if let draftProfile {
                                export(profile: draftProfile)
                            }
                        }
                    }
                    .padding(.horizontal)

                    if let dryRunSummary {
                        DryRunSummaryView(summary: dryRunSummary)
                            .padding(.horizontal)
                    }
                } else {
                    ContentUnavailableView("No Profile Selected", systemImage: "person.crop.rectangle.stack")
                        .frame(maxWidth: .infinity, minHeight: 260)
                }

                if let message {
                    Label(message, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private var triggerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("Enable smart triggers", isOn: $settingsStore.smartTriggersEnabled)
                    .onChange(of: settingsStore.smartTriggersEnabled) { _, _ in
                        onTriggersChanged()
                    }

                Toggle("Pause all automation", isOn: $settingsStore.automationPaused)
                    .onChange(of: settingsStore.automationPaused) { _, _ in
                        onTriggersChanged()
                    }

                Spacer()
            }

            TriggerDraftForm(isProfileSelected: selectedProfile != nil) { rule, name in
                addTrigger(rule: rule, name: name)
            }

            if settingsStore.automationPaused {
                Label("Automation is paused. Smart triggers will not apply profiles until resumed.", systemImage: "pause.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if triggerService.triggers.isEmpty {
                Text("No triggers configured.")
                    .foregroundStyle(.secondary)
            } else {
                List(triggerService.triggers) { trigger in
                    HStack {
                        Toggle(
                            trigger.name,
                            isOn: Binding(
                                get: { trigger.isEnabled },
                                set: { isEnabled in
                                    var updated = trigger
                                    updated.isEnabled = isEnabled
                                    triggerService.update(updated)
                                    onTriggersChanged()
                                }
                            )
                        )

                        Text(trigger.rule.displayName)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Delete", systemImage: "trash", role: .destructive) {
                            triggerService.delete(trigger)
                            onTriggersChanged()
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                    }
                }
                .frame(minHeight: 90)
            }
        }
        .padding()
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
        HStack {
            Picker("Trigger", selection: $draft.kind) {
                ForEach(TriggerDraftKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .frame(width: 170)

            draftControls

            Button("Add Trigger", systemImage: "plus") {
                addTrigger()
            }
            .disabled(!isProfileSelected || !draft.canAdd)
        }
        .onAppear {
            seedDefaultBundleIdentifierIfNeeded()
        }
        .onChange(of: draft.kind) { _, _ in
            seedDefaultBundleIdentifierIfNeeded()
        }
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
                .frame(width: 130)
            case .appLaunched, .frontmostApp:
                TextField("Bundle ID", text: $draft.bundleIdentifier)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
            case .batteryLow:
                Stepper(
                    "Battery: \(draft.batteryThreshold)%",
                    value: $draft.batteryThreshold,
                    in: 1...100
                )
                .frame(width: 150)
            case .timeOfDay:
                DatePicker(
                    "Time",
                    selection: $draft.time,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .frame(width: 110)
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
            Text("Dry Run")
                .font(.headline)

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
        .padding()
        .background(.quaternary, in: .rect(cornerRadius: 8))
    }
}
