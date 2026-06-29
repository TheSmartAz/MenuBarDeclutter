import AppKit

@MainActor
struct IconGroupStatusItemHandle {
    let item: NSStatusItem
    let target: IconGroupStatusItemTarget
}

@MainActor
final class IconGroupStatusItemFactory {
    private let diagnosticsLogger: DiagnosticsLogger

    init(diagnosticsLogger: DiagnosticsLogger) {
        self.diagnosticsLogger = diagnosticsLogger
    }

    func makeStatusItem(
        for group: IconGroup,
        open: @escaping () -> Void,
        edit: @escaping () -> Void,
        hide: @escaping () -> Void
    ) -> IconGroupStatusItemHandle {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let target = IconGroupStatusItemTarget(group: group, open: open, edit: edit, hide: hide)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: group.symbolName ?? "folder", accessibilityDescription: group.name)
            button.title = group.symbolName == nil ? String(group.name.prefix(1)) : ""
            button.target = target
            button.action = #selector(IconGroupStatusItemTarget.handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = group.name
        }
        diagnosticsLogger.log("Created group status item.", level: .debug, category: .layout)
        return IconGroupStatusItemHandle(item: item, target: target)
    }

    func remove(_ item: NSStatusItem) {
        NSStatusBar.system.removeStatusItem(item)
    }
}

@MainActor
final class IconGroupStatusItemTarget: NSObject {
    private let group: IconGroup
    private let open: () -> Void
    private let edit: () -> Void
    private let hide: () -> Void

    init(
        group: IconGroup,
        open: @escaping () -> Void,
        edit: @escaping () -> Void,
        hide: @escaping () -> Void
    ) {
        self.group = group
        self.open = open
        self.edit = edit
        self.hide = hide
    }

    @objc func handleClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Open Group", action: #selector(openGroup), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Edit Group", action: #selector(editGroup), keyEquivalent: ""))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Hide Group Status Item", action: #selector(hideGroup), keyEquivalent: ""))
            for item in menu.items {
                item.target = self
            }
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
        } else {
            open()
        }
    }

    @objc private func openGroup() {
        open()
    }

    @objc private func editGroup() {
        edit()
    }

    @objc private func hideGroup() {
        hide()
    }
}
