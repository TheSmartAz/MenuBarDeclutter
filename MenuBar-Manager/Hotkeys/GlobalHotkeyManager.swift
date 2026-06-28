import AppKit
import Carbon
import Carbon.HIToolbox
import Foundation
import Synchronization

/// Owns Carbon `RegisterEventHotKey` registrations for app-level global hotkeys.
///
/// Phase 5 adds named registrations so the Basic visibility toggle and the
/// optional Find Icon search hotkey can coexist. Carbon callbacks cannot
/// capture Swift context, so a shared mutex stores the active manager and the
/// callback forwards the pressed hotkey ID back to `MainActor`.
@MainActor
final class GlobalHotkeyManager {
    enum RegistrationIdentifier: String, CaseIterable, Hashable, Sendable {
        case visibilityToggle
        case findIcon

        var displayName: String {
            switch self {
            case .visibilityToggle:
                "Visibility Toggle"
            case .findIcon:
                "Find Icon"
            }
        }
    }

    private struct ActiveRegistration {
        let identifier: RegistrationIdentifier
        let hotkey: HotkeyModel
        let carbonID: UInt32
        let action: () -> Void
    }

    private nonisolated static let activeManagerMutex: Mutex<GlobalHotkeyManager?> = Mutex(nil)

    private let diagnosticsLogger: DiagnosticsLogger

    private nonisolated(unsafe) var eventHandler: EventHandlerRef?
    private var eventHandlerInstalled = false
    private nonisolated(unsafe) var registeredHotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var currentHotkeyIDCounter: UInt32 = 0
    private var registrationsByIdentifier: [RegistrationIdentifier: ActiveRegistration] = [:]
    private var identifierByCarbonID: [UInt32: RegistrationIdentifier] = [:]

    /// Backward-compatible visibility-toggle hotkey accessor.
    var registeredHotkey: HotkeyModel? {
        registeredHotkey(identifier: .visibilityToggle)
    }

    var isRegistered: Bool {
        !registrationsByIdentifier.isEmpty
    }

    /// Closure invoked when the visibility-toggle hotkey fires. Always called
    /// on the main actor. Kept so Phase 2 call sites do not need to know about
    /// named registrations.
    var onTrigger: (() -> Void)?

    init(diagnosticsLogger: DiagnosticsLogger) {
        self.diagnosticsLogger = diagnosticsLogger
        installApplicationEventHandler()
        Self.activeManagerMutex.withLock { $0 = self }
    }

    deinit {
        Self.activeManagerMutex.withLock { manager in
            if manager === self {
                manager = nil
            }
        }
        for ref in registeredHotKeyRefs.values {
            UnregisterEventHotKey(ref)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    /// Updates the visibility-toggle hotkey. Passing `nil` unregisters.
    func register(hotkey: HotkeyModel?) {
        register(identifier: .visibilityToggle, hotkey: hotkey) { [weak self] in
            self?.onTrigger?()
        }
    }

    /// Updates a named hotkey registration. Passing `nil` unregisters that
    /// identifier. Failures are logged but never crash the app.
    func register(
        identifier: RegistrationIdentifier,
        hotkey: HotkeyModel?,
        action: @escaping () -> Void
    ) {
        unregister(identifier: identifier)

        guard let hotkey else {
            diagnosticsLogger.log("\(identifier.displayName) hotkey cleared.", level: .debug)
            return
        }

        guard !hotkey.hasNoModifiers else {
            diagnosticsLogger.log(
                "Refusing to register \(identifier.displayName) hotkey with no modifiers.",
                level: .warning
            )
            return
        }

        currentHotkeyIDCounter &+= 1
        let carbonID = currentHotkeyIDCounter
        let id = EventHotKeyID(signature: AppConstants.hotkeyIDSignature, id: carbonID)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.modifiersRaw,
            id,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status == noErr, let ref {
            registeredHotKeyRefs[carbonID] = ref
            registrationsByIdentifier[identifier] = ActiveRegistration(
                identifier: identifier,
                hotkey: hotkey,
                carbonID: carbonID,
                action: action
            )
            identifierByCarbonID[carbonID] = identifier
            diagnosticsLogger.log("Registered \(identifier.displayName) hotkey \(hotkey.displayName).")
        } else {
            diagnosticsLogger.log(
                "Failed to register \(identifier.displayName) hotkey (keyCode=\(hotkey.keyCode), status=\(status)).",
                level: .warning
            )
        }
    }

    func unregister(identifier: RegistrationIdentifier) {
        guard let registration = registrationsByIdentifier.removeValue(forKey: identifier) else {
            return
        }

        if let ref = registeredHotKeyRefs.removeValue(forKey: registration.carbonID) {
            UnregisterEventHotKey(ref)
        }
        identifierByCarbonID.removeValue(forKey: registration.carbonID)
        diagnosticsLogger.log("Unregistered \(identifier.displayName) hotkey.", level: .debug)
    }

    /// Unregisters every active hotkey.
    func unregister() {
        for identifier in Array(registrationsByIdentifier.keys) {
            unregister(identifier: identifier)
        }
    }

    func isRegistered(identifier: RegistrationIdentifier) -> Bool {
        registrationsByIdentifier[identifier] != nil
    }

    func registeredHotkey(identifier: RegistrationIdentifier) -> HotkeyModel? {
        registrationsByIdentifier[identifier]?.hotkey
    }

    private func handleHotKeyPressed(carbonID: UInt32?) {
        let registration: ActiveRegistration?
        if let carbonID,
           let identifier = identifierByCarbonID[carbonID] {
            registration = registrationsByIdentifier[identifier]
        } else if registrationsByIdentifier.count == 1 {
            registration = registrationsByIdentifier.values.first
        } else {
            registration = nil
        }

        guard let registration else {
            diagnosticsLogger.log("Received unknown global hotkey callback.", level: .warning)
            return
        }

        diagnosticsLogger.log("\(registration.identifier.displayName) hotkey fired.")
        registration.action()
    }

    // MARK: Carbon event handler installation

    private func installApplicationEventHandler() {
        guard !eventHandlerInstalled else { return }

        var spec = EventTypeSpec(eventClass: UInt32(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                GlobalHotkeyManager.dispatchHotkeyFromCallback(event)
                return noErr
            },
            1,
            &spec,
            nil,
            &eventHandler
        )

        if status == noErr {
            eventHandlerInstalled = true
            diagnosticsLogger.log("Global hotkey event handler installed.", level: .debug)
        } else {
            diagnosticsLogger.log(
                "Failed to install global hotkey event handler (status=\(status)).",
                level: .warning
            )
        }
    }

    nonisolated static func dispatchHotkeyFromCallback(_ event: EventRef?) {
        let carbonID = carbonHotkeyID(from: event)
        let manager = Self.activeManagerMutex.withLock { $0 }
        guard manager != nil else { return }

        Task { @MainActor in
            manager?.handleHotKeyPressed(carbonID: carbonID)
        }
    }

    private nonisolated static func carbonHotkeyID(from event: EventRef?) -> UInt32? {
        guard let event else { return nil }

        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )

        guard status == noErr else { return nil }
        return hotkeyID.id
    }
}
