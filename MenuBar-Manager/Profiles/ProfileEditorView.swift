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
            identitySection
            visibilitySection
            behaviorSection
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

    private var identitySection: some View {
        ProfileEditorSection("Identity") {
            ProfileEditorRow(title: "Name", systemImage: "textformat") {
                TextField("Name", text: $profile.name)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var visibilitySection: some View {
        ProfileEditorSection("Visibility & Zones") {
            ProfileEditorRow(title: "Preferred Visibility", systemImage: "eye") {
                Picker("Preferred Visibility", selection: $profile.preferredVisibilityState) {
                    ForEach(HidingVisibilityState.allCases, id: \.self) { state in
                        Text(state.profileDisplayName)
                            .tag(state)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)
            }

            profileEditorDivider

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .frame(width: 22)

                    Text("Target Zones")

                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .help("One mapping per line. Supported zones: visible, hidden, alwaysHidden.")

                    Spacer()

                    Text("\(profile.targetZonesByBundleID.count) mapping\(profile.targetZonesByBundleID.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextEditor(text: targetZoneTextBinding)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 112)
                    .padding(6)
                    .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 0.5)
                    }
                    .focused($isTargetZoneEditorFocused)
            }
            .padding(.vertical, 8)
        }
    }

    private var behaviorSection: some View {
        ProfileEditorSection("Behavior") {
            ProfileEditorToggleRow(
                title: "Show Second Bar",
                systemImage: "rectangle.bottomthird.inset.filled",
                isOn: $profile.showSecondBar
            )

            profileEditorDivider

            ProfileEditorToggleRow(
                title: "Auto-rehide Enabled",
                systemImage: "timer",
                isOn: $profile.autoRehideEnabled
            )

            profileEditorDivider

            ProfileEditorToggleRow(
                title: "Hover Reveal Enabled",
                systemImage: "cursorarrow.motionlines",
                isOn: $profile.hoverRevealEnabled
            )
        }
    }

    private var notesSection: some View {
        ProfileEditorSection("Notes") {
            TextEditor(text: $profile.notes)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 72)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 7))
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 0.5)
                }
                .padding(.vertical, 8)
        }
    }

    private var profileEditorDivider: some View {
        Divider()
            .padding(.leading, 34)
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

private struct ProfileEditorSection<Content: View>: View {
    private let title: String
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
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
}

private struct ProfileEditorRow<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                rowLabel
                    .frame(width: 190, alignment: .leading)

                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 8) {
                rowLabel
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 8)
    }

    private var rowLabel: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(title)
                .lineLimit(1)
        }
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
