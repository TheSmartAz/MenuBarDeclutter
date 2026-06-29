import AppKit
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
        VStack(alignment: .leading, spacing: 12) {
            nameRow
            Divider()

            VStack(alignment: .leading, spacing: 12) {
                visibilityAndZones
                behaviorToggles
            }

            Divider()
            notesSection
        }
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

    private var nameRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("Profile name")
                .foregroundStyle(.secondary)
                .frame(width: 118, alignment: .leading)

            TextField("Name", text: $profile.name)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var visibilityAndZones: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Preferred visibility")
                    .foregroundStyle(.secondary)
                    .frame(width: 118, alignment: .leading)

                Picker("Preferred visibility", selection: $profile.preferredVisibilityState) {
                    ForEach(HidingVisibilityState.allCases, id: \.self) { state in
                        Text(state.profileDisplayName)
                            .tag(state)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("Target Zones")
                        .font(.subheadline)
                        .bold()

                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .help("One mapping per line. Supported zones: visible, hidden, alwaysHidden.")
                }

                TextEditor(text: targetZoneTextBinding)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 112)
                    .padding(6)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.65), in: .rect(cornerRadius: 7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(Color(nsColor: .separatorColor).opacity(0.35))
                    }
                    .focused($isTargetZoneEditorFocused)

                Text("Example: com.example.app=hidden. Supported zones: visible, hidden, alwaysHidden.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var behaviorToggles: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProfileEditorToggleRow(
                title: "Show Second Bar",
                systemImage: "rectangle.bottomthird.inset.filled",
                isOn: $profile.showSecondBar
            )
            Divider()
            ProfileEditorToggleRow(
                title: "Auto-rehide enabled",
                systemImage: "timer",
                isOn: $profile.autoRehideEnabled
            )
            Divider()
            ProfileEditorToggleRow(
                title: "Hover reveal enabled",
                systemImage: "cursorarrow.motionlines",
                isOn: $profile.hoverRevealEnabled
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.3))
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(.subheadline)
                .bold()

            TextEditor(text: $profile.notes)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 72)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.65), in: .rect(cornerRadius: 7))
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color(nsColor: .separatorColor).opacity(0.35))
                }
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

private struct ProfileEditorToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: systemImage)
                .lineLimit(1)
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
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
