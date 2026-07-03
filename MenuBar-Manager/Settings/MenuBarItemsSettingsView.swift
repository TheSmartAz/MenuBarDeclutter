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
    @State private var visibleSnapshots: [MenuBarItemSnapshot] = []

    private var snapshots: [MenuBarItemSnapshot] {
        liveStatus?.scannedMenuBarItems ?? []
    }

    private var selectedSnapshot: MenuBarItemSnapshot? {
        guard let selectedSnapshotID else { return visibleSnapshots.first }
        return visibleSnapshots.first { $0.id == selectedSnapshotID }
    }

    private var permissionStatus: AccessibilityPermissionStatus {
        liveStatus?.accessibilityPermissionStatus ?? .notRequested
    }

    private var discoveryPresentation: MenuBarItemsDiscoveryPresentation {
        if !settingsStore.proModeEnabled {
            return MenuBarItemsDiscoveryPresentation(
                title: "Basic Mode",
                subtitle: "Discovery is off because Pro Mode is disabled. Basic Mode remains fully usable.",
                systemImage: "hand.raised.slash",
                style: .secondary
            )
        }

        if !settingsStore.accessibilityDiscoveryEnabled {
            return MenuBarItemsDiscoveryPresentation(
                title: "Discovery Off",
                subtitle: "Enable Accessibility Discovery in Privacy settings to build a local item snapshot.",
                systemImage: "eye.slash",
                style: .warning
            )
        }

        if permissionStatus != .granted {
            return MenuBarItemsDiscoveryPresentation(
                title: permissionStatus.displayName,
                subtitle: "Accessibility permission is required before Pro item discovery can inspect the menu bar.",
                systemImage: "lock",
                style: .warning
            )
        }

        return MenuBarItemsDiscoveryPresentation(
            title: "Ready",
            subtitle: "Pro discovery can refresh the current local menu bar snapshot.",
            systemImage: "checkmark.circle",
            style: .success
        )
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
            subtitle: "Inspect the current local Accessibility discovery snapshot.",
            badges: [.stable, .proMode, .accessibilityRequired],
            sectionAnchors: [
                ClearGlassPageAnchor("Snapshot", systemImage: "camera.metering.matrix"),
                ClearGlassPageAnchor("Items", systemImage: "list.bullet.rectangle")
            ]
        ) {
            MenuBarItemsSummaryStrip(liveStatus: liveStatus, snapshots: snapshots)

            ClearGlassSection("Snapshot", subtitle: scanStatusText) {
                ClearGlassControlRow(
                    systemImage: discoveryPresentation.systemImage,
                    title: "Discovery State",
                    subtitle: discoveryPresentation.subtitle,
                    iconTint: discoveryPresentation.style.tint
                ) {
                    ClearGlassStatusValue(
                        text: discoveryPresentation.title,
                        style: discoveryPresentation.style
                    )
                }

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

                snapshotStateMessage
            }

            ClearGlassSection("Items", subtitle: "Select a source item to inspect owner, zone, and geometry.") {
                if snapshots.isEmpty {
                    MenuBarItemsUnavailableView(
                        hasSnapshots: false,
                        proModeEnabled: settingsStore.proModeEnabled,
                        discoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
                        permissionStatus: permissionStatus,
                        onOpenPrivacySettings: onOpenPrivacySettings
                    )
                } else {
                        ClearGlassPaneLayout(primaryWidth: 280, spacing: 0) {
                            MenuBarItemsSourcePane(
                                snapshots: visibleSnapshots,
                                totalCount: snapshots.count,
                                searchText: $searchText,
                                selectedFilter: $selectedFilter,
                                selectedSnapshotID: $selectedSnapshotID
                        )
                        .frame(minHeight: 320, maxHeight: 430)
                    } detail: {
                        MenuBarItemInspector(
                            snapshot: selectedSnapshot,
                            onRefresh: {
                                scanCoordinator?.requestManualRefresh()
                            }
                        )
                        .frame(minHeight: 320)
                    }
                    .frame(minHeight: 430)
                    .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
                    }
                }
            }
        }
        .onAppear(perform: refreshVisibleSnapshots)
        .onChange(of: snapshots) { _, _ in
            refreshVisibleSnapshots()
        }
        .onChange(of: searchText) { _, _ in
            refreshVisibleSnapshots()
        }
        .onChange(of: selectedFilter) { _, _ in
            refreshVisibleSnapshots()
        }
    }

    @ViewBuilder
    private var snapshotStateMessage: some View {
        if !settingsStore.proModeEnabled {
            ClearGlassInlineMessage(
                text: "Menu bar item discovery is opt-in Pro functionality. Basic Mode does not request Accessibility permission.",
                systemImage: "hand.raised.slash",
                style: .secondary
            )
        } else if !settingsStore.accessibilityDiscoveryEnabled {
            ClearGlassInlineMessage(
                text: "Accessibility Discovery is off. Turn it on from Privacy settings when you want local item inspection.",
                systemImage: "eye.slash",
                style: .warning
            )
        } else if permissionStatus != .granted {
            ClearGlassInlineMessage(
                text: "Accessibility permission is \(permissionStatus.displayName.lowercased()). Grant it from Privacy settings to refresh item snapshots.",
                systemImage: "lock",
                style: .warning
            )
        } else if snapshots.isEmpty, let lastSkipReason = scanCoordinator?.lastSkipReason {
            ClearGlassInlineMessage(
                text: lastSkipReason,
                systemImage: "info.circle",
                style: .info
            )
        }
    }

    private func refreshVisibleSnapshots() {
        let nextSnapshots = Self.filteredSnapshots(
            from: snapshots,
            selectedFilter: selectedFilter,
            searchText: searchText
        )
        if visibleSnapshots != nextSnapshots {
            visibleSnapshots = nextSnapshots
        }
        reconcileSelection(in: nextSnapshots)
    }

    private func reconcileSelection(in snapshots: [MenuBarItemSnapshot]) {
        guard !snapshots.isEmpty else {
            selectedSnapshotID = nil
            return
        }

        if let selectedSnapshotID,
           snapshots.contains(where: { $0.id == selectedSnapshotID }) {
            return
        }

        selectedSnapshotID = snapshots.first?.id
    }

    private static func filteredSnapshots(
        from snapshots: [MenuBarItemSnapshot],
        selectedFilter: MenuBarItemsFilter,
        searchText: String
    ) -> [MenuBarItemSnapshot] {
        let filteredByZone = snapshots.filter { selectedFilter.includes($0) }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return filteredByZone
        }

        return filteredByZone.filter { snapshot in
            snapshot.searchText.localizedStandardContains(query)
        }
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
            "All Items"
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

