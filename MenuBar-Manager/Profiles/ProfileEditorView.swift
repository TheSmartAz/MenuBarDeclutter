import SwiftUI

struct ProfileEditorView: View {
    @Binding var profile: ProfileModel

    @State private var targetZoneText: String
    @State private var targetZoneTextNeedsCommit = false
    @FocusState private var isTargetZoneEditorFocused: Bool

    private var targetZoneTextBinding: Binding<String> {
        Binding(
            get: { targetZoneText },
            set: { newValue in
                targetZoneText = newValue
                targetZoneTextNeedsCommit = true
            }
        )
    }

    init(profile: Binding<ProfileModel>) {
        self._profile = profile
        self._targetZoneText = State(initialValue: Self.text(from: profile.wrappedValue.targetZonesByBundleID))
    }

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name", text: $profile.name)

                Picker("Preferred visibility", selection: $profile.preferredVisibilityState) {
                    ForEach(HidingVisibilityState.allCases, id: \.self) { state in
                        Text(state.rawValue)
                            .tag(state)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Show Second Bar", isOn: $profile.showSecondBar)
                Toggle("Auto-rehide enabled", isOn: $profile.autoRehideEnabled)
                Toggle("Hover reveal enabled", isOn: $profile.hoverRevealEnabled)
            }

            Section("Target Zones") {
                TextEditor(text: targetZoneTextBinding)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 96)
                    .focused($isTargetZoneEditorFocused)

                Text("One mapping per line, for example: com.example.app=hidden. Supported zones: visible, hidden, alwaysHidden.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Notes") {
                TextEditor(text: $profile.notes)
                    .frame(minHeight: 72)
            }
        }
        .formStyle(.grouped)
        .onChange(of: isTargetZoneEditorFocused) { _, isFocused in
            if !isFocused {
                commitTargetZoneTextIfNeeded()
            }
        }
        .onChange(of: profile.id) { _, _ in
            syncTargetZoneText(from: profile.targetZonesByBundleID, force: true)
        }
        .onChange(of: profile.targetZonesByBundleID) { _, newValue in
            syncTargetZoneText(from: newValue, force: false)
        }
        .onDisappear {
            commitTargetZoneTextIfNeeded()
        }
    }

    private func commitTargetZoneTextIfNeeded() {
        guard targetZoneTextNeedsCommit else { return }

        let zones = Self.zones(from: targetZoneText)
        targetZoneTextNeedsCommit = false
        guard profile.targetZonesByBundleID != zones else { return }

        profile.targetZonesByBundleID = zones
    }

    private func syncTargetZoneText(from zones: [String: MenuBarZone], force: Bool) {
        if !force {
            guard !targetZoneTextNeedsCommit else { return }
            guard Self.zones(from: targetZoneText) != zones else { return }
        }

        let text = Self.text(from: zones)
        if targetZoneText != text {
            targetZoneText = text
        }
        targetZoneTextNeedsCommit = false
    }

    static func text(from zones: [String: MenuBarZone]) -> String {
        zones
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.rawValue)" }
            .joined(separator: "\n")
    }

    static func zones(from text: String) -> [String: MenuBarZone] {
        var zones: [String: MenuBarZone] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: "=", maxSplits: 1).map {
                String($0).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard parts.count == 2,
                  !parts[0].isEmpty,
                  let zone = MenuBarZone(rawValue: parts[1]) else {
                continue
            }
            zones[parts[0]] = zone
        }
        return zones
    }
}
