import SwiftUI

struct AutomationSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var onChange: (() -> Void)?

    private let intents = [
        "Expand Menu Bar Items",
        "Collapse Menu Bar Items",
        "Reveal All Menu Bar Items",
        "Show Second Bar",
        "Hide Second Bar",
        "Enter Full Menu Bar Mode",
        "Exit Full Menu Bar Mode",
        "Apply Profile",
        "Pause Automation",
        "Resume Automation",
        "Set Layout Spacing Preset"
    ]

    var body: some View {
        ClearGlassSettingsPage(
            "Automation",
            subtitle: "Configure App Shortcuts and automation boundaries.",
            badges: [.privacySafe]
        ) {
            ClearGlassSection("App Shortcuts") {
                ClearGlassControlRow(
                    systemImage: "link",
                    title: "Enable App Intents",
                    subtitle: "Expose MenuBarDeclutter actions to Shortcuts. Apple Events are not used."
                ) {
                    Toggle("Enable App Intents", isOn: $settingsStore.appIntentsEnabled)
                        .labelsHidden()
                        .onChange(of: settingsStore.appIntentsEnabled) { _, _ in onChange?() }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "person.crop.rectangle.stack",
                    title: "Allow Profile Apply",
                    subtitle: "Let App Shortcuts apply profiles when automation is not paused."
                ) {
                    Toggle("Allow Profile Apply", isOn: $settingsStore.appIntentsCanApplyProfiles)
                        .labelsHidden()
                        .disabled(!settingsStore.appIntentsEnabled)
                        .onChange(of: settingsStore.appIntentsCanApplyProfiles) { _, _ in onChange?() }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "testtube.2",
                    title: "Allow Labs Access",
                    subtitle: "Allow App Shortcuts to request Labs features. Labs settings remain gated."
                ) {
                    Toggle("Allow Labs Access", isOn: $settingsStore.appIntentsCanAccessLabs)
                        .labelsHidden()
                        .disabled(!settingsStore.appIntentsEnabled)
                        .onChange(of: settingsStore.appIntentsCanAccessLabs) { _, _ in onChange?() }
                }

                ClearGlassDivider()

                Button("Open Shortcuts", systemImage: "arrow.up.right.square") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Shortcuts.app"))
                }
            }

            ClearGlassSection("Available Actions") {
                ForEach(intents, id: \.self) { intent in
                    ClearGlassControlRow(systemImage: "sparkles", title: intent) {
                        Text("Available")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ClearGlassSection("Safety") {
                ClearGlassInlineMessage(
                    text: "App Intents honor Safe Mode, automation pause, Private Access, Pro requirements, and Labs requirements. They do not add Apple Events or network access.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }
        }
    }
}