private struct MenuBarItemsDiscoveryPresentation {
    let title: String
    let subtitle: String
    let systemImage: String
    let style: ClearGlassStatusStyle
}

private struct MenuBarItemsSummaryStrip: View {
    var liveStatus: LiveDiagnosticsStatus?
    let snapshots: [MenuBarItemSnapshot]

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            MenuBarItemsMetric(
                title: "Total",
                value: snapshots.count,
                systemImage: "list.bullet.rectangle"
            )
            MenuBarItemsMetric(
                title: "Visible",
                value: liveStatus?.menuBarScanVisibleCount ?? zoneCount(.visible),
                systemImage: "eye",
                style: .success
            )
            MenuBarItemsMetric(
                title: "Hidden",
                value: liveStatus?.menuBarScanHiddenCount ?? zoneCount(.hidden),
                systemImage: "eye.slash",
                style: .warning
            )
            MenuBarItemsMetric(
                title: "Always Hidden",
                value: liveStatus?.menuBarScanAlwaysHiddenCount ?? zoneCount(.alwaysHidden),
                systemImage: "lock",
                style: .danger
            )
            MenuBarItemsMetric(
                title: "Unknown",
                value: liveStatus?.menuBarScanUnknownCount ?? zoneCount(.unknown),
                systemImage: "questionmark.circle",
                style: .secondary
            )
        }
    }

    private func zoneCount(_ zone: MenuBarZone) -> Int {
        snapshots.filter { $0.zone == zone }.count
    }
}

private struct MenuBarItemsMetric: View {
    let title: String
    let value: Int
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

                Text(value, format: .number)
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
        .accessibilityElement(children: .combine)
    }
}

private struct MenuBarItemsSourcePane: View {
    let snapshots: [MenuBarItemSnapshot]
    let totalCount: Int
    @Binding var searchText: String
    @Binding var selectedFilter: MenuBarItemsFilter
    @Binding var selectedSnapshotID: MenuBarItemSnapshot.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuBarItemsSourceToolbar(
                searchText: $searchText,
                selectedFilter: $selectedFilter,
                visibleCount: snapshots.count,
                totalCount: totalCount
            )

            Divider()

            ScrollView {
                if snapshots.isEmpty {
                    SettingsUnavailableGate(
                        .noMatches,
                        title: "No Matching Items",
                        message: "Try a different filter or search term.",
                        systemImage: "line.3.horizontal.decrease.circle",
                        minHeight: 260
                    )
                    .frame(maxWidth: .infinity, minHeight: 260)
                } else {
                    LazyVStack(spacing: 6) {
                        ForEach(snapshots) { snapshot in
                            MenuBarItemSourceRow(
                                snapshot: snapshot,
                                isSelected: snapshot.id == selectedSnapshotID
                            ) {
                                selectedSnapshotID = snapshot.id
                            }
                        }
                    }
                    .padding(6)
                }
            }
        }
    }
}

