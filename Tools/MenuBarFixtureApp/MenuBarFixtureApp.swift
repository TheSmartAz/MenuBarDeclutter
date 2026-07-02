import AppKit

@main
struct MenuBarFixtureAppMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = MenuBarFixtureAppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}

@MainActor
final class MenuBarFixtureAppDelegate: NSObject, NSApplicationDelegate {
    private let controller = MenuBarFixtureController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller.install()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.removeAllItems()
    }
}

@MainActor
final class MenuBarFixtureController {
    private enum FixtureKind {
        case icon(systemName: String)
        case title(String)
        case dynamic
        case badge
    }

    private struct FixtureDefinition {
        let name: String
        let length: CGFloat
        let kind: FixtureKind
        let menuItems: [String]
    }

    private var statusItems: [NSStatusItem] = []
    private var noisyItems: [NSStatusItem] = []
    private var dynamicTimer: Timer?
    private var dynamicUpdatesEnabled = true
    private var dynamicTick = 0
    private var badgeTick = 0

    private let definitions: [FixtureDefinition] = [
        FixtureDefinition(
            name: "Fixture Icon 1",
            length: NSStatusItem.squareLength,
            kind: .icon(systemName: "circle.fill"),
            menuItems: []
        ),
        FixtureDefinition(
            name: "Fixture Icon 2",
            length: NSStatusItem.squareLength,
            kind: .icon(systemName: "star.fill"),
            menuItems: []
        ),
        FixtureDefinition(
            name: "Fixture Title 1",
            length: NSStatusItem.variableLength,
            kind: .title("FX1"),
            menuItems: []
        ),
        FixtureDefinition(
            name: "Fixture Wide 1",
            length: NSStatusItem.variableLength,
            kind: .title("Fixture Wide Item"),
            menuItems: []
        ),
        FixtureDefinition(
            name: "Fixture Dynamic 1",
            length: NSStatusItem.variableLength,
            kind: .dynamic,
            menuItems: []
        ),
        FixtureDefinition(
            name: "Fixture Menu 1",
            length: NSStatusItem.variableLength,
            kind: .title("Menu"),
            menuItems: ["First action", "Second action"]
        ),
        FixtureDefinition(
            name: "Fixture Badge 1",
            length: NSStatusItem.variableLength,
            kind: .badge,
            menuItems: []
        ),
        FixtureDefinition(
            name: "Fixture Hidden Test 1",
            length: NSStatusItem.variableLength,
            kind: .title("Hide 1"),
            menuItems: []
        ),
        FixtureDefinition(
            name: "Fixture Hidden Test 2",
            length: NSStatusItem.variableLength,
            kind: .title("Hide 2"),
            menuItems: []
        ),
        FixtureDefinition(
            name: "Fixture Long Menu",
            length: NSStatusItem.variableLength,
            kind: .title("Long"),
            menuItems: [
                "Long option 1",
                "Long option 2",
                "Long option 3",
                "Long option 4",
                "Long option 5",
                "Long option 6"
            ]
        )
    ]

    func install() {
        removeAllItems()
        dynamicTick = 0
        badgeTick = 0
        statusItems = definitions.map(makeStatusItem)
        startTimerIfNeeded()
    }

