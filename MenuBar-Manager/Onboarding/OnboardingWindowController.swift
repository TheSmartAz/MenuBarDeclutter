import AppKit
import SwiftUI

/// Owns the AppKit onboarding window and hosts the SwiftUI onboarding content.
/// The window is presented once on first launch (when
/// `SettingsStore.hasCompletedOnboarding` is false) and can be re-presented
/// from Settings.
@MainActor
final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    private let navigationModel = OnboardingNavigationModel()
    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let onComplete: () -> Void
    private let onOpenSettings: () -> Void
    private let onOpenArrange: () -> Void
    private let onOpenWorkspaces: () -> Void
    private let onCreateSampleWorkspace: () -> Void

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        onComplete: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void = {},
        onOpenArrange: @escaping () -> Void = {},
        onOpenWorkspaces: @escaping () -> Void = {},
        onCreateSampleWorkspace: @escaping () -> Void = {}
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.onComplete = onComplete
        self.onOpenSettings = onOpenSettings
        self.onOpenArrange = onOpenArrange
        self.onOpenWorkspaces = onOpenWorkspaces
        self.onCreateSampleWorkspace = onCreateSampleWorkspace

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 740, height: 620),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "\(AppConstants.displayName) Setup"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.isReleasedWhenClosed = false
        window.center()
        window.minSize = NSSize(width: 700, height: 560)

        super.init(window: window)

        let contentView = OnboardingRootView(
            navigationModel: navigationModel,
            onComplete: { [weak self] in
                self?.complete()
            },
            onOpenSettings: { [weak self] in
                self?.onOpenSettings()
            },
            onOpenArrange: { [weak self] in
                self?.onOpenArrange()
            },
            onOpenWorkspaces: { [weak self] in
                self?.onOpenWorkspaces()
            },
            onCreateSampleWorkspace: { [weak self] in
                self?.onCreateSampleWorkspace()
            }
        )

        window.contentViewController = NSHostingController(rootView: contentView)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("OnboardingWindowController does not support storyboards.")
    }

    func showIfNeeded() -> Bool {
        guard !settingsStore.hasCompletedOnboarding else { return false }
        show()
        return true
    }

    func show() {
        navigationModel.reset()
        if window?.isVisible != true {
            window?.center()
        }
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        diagnosticsLogger.log("Onboarding presented.", level: .info)
    }

    func complete() {
        settingsStore.hasCompletedOnboarding = true
        diagnosticsLogger.log("Onboarding completed.", level: .info)
        window?.close()
        onComplete()
    }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Closing without completing (e.g. via the red traffic-light button)
        // does not mark onboarding complete; the user can re-trigger from
        // Settings → General → Show Onboarding Again.
    }
}
