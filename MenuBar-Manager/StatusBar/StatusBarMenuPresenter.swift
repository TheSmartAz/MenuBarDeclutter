import AppKit
import Foundation

/// Presents the status bar menu and reports whether menu tracking is active.
@MainActor
final class StatusBarMenuPresenter: NSObject, NSMenuDelegate {
    private let menuBuilder: StatusBarMenuBuilder
    private let menuOpenDidChange: (Bool) -> Void
    private var isMenuOpen = false

    init(
        menuBuilder: StatusBarMenuBuilder,
        menuOpenDidChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.menuBuilder = menuBuilder
        self.menuOpenDidChange = menuOpenDidChange
        super.init()
    }

    func showMenu(from button: NSStatusBarButton) {
        let menu = menuBuilder.makeMenu()
        menu.delegate = self
        menu.popUp(
            positioning: nil,
            at: NSPoint(x: 0, y: button.bounds.height),
            in: button
        )
    }

    func refresh(for visibility: HidingVisibilityState) {
        menuBuilder.refresh(for: visibility)
    }

    func resetMenuOpenState() {
        setMenuOpen(false)
    }

    func menuWillOpen(_ menu: NSMenu) {
        setMenuOpen(true)
    }

    func menuDidClose(_ menu: NSMenu) {
        setMenuOpen(false)
    }

    private func setMenuOpen(_ isOpen: Bool) {
        guard isMenuOpen != isOpen else { return }
        isMenuOpen = isOpen
        menuOpenDidChange(isOpen)
    }
}
