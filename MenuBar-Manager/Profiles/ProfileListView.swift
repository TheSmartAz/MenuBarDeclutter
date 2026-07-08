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
    var commandAvailability: ((ProfileModel) -> MenuBarCommandAvailabilitySummary?)?
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

    private var triggerCountsByProfileID: [ProfileModel.ID: Int] {
        Dictionary(grouping: triggerService.triggers, by: \.profileID)
            .mapValues(\.count)
    }

    private var profileNamesByID: [ProfileModel.ID: String] {
        Dictionary(uniqueKeysWithValues: profileStore.profiles.map { ($0.id, $0.name) })
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Profiles",
            subtitle: "Save, preview, and apply local menu bar layouts.",
            badges: [.preview, .privacySafe],
            style: .tool,
            sectionAnchors: [
                ClearGlassPageAnchor("Profiles", systemImage: "person.crop.rectangle.stack"),
                ClearGlassPageAnchor("Smart Triggers", systemImage: "bolt")
            ]
        ) {
            ProfileOverviewStrip(
                profileCount: profileStore.profiles.count,
                triggerCount: triggerService.triggers.count,
                automationPaused: settingsStore.automationPaused
            )

            ClearGlassSection("Profiles", subtitle: "Create, edit, preview, apply, import, and export local layouts.") {
                VStack(alignment: .leading, spacing: 12) {
                    ClearGlassActionStrip(
                        "Profile Library Actions",
                        subtitle: "Start with a saved layout, then edit, dry-run, apply, or export it from the detail pane.",
                        systemImage: "person.crop.rectangle.stack",
                        statusText: profileStore.profiles.isEmpty ? "Empty" : "\(profileStore.profiles.count) Profiles",
                        statusStyle: profileStore.profiles.isEmpty ? .secondary : .success
                    ) {
                        Button("Create Profile", systemImage: "plus") {
                            createProfile()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Import Profile", systemImage: "square.and.arrow.down") {
                            importProfile()
                        }
                    }

                    ClearGlassPaneLayout(primaryWidth: 300, spacing: 14) {
                        profileLibrary
                    } detail: {
                        profileDetail
                    }

                    if let message {
                        ClearGlassInlineMessage(text: message, systemImage: "info.circle", style: .info)
                    }

                    if let lastError = profileStore.lastError {
                        ClearGlassInlineMessage(
                            text: lastError,
                            systemImage: "exclamationmark.triangle",
                            style: .warning
                        )
                    }
                }
            }

            ClearGlassSection("Smart Triggers", subtitle: "Optional local automation that can apply profiles when rules match.") {
                triggerSection
            }
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

    @ViewBuilder
    private var profileLibrary: some View {
        let triggerCountsByProfileID = triggerCountsByProfileID

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Profiles", systemImage: "sidebar.left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(filteredProfiles.count) of \(profileStore.profiles.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            SearchField("Search Profiles", text: $searchText)

            ScrollView {
                if filteredProfiles.isEmpty {
                    SettingsUnavailableGate(
                        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .emptyData : .noMatches,
                        title: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No Profiles" : "No Matching Profiles",
                        message: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? "Create a profile to save a local menu bar layout."
                            : "Try a different profile name, note, or bundle ID.",
                        systemImage: "person.crop.rectangle.stack",
                        minHeight: 220,
                        nextSteps: searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? ["Create a profile from the current layout.", "Use Dry Run before applying changes."]
                            : ["Clear the search to return to all profiles."]
                    ) {
                        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button("Create Profile", systemImage: "plus") {
                                createProfile()
                            }
                        } else {
                            Button("Clear Search", systemImage: "xmark.circle") {
                                searchText = ""
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredProfiles) { profile in
                            ProfileListRow(
                                profile: profile,
                                isSelected: selectedProfileID == profile.id,
                                isActive: liveStatus.activeProfileID == profile.id.uuidString,
                                triggerCount: triggerCountsByProfileID[profile.id, default: 0]
                            ) {
                                selectedProfileID = profile.id
                            }
                        }
                    }
                    .padding(6)
                }
            }
            .frame(minHeight: 300, maxHeight: 460)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
            }
        }
    }

    @ViewBuilder
    private var profileDetail: some View {
        let triggerCountsByProfileID = triggerCountsByProfileID

        VStack(alignment: .leading, spacing: 10) {
            if let binding = draftBinding,
               let draftProfile {
                ProfileDetailHeader(
                    profile: draftProfile,
                    isActive: liveStatus.activeProfileID == draftProfile.id.uuidString,
                    triggerCount: triggerCountsByProfileID[draftProfile.id, default: 0],
                    dryRunSummary: dryRunSummary
                )

                ProfileEditorView(profile: binding)

                if let commandAvailability = commandAvailability?(draftProfile) {
                    VStack(spacing: 0) {
                        CommandAvailabilityRow(summary: commandAvailability)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
                    }
                }

                profileActionPanel

                if let dryRunSummary {
                    DryRunSummaryView(summary: dryRunSummary)
                }
            } else {
                SettingsUnavailableGate(
                    .emptyData,
                    title: "No Profile Selected",
                    message: "Create or select a profile to edit its local layout settings.",
                    systemImage: "person.crop.rectangle.stack",
                    minHeight: 300,
                    nextSteps: ["Create a profile from the action strip.", "Select a profile from the library to edit it."]
                ) {
                    Button("Create Profile", systemImage: "plus") {
                        createProfile()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            }
        }
    }

    private var profileActionPanel: some View {
        ClearGlassActionStrip(
            "Profile Actions",
            subtitle: "Save the draft before running or exporting this profile.",
            systemImage: "play.circle",
            statusText: dryRunSummary == nil ? "Draft" : "Dry Run",
            statusStyle: dryRunSummary == nil ? .secondary : .success
        ) {
            profileActionButtons
        }
    }

    @ViewBuilder
    private var profileActionButtons: some View {
        Button("Save", systemImage: "checkmark", action: saveDraft)
            .buttonStyle(.borderedProminent)

        Button("Apply", systemImage: "play", action: applyDraft)

        Menu("More", systemImage: "ellipsis.circle") {
            Button("Dry Run", systemImage: "doc.text.magnifyingglass", action: runDryRun)
            Button("Export", systemImage: "square.and.arrow.up", action: exportDraft)
            Button("Duplicate", systemImage: "plus.square.on.square", action: duplicateSelected)

            Divider()

            Button("Delete", systemImage: "trash", role: .destructive, action: deleteSelected)
        }
    }

    private var triggerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureGateNotice(
                .preview,
                text: "Preview in v0.1.3. Triggers stay paused when automation is paused."
            )

            triggerControlPanel

            if settingsStore.automationPaused {
                ClearGlassInlineMessage(
                    text: "Automation is paused. Smart triggers will not apply profiles until resumed.",
                    systemImage: "pause.circle",
                    style: .warning
                )
            }

            if let lastError = triggerService.lastError {
                ClearGlassInlineMessage(
                    text: lastError,
                    systemImage: "exclamationmark.triangle",
                    style: .warning
                )
            }

            if let lastUnsupportedRuleWarning = triggerService.lastUnsupportedRuleWarning {
                ClearGlassInlineMessage(
                    text: lastUnsupportedRuleWarning,
                    systemImage: "exclamationmark.triangle",
                    style: .warning
                )
            }

            TriggerDraftForm(
                isProfileSelected: selectedProfile != nil,
                selectedProfileName: selectedProfile?.name ?? "No Profile"
            ) { rule, name in
                addTrigger(rule: rule, name: name)
            }

            triggerList
        }
    }

    private var triggerControlPanel: some View {
        VStack(spacing: 0) {
            ClearGlassRowStack {
                ClearGlassControlRow(
                    systemImage: "bolt",
                    title: "Enable Smart Triggers",
                    subtitle: "Evaluate local rules and apply profiles when the app is running."
                ) {
                    Toggle("Enable Smart Triggers", isOn: $settingsStore.smartTriggersEnabled)
                        .labelsHidden()
                        .onChange(of: settingsStore.smartTriggersEnabled) { _, _ in onTriggersChanged() }
                }

                ClearGlassControlRow(
                    systemImage: "pause.circle",
                    title: "Pause All Automation",
                    subtitle: "Keep trigger rules saved but stop them from applying profiles."
                ) {
                    Toggle("Pause All Automation", isOn: $settingsStore.automationPaused)
                        .labelsHidden()
                        .onChange(of: settingsStore.automationPaused) { _, _ in onTriggersChanged() }
                }
            }
        }
    }

    @ViewBuilder
    private var triggerList: some View {
        let profileNamesByID = profileNamesByID

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Rules", systemImage: "list.bullet.rectangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                ClearGlassStatusValue(
                    text: triggerStatusText,
                    style: triggerStatusStyle
                )
            }

            if triggerService.triggers.isEmpty {
                SettingsUnavailableGate(
                    .emptyData,
                    title: "No Triggers",
                    message: "Add a rule to apply the selected profile automatically.",
                    systemImage: "bolt.badge.xmark",
                    minHeight: 150,
                    nextSteps: ["Select a profile.", "Choose a local trigger rule above."]
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(triggerService.triggers) { trigger in
                            TriggerRuleRow(
                                trigger: trigger,
                                profileName: profileNamesByID[trigger.profileID] ?? "Missing Profile",
                                smartTriggersEnabled: settingsStore.smartTriggersEnabled,
                                automationPaused: settingsStore.automationPaused,
                                onEnabledChanged: { isEnabled in
                                    updateTrigger(trigger, isEnabled: isEnabled)
                                },
                                onDelete: {
                                    deleteTrigger(trigger)
                                }
                            )
                        }
                    }
                    .padding(6)
                }
                .frame(minHeight: 180, maxHeight: 360)
                .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
                }
            }
        }
    }

    private var triggerStatusText: String {
        if !settingsStore.smartTriggersEnabled {
            return "Off"
        }
        return settingsStore.automationPaused ? "Paused" : "Ready"
    }

    private var triggerStatusStyle: ClearGlassStatusStyle {
        if !settingsStore.smartTriggersEnabled {
            return .secondary
        }
        return settingsStore.automationPaused ? .warning : .success
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
        if let selectedProfileID,
           profileStore.profiles.contains(where: { $0.id == selectedProfileID }) {
            loadDraft()
            return
        }

        selectedProfileID = profileStore.profiles.first?.id
        loadDraft()
    }

    private func loadDraft() {
        draftProfile = selectedProfile
        dryRunSummary = nil
    }

    private func createProfile() {
        let profile = profileStore.createProfile()
        selectedProfileID = profile.id
        draftProfile = profile
        dryRunSummary = nil
        message = "Created \(profile.name)."
    }

    private func saveDraft() {
        guard let draftProfile else { return }
        profileStore.update(draftProfile)
        selectedProfileID = draftProfile.id
        self.draftProfile = profileStore.profiles.first { $0.id == draftProfile.id } ?? draftProfile
        message = "Saved \(draftProfile.name)."
    }

    private func runDryRun() {
        guard let draftProfile else { return }
        dryRunSummary = onDryRun(draftProfile)
    }

    private func applyDraft() {
        guard let draftProfile else { return }
        saveDraft()
        dryRunSummary = onApply(draftProfile)
    }

    private func exportDraft() {
        guard let draftProfile else { return }
        export(profile: draftProfile)
    }

    private func duplicateSelected() {
        guard let selectedProfile else { return }
        let copy = profileStore.duplicate(selectedProfile)
        selectedProfileID = copy.id
        draftProfile = copy
        dryRunSummary = nil
        message = "Duplicated \(selectedProfile.name)."
    }

    private func deleteSelected() {
        guard let selectedProfile else { return }
        profileStore.delete(selectedProfile)
        selectedProfileID = profileStore.profiles.first?.id
        loadDraft()
        message = "Deleted \(selectedProfile.name)."
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
        message = "Added trigger for \(selectedProfile.name)."
    }

    private func updateTrigger(_ trigger: TriggerModel, isEnabled: Bool) {
        var updated = trigger
        updated.isEnabled = isEnabled
        triggerService.update(updated)
        onTriggersChanged()
    }

    private func deleteTrigger(_ trigger: TriggerModel) {
        triggerService.delete(trigger)
        onTriggersChanged()
        message = "Deleted trigger \(trigger.name)."
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
            dryRunSummary = nil
            message = "Imported \(profile.name)."
        } catch {
            message = "Import failed: \(error.localizedDescription)"
        }
    }
}

