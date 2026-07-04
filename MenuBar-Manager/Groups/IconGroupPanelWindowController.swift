import AppKit
import SwiftUI

@MainActor
final class IconGroupPanelWindowController: NSWindowController, NSWindowDelegate {
    private let diagnosticsLogger: DiagnosticsLogger
    private let activationService: IconGroupActivationService
    private let protectedActionGate: ProtectedActionGate?

    init(
        diagnosticsLogger: DiagnosticsLogger,
        activationService: IconGroupActivationService,
        protectedActionGate: ProtectedActionGate? = nil
    ) {
        self.diagnosticsLogger = diagnosticsLogger
        self.activationService = activationService
        self.protectedActionGate = protectedActionGate

        let panel = IconGroupPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.applyMenuBarDeclutterFloatingPanelStyle(title: "Group")
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.minSize = NSSize(width: 500, height: 360)

        super.init(window: panel)
        panel.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("IconGroupPanelWindowController does not support storyboards.")
    }

    func show(group: IconGroup, snapshots: [MenuBarItemSnapshot]) {
        let root = IconGroupPanelRootView(
            group: group,
            snapshots: snapshots,
            onActivate: { [weak self] snapshot in
                guard let self else {
                    return MenuItemActivationResult(outcome: .selectedWithoutHighlight, message: "Group panel unavailable.")
                }
                return self.activate(snapshot: snapshot, in: group)
            },
            onDismiss: { [weak self] in
                self?.window?.close()
            }
        )

        window?.contentViewController = NSHostingController(rootView: root)
        window?.title = group.name
        window?.setContentSize(NSSize(width: 560, height: 420))
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        diagnosticsLogger.log(
            group.isProtected ? "Protected group panel opened." : "Group panel opened: \(group.name).",
            category: .layout
        )
    }

    private func activate(snapshot: MenuBarItemSnapshot, in group: IconGroup) -> MenuItemActivationResult {
        let resource = ProtectedResource.protectedGroup(group.id)
        guard group.isProtected, protectedActionGate?.canAccessWithoutPrompt(resource) == false else {
            return activationService.activate(snapshot: snapshot)
        }

        Task { @MainActor in
            await protectedActionGate?.execute(
                resource: resource,
                reason: "Unlock to open \(group.name)."
            ) {
                _ = activationService.activate(snapshot: snapshot)
            }
        }
        return MenuItemActivationResult(
            outcome: .selectedWithoutHighlight,
            message: "Private Access authentication requested."
        )
    }

    func windowDidResignKey(_ notification: Notification) {
        guard window?.isVisible == true else { return }
        window?.close()
    }
}

private final class IconGroupPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
