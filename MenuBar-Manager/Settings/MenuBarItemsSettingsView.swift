import CoreGraphics
import SwiftUI

struct MenuBarItemsSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var liveStatus: LiveDiagnosticsStatus?
    var scanCoordinator: MenuBarScanCoordinator?
    var onOpenPrivacySettings: (() -> Void)?

    @State private var selectedSnapshotID: MenuBarItemSnapshot.ID?
    @State private var searchText = ""
    @State private var selectedFilter: MenuBarItemsFilter = .all

    private var snapshots: [MenuBarItemSnapshot] {
        liveStatus?.scannedMenuBarItems ?? []
    }

    private var filteredSnapshots: [MenuBarItemSnapshot] {
        let filteredByZone = snapshots.filter { selectedFilter.includes($0) }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return filteredByZone
        }

        return filteredByZone.filter { snapshot in
            snapshot.searchText.localizedStandardContains(query)
        }
    }

    private var selectedSnapshot: MenuBarItemSnapshot? {
        guard let selectedSnapshotID else { return nil }
        return snapshots.first { $0.id == selectedSnapshotID }
    }

    private var scanStatusText: String {
        if let lastMenuBarScanTime = liveStatus?.lastMenuBarScanTime {
            return "Last scanned \(lastMenuBarScanTime.formatted(date: .omitted, time: .standard))"
        }

        return scanCoordinator?.lastSkipReason ?? "No scan yet"
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Menu Bar Items",
            subtitle: "Inspect the current local menu bar discovery snapshot.",
            badges: [.stable, .proMode, .accessibilityRequired]
        ) {
            ClearGlassSection("Snapshot", subtitle: scanStatusText) {
                MenuBarItemsSummaryStrip(liveStatus: liveStatus, snapshots: snapshots)

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "arrow.clockwise",
                    title: "Refresh Snapshot",
                    subtitle: "Refresh the local Accessibility discovery index when Pro Mode is enabled."
                ) {
                    HStack(spacing: 10) {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            scanCoordinator?.requestManualRefresh()
                        }
                        .disabled(scanCoordinator?.canScan != true)

                        Button("Privacy Settings", systemImage: "hand.raised") {
                            onOpenPrivacySettings?()
                        }
                    }
                }
            }

            ClearGlassSection("Items", subtitle: "Use the table to compare ownership and zone, then inspect details on the right.") {
                MenuBarItemsToolbar(
                    searchText: $searchText,
                    selectedFilter: $selectedFilter
                )

                ClearGlassDivider()

                if filteredSnapshots.isEmpty {
                    MenuBarItemsUnavailableView(
                        hasSnapshots: snapshots.isEmpty == false,
                        proModeEnabled: settingsStore.proModeEnabled,
                        discoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
                        permissionStatus: liveStatus?.accessibilityPermissionStatus ?? .notRequested,
                        onOpenPrivacySettings: onOpenPrivacySettings
                    )
                } else {
                    HStack(spacing: 0) {
                        MenuBarItemsTable(
                            snapshots: filteredSnapshots,
                            selectedSnapshotID: $selectedSnapshotID
                        )
                        .frame(minHeight: 360)

                        Divider()

                        MenuBarItemInspector(
                            snapshot: selectedSnapshot,
                            onRefresh: {
                                scanCoordinator?.requestManualRefresh()
                            }
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
        .onAppear(perform: reconcileSelection)
        .onChange(of: filteredSnapshots.map(\.id)) {
            reconcileSelection()
        }
    }

    private func reconcileSelection() {
        guard filteredSnapshots.isEmpty == false else {
            selectedSnapshotID = nil
            return
        }

        if let selectedSnapshotID,
           filteredSnapshots.contains(where: { $0.id == selectedSnapshotID }) {
            return
        }

        selectedSnapshotID = filteredSnapshots.first?.id
    }
}

private enum MenuBarItemsFilter: String, CaseIterable, Identifiable {
    case all
    case visible
    case hidden
    case alwaysHidden
    case system
    case app

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "All"
        case .visible:
            "Visible"
        case .hidden:
            "Hidden"
        case .alwaysHidden:
            "Always Hidden"
        case .system:
            "System"
        case .app:
            "Apps"
        }
    }

    func includes(_ snapshot: MenuBarItemSnapshot) -> Bool {
        switch self {
        case .all:
            true
        case .visible:
            snapshot.zone == .visible
        case .hidden:
            snapshot.zone == .hidden
        case .alwaysHidden:
            snapshot.zone == .alwaysHidden
        case .system:
            snapshot.isLikelySystemItem
        case .app:
            snapshot.isLikelySystemItem == false
        }
    }
}