private struct ProfileOverviewStrip: View {
    let profileCount: Int
    let triggerCount: Int
    let automationPaused: Bool

    var body: some View {
        ClearGlassOverviewStrip([
            ClearGlassOverviewMetric(
                title: "Profiles",
                value: "\(profileCount)",
                systemImage: "person.crop.rectangle.stack",
                style: .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Triggers",
                value: "\(triggerCount)",
                systemImage: "bolt",
                style: .info
            ),
            ClearGlassOverviewMetric(
                title: "Automation",
                value: automationPaused ? "Paused" : "Ready",
                systemImage: automationPaused ? "pause.circle" : "checkmark.circle",
                style: automationPaused ? .warning : .success
            )
        ])
    }
}

private struct ProfileListRow: View {
    let profile: ProfileModel
    let isSelected: Bool
    let isActive: Bool
    let triggerCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(iconColor.opacity(isSelected ? 0.20 : 0.12))

                    Image(systemName: "person.crop.rectangle.stack")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(profile.name)
                            .font(.body)
                            .lineLimit(1)

                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    HStack(spacing: 6) {
                        Text("\(profile.targetZonesByBundleID.count) zone\(profile.targetZonesByBundleID.count == 1 ? "" : "s")")

                        if profile.showSecondBar {
                            ProfileRowBadge("Second Bar shortcut", systemImage: "rectangle.bottomthird.inset.filled")
                        }

                        if triggerCount > 0 {
                            ProfileRowBadge("\(triggerCount)", systemImage: "bolt")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)

                Text(profile.updatedAt, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .background(rowBackground, in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(rowStroke, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var iconColor: Color {
        isActive ? .green : .secondary
    }

    private var rowBackground: Color {
        isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor).opacity(0.35)
    }

    private var rowStroke: Color {
        isSelected ? Color.accentColor.opacity(0.42) : Color(nsColor: .separatorColor).opacity(0.24)
    }
}

private struct ProfileRowBadge: View {
    let text: String
    let systemImage: String

    init(_ text: String, systemImage: String) {
        self.text = text
        self.systemImage = systemImage
    }

    var body: some View {
        Label(text, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(nsColor: .quaternaryLabelColor).opacity(0.12), in: .capsule)
    }
}

private struct ProfileDetailHeader: View {
    let profile: ProfileModel
    let isActive: Bool
    let triggerCount: Int
    let dryRunSummary: ProfileApplicationDryRun?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill((isActive ? Color.green : Color.secondary).opacity(0.12))

                    Image(systemName: "person.crop.rectangle.stack")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isActive ? .green : .secondary)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.title3)
                        .lineLimit(1)

                    Text(profile.notes.isEmpty ? "Local profile" : profile.notes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                ClearGlassStatusValue(
                    text: isActive ? "Active" : "Saved",
                    style: isActive ? .success : .secondary
                )
            }

            HStack(spacing: 8) {
                ProfileMetricView(value: profile.preferredVisibilityState.profileDisplayName, label: "Visibility")
                ProfileMetricView(value: "\(profile.targetZonesByBundleID.count)", label: "Zones")
                ProfileMetricView(value: "\(triggerCount)", label: "Triggers")
                ProfileMetricView(value: dryRunSummary?.isEmpty == false ? "Review" : "Ready", label: "Preview")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
    }
}

private struct ProfileMetricView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(minWidth: 84, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.36), lineWidth: 0.5)
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
    let selectedProfileName: String
    let frontmostBundleIdentifier: @MainActor () -> String?
    let onAdd: (TriggerRule, String) -> Void

    @State private var draft: TriggerDraft
    @State private var didSeedDefaultBundleIdentifier = false

    init(
        isProfileSelected: Bool,
        selectedProfileName: String,
        frontmostBundleIdentifier: @escaping @MainActor () -> String? = Self.currentFrontmostBundleIdentifier,
        onAdd: @escaping (TriggerRule, String) -> Void
    ) {
        self.isProfileSelected = isProfileSelected
        self.selectedProfileName = selectedProfileName
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("New Rule", systemImage: "plus.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Label(selectedProfileName, systemImage: "person.crop.rectangle.stack")
                    .font(.caption)
                    .foregroundStyle(isProfileSelected ? Color.secondary : Color.orange)
                    .lineLimit(1)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 10) {
                    triggerPicker
                    draftControls
                    Spacer(minLength: 12)
                    addButton
                }

                VStack(alignment: .leading, spacing: 8) {
                    triggerPicker
                    draftControls
                    addButton
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
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
        .pickerStyle(.menu)
        .frame(width: 160)
    }

    @ViewBuilder
    private var draftControls: some View {
        switch draft.kind {
        case .externalDisplay:
            Stepper(
                "Displays: \(draft.minimumDisplayCount)",
                value: $draft.minimumDisplayCount,
                in: 2...8
            )
            .frame(width: 170, alignment: .leading)
        case .appLaunched, .frontmostApp:
            TextField("Bundle ID", text: $draft.bundleIdentifier)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)
        case .batteryLow:
            Stepper(
                "Battery: \(draft.batteryThreshold)%",
                value: $draft.batteryThreshold,
                in: 1...100
            )
            .frame(width: 170, alignment: .leading)
        case .timeOfDay:
            DatePicker(
                "Time",
                selection: $draft.time,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .frame(width: 130, alignment: .leading)
        }
    }

    private var addButton: some View {
        Button("Add Rule", systemImage: "plus") {
            addTrigger()
        }
        .disabled(!isProfileSelected || !draft.canAdd)
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

private struct TriggerRuleRow: View {
    let trigger: TriggerModel
    let profileName: String
    let smartTriggersEnabled: Bool
    let automationPaused: Bool
    let onEnabledChanged: (Bool) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(ruleColor.opacity(0.12))

                Image(systemName: trigger.rule.systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ruleColor)
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(trigger.name)
                    .font(.body)
                    .lineLimit(1)

                Text(trigger.rule.unsupportedRuntimeReason ?? trigger.rule.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 6) {
                    Label(profileName, systemImage: "person.crop.rectangle.stack")

                    if let lastFiredAt = trigger.lastFiredAt {
                        Label {
                            Text(lastFiredAt, format: .dateTime.month().day().hour().minute())
                        } icon: {
                            Image(systemName: "clock")
                        }
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 12)

            ClearGlassStatusValue(text: statusText, style: statusStyle)

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
            .disabled(!trigger.rule.isSupportedByCurrentRuntime)

            Button("Delete Trigger", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Delete Trigger")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.24), lineWidth: 0.5)
        }
    }

    private var statusText: String {
        if !trigger.rule.isSupportedByCurrentRuntime {
            return "Unsupported"
        }
        if !smartTriggersEnabled {
            return "Off"
        }
        if automationPaused {
            return "Paused"
        }
        return trigger.isEnabled ? "Enabled" : "Disabled"
    }

    private var statusStyle: ClearGlassStatusStyle {
        if !trigger.rule.isSupportedByCurrentRuntime {
            return .warning
        }
        if !smartTriggersEnabled || !trigger.isEnabled {
            return .secondary
        }
        return automationPaused ? .warning : .success
    }

    private var ruleColor: Color {
        switch trigger.rule {
        case .externalDisplayConnected:
            .blue
        case .appLaunched:
            .green
        case .frontmostApp:
            .purple
        case .batteryLow:
            .orange
        case .timeOfDay:
            .secondary
        case .focusModePlaceholder:
            .indigo
        case .wifiSSID:
            .cyan
        }
    }
}

private struct DryRunSummaryView: View {
    let summary: ProfileApplicationDryRun

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Preview", systemImage: summary.isEmpty ? "checkmark.circle" : "doc.text.magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(summary.isEmpty ? .green : .primary)

                Spacer()

                ClearGlassStatusValue(
                    text: summary.isEmpty ? "Ready" : "Review",
                    style: summary.isEmpty ? .success : .warning
                )
            }

            Text(summary.summary)
                .font(.callout)
                .foregroundStyle(.secondary)

            DryRunSummarySection(title: "Reveal", items: summary.itemsToReveal, systemImage: "eye", color: .secondary)
            DryRunMoveSection(items: summary.itemsToMove)
            DryRunSummarySection(title: "Groups", items: summary.groupChanges, systemImage: "person.2", color: .secondary)
            DryRunSummarySection(title: "Layout", items: summary.layoutChanges, systemImage: "rectangle.split.3x1", color: .secondary)
            DryRunSummarySection(title: "Labs", items: summary.labsChanges, systemImage: "testtube.2", color: .secondary)
            DryRunSummarySection(title: "Unavailable", items: summary.unavailableItems, systemImage: "questionmark.circle", color: .orange)
            DryRunSummarySection(title: "Requirements", items: summary.permissionRequirements, systemImage: "exclamationmark.triangle", color: .orange)
            DryRunSummarySection(title: "Protected", items: summary.protectedActions, systemImage: "lock.fill", color: .secondary)
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
        }
    }
}

