import Carbon.HIToolbox
import SwiftUI

struct DynamicHotkeysSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    let bindingStore: HotkeyBindingStore
    let groups: [IconGroup]
    let profiles: [ProfileModel]
    var onHotkeysChanged: (() -> Void)?

    @State private var revision = 0
    @State private var selectedBindingID: HotkeyBinding.ID?
    @State private var searchText = ""
    @State private var selectedFilter: DynamicHotkeyFilter = .all
    @State private var selectedAction = HotkeyAction.enterFullMenuBarMode
    @State private var selectedKeyCode = Int(kVK_ANSI_L)
    @State private var command = true
    @State private var option = true
    @State private var shift = false
    @State private var control = false

    private var bindings: [HotkeyBinding] {
        _ = revision
        return bindingStore.bindings
    }

    private var conflicts: Set<UUID> {
        let enabledBindings = bindings.filter(\.isEnabled)
        return Set(HotkeyConflictDetector.detectConflicts(in: enabledBindings).flatMap { [$0.0.id, $0.1.id] })
    }

    private var readyBindingCount: Int {
        bindings.filter { bindingStatus(for: $0).canRegister }.count
    }

    private var warningBindingCount: Int {
        bindings.filter { bindingStatus(for: $0).isWarning }.count
    }

    private var filteredBindings: [HotkeyBinding] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return bindings.filter { binding in
            let status = bindingStatus(for: binding)
            guard selectedFilter.includes(binding: binding, status: status) else {
                return false
            }

            guard !query.isEmpty else {
                return true
            }

            let presentation = actionPresentation(for: binding.action)
            let shortcut = hotkeyDisplayName(for: binding)
            let searchableText = [
                binding.label,
                presentation.title,
                presentation.subtitle,
                shortcut,
                status.label,
                status.message
            ]
            .joined(separator: " ")

            return searchableText.localizedStandardContains(query)
        }
    }

    private var selectedBinding: HotkeyBinding? {
        guard let selectedBindingID else { return filteredBindings.first }
        return bindings.first { $0.id == selectedBindingID }
    }

    private var availableActionOptions: [HotkeyActionOption] {
        var options: [HotkeyActionOption] = [
            HotkeyActionOption(
                action: .enterFullMenuBarMode,
                title: "Enter Full Menu Bar Mode",
                subtitle: "Reveal the full menu bar layout.",
                systemImage: "menubar.rectangle"
            ),
            HotkeyActionOption(
                action: .exitFullMenuBarMode,
                title: "Exit Full Menu Bar Mode",
                subtitle: "Return to the saved decluttered layout.",
                systemImage: "menubar.arrow.down.rectangle"
            ),
            HotkeyActionOption(
                action: .pauseAutomation,
                title: "Pause Automation",
                subtitle: "Stop optional automation until resumed.",
                systemImage: "pause.circle"
            ),
            HotkeyActionOption(
                action: .resumeAutomation,
                title: "Resume Automation",
                subtitle: "Allow optional automation to run again.",
                systemImage: "play.circle"
            )
        ]

        for group in IconGroupSort.sort(groups) {
            let name = group.name.isEmpty ? "Untitled Group" : group.name
            let symbolName = group.symbolName?.isEmpty == false ? group.symbolName ?? "folder" : "folder"

            options.append(
                HotkeyActionOption(
                    action: .openGroup(group.id),
                    title: "Open \(name)",
                    subtitle: "Open the local group panel.",
                    systemImage: symbolName
                )
            )
            options.append(
                HotkeyActionOption(
                    action: .revealGroup(group.id),
                    title: "Reveal \(name)",
                    subtitle: "Reveal matching menu bar items. Requires Pro Mode at runtime.",
                    systemImage: "eye",
                    requiresProMode: true
                )
            )
            options.append(
                HotkeyActionOption(
                    action: .openSecondBarFilteredToGroup(group.id),
                    title: "Second Bar: \(name)",
                    subtitle: "Open Second Bar filtered to this group.",
                    systemImage: "rectangle.bottomthird.inset.filled"
                )
            )
        }

        for profile in profiles {
            let name = profile.name.isEmpty ? "Untitled Profile" : profile.name
            options.append(
                HotkeyActionOption(
                    action: .applyProfile(profile.id),
                    title: "Apply \(name)",
                    subtitle: "Apply this saved local profile.",
                    systemImage: "person.crop.rectangle.stack"
                )
            )
        }

        return options
    }

    private var selectedActionPresentation: HotkeyActionPresentation {
        actionPresentation(for: selectedAction)
    }

    private var currentShortcutDisplay: String {
        HotkeyModel(keyCode: UInt32(selectedKeyCode), modifiersRaw: UInt32(currentModifiersRaw)).displayName
    }

    private var currentDraftConflicts: Bool {
        guard currentModifiersRaw != 0 else { return false }
        let draft = HotkeyBinding(
            action: selectedAction,
            keyCode: selectedKeyCode,
            modifiersRaw: currentModifiersRaw
        )
        return HotkeyConflictDetector.wouldConflict(draft, in: bindings.filter(\.isEnabled))
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Hotkeys",
            subtitle: "Create optional local shortcuts for groups, profiles, and layout actions.",
            badges: [.preview, .privacySafe]
        ) {
            DynamicHotkeyOverviewStrip(
                totalCount: bindings.count,
                enabledCount: bindings.filter(\.isEnabled).count,
                readyCount: readyBindingCount,
                warningCount: warningBindingCount
            )

            ClearGlassSection("Dynamic Hotkeys", subtitle: "Registration limits and the global enable switch.") {
                FeatureGateNotice(
                    .preview,
                    text: "Preview in v0.1.1. Conflicts fail closed and do not replace the stable Basic hotkey."
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "keyboard",
                    title: "Enable Dynamic Hotkeys",
                    subtitle: "Register user-created hotkeys for groups, profiles, and layout actions."
                ) {
                    Toggle("Enable Dynamic Hotkeys", isOn: $settingsStore.dynamicHotkeysEnabled)
                        .labelsHidden()
                        .onChange(of: settingsStore.dynamicHotkeysEnabled) { _, _ in notifyChanged() }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "number",
                    title: "Maximum Dynamic Hotkeys",
                    subtitle: "Limit registrations so accidental bulk imports cannot register too many shortcuts."
                ) {
                    HStack(spacing: 10) {
                        Text(settingsStore.maxDynamicHotkeys, format: .number)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, alignment: .trailing)

                        Stepper(
                            "Maximum Dynamic Hotkeys",
                            value: $settingsStore.maxDynamicHotkeys,
                            in: 0...50
                        )
                        .labelsHidden()
                        .onChange(of: settingsStore.maxDynamicHotkeys) { _, _ in notifyChanged() }
                    }
                }

                hotkeyDegradedStateMessages
            }

            ClearGlassSection("New Binding", subtitle: "Choose an action, at least one modifier, and a key.") {
                DynamicHotkeyComposer(
                    selectedAction: $selectedAction,
                    selectedKeyCode: $selectedKeyCode,
                    command: $command,
                    option: $option,
                    shift: $shift,
                    control: $control,
                    actionOptions: availableActionOptions,
                    selectedActionPresentation: selectedActionPresentation,
                    shortcutDisplay: currentShortcutDisplay,
                    hasModifiers: currentModifiersRaw != 0,
                    hasEnabledConflict: currentDraftConflicts,
                    onAdd: addBinding
                )
            }

            ClearGlassSection("Bindings", subtitle: "Filter saved shortcuts, inspect status, and manage registration.") {
                DynamicHotkeyBindingsToolbar(
                    searchText: $searchText,
                    selectedFilter: $selectedFilter,
                    bindingCount: bindings.count,
                    onDisableAll: disableAllDynamicHotkeys
                )
                .disabled(bindings.isEmpty)

                ClearGlassDivider()

                if filteredBindings.isEmpty {
                    DynamicHotkeyUnavailableView(
                        hasBindings: !bindings.isEmpty,
                        searchText: searchText
                    )
                } else {
                    HStack(spacing: 0) {
                        DynamicHotkeyBindingsList(
                            bindings: filteredBindings,
                            selectedBindingID: $selectedBindingID,
                            statusProvider: bindingStatus(for:),
                            presentationProvider: actionPresentation(for:),
                            shortcutProvider: hotkeyDisplayName(for:),
                            onEnabledChanged: updateBindingEnabled
                        )
                        .frame(minWidth: 430, maxWidth: .infinity, minHeight: 360)

                        Divider()

                        DynamicHotkeyBindingInspector(
                            binding: selectedBinding,
                            status: selectedBinding.map(bindingStatus(for:)),
                            presentation: selectedBinding.map { actionPresentation(for: $0.action) },
                            shortcutDisplay: selectedBinding.map(hotkeyDisplayName(for:)),
                            canResetToSuggestedShortcut: selectedBinding.map(canResetToSuggestedShortcut) ?? false,
                            onRefresh: notifyChanged,
                            onReset: resetToSuggestedShortcut,
                            onDisable: disableBinding,
                            onDelete: deleteBinding
                        )
                        .frame(width: 300)
                    }
                    .frame(minHeight: 360)
                    .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
                    }
                }
            }
        }
        .onAppear {
            bindingStore.load()
            revision += 1
            reconcileActionSelection()
            reconcileBindingSelection()
        }
        .onChange(of: filteredBindings.map(\.id)) {
            reconcileBindingSelection()
        }
        .onChange(of: availableActionOptions.map(\.id)) {
            reconcileActionSelection()
        }
    }

    @ViewBuilder
    private var hotkeyDegradedStateMessages: some View {
        if !settingsStore.dynamicHotkeysEnabled {
            ClearGlassInlineMessage(
                text: "Dynamic hotkeys are off. Saved bindings stay local and the stable Basic hotkey continues to work.",
                systemImage: "keyboard.badge.ellipsis",
                style: .secondary
            )
        }

        if settingsStore.maxDynamicHotkeys == 0 {
            ClearGlassInlineMessage(
                text: "The registration limit is zero. Bindings can be saved, but none will register until the limit is raised.",
                systemImage: "number.circle",
                style: .warning
            )
        }

        if !conflicts.isEmpty {
            ClearGlassInlineMessage(
                text: "\(conflicts.count) hotkey target(s) conflict. Conflicting bindings will not register.",
                systemImage: "exclamationmark.triangle",
                style: .warning
            )
        }
    }

    private func bindingStatus(for binding: HotkeyBinding) -> DynamicHotkeyBindingStatus {
        DynamicHotkeyBindingStatusPlanner.status(
            for: binding,
            in: bindings,
            dynamicHotkeysEnabled: settingsStore.dynamicHotkeysEnabled,
            maxDynamicHotkeys: settingsStore.maxDynamicHotkeys,
            proModeEnabled: settingsStore.proModeEnabled
        )
    }

    private func actionPresentation(for action: HotkeyAction) -> HotkeyActionPresentation {
        if let option = availableActionOptions.first(where: { $0.action == action }) {
            return HotkeyActionPresentation(
                title: option.title,
                subtitle: option.subtitle,
                systemImage: option.systemImage,
                requiresProMode: option.requiresProMode
            )
        }

        switch action {
        case .revealAndHighlightItem:
            return HotkeyActionPresentation(
                title: action.displayLabel,
                subtitle: "Saved item reference is no longer available in this settings view.",
                systemImage: "scope",
                requiresProMode: true
            )
        case .openGroup, .revealGroup, .openSecondBarFilteredToGroup:
            return HotkeyActionPresentation(
                title: action.displayLabel,
                subtitle: "The referenced group may have been removed.",
                systemImage: "folder.badge.questionmark",
                requiresProMode: action.requiresProMode
            )
        case .openSecondBarFilteredToItem:
            return HotkeyActionPresentation(
                title: action.displayLabel,
                subtitle: "Saved item reference is no longer available in this settings view.",
                systemImage: "rectangle.bottomthird.inset.filled",
                requiresProMode: true
            )
        case .applyProfile:
            return HotkeyActionPresentation(
                title: action.displayLabel,
                subtitle: "The referenced profile may have been removed.",
                systemImage: "person.crop.rectangle.badge.questionmark",
                requiresProMode: false
            )
        case .enterFullMenuBarMode, .exitFullMenuBarMode, .pauseAutomation, .resumeAutomation:
            return HotkeyActionPresentation(
                title: action.displayLabel,
                subtitle: "Local app action.",
                systemImage: "keyboard",
                requiresProMode: action.requiresProMode
            )
        }
    }

    private func hotkeyDisplayName(for binding: HotkeyBinding) -> String {
        HotkeyModel(keyCode: UInt32(binding.keyCode), modifiersRaw: UInt32(binding.modifiersRaw)).displayName
    }

    private var currentModifiersRaw: UInt {
        var raw: UInt = 0
        if command { raw |= UInt(cmdKey) }
        if option { raw |= UInt(optionKey) }
        if shift { raw |= UInt(shiftKey) }
        if control { raw |= UInt(controlKey) }
        return raw
    }

    private func addBinding() {
        let binding = HotkeyBinding(
            action: selectedAction,
            keyCode: selectedKeyCode,
            modifiersRaw: currentModifiersRaw,
            label: selectedActionPresentation.title
        )
        bindingStore.add(binding: binding)
        selectedBindingID = binding.id
        notifyChanged()
    }

    private func updateBindingEnabled(_ binding: HotkeyBinding, isEnabled: Bool) {
        bindingStore.update(id: binding.id) { $0.isEnabled = isEnabled }
        notifyChanged()
    }

    private func disableBinding(_ binding: HotkeyBinding) {
        bindingStore.update(id: binding.id) { $0.isEnabled = false }
        notifyChanged()
    }

    private func deleteBinding(_ binding: HotkeyBinding) {
        bindingStore.remove(id: binding.id)
        selectedBindingID = nil
        notifyChanged()
        reconcileBindingSelection()
    }

    private func disableAllDynamicHotkeys() {
        for binding in bindings {
            bindingStore.update(id: binding.id) { $0.isEnabled = false }
        }
        notifyChanged()
    }

    private func canResetToSuggestedShortcut(_ binding: HotkeyBinding) -> Bool {
        groupResetTarget(for: binding) != nil
    }

    private func resetToSuggestedShortcut(_ binding: HotkeyBinding) {
        guard let target = groupResetTarget(for: binding) else { return }
        let plan = GroupHotkeyAssignmentPlanner().plan(
            groupID: target.groupID,
            kind: target.kind,
            existingBindings: bindings.filter { $0.id != binding.id }
        )

        guard case .add(let suggestedBinding) = plan.operation else { return }
        bindingStore.update(id: binding.id) { existing in
            existing.keyCode = suggestedBinding.keyCode
            existing.modifiersRaw = suggestedBinding.modifiersRaw
            existing.isEnabled = true
            existing.label = suggestedBinding.label
        }
        notifyChanged()
    }

    private func groupResetTarget(for binding: HotkeyBinding) -> (groupID: UUID, kind: GroupHotkeyAssignmentKind)? {
        switch binding.action {
        case .openGroup(let groupID):
            return (groupID, .openPanel)
        case .revealGroup(let groupID):
            return (groupID, .reveal)
        default:
            return nil
        }
    }

    private func reconcileActionSelection() {
        guard availableActionOptions.contains(where: { $0.action == selectedAction }) else {
            selectedAction = availableActionOptions.first?.action ?? .enterFullMenuBarMode
            return
        }
    }

    private func reconcileBindingSelection() {
        guard !filteredBindings.isEmpty else {
            selectedBindingID = nil
            return
        }

        if let selectedBindingID,
           filteredBindings.contains(where: { $0.id == selectedBindingID }) {
            return
        }

        selectedBindingID = filteredBindings.first?.id
    }

    private func notifyChanged() {
        revision += 1
        onHotkeysChanged?()
    }

    fileprivate static let commonKeys: [(label: String, keyCode: Int)] = [
        ("A", Int(kVK_ANSI_A)), ("B", Int(kVK_ANSI_B)), ("C", Int(kVK_ANSI_C)),
        ("F", Int(kVK_ANSI_F)), ("G", Int(kVK_ANSI_G)), ("H", Int(kVK_ANSI_H)),
        ("L", Int(kVK_ANSI_L)), ("P", Int(kVK_ANSI_P)), ("S", Int(kVK_ANSI_S)),
        ("Space", Int(kVK_Space)), ("F6", Int(kVK_F6)), ("F7", Int(kVK_F7))
    ]
}