private struct MenuBarItemsSummaryStrip: View {
    var liveStatus: LiveDiagnosticsStatus?
    let snapshots: [MenuBarItemSnapshot]

    private let columns = [
        GridItem(.adaptive(minimum: 128), spacing: 14)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            MenuBarItemsMetric(
                title: "Total",
                value: snapshots.count,
                systemImage: "list.bullet.rectangle"
            )
            MenuBarItemsMetric(
                title: "Visible",
                value: liveStatus?.menuBarScanVisibleCount ?? zoneCount(.visible),
                systemImage: "eye",
                tone: .privacySafe
            )
            MenuBarItemsMetric(
                title: "Hidden",
                value: liveStatus?.menuBarScanHiddenCount ?? zoneCount(.hidden),
                systemImage: "eye.slash",
                tone: .experimental
            )
            MenuBarItemsMetric(
                title: "Always Hidden",
                value: liveStatus?.menuBarScanAlwaysHiddenCount ?? zoneCount(.alwaysHidden),
                systemImage: "lock",
                tone: .destructive
            )
            MenuBarItemsMetric(
                title: "Unknown",
                value: liveStatus?.menuBarScanUnknownCount ?? zoneCount(.unknown),
                systemImage: "questionmark.circle",
                tone: .disabled
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func zoneCount(_ zone: MenuBarZone) -> Int {
        snapshots.filter { $0.zone == zone }.count
    }
}

private struct MenuBarItemsMetric: View {
    let title: String
    let value: Int
    let systemImage: String
    var tone: DesignTokens.SemanticTone = .neutral

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .foregroundStyle(tone.foregroundStyle)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(value, format: .number)
                    .font(.title3.monospacedDigit())

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct MenuBarItemsToolbar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: MenuBarItemsFilter

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                filterPicker

                Spacer(minLength: 16)

                searchField
            }

            VStack(alignment: .leading, spacing: 8) {
                filterPicker
                searchField
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(MenuBarItemsFilter.allCases) { filter in
                Text(filter.title)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .frame(minWidth: 360, idealWidth: 500, maxWidth: 500)
    }

    private var searchField: some View {
        SearchField("Search Items", text: $searchText, width: 240)
    }
}

private struct MenuBarItemsTable: View {
    let snapshots: [MenuBarItemSnapshot]
    @Binding var selectedSnapshotID: MenuBarItemSnapshot.ID?

    var body: some View {
        Table(snapshots, selection: $selectedSnapshotID) {
            TableColumn("Item") { snapshot in
                MenuBarItemTitleCell(snapshot: snapshot)
            }
            .width(min: 190, ideal: 220)

            TableColumn("App") { snapshot in
                Text(snapshot.owningApplicationName ?? "-")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .width(min: 120, ideal: 150)

            TableColumn("Zone") { snapshot in
                Text(snapshot.zone.displayName)
                    .foregroundStyle(snapshot.zone.statusStyle.foreground)
                    .lineLimit(1)
            }
            .width(min: 95, ideal: 120)

        }
    }
}

private struct MenuBarItemTitleCell: View {
    let snapshot: MenuBarItemSnapshot

    var body: some View {
        HStack(spacing: 8) {
            AppIconView(snapshot: snapshot, size: 20, cornerRadius: 5)

            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.displayTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(snapshot.bundleIdentifier ?? snapshot.role ?? "Unknown owner")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}

private struct MenuBarItemInspector: View {
    let snapshot: MenuBarItemSnapshot?
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let snapshot {
                inspectorHeader(snapshot)

                Divider()

                inspectorValue("Zone", value: snapshot.zone.displayName, style: snapshot.zone.statusStyle)
                inspectorValue("Kind", value: snapshot.isLikelySystemItem ? "System Item" : "App Item")
                inspectorValue("App", value: snapshot.owningApplicationName ?? "Unknown")
                inspectorValue("Bundle", value: snapshot.bundleIdentifier ?? "-", monospaced: true)
                inspectorValue("Role", value: snapshot.role ?? "-")
                inspectorValue("Subrole", value: snapshot.subrole ?? "-")
                inspectorValue("Frame", value: snapshot.frameDescription, monospaced: true)
                inspectorValue("Process ID", value: snapshot.processDescription, monospaced: true)
                inspectorValue("Last Seen", value: snapshot.scanTimestamp.formatted(date: .omitted, time: .standard))

                Divider()

                Button("Refresh Snapshot", systemImage: "arrow.clockwise", action: onRefresh)
                    .controlSize(.small)
            } else {
                ContentUnavailableView(
                    "No Item Selected",
                    systemImage: "sidebar.right",
                    description: Text("Select an item in the table to inspect its owner, zone, and geometry.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private func inspectorHeader(_ snapshot: MenuBarItemSnapshot) -> some View {
        HStack(alignment: .top, spacing: 10) {
            AppIconView(snapshot: snapshot, size: 32, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(snapshot.displayTitle)
                    .font(.headline)
                    .lineLimit(2)

                Text(snapshot.owningApplicationName ?? "Unknown app")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private func inspectorValue(
        _ title: String,
        value: String,
        style: ClearGlassStatusStyle? = nil,
        monospaced: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let style {
                ClearGlassStatusValue(text: value, style: style)
            } else {
                Text(value)
                    .font(monospaced ? .system(.caption, design: .monospaced) : .callout)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MenuBarItemsUnavailableView: View {
    let hasSnapshots: Bool
    let proModeEnabled: Bool
    let discoveryEnabled: Bool
    let permissionStatus: AccessibilityPermissionStatus
    var onOpenPrivacySettings: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if onOpenPrivacySettings != nil {
                Button("Open Privacy Settings", systemImage: "hand.raised") {
                    onOpenPrivacySettings?()
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var title: String {
        if hasSnapshots {
            "No Matching Items"
        } else {
            "No Menu Bar Items"
        }
    }

    private var systemImage: String {
        hasSnapshots ? "line.3.horizontal.decrease.circle" : "menubar.rectangle"
    }

    private var message: String {
        if hasSnapshots {
            return "Try a different filter or search term."
        }

        if !proModeEnabled {
            return "Menu bar item discovery is a Pro Mode feature. Basic Mode still works without this snapshot."
        }

        if !discoveryEnabled {
            return "Accessibility Discovery is off. Enable it in Privacy settings to build a local snapshot."
        }

        if permissionStatus != .granted {
            return "Accessibility permission is \(permissionStatus.displayName.lowercased()). Grant permission to inspect menu bar items locally."
        }

        return "Refresh the snapshot to inspect discovered menu bar items."
    }
}

private extension MenuBarItemSnapshot {
    var displayTitle: String {
        if let title, title.isEmpty == false {
            return title
        }

        if let owningApplicationName, owningApplicationName.isEmpty == false {
            return owningApplicationName
        }

        return "Untitled Item"
    }

    var searchText: String {
        [
            title,
            owningApplicationName,
            bundleIdentifier,
            role,
            subrole,
            zone.displayName,
            isLikelySystemItem ? "System" : "App"
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }

    var frameDescription: String {
        guard let frame else { return "-" }
        return "x \(Int(frame.origin.x)), y \(Int(frame.origin.y)), \(Int(frame.width)) x \(Int(frame.height))"
    }

    var processDescription: String {
        owningProcessIdentifier.map(String.init) ?? "-"
    }
}

private extension MenuBarZone {
    var statusStyle: ClearGlassStatusStyle {
        switch self {
        case .visible:
            .success
        case .hidden:
            .warning
        case .alwaysHidden:
            .danger
        case .unknown:
            .secondary
        }
    }
}

#Preview {
    MenuBarItemsSettingsView(
        settingsStore: SettingsStore(),
        liveStatus: LiveDiagnosticsStatus()
    )
}