    func removeAllItems() {
        dynamicTimer?.invalidate()
        dynamicTimer = nil
        for item in statusItems + noisyItems {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItems.removeAll()
        noisyItems.removeAll()
    }

    private func makeStatusItem(definition: FixtureDefinition) -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: definition.length)
        configure(item, with: definition)
        return item
    }

    private func configure(_ item: NSStatusItem, with definition: FixtureDefinition) {
        item.button?.identifier = NSUserInterfaceItemIdentifier(definition.name)
        item.button?.setAccessibilityLabel(definition.name)
        item.button?.toolTip = definition.name

        switch definition.kind {
        case let .icon(systemName):
            item.button?.image = NSImage(
                systemSymbolName: systemName,
                accessibilityDescription: definition.name
            )
            item.button?.title = ""
        case let .title(title):
            item.button?.title = title
        case .dynamic:
            item.button?.title = "Dyn 0"
        case .badge:
            item.button?.title = "B0"
            item.button?.image = NSImage(
                systemSymbolName: "bell",
                accessibilityDescription: definition.name
            )
            item.button?.imagePosition = .imageLeading
        }

        item.menu = menu(for: definition)
    }

    private func menu(for definition: FixtureDefinition) -> NSMenu {
        let menu = NSMenu(title: definition.name)
        let title = NSMenuItem(title: definition.name, action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)

        for itemTitle in definition.menuItems {
            menu.addItem(NSMenuItem(title: itemTitle, action: nil, keyEquivalent: ""))
        }

        if !definition.menuItems.isEmpty {
            menu.addItem(.separator())
        }

        menu.addItem(
            NSMenuItem(
                title: dynamicUpdatesEnabled ? "Pause Dynamic Updates" : "Resume Dynamic Updates",
                action: #selector(toggleDynamicUpdates),
                keyEquivalent: ""
            ).targeting(self)
        )
        menu.addItem(NSMenuItem(title: "Reset Fixture Items", action: #selector(resetItems), keyEquivalent: "").targeting(self))
        menu.addItem(NSMenuItem(title: "Add Noisy Items", action: #selector(addNoisyItems), keyEquivalent: "").targeting(self))
        menu.addItem(NSMenuItem(title: "Remove Noisy Items", action: #selector(removeNoisyItems), keyEquivalent: "").targeting(self))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Fixture", action: #selector(quit), keyEquivalent: "q").targeting(self))
        return menu
    }

    private func startTimerIfNeeded() {
        dynamicTimer?.invalidate()
        dynamicTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard dynamicUpdatesEnabled else { return }
        dynamicTick += 1
        badgeTick += 1

        for (index, definition) in definitions.enumerated() {
            guard statusItems.indices.contains(index) else { continue }
            let item = statusItems[index]
            switch definition.kind {
            case .dynamic:
                item.button?.title = "Dyn \(dynamicTick % 100)"
            case .badge:
                item.button?.title = "B\(badgeTick % 10)"
                let imageName = badgeTick.isMultiple(of: 2) ? "bell" : "bell.badge"
                item.button?.image = NSImage(
                    systemSymbolName: imageName,
                    accessibilityDescription: definition.name
                )
            case .icon, .title:
                break
            }
        }
    }

    @objc private func resetItems() {
        install()
    }

    @objc private func toggleDynamicUpdates() {
        dynamicUpdatesEnabled.toggle()
        refreshMenus()
    }

    @objc private func addNoisyItems() {
        guard noisyItems.isEmpty else { return }
        noisyItems = (1...5).map { index in
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.title = "Noise \(index)"
            item.button?.identifier = NSUserInterfaceItemIdentifier("Fixture Noise \(index)")
            item.button?.setAccessibilityLabel("Fixture Noise \(index)")
            item.button?.toolTip = "Fixture Noise \(index)"
            item.menu = menu(
                for: FixtureDefinition(
                    name: "Fixture Noise \(index)",
                    length: NSStatusItem.variableLength,
                    kind: .title("Noise \(index)"),
                    menuItems: []
                )
            )
            return item
        }
    }

    @objc private func removeNoisyItems() {
        for item in noisyItems {
            NSStatusBar.system.removeStatusItem(item)
        }
        noisyItems.removeAll()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func refreshMenus() {
        for (index, definition) in definitions.enumerated() where statusItems.indices.contains(index) {
            statusItems[index].menu = menu(for: definition)
        }
        for (index, item) in noisyItems.enumerated() {
            item.menu = menu(
                for: FixtureDefinition(
                    name: "Fixture Noise \(index + 1)",
                    length: NSStatusItem.variableLength,
                    kind: .title("Noise \(index + 1)"),
                    menuItems: []
                )
            )
        }
    }
}

private extension NSMenuItem {
    func targeting(_ target: AnyObject) -> NSMenuItem {
        self.target = target
        return self
    }
}