private enum DynamicHotkeyFilter: String, CaseIterable, Identifiable {
    case all
    case ready
    case warnings
    case disabled
    case proMode

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "All"
        case .ready:
            "Ready"
        case .warnings:
            "Warnings"
        case .disabled:
            "Disabled"
        case .proMode:
            "Pro"
        }
    }

    func includes(binding: HotkeyBinding, status: DynamicHotkeyBindingStatus) -> Bool {
        switch self {
        case .all:
            true
        case .ready:
            status.kind == .ready
        case .warnings:
            status.isWarning
        case .disabled:
            !binding.isEnabled || status.kind == .registrationDisabled
        case .proMode:
            binding.action.requiresProMode || status.kind == .requiresProMode
        }
    }
}

private struct HotkeyActionOption: Identifiable {
    let action: HotkeyAction
    let title: String
    let subtitle: String
    let systemImage: String
    var requiresProMode = false

    var id: HotkeyAction { action }
}

private struct HotkeyActionPresentation {
    let title: String
    let subtitle: String
    let systemImage: String
    let requiresProMode: Bool
}

private struct DynamicHotkeyOverviewStrip: View {
    let totalCount: Int
    let enabledCount: Int
    let readyCount: Int
    let warningCount: Int

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            DynamicHotkeyMetricView(
                title: "Bindings",
                value: totalCount.formatted(.number),
                systemImage: "keyboard"
            )
            DynamicHotkeyMetricView(
                title: "Enabled",
                value: enabledCount.formatted(.number),
                systemImage: "power",
                style: enabledCount > 0 ? .success : .secondary
            )
            DynamicHotkeyMetricView(
                title: "Registerable",
                value: readyCount.formatted(.number),
                systemImage: "checkmark.circle",
                style: .success
            )
            DynamicHotkeyMetricView(
                title: "Needs Review",
                value: warningCount.formatted(.number),
                systemImage: "exclamationmark.triangle",
                style: warningCount > 0 ? .warning : .secondary
            )
        }
    }
}

