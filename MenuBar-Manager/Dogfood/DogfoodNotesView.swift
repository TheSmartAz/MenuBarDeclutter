import SwiftUI

struct DogfoodNotesView: View {
    @Bindable var settingsStore: SettingsStore
    @Bindable var dogfoodStore: DogfoodStore
    let onExportBundle: () -> Void

    @State private var noteText = ""

    private var activeRunID: String? {
        settingsStore.dogfoodRunID
    }

    private var canAddNote: Bool {
        settingsStore.dogfoodNotesEnabled
            && activeRunID != nil
            && !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if let error = dogfoodStore.lastError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            controls

            if settingsStore.dogfoodModeEnabled {
                checklist
                notesSection
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .onAppear {
            dogfoodStore.loadRun(id: settingsStore.dogfoodRunID)
        }
        .onChange(of: settingsStore.dogfoodRunID) { _, newValue in
            dogfoodStore.loadRun(id: newValue)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label("Dogfood", systemImage: "checklist")
                .font(.headline)

            Text(activeRunID ?? "No active run")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Spacer()

            Toggle("Mode", isOn: $settingsStore.dogfoodModeEnabled)
                .toggleStyle(.switch)
        }
        .padding(.top, 4)
    }

    private var controls: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                buttons
                notesToggle
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    buttons
                }
                notesToggle
            }
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private var buttons: some View {
        Button("Start Dogfood Run", systemImage: "play") {
            startRun()
        }

        Button("End Dogfood Run", systemImage: "stop") {
            endRun()
        }
        .disabled(activeRunID == nil)

        Button("Export Dogfood Bundle", systemImage: "shippingbox") {
            onExportBundle()
        }
        .disabled(!settingsStore.dogfoodModeEnabled)
    }

    private var notesToggle: some View {
        Toggle("Notes", isOn: $settingsStore.dogfoodNotesEnabled)
            .toggleStyle(.checkbox)
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(DogfoodGate.allCases) { gate in
                DisclosureGroup(gate.title) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(dogfoodStore.checklistItems(for: gate)) { item in
                            DogfoodChecklistRow(
                                item: item,
                                isEditable: dogfoodStore.currentRun != nil,
                                onChange: { result in
                                    updateChecklistItem(item, result: result)
                                }
                            )
                        }
                    }
                    .padding(.leading, 8)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Add local note", text: $noteText, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!settingsStore.dogfoodNotesEnabled || activeRunID == nil)

                Button("Add Note", systemImage: "plus") {
                    addNote()
                }
                .disabled(!canAddNote)
            }

            ForEach(dogfoodStore.notes.suffix(3)) { note in
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.createdAt.formatted(date: .abbreviated, time: .standard))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(note.text)
                        .font(.caption)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func startRun() {
        do {
            let run = try dogfoodStore.startRun()
            settingsStore.dogfoodModeEnabled = true
            settingsStore.dogfoodRunID = run.id
        } catch {
            dogfoodStore.lastError = error.localizedDescription
        }
    }

    private func endRun() {
        do {
            _ = try dogfoodStore.endCurrentRun()
            settingsStore.dogfoodRunID = nil
        } catch {
            dogfoodStore.lastError = error.localizedDescription
        }
    }

    private func addNote() {
        guard let activeRunID else { return }
        do {
            _ = try dogfoodStore.addNote(runID: activeRunID, text: noteText)
            noteText = ""
        } catch {
            dogfoodStore.lastError = error.localizedDescription
        }
    }

    private func updateChecklistItem(_ item: DogfoodChecklistItem, result: DogfoodChecklistResult) {
        do {
            try dogfoodStore.updateChecklistItem(id: item.id, result: result)
        } catch {
            dogfoodStore.lastError = error.localizedDescription
        }
    }
}

private struct DogfoodChecklistRow: View {
    let item: DogfoodChecklistItem
    let isEditable: Bool
    let onChange: @MainActor @Sendable (DogfoodChecklistResult) -> Void

    var body: some View {
        HStack {
            Text(item.title)
                .font(.caption)

            Spacer()

            Picker("Result", selection: resultBinding) {
                ForEach(DogfoodChecklistResult.allCases) { result in
                    Text(result.displayName)
                        .tag(result)
                }
            }
            .labelsHidden()
            .frame(width: 130)
            .disabled(!isEditable)
        }
    }

    private var resultBinding: Binding<DogfoodChecklistResult> {
        Binding(
            get: { item.result },
            set: { result in
                onChange(result)
            }
        )
    }
}
