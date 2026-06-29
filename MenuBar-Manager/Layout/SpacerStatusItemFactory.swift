import AppKit
import Foundation

/// Creates and manages app-owned `NSStatusItem` spacer/divider items.
///
/// The app owns these status items; the user can Command-drag them like
/// other menu bar items. They are not used to hide third-party icons.
@MainActor
final class SpacerStatusItemFactory {
    private let diagnosticsLogger: DiagnosticsLogger?

    init(diagnosticsLogger: DiagnosticsLogger? = nil) {
        self.diagnosticsLogger = diagnosticsLogger
    }

    /// Create a status item for the given spacer model.
    func makeStatusItem(for model: SpacerItemModel) -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: model.length)

        if let button = item.button {
            button.toolTip = model.title.isEmpty ? "MenuBarDeclutter \(model.type.displayName)" : model.title
            button.setAccessibilityLabel("MenuBarDeclutter \(model.type.displayName)")

            if model.showMarker {
                applyMarker(to: button, model: model)
            } else {
                button.image = nil
                button.title = ""
            }
        }

        return item
    }

    /// Update an existing status item to match the model.
    func update(_ item: NSStatusItem, for model: SpacerItemModel) {
        item.length = model.length

        if let button = item.button {
            button.toolTip = model.title.isEmpty ? "MenuBarDeclutter \(model.type.displayName)" : model.title
            button.setAccessibilityLabel("MenuBarDeclutter \(model.type.displayName)")

            if model.showMarker {
                applyMarker(to: button, model: model)
            } else {
                button.image = nil
                button.title = ""
            }
        }
    }

    /// Remove a status item from the system bar.
    func remove(_ item: NSStatusItem) {
        NSStatusBar.system.removeStatusItem(item)
    }

    private func applyMarker(to button: NSStatusBarButton, model: SpacerItemModel) {
        switch model.type {
        case .divider:
            button.image = nil
            button.title = "|"
        case .thinSpacer:
            button.image = nil
            button.title = "·"
        case .wideSpacer:
            button.image = nil
            button.title = ""
        case .label:
            button.image = nil
            button.title = model.title
        case .icon:
            if let imageName = model.systemImageName,
               let image = NSImage(systemSymbolName: imageName, accessibilityDescription: model.title) {
                image.isTemplate = true
                button.image = image
                button.title = ""
            } else {
                button.image = nil
                button.title = "○"
            }
        case .invisible:
            button.image = nil
            button.title = ""
        }
    }
}
