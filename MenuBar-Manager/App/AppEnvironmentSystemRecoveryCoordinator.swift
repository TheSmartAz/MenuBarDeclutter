import AppKit

@MainActor
final class AppEnvironmentSystemRecoveryCoordinator {
    private let recoverAfterSystemChange: (String) -> Void
    private var observers: [NSObjectProtocol] = []

    init(recoverAfterSystemChange: @escaping (String) -> Void) {
        self.recoverAfterSystemChange = recoverAfterSystemChange
    }

    func startObserving() {
        guard observers.isEmpty else { return }

        let notificationCenter = NotificationCenter.default
        observers.append(
            notificationCenter.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: NSApp,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.recoverAfterSystemChange("screen parameters changed")
                }
            }
        )

        observers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.recoverAfterSystemChange("workspace wake")
                }
            }
        )

        observers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.activeSpaceDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.recoverAfterSystemChange("active space changed")
                }
            }
        )
    }

    func stopObserving() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
    }
}