private struct DryRunSummarySection: View {
    let title: String
    let items: [String]
    let systemImage: String
    let color: Color

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    Label(item, systemImage: systemImage)
                        .font(.callout)
                        .foregroundStyle(color)
                        .lineLimit(2)
                }
            }
        }
    }
}

private struct DryRunMoveSection: View {
    let items: [ProfileMovePreview]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Moves")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(items, id: \.bundleIdentifier) { item in
                    Label(
                        "\(item.displayName): \(item.currentZone.displayName) -> \(item.targetZone.displayName)",
                        systemImage: "arrow.left.and.right"
                    )
                    .font(.callout)
                    .lineLimit(2)
                }
            }
        }
    }
}

private extension TriggerRule {
    var systemImage: String {
        switch self {
        case .externalDisplayConnected:
            "display.2"
        case .appLaunched:
            "app.badge"
        case .frontmostApp:
            "macwindow"
        case .batteryLow:
            "battery.25percent"
        case .timeOfDay:
            "clock"
        case .focusModePlaceholder:
            "moon"
        case .wifiSSID:
            "wifi"
        }
    }
}

private extension HidingVisibilityState {
    var profileDisplayName: String {
        switch self {
        case .collapsed:
            "Collapsed"
        case .expanded:
            "Expanded"
        case .revealAll:
            "Reveal All"
        }
    }
}
