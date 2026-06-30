import Carbon.HIToolbox
import SwiftUI

struct DynamicHotkeysSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    let bindingStore: HotkeyBindingStore
    let groups: [IconGroup]
    let profiles: [ProfileModel]
    var onHotkeysChanged: (() -> Void)?

    @State private var revision = 0
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
        Set(HotkeyConflictDetector.detectConflicts(in: bindings).flatMap { [$0.0.id, $0.1.id] })
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Hotkeys",
            subtitle: "Create optional per-action hotkeys. Existing Basic and Find Icon hotkeys keep working.",
            badges: [.preview, .privacySafe]
        ) {
            ClearGlassSection("Dynamic Hotkeys") {
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
                    Stepper("\(settingsStore.maxDynamicHotkeys)", value: $settingsStore.maxDynamicHotkeys, in: 0...50)
                        .onChange(of: settingsStore.maxDynamicHotkeys) { _, _ in notifyChanged() }
                }

                if !conflicts.isEmpty {
                    ClearGlassInlineMessage(
                        text: "\(conflicts.count) hotkey target(s) conflict. Conflicting bindings will not register.",
                        systemImage: "exclamationmark.triangle",
                        style: .warning
                    )
                }
            }

            ClearGlassSection("Bindings", subtitle: "Add, edit, delete, and test saved hotkey bindings.") {
                addBindingEditor

                ClearGlassDivider()

                if bindings.isEmpty {
                    ContentUnavailableView("No Dynamic Hotkeys", systemImage: "keyboard")
                        .frame(maxWidth: .infinity, minHeight: 140)
                } else {
                    VStack(spacing: 0) {
                        ForEach(bindings) { binding in
                            hotkeyRow(binding)
                            if binding.id != bindings.last?.id {
                                ClearGlassDivider()
                            }
                        }
                    }
                }

                Button("Disable All Dynamic Hotkeys", systemImage: "keyboard.badge.ellipsis") {
                    for binding in bindings {
                        bindingStore.update(id: binding.id) { $0.isEnabled = false }
                    }
                    notifyChanged()
                }
                .disabled(bindings.isEmpty)
            }
        }
        .onAppear {
            bindingStore.load()
            revision += 1
        }
    }

    private var addBindingEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Action", selection: $selectedAction) {
                ForEach(availableActions, id: \.self) { action in
                    Text(action.displayLabel).tag(action)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 12) {
                Toggle("Command", isOn: $command)
                Toggle("Option", isOn: $option)
                Toggle("Shift", isOn: $shift)
                Toggle("Control", isOn: $control)

                Picker("Key", selection: $selectedKeyCode) {
                    ForEach(Self.commonKeys, id: \.keyCode) { key in
                        Text(key.label).tag(key.keyCode)
                    }
                }
                .frame(width: 120)

                Button("Add Binding", systemImage: "plus") {
                    addBinding()
                }
                .disabled(currentModifiersRaw == 0)
            }
        }
    }

    private func hotkeyRow(_ binding: HotkeyBinding) -> some View {
        HStack(spacing: 12) {
            Image(systemName: conflicts.contains(binding.id) ? "exclamationmark.triangle" : "keyboard")
                .foregroundStyle(conflicts.contains(binding.id) ? .orange : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(binding.label)
                Text(HotkeyModel(keyCode: UInt32(binding.keyCode), modifiersRaw: UInt32(binding.modifiersRaw)).displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("Enabled", isOn: Binding(
                get: { binding.isEnabled },
                set: { isEnabled in
                    bindingStore.update(id: binding.id) { $0.isEnabled = isEnabled }
                    notifyChanged()
                }
            ))
            .labelsHidden()

            Button("Test", systemImage: "play") {
                // Test registration semantics without firing the action.
                notifyChanged()
            }
            .labelStyle(.iconOnly)
            .help("Refresh Registration")

            Button("Delete", systemImage: "trash", role: .destructive) {
                bindingStore.remove(id: binding.id)
                notifyChanged()
            }
            .labelStyle(.iconOnly)
            .help("Delete")
        }
        .padding(.vertical, 8)
    }

    private var availableActions: [HotkeyAction] {
        var actions: [HotkeyAction] = [
            .enterFullMenuBarMode,
            .exitFullMenuBarMode,
            .pauseAutomation,
            .resumeAutomation
        ]
        actions += groups.map { .openGroup($0.id) }
        actions += groups.map { .openSecondBarFilteredToGroup($0.id) }
        actions += profiles.map { .applyProfile($0.id) }
        return actions
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
            modifiersRaw: currentModifiersRaw
        )
        bindingStore.add(binding: binding)
        notifyChanged()
    }

    private func notifyChanged() {
        revision += 1
        onHotkeysChanged?()
    }

    private static let commonKeys: [(label: String, keyCode: Int)] = [
        ("A", Int(kVK_ANSI_A)), ("B", Int(kVK_ANSI_B)), ("C", Int(kVK_ANSI_C)),
        ("F", Int(kVK_ANSI_F)), ("G", Int(kVK_ANSI_G)), ("H", Int(kVK_ANSI_H)),
        ("L", Int(kVK_ANSI_L)), ("P", Int(kVK_ANSI_P)), ("S", Int(kVK_ANSI_S)),
        ("Space", Int(kVK_Space)), ("F6", Int(kVK_F6)), ("F7", Int(kVK_F7))
    ]
}
