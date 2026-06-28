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
    @State private var triggerDraftKind: TriggerDraftKind = .externalDisplay
    @State private var triggerBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "com.apple.finder"
    @State private var triggerMinimumDisplayCount = 2
    @State private var triggerBatteryThreshold = 20
    @State private var triggerTime = Calendar.current.date(
        bySettingHour: 9,
        minute: 0,
        second: 0,
        of: Date()
    ) ?? Date()

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

                Spacer()

                Picker("Trigger", selection: $triggerDraftKind) {
                    ForEach(TriggerDraftKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .frame(width: 170)

                triggerDraftControls

                Button("Add Trigger", systemImage: "plus") {
                    addConfiguredTrigger()
                }
                .disabled(selectedProfile == nil || !canAddConfiguredTrigger)
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

    private var triggerDraftControls: some View {
        Group {
            switch triggerDraftKind {
            case .externalDisplay:
                Stepper(
                    "Displays: \(triggerMinimumDisplayCount)",
                    value: $triggerMinimumDisplayCount,
                    in: 2...8
                )
                .frame(width: 130)
            case .appLaunched, .frontmostApp:
                TextField("Bundle ID", text: $triggerBundleIdentifier)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
            case .batteryLow:
                Stepper(
                    "Battery: \(triggerBatteryThreshold)%",
                    value: $triggerBatteryThreshold,
                    in: 1...100
                )
                .frame(width: 150)
            case .timeOfDay:
                DatePicker(
                    "Time",
                    selection: $triggerTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .frame(width: 110)
            }
        }
    }

    private var canAddConfiguredTrigger: Bool {
        switch triggerDraftKind {
        case .appLaunched, .frontmostApp:
            !triggerBundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .externalDisplay, .batteryLow, .timeOfDay:
            true
        }
    }

    private func addConfiguredTrigger() {
        guard let rule = configuredTriggerRule else { return }
        addTrigger(rule: rule, name: configuredTriggerName)
    }

    private var configuredTriggerRule: TriggerRule? {
        switch triggerDraftKind {
        case .externalDisplay:
            .externalDisplayConnected(minimumDisplayCount: triggerMinimumDisplayCount)
        case .appLaunched:
            normalizedTriggerBundleID.map { .appLaunched(bundleIdentifier: $0) }
        case .frontmostApp:
            normalizedTriggerBundleID.map { .frontmostApp(bundleIdentifier: $0) }
        case .batteryLow:
            .batteryLow(thresholdPercent: triggerBatteryThreshold)
        case .timeOfDay:
            .timeOfDay(
                hour: Calendar.current.component(.hour, from: triggerTime),
                minute: Calendar.current.component(.minute, from: triggerTime)
            )
        }
    }

    private var configuredTriggerName: String {
        switch triggerDraftKind {
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

    private var normalizedTriggerBundleID: String? {
        let bundleID = triggerBundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        return bundleID.isEmpty ? nil : bundleID
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
}

private struct DryRunSummaryView: View {
    let summary: ProfileApplicationDryRun

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dry Run")
                .font(.headline)

            Text(summary.summary)
                .foregroundStyle(.secondary)

            ForEach(summary.itemsToReveal, id: \.self) { item in
                Label(item, systemImage: "eye")
            }

            ForEach(summary.itemsToMove, id: \.bundleIdentifier) { item in
                Label(
                    "\(item.displayName): \(item.currentZone.displayName) -> \(item.targetZone.displayName)",
                    systemImage: "arrow.left.and.right"
                )
            }

            ForEach(summary.unavailableItems, id: \.self) { item in
                Label(item, systemImage: "questionmark.circle")
                    .foregroundStyle(.orange)
            }

            ForEach(summary.permissionRequirements, id: \.self) { requirement in
                Label(requirement, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(.quaternary, in: .rect(cornerRadius: 8))
    }
}