private struct DynamicHotkeyMetricView: View {
    let title: String
    let value: String
    let systemImage: String
    var style: ClearGlassStatusStyle = .secondary

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(style.tint)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
    }
}

private struct DynamicHotkeyComposer: View {
    @Binding var selectedAction: HotkeyAction
    @Binding var selectedKeyCode: Int
    @Binding var command: Bool
    @Binding var option: Bool
    @Binding var shift: Bool
    @Binding var control: Bool

    let actionOptions: [HotkeyActionOption]
    let selectedActionPresentation: HotkeyActionPresentation
    let shortcutDisplay: String
    let hasModifiers: Bool
    let hasEnabledConflict: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ClearGlassControlRow(
                systemImage: selectedActionPresentation.systemImage,
                title: "Action",
                subtitle: selectedActionPresentation.subtitle,
                iconTint: selectedActionPresentation.requiresProMode ? .orange : .secondary
            ) {
                Picker("Action", selection: $selectedAction) {
                    ForEach(actionOptions) { option in
                        Text(option.title).tag(option.action)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 260)
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "command",
                title: "Modifiers",
                subtitle: "Use at least one modifier so normal typing never triggers a global shortcut."
            ) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        modifierToggles
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        modifierToggles
                    }
                }
            }

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "key",
                title: "Key",
                subtitle: hasEnabledConflict
                    ? "This shortcut matches an enabled binding and will be saved as a conflict."
                    : "Preview the shortcut before adding it to the local binding list.",
                iconTint: hasEnabledConflict ? .orange : .secondary
            ) {
                HStack(spacing: 10) {
                    Picker("Key", selection: $selectedKeyCode) {
                        ForEach(DynamicHotkeysSettingsView.commonKeys, id: \.keyCode) { key in
                            Text(key.label).tag(key.keyCode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)

                    KeyboardShortcutToken(text: shortcutDisplay)

                    Button("Add Binding", systemImage: "plus", action: onAdd)
                        .buttonStyle(.borderedProminent)
                        .disabled(!hasModifiers)
                }
            }
        }
    }

    @ViewBuilder
    private var modifierToggles: some View {
        Toggle("Command", isOn: $command)
            .toggleStyle(.checkbox)
        Toggle("Option", isOn: $option)
            .toggleStyle(.checkbox)
        Toggle("Shift", isOn: $shift)
            .toggleStyle(.checkbox)
        Toggle("Control", isOn: $control)
            .toggleStyle(.checkbox)
    }
}

