import Foundation
import IOKit.ps

@MainActor
protocol InfoTileProvider {
    var id: InfoTileProviderID { get }
    var displayName: String { get }
    var category: InfoTileCategory { get }
    var requiredPermission: InfoTilePermission { get }
    var defaultPriority: Int { get }
    func availability(context: InfoTileContext) -> InfoTileAvailability
    func snapshot(context: InfoTileContext) -> InfoTileSnapshot?
}

@MainActor
final class InfoTileProviderRegistry {
    private var providersByID: [String: any InfoTileProvider] = [:]

    init(registerDefaults: Bool = true) {
        if registerDefaults {
            registerDefaultsProviders()
        }
    }

    func register(_ provider: any InfoTileProvider) {
        providersByID[provider.id.rawValue] = provider
    }

    func provider(id: String) -> (any InfoTileProvider)? {
        providersByID[id]
    }

    func availableProviders(context: InfoTileContext) -> [any InfoTileProvider] {
        providersByID.values
            .filter { $0.availability(context: context).isAvailable }
            .sorted { $0.defaultPriority < $1.defaultPriority }
    }

    func snapshots(for providerIDs: [String], context: InfoTileContext) -> [InfoTileSnapshot] {
        providerIDs.compactMap { providerID in
            guard let provider = providersByID[providerID],
                  provider.availability(context: context).isAvailable else {
                return nil
            }
            return provider.snapshot(context: context)
        }
    }

    private func registerDefaultsProviders() {
        register(WorkspaceNameTileProvider())
        register(ClockTileProvider())
        register(BatteryTileProvider())
        register(HiddenCountTileProvider())
        register(NewItemCountTileProvider())
        register(RecoveryWarningTileProvider())
        register(StaleScanWarningTileProvider())
    }
}

struct WorkspaceNameTileProvider: InfoTileProvider {
    let id = InfoTileProviderID.currentWorkspace
    let displayName = "Current Workspace"
    let category = InfoTileCategory.workspace
    let requiredPermission = InfoTilePermission.none
    let defaultPriority = 10

    func availability(context: InfoTileContext) -> InfoTileAvailability {
        context.activeWorkspace == nil ? .unavailable("No active workspace.") : .available
    }

    func snapshot(context: InfoTileContext) -> InfoTileSnapshot? {
        guard let workspace = context.activeWorkspace else { return nil }
        return InfoTileSnapshot(
            providerID: id.rawValue,
            title: WorkspaceDiagnosticsRedactor.displayName(for: workspace),
            subtitle: "Workspace Preview",
            iconName: workspace.iconName,
            timestamp: context.currentDate,
            action: InfoTileAction(commandID: WorkspaceCommandReference.showWorkspacePreview.actionID, label: "Manage"),
            privacyLevel: workspace.isProtected ? .redactedInDiagnostics : .safeForDiagnostics
        )
    }
}

struct ClockTileProvider: InfoTileProvider {
    let id = InfoTileProviderID.clock
    let displayName = "Clock"
    let category = InfoTileCategory.time
    let requiredPermission = InfoTilePermission.none
    let defaultPriority = 20

    func availability(context: InfoTileContext) -> InfoTileAvailability { .available }

    func snapshot(context: InfoTileContext) -> InfoTileSnapshot? {
        InfoTileSnapshot(
            providerID: id.rawValue,
            title: context.currentDate.formatted(date: .omitted, time: .shortened),
            subtitle: context.currentDate.formatted(date: .abbreviated, time: .omitted),
            iconName: "clock",
            timestamp: context.currentDate
        )
    }
}

struct BatteryTileProvider: InfoTileProvider {
    var batterySummaryProvider: () -> String? = { Self.defaultBatterySummary() }

    let id = InfoTileProviderID.battery
    let displayName = "Battery"
    let category = InfoTileCategory.power
    let requiredPermission = InfoTilePermission.none
    let defaultPriority = 30

    func availability(context: InfoTileContext) -> InfoTileAvailability {
        batterySummaryProvider() == nil ? .unavailable("Battery status is unavailable on this Mac.") : .available
    }

    func snapshot(context: InfoTileContext) -> InfoTileSnapshot? {
        guard let summary = batterySummaryProvider() else { return nil }
        return InfoTileSnapshot(
            providerID: id.rawValue,
            title: "Battery",
            subtitle: summary,
            iconName: "battery.100",
            timestamp: context.currentDate
        )
    }