private struct MenuBarItemsSourceToolbar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: MenuBarItemsFilter
    let visibleCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Label("Source List", systemImage: "sidebar.left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Text("\(visibleCount) of \(totalCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            SearchField("Search Items", text: $searchText)

            Picker("Filter", selection: $selectedFilter) {
                ForEach(MenuBarItemsFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
    }
}

private struct MenuBarItemSourceRow: View {
    let snapshot: MenuBarItemSnapshot
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                AppIconView(snapshot: snapshot, size: 28, cornerRadius: 7)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(snapshot.displayTitle)
                            .font(.body)
                            .lineLimit(1)

                        Image(systemName: snapshot.isLikelySystemItem ? "apple.logo" : "app")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(snapshot.sourceSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                MenuBarZoneTextBadge(zone: snapshot.zone)
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

    private var rowBackground: Color {
        isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor).opacity(0.35)
    }

    private var rowStroke: Color {
        isSelected ? Color.accentColor.opacity(0.42) : Color(nsColor: .separatorColor).opacity(0.24)
    }
}

private struct MenuBarZoneTextBadge: View {
    let zone: MenuBarZone

    var body: some View {
        Text(zone.displayName)
            .font(.caption2)
            .foregroundStyle(zone.statusStyle.foreground)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(zone.statusStyle.background, in: .capsule)
            .overlay {
                Capsule()
                    .stroke(zone.statusStyle.border, lineWidth: 0.5)
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

                MenuBarInspectorGroup("Identity") {
                    MenuBarInspectorRow("Zone", value: snapshot.zone.displayName, style: snapshot.zone.statusStyle)
                    MenuBarInspectorRow("Kind", value: snapshot.isLikelySystemItem ? "System Item" : "App Item")
                    MenuBarInspectorRow("App", value: snapshot.owningApplicationName ?? "Unknown")
                    MenuBarInspectorRow("Bundle", value: snapshot.bundleIdentifier ?? "-", monospaced: true)
                    MenuBarInspectorRow("Role", value: snapshot.role ?? "-")
                    MenuBarInspectorRow("Subrole", value: snapshot.subrole ?? "-")
                }

                MenuBarInspectorGroup("Geometry") {
                    MenuBarInspectorRow("Frame", value: snapshot.frameDescription, monospaced: true)
                    MenuBarInspectorRow("Process ID", value: snapshot.processDescription, monospaced: true)
                    MenuBarInspectorRow("Last Seen", value: snapshot.scanTimestamp.formatted(date: .omitted, time: .standard))
                }

                Button("Refresh Snapshot", systemImage: "arrow.clockwise", action: onRefresh)
                    .controlSize(.small)
            } else {
                SettingsUnavailableGate(
                    .emptyData,
                    title: "No Item Selected",
                    message: "Select an item in the source list to inspect its owner, zone, and geometry.",
                    systemImage: "sidebar.right",
                    minHeight: 260
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private func inspectorHeader(_ snapshot: MenuBarItemSnapshot) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                inspectorIdentity(snapshot)

                ClearGlassStatusValue(text: snapshot.zone.displayName, style: snapshot.zone.statusStyle)
            }

            VStack(alignment: .leading, spacing: 8) {
                inspectorIdentity(snapshot)
                ClearGlassStatusValue(text: snapshot.zone.displayName, style: snapshot.zone.statusStyle)
            }
        }
    }

    private func inspectorIdentity(_ snapshot: MenuBarItemSnapshot) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AppIconView(snapshot: snapshot, size: 40, cornerRadius: 9)

            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.displayTitle)
                    .font(.headline)
                    .lineLimit(2)

                Text(snapshot.owningApplicationName ?? "Unknown app")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MenuBarInspectorGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
            }
        }
    }
}

private struct MenuBarInspectorRow: View {
    let title: String
    let value: String
    var style: ClearGlassStatusStyle?
    var monospaced = false

    init(
        _ title: String,
        value: String,
        style: ClearGlassStatusStyle? = nil,
        monospaced: Bool = false
    ) {
        self.title = title
        self.value = value
        self.style = style
        self.monospaced = monospaced
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .leading)

            if let style {
                ClearGlassStatusValue(text: value, style: style)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Text(value)
                    .font(monospaced ? .system(.caption, design: .monospaced) : .callout)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct MenuBarItemsUnavailableView: View {
    let hasSnapshots: Bool
    let proModeEnabled: Bool
    let discoveryEnabled: Bool
    let permissionStatus: AccessibilityPermissionStatus
    var onOpenPrivacySettings: (() -> Void)?

    var body: some View {
        SettingsUnavailableGate(
            hasSnapshots ? .noMatches : unavailableReason,
            title: title,
            message: message,
            systemImage: systemImage,
            minHeight: 320,
            showsActions: onOpenPrivacySettings != nil
        ) {
            if onOpenPrivacySettings != nil {
                Button("Open Privacy Settings", systemImage: "hand.raised") {
                    onOpenPrivacySettings?()
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var unavailableReason: SettingsUnavailableReason {
        if !proModeEnabled {
            return .proModeDisabled
        }

        if !discoveryEnabled {
            return .previewDisabled
        }

        if permissionStatus != .granted {
            return .permissionMissing(status: permissionStatus.displayName)
        }

        return .emptyData
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

    var sourceSubtitle: String {
        for value in [owningApplicationName, bundleIdentifier, role] {
            if let value, !value.isEmpty {
                return value
            }
        }

        return "Unknown owner"
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