private struct DynamicHotkeyBindingsToolbar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: DynamicHotkeyFilter
    let bindingCount: Int
    let onDisableAll: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                Label("Bindings", systemImage: "list.bullet.rectangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(DynamicHotkeyFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 360)

                Spacer(minLength: 12)

                SearchField("Search Hotkeys", text: $searchText, width: 220)

                Button("Disable All", systemImage: "pause.circle", role: .destructive, action: onDisableAll)
                    .controlSize(.small)
                    .disabled(bindingCount == 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Label("Bindings", systemImage: "list.bullet.rectangle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(DynamicHotkeyFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 150)

                    Button("Disable All", systemImage: "pause.circle", role: .destructive, action: onDisableAll)
                        .controlSize(.small)
                        .disabled(bindingCount == 0)
                }

                SearchField("Search Hotkeys", text: $searchText)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DynamicHotkeyBindingsList: View {
    let bindings: [HotkeyBinding]
    @Binding var selectedBindingID: HotkeyBinding.ID?
    let statusProvider: (HotkeyBinding) -> DynamicHotkeyBindingStatus
    let presentationProvider: (HotkeyAction) -> HotkeyActionPresentation
    let shortcutProvider: (HotkeyBinding) -> String
    let onEnabledChanged: (HotkeyBinding, Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            DynamicHotkeyBindingsHeader()

            Divider()

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(bindings) { binding in
                        DynamicHotkeyBindingRow(
                            binding: binding,
                            status: statusProvider(binding),
                            presentation: presentationProvider(binding.action),
                            shortcutDisplay: shortcutProvider(binding),
                            isSelected: binding.id == selectedBindingID,
                            onSelect: {
                                selectedBindingID = binding.id
                            },
                            onEnabledChanged: { isEnabled in
                                onEnabledChanged(binding, isEnabled)
                            }
                        )
                    }
                }
                .padding(6)
            }
        }
    }
}

private struct DynamicHotkeyBindingsHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("Action")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Shortcut")
                .frame(width: 116, alignment: .leading)
            Text("Status")
                .frame(width: 112, alignment: .leading)
            Text("On")
                .frame(width: 42, alignment: .center)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
}

private struct DynamicHotkeyBindingRow: View {
    let binding: HotkeyBinding
    let status: DynamicHotkeyBindingStatus
    let presentation: HotkeyActionPresentation
    let shortcutDisplay: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onEnabledChanged: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(status.style.tint.opacity(isSelected ? 0.18 : 0.10))

                        Image(systemName: presentation.systemImage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(status.style.tint)
                    }
                    .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(presentation.title)
                            .font(.body)
                            .lineLimit(1)

                        Text(presentation.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(shortcutDisplay)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .frame(width: 116, alignment: .leading)

                    ClearGlassStatusValue(text: status.label, style: status.style)
                        .frame(width: 112, alignment: .leading)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            Toggle("Enabled", isOn: Binding(
                get: { binding.isEnabled },
                set: onEnabledChanged
            ))
            .labelsHidden()
            .frame(width: 42)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(rowBackground, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(rowStroke, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var rowBackground: Color {
        isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor).opacity(0.35)
    }

    private var rowStroke: Color {
        isSelected ? Color.accentColor.opacity(0.42) : Color(nsColor: .separatorColor).opacity(0.24)
    }
}

private struct DynamicHotkeyBindingInspector: View {
    let binding: HotkeyBinding?
    let status: DynamicHotkeyBindingStatus?
    let presentation: HotkeyActionPresentation?
    let shortcutDisplay: String?
    let canResetToSuggestedShortcut: Bool
    let onRefresh: () -> Void
    let onReset: (HotkeyBinding) -> Void
    let onDisable: (HotkeyBinding) -> Void
    let onDelete: (HotkeyBinding) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let binding, let status, let presentation, let shortcutDisplay {
                inspectorHeader(
                    presentation: presentation,
                    status: status,
                    shortcutDisplay: shortcutDisplay
                )

                Divider()

                HotkeyInspectorValue("Registration", value: status.message)
                HotkeyInspectorValue("Action", value: presentation.title)
                HotkeyInspectorValue("Shortcut", value: shortcutDisplay, monospaced: true)
                HotkeyInspectorValue("Created", value: binding.createdAt.formatted(date: .abbreviated, time: .shortened))
                HotkeyInspectorValue("Updated", value: binding.updatedAt.formatted(date: .abbreviated, time: .shortened))

                Divider()

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        actionButtons(for: binding)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        actionButtons(for: binding)
                    }
                }
                .controlSize(.small)
            } else {
                ContentUnavailableView(
                    "No Binding Selected",
                    systemImage: "keyboard",
                    description: Text("Select a binding to inspect registration status and actions.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private func inspectorHeader(
        presentation: HotkeyActionPresentation,
        status: DynamicHotkeyBindingStatus,
        shortcutDisplay: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(status.style.tint.opacity(0.12))

                Image(systemName: presentation.systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(status.style.tint)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(presentation.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(shortcutDisplay)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            ClearGlassStatusValue(text: status.label, style: status.style)
        }
    }

    @ViewBuilder
    private func actionButtons(for binding: HotkeyBinding) -> some View {
        Button("Refresh Registration", systemImage: "arrow.clockwise", action: onRefresh)
            .labelStyle(.iconOnly)
            .help("Refresh Registration")

        if canResetToSuggestedShortcut {
            Button("Reset Suggested Shortcut", systemImage: "arrow.counterclockwise") {
                onReset(binding)
            }
            .labelStyle(.iconOnly)
            .help("Reset suggested shortcut")
        }

        Button("Disable", systemImage: "pause.circle") {
            onDisable(binding)
        }
        .labelStyle(.iconOnly)
        .help("Disable")
        .disabled(!binding.isEnabled)

        Button("Delete", systemImage: "trash", role: .destructive) {
            onDelete(binding)
        }
        .labelStyle(.iconOnly)
        .help("Delete")
    }
}

private struct HotkeyInspectorValue: View {
    let title: String
    let value: String
    var monospaced = false

    init(_ title: String, value: String, monospaced: Bool = false) {
        self.title = title
        self.value = value
        self.monospaced = monospaced
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(monospaced ? .system(.caption, design: .monospaced) : .callout)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DynamicHotkeyUnavailableView: View {
    let hasBindings: Bool
    let searchText: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(message)
        )
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var title: String {
        hasBindings ? "No Matching Hotkeys" : "No Dynamic Hotkeys"
    }

    private var systemImage: String {
        hasBindings ? "line.3.horizontal.decrease.circle" : "keyboard"
    }

    private var message: String {
        if hasBindings {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            return query.isEmpty ? "Try a different filter." : "Try a different filter or search term."
        }

        return "Create a binding to add optional local shortcuts. The stable Basic hotkey remains available separately."
    }
}

private extension DynamicHotkeyBindingStatus {
    var label: String {
        switch kind {
        case .ready:
            "Ready"
        case .disabled:
            "Off"
        case .registrationDisabled:
            "Global Off"
        case .conflict:
            "Conflict"
        case .overLimit:
            "Limit"
        case .requiresProMode:
            "Pro"
        }
    }

    var style: ClearGlassStatusStyle {
        switch kind {
        case .ready:
            .success
        case .disabled, .registrationDisabled:
            .secondary
        case .conflict, .overLimit, .requiresProMode:
            .warning
        }
    }
}