    private static func defaultBatterySummary() -> String? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any],
                let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int,
                let maxCapacity = description[kIOPSMaxCapacityKey] as? Int,
                maxCapacity > 0 else {
                continue
            }

            let percent = max(0, min(100, Int((Double(currentCapacity) / Double(maxCapacity) * 100).rounded())))
            let powerState = description[kIOPSPowerSourceStateKey] as? String
            let isCharging = powerState == kIOPSACPowerValue
            return isCharging ? "\(percent)% charging" : "\(percent)%"
        }

        return nil
    }
}

struct HiddenCountTileProvider: InfoTileProvider {
    let id = InfoTileProviderID.hiddenCount
    let displayName = "Hidden Count"
    let category = InfoTileCategory.menuBar
    let requiredPermission = InfoTilePermission.none
    let defaultPriority = 40

    func availability(context: InfoTileContext) -> InfoTileAvailability { .available }

    func snapshot(context: InfoTileContext) -> InfoTileSnapshot? {
        let hidden = context.hiddenItemCount ?? 0
        let alwaysHidden = context.alwaysHiddenItemCount ?? 0
        return InfoTileSnapshot(
            providerID: id.rawValue,
            title: "\(hidden) hidden",
            subtitle: "\(alwaysHidden) always hidden",
            iconName: "eye.slash",
            timestamp: context.currentDate,
            action: InfoTileAction(commandID: WorkspaceCommandReference.revealAll.actionID, label: "Reveal All")
        )
    }
}

struct NewItemCountTileProvider: InfoTileProvider {
    let id = InfoTileProviderID.newItemCount
    let displayName = "New Items"
    let category = InfoTileCategory.menuBar
    let requiredPermission = InfoTilePermission.proDiscovery
    let defaultPriority = 50

    func availability(context: InfoTileContext) -> InfoTileAvailability {
        context.proDiscoveryAvailable ? .available : .permissionRequired(.proDiscovery)
    }

    func snapshot(context: InfoTileContext) -> InfoTileSnapshot? {
        InfoTileSnapshot(
            providerID: id.rawValue,
            title: "\(context.newItemCount ?? 0) new",
            subtitle: "Menu bar item inbox",
            iconName: "tray",
            timestamp: context.currentDate,
            action: InfoTileAction(commandID: WorkspaceCommandReference.showWorkspacePreview.actionID, label: "Review")
        )
    }
}

struct RecoveryWarningTileProvider: InfoTileProvider {
    let id = InfoTileProviderID.recoveryWarning
    let displayName = "Recovery Warning"
    let category = InfoTileCategory.health
    let requiredPermission = InfoTilePermission.none
    let defaultPriority = 60

    func availability(context: InfoTileContext) -> InfoTileAvailability { .available }

    func snapshot(context: InfoTileContext) -> InfoTileSnapshot? {
        let count = context.healthWarningCount
        return InfoTileSnapshot(
            providerID: id.rawValue,
            title: count == 0 ? "All clear" : "\(count) warning\(count == 1 ? "" : "s")",
            subtitle: context.safeModeActive ? "Safe Mode active" : "Recovery status",
            iconName: count == 0 ? "checkmark.circle" : "exclamationmark.triangle",
            severity: context.safeModeActive ? .critical : (count == 0 ? .normal : .warning),
            timestamp: context.currentDate,
            action: InfoTileAction(commandID: WorkspaceCommandReference.openRecovery.actionID, label: "Open Recovery")
        )
    }
}

struct StaleScanWarningTileProvider: InfoTileProvider {
    let id = InfoTileProviderID.staleScanWarning
    let displayName = "Stale Scan"
    let category = InfoTileCategory.health
    let requiredPermission = InfoTilePermission.proDiscovery
    let defaultPriority = 70

    func availability(context: InfoTileContext) -> InfoTileAvailability {
        context.proDiscoveryAvailable ? .available : .permissionRequired(.proDiscovery)
    }

    func snapshot(context: InfoTileContext) -> InfoTileSnapshot? {
        let age = context.latestScanAgeSeconds
        let isStale = age.map { $0 > 600 } ?? true
        return InfoTileSnapshot(
            providerID: id.rawValue,
            title: isStale ? "Scan may be stale" : "Scan up to date",
            subtitle: age.map { "\($0)s old" },
            iconName: isStale ? "clock.badge.exclamationmark" : "checkmark.circle",
            severity: isStale ? .warning : .normal,
            timestamp: context.currentDate
        )
    }
}
