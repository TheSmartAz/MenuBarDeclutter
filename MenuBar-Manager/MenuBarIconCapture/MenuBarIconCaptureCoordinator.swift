import Foundation

@MainActor
final class MenuBarIconCaptureCoordinator {
    private let settingsStore: SettingsStore
    private let permissionService: ScreenCapturePermissionService
    private let diagnosticsLogger: DiagnosticsLogger
    private let cache: MenuBarRenderedIconCache
    private let visibleCapturer: MenuBarVisibleIconCapturer
    private let currentVisibilityProvider: () -> HidingVisibilityState
    private let setVisibility: (HidingVisibilityState) -> Void
    private let refreshSnapshots: () async -> [MenuBarItemSnapshot]
    private var visibleCaptureTask: Task<Void, Never>?
    private var revealSweepTask: Task<Void, Never>?

    init(
        settingsStore: SettingsStore,
        permissionService: ScreenCapturePermissionService,
        diagnosticsLogger: DiagnosticsLogger,
        cache: MenuBarRenderedIconCache,
        visibleCapturer: MenuBarVisibleIconCapturer = MenuBarVisibleIconCapturer(),
        currentVisibilityProvider: @escaping () -> HidingVisibilityState,
        setVisibility: @escaping (HidingVisibilityState) -> Void,
        refreshSnapshots: @escaping () async -> [MenuBarItemSnapshot]
    ) {
        self.settingsStore = settingsStore
        self.permissionService = permissionService
        self.diagnosticsLogger = diagnosticsLogger
        self.cache = cache
        self.visibleCapturer = visibleCapturer
        self.currentVisibilityProvider = currentVisibilityProvider
        self.setVisibility = setVisibility
        self.refreshSnapshots = refreshSnapshots
    }

    var canCaptureRenderedIcons: Bool {
        settingsStore.renderedIconCaptureEnabled
            && permissionService.refreshStatus() == .granted
    }

    func refreshVisibleIconsIfAllowed(
        snapshots: [MenuBarItemSnapshot],
        reason: String
    ) {
        guard canCaptureRenderedIcons else { return }
        let visibleSnapshots = snapshots.filter { $0.frame != nil && $0.zone == .visible }
        guard !visibleSnapshots.isEmpty else { return }

        visibleCaptureTask?.cancel()
        visibleCaptureTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let captured = await self.visibleCapturer.captureVisibleIcons(snapshots: visibleSnapshots)
            guard !Task.isCancelled else { return }
            for iconSnapshot in captured {
                self.cache.cache(iconSnapshot)
            }
            self.diagnosticsLogger.log(
                "Rendered icon capture refreshed \(captured.count) visible item thumbnail(s) for \(reason).",
                level: .debug,
                category: .scan
            )
            self.visibleCaptureTask = nil
        }
    }

    func refreshHiddenIconsViaRevealSweepIfAllowed(reason: String) {
        guard settingsStore.renderedIconCaptureEnabled,
              settingsStore.renderedIconRevealSweepEnabled,
              permissionService.refreshStatus() == .granted else {
            return
        }

        _ = startRevealSweepCapture(
            startMessage: "Rendered icon reveal-sweep capture started for \(reason).",
            finishedMessage: { "Rendered icon reveal-sweep capture refreshed \($0) thumbnail(s)." }
        )
    }

    @discardableResult
    func warmUpSecondBarIconsIfAllowed(reason: String) -> Bool {
        guard settingsStore.renderedIconCaptureEnabled,
              permissionService.refreshStatus() == .granted else {
            return false
        }

        return startRevealSweepCapture(
            startMessage: "Rendered icon Second Bar warm-up started for \(reason).",
            finishedMessage: { "Rendered icon Second Bar warm-up refreshed \($0) thumbnail(s)." }
        )
    }

    @discardableResult
    private func startRevealSweepCapture(
        startMessage: String,
        finishedMessage: @escaping (Int) -> String
    ) -> Bool {
        revealSweepTask?.cancel()
        revealSweepTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let previousVisibility = self.currentVisibilityProvider()
            defer {
                self.setVisibility(previousVisibility)
                self.revealSweepTask = nil
            }

            self.diagnosticsLogger.log(
                startMessage,
                level: .debug,
                category: .scan
            )

            self.setVisibility(.revealAll)
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }

            let snapshots = await self.refreshSnapshots()
            let capturableSnapshots = snapshots.filter { $0.frame != nil }
            let captured = await self.visibleCapturer.captureVisibleIcons(snapshots: capturableSnapshots)
            guard !Task.isCancelled else { return }

            for iconSnapshot in captured {
                self.cache.cache(iconSnapshot)
            }

            self.diagnosticsLogger.log(
                finishedMessage(captured.count),
                level: .debug,
                category: .scan
            )
        }
        return true
    }

    @discardableResult
    func clearCache() -> Bool {
        let success = cache.removeAll()
        diagnosticsLogger.log(
            success ? "Rendered icon cache cleared." : "Rendered icon cache clear failed.",
            level: success ? .info : .warning,
            category: .scan
        )
        return success
    }

    func stop() {
        visibleCaptureTask?.cancel()
        visibleCaptureTask = nil
        revealSweepTask?.cancel()
        revealSweepTask = nil
    }
}
